import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _onboardingComplete = false;
  int _currentStep = 1;

  // Form Controllers for Step 1: Socials
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _spotifyController = TextEditingController();

  // Form Controllers for Step 2: Personal Details
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdayController = TextEditingController();

  // 📸 NEW: Local Memory File Holder instead of text URL string input
  File? _selectedImage;
  String? _savedAvatarPath;

  @override
  void initState() {
    super.initState();
    _checkUserOnboardingStatus();
  }

  Future<void> _checkUserOnboardingStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await supabase
          .from('profiles')
          .select(
            'onboarding_complete, display_name, phone_number, birthday, avatar_url',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _onboardingComplete = data['onboarding_complete'] ?? false;
          if (_onboardingComplete) {
            _displayNameController.text = data['display_name'] ?? 'User';
            _phoneController.text = data['phone_number'] ?? '';
            _birthdayController.text = data['birthday'] ?? '';
            _savedAvatarPath = data['avatar_url'];
          }
        });
        if (_onboardingComplete) {
          await _loadSocialLinks(user.id);
        }
      }
      setState(() => _isLoading = false);
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSocialLinks(String userId) async {
    final data = await supabase
        .from('social_links')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data != null) {
      setState(() {
        _instagramController.text = data['instagram'] ?? '';
        _linkedinController.text = data['linkedin'] ?? '';
        _githubController.text = data['github'] ?? '';
        _spotifyController.text = data['spotify'] ?? '';
      });
    }
  }

  // 🖼️ NATIVE FUNCTION: Wake up device antenna and select image from gallery frame
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality:
          70, // Compresses image profile footprint file size down for instant cloud parsing
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _saveSocialStep() {
    if (_instagramController.text.isEmpty && _linkedinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one social handle to proceed.'),
        ),
      );
      return;
    }
    setState(() => _currentStep = 2);
  }

  Future<void> _finalizeOnboarding() async {
    if (_displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name field is required.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      final userId = user?.id ?? '00000000-0000-0000-0000-000000000000';

      // Fallback display vector image if no image asset picked
      String finalAvatarPath = _selectedImage != null
          ? _selectedImage!.path
          : 'https://api.dicebear.com/7.x/bottts/svg?seed=${_displayNameController.text}';

      await supabase.from('profiles').upsert({
        'id': userId,
        'username': _displayNameController.text.trim().toLowerCase().replaceAll(
          ' ',
          '',
        ),
        'display_name': _displayNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'avatar_url':
            finalAvatarPath, // Saves local image source track path vector line
        'onboarding_complete': true,
      });

      await supabase.from('social_links').upsert({
        'id': userId,
        'instagram': _instagramController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'spotify': _spotifyController.text.trim(),
      });

      setState(() {
        _savedAvatarPath = finalAvatarPath;
        _onboardingComplete = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Onboarding Error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050507),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      );
    }

    if (_onboardingComplete) {
      return _buildDashboardView();
    }

    return _currentStep == 1
        ? _buildSocialsOnboardingView()
        : _buildPersonalOnboardingView();
  }

  Widget _buildSocialsOnboardingView() {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'STEP 1 OF 2',
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Link Your Profiles',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the social handles you want to deploy to your physical 7even NFC card.',
                style: TextStyle(color: Color(0xFF6C6C7A), fontSize: 14),
              ),
              const SizedBox(height: 40),
              _buildMinimalTextField(
                controller: _instagramController,
                hint: 'Instagram Username',
                icon: Icons.camera_alt,
                accentColor: Colors.pinkAccent,
              ),
              const SizedBox(height: 16),
              _buildMinimalTextField(
                controller: _linkedinController,
                hint: 'LinkedIn Profile Handle',
                icon: Icons.business,
                accentColor: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              _buildMinimalTextField(
                controller: _githubController,
                hint: 'GitHub Username',
                icon: Icons.code,
                accentColor: Colors.white,
              ),
              const SizedBox(height: 16),
              _buildMinimalTextField(
                controller: _spotifyController,
                hint: 'Spotify Playlist/User Link',
                icon: Icons.music_note,
                accentColor: Colors.greenAccent,
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _saveSocialStep,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Continue to Personal Details',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalOnboardingView() {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () => setState(() => _currentStep = 1),
              ),
              const SizedBox(height: 16),
              const Text(
                'STEP 2 OF 2',
                style: TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Personal Identity',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete your public profile frame configuration.',
                style: TextStyle(color: Color(0xFF6C6C7A), fontSize: 14),
              ),
              const SizedBox(height: 40),

              // 📸 PREMIUM SLICK GALLERY PICKER BOTTON MATRIX
              Center(
                child: GestureDetector(
                  onTap: _pickImageFromGallery,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFF121216),
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : null,
                        child: _selectedImage == null
                            ? const Icon(
                                Icons.add_a_photo_outlined,
                                color: Colors.deepPurpleAccent,
                                size: 28,
                              )
                            : null,
                      ),
                      if (_selectedImage != null)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.deepPurpleAccent,
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Upload Display Photo',
                  style: TextStyle(
                    color: Color(0xFF6C6C7A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildMinimalTextField(
                controller: _displayNameController,
                hint: 'Your Full Name',
                icon: Icons.person,
                accentColor: Colors.deepPurpleAccent,
              ),
              const SizedBox(height: 16),
              _buildMinimalTextField(
                controller: _phoneController,
                hint: 'Contact Phone Number',
                icon: Icons.phone,
                accentColor: Colors.grey,
              ),
              const SizedBox(height: 16),
              _buildMinimalTextField(
                controller: _birthdayController,
                hint: 'Birthday (DD/MM/YYYY)',
                icon: Icons.cake,
                accentColor: Colors.grey,
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: _finalizeOnboarding,
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Complete Setup & Launch Matrix',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      appBar: AppBar(
        title: const Text(
          '7EVEN DASHBOARD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6C6C7A), size: 18),
            onPressed: () {
              supabase.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF121216),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1C1C24)),
              ),
              child: Row(
                children: [
                  // Dynamic Render Image Avatar from Local Storage or Web
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.deepPurpleAccent.withOpacity(0.15),
                    backgroundImage:
                        _savedAvatarPath != null &&
                            !_savedAvatarPath!.startsWith('http')
                        ? FileImage(File(_savedAvatarPath!)) as ImageProvider
                        : (_savedAvatarPath != null
                              ? NetworkImage(_savedAvatarPath!)
                              : null),
                    child: _savedAvatarPath == null
                        ? const Icon(
                            Icons.person,
                            color: Colors.deepPurpleAccent,
                            size: 30,
                          )
                        : null,
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayNameController.text,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⚡ Live Matrix Node',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Social Network Vectors',
              style: TextStyle(
                color: Color(0xFF6C6C7A),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                if (_instagramController.text.isNotEmpty)
                  _buildDashboardBentoTile(
                    title: 'Instagram',
                    value: _instagramController.text,
                    icon: Icons.camera_alt,
                    color: Colors.pinkAccent,
                    url: 'instagram://user?username=',
                  ),
                if (_linkedinController.text.isNotEmpty)
                  _buildDashboardBentoTile(
                    title: 'LinkedIn',
                    value: _linkedinController.text,
                    icon: Icons.business,
                    color: Colors.blueAccent,
                    url: 'linkedin://profile/',
                  ),
                if (_githubController.text.isNotEmpty)
                  _buildDashboardBentoTile(
                    title: 'GitHub',
                    value: _githubController.text,
                    icon: Icons.code,
                    color: Colors.white,
                    url: 'https://github.com/',
                  ),
                if (_spotifyController.text.isNotEmpty)
                  _buildDashboardBentoTile(
                    title: 'Spotify',
                    value: _spotifyController.text,
                    icon: Icons.music_note,
                    color: Colors.greenAccent,
                    url: 'spotify://user/',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121216),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C1C24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          icon: Icon(icon, color: accentColor, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF4C4C5E)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDashboardBentoTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String url,
  }) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Launching native app loop for $title...'),
            backgroundColor: color.withOpacity(0.8),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121216),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF1C1C24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                const Icon(
                  Icons.arrow_outward,
                  color: Color(0xFF4C4C5E),
                  size: 14,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6C6C7A),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
