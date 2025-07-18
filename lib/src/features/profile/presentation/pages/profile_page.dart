import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Avatar and user info
              CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF6C63FF),
                child: Text(
                  'EF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Eshonov Fakhriyor',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'Faksa.the@gmail.com',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Vehicle card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Volvo VNL Series',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '-\$100',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/images/truck.png',
                          width: 64,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Menu items
              _ProfileMenu(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileMenuItem(
          icon: Icons.person_outline,
          title: 'Mening ma’lumotlarim',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.history,
          title: 'Buyurtmalar tarixi',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.star_border,
          title: 'Ilovamizni baholang',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.help_outline,
          title: 'Savol yoki takliflar uchun',
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.language,
          title: 'Til',
          trailing: const Text(
            'O’zbekcha',
            style: TextStyle(color: Colors.grey),
          ),
          onTap: () {},
        ),
        _ProfileMenuItem(
          icon: Icons.build_outlined,
          title: 'Usta bo’lish',
          onTap: () {},
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
    );
  }
}
