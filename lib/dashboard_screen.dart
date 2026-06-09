import 'package:flutter/material.dart';
import 'main.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _profileExists = false;

  // Controllers for the onboarding form fields
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  // Controllers for the social matrix fields
  final _instagramController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _githubController = TextEditingController();
  final _spotifyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  // 1. Check Profile status using a static test user profile row
  Future<void> _checkProfileStatus() async {
    try {
      const testUserId = '00000000-0000-0000-0000-000000000000';

      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', testUserId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profileExists = data != null;
          _isLoading = false;
        });

        if (_profileExists) {
          _loadSocialLinks(testUserId);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 2. Load existing vectors from the social_links table
  Future<void> _loadSocialLinks(String userId) async {
    try {
      final data = await supabase
          .from('social_links')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _instagramController.text = data['instagram'] ?? '';
          _linkedinController.text = data['linkedin'] ?? '';
          _githubController.text = data['github'] ?? '';
          _spotifyController.text = data['spotify'] ?? '';
        });
      }
    } catch (_) {
      // Quietly pass if no link row exists yet
    }
  }

  // 3. Insert profile using a randomized timestamp string to fake a unique User ID
  Future<void> _createProfile() async {
    final username = _usernameController.text.trim().toLowerCase();
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();

    if (username.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username and Display Name are mandatory.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fakeUniqueId =
          '00000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';

      await supabase.from('profiles').insert({
        'id': fakeUniqueId,
        'username': username,
        'display_name': displayName,
        'bio': bio,
      });

      if (mounted) {
        setState(() {
          _profileExists = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Username taken or error: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 4. Upsert vector records directly into the social_links table
  Future<void> _syncSocialMatrix() async {
    setState(() => _isLoading = true);
    try {
      const testUserId = '00000000-0000-0000-0000-000000000000';

      await supabase.from('social_links').upsert({
        'id': testUserId,
        'instagram': _instagramController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'github': _githubController.text.trim(),
        'spotify': _spotifyController.text.trim(),
      });

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vectors synchronized to 7even.online cloud!'),
            backgroundColor: Colors.deepPurpleAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync Failed: $error'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B0F),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
        ),
      );
    }

    if (_profileExists) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0B0F),
        appBar: AppBar(
          title: const Text(
            '7even Control Matrix',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
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
              const Text(
                'Your Digital Matrix',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Update your vectors. Changes deploy globally instantly.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 28),

              _buildLinkField(
                controller: _instagramController,
                label: 'Instagram Username',
                prefix: 'instagram.com/',
                icon: Icons.camera_alt,
                color: Colors.pinkAccent,
              ),
              const SizedBox(height: 16),

              _buildLinkField(
                controller: _linkedinController,
                label: 'LinkedIn Profile Name',
                prefix: 'linkedin.com/in/',
                icon: Icons.business,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),

              _buildLinkField(
                controller: _githubController,
                label: 'GitHub Username',
                prefix: 'github.com/',
                icon: Icons.code,
                color: Colors.white,
              ),
              const SizedBox(height: 16),

              _buildLinkField(
                controller: _spotifyController,
                label: 'Spotify Username',
                prefix: 'spotify.com/',
                icon: Icons.music_note,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 36),

              ElevatedButton.icon(
                onPressed: _syncSocialMatrix,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.sync, color: Colors.white),
                label: const Text(
                  'Sync Social Matrix',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            const Text(
              'Claim Your Handle',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This maps directly to your physical NFC card.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 36),

            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Unique Username (e.g., ishaan)',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixText: '@ ',
                prefixStyle: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color(0xFF12121A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _displayNameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Display Name (Your full name)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12121A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio (Tell others who you are)',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF12121A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _createProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Initialize Digital Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkField({
    required TextEditingController controller,
    required String label,
    required String prefix,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        prefixText: prefix,
        prefixStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: const Color(0xFF12121A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
