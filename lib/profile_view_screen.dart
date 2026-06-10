import 'package:flutter/material.dart';
import 'main.dart';

class ProfileViewScreen extends StatefulWidget {
  final String username;
  const ProfileViewScreen({super.key, required this.username});

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _linksData;

  @override
  void initState() {
    super.initState();
    _fetchPublicProfile();
  }

  Future<void> _fetchPublicProfile() async {
    try {
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('username', widget.username)
          .maybeSingle();

      if (profile != null) {
        final links = await supabase
            .from('social_links')
            .select()
            .eq('id', profile['id'])
            .maybeSingle();

        if (mounted) {
          setState(() {
            _profileData = profile;
            _linksData = links;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

    if (_profileData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF050507),
        body: Center(
          child: Text(
            'Profile Vector Non-Existent',
            style: TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050507),
      body: Center(
        child: Container(
          // 💡 FIXED: Wrap the layout width rule inside a BoxConstraints argument
          constraints: const BoxConstraints(maxWidth: 450),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurpleAccent.withOpacity(0.2),
                child: Text(
                  _profileData!['display_name'][0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _profileData!['display_name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '@${_profileData!['username']}',
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _profileData!['bio'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),

              if (_linksData?['instagram'] != null &&
                  _linksData!['instagram'].toString().isNotEmpty)
                _buildWebSocialButton(
                  label: 'Instagram',
                  handle: _linksData!['instagram'],
                  color: Colors.pinkAccent,
                  icon: Icons.camera_alt,
                ),
              const SizedBox(height: 12),

              if (_linksData?['linkedin'] != null &&
                  _linksData!['linkedin'].toString().isNotEmpty)
                _buildWebSocialButton(
                  label: 'LinkedIn',
                  handle: _linksData!['linkedin'],
                  color: Colors.blueAccent,
                  icon: Icons.business,
                ),
              const SizedBox(height: 12),

              if (_linksData?['github'] != null &&
                  _linksData!['github'].toString().isNotEmpty)
                _buildWebSocialButton(
                  label: 'GitHub',
                  handle: _linksData!['github'],
                  color: Colors.white,
                  icon: Icons.code,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebSocialButton({
    required String label,
    required String handle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF12121A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 14,
        ),
        onTap: () {},
      ),
    );
  }
}
