import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../settings/language_settings_screen.dart';
import '../../../providers/language_provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../widgets/language_selector_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, LanguageProvider>(
      builder: (context, authProvider, languageProvider, child) {
        final user = authProvider.currentUser;
        final lang = languageProvider.currentLanguage;

        if (user == null) {
          return _buildLoginPrompt(context, lang);
        }

        return Scaffold(
          body: Stack(
            children: [
              // OVERALL BACKGROUND IMAGE
              Positioned.fill(
                child: Image.asset(
                  'assets/images/backgrounds/OVERALLBACKGROUND.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  repeat: ImageRepeat.noRepeat,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/background.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      repeat: ImageRepeat.noRepeat,
                      errorBuilder: (ctx, err, stack) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade50, Colors.amber.shade50],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                      colors: [
                        Colors.white.withOpacity(0.80),
                        Colors.white.withOpacity(0.65),
                        Colors.white.withOpacity(0.70),
                        Colors.white.withOpacity(0.80),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: 240,
                    floating: false,
                    pinned: true,
                    backgroundColor: Colors.green.shade700.withOpacity(0.9),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: const LanguageSelectorWidget(showAsButton: true),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade700.withOpacity(0.9),
                              Colors.green.shade500.withOpacity(0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  user.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user.role == 'farmer'
                                    ? '👨‍🌾 ${AppStrings.get('profile', 'farmer', lang)}'
                                    : '👔 ${AppStrings.get('profile', 'official', lang)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoCard(
                            title: AppStrings.get('profile', 'contact_information', lang),
                            icon: Icons.contact_phone,
                            children: [
                              _buildInfoRow(Icons.phone, AppStrings.get('profile', 'phone', lang), user.phone),
                              _buildInfoRow(Icons.email, AppStrings.get('profile', 'email', lang), user.email),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (user.role == 'farmer') ...[
                            _buildInfoCard(
                              title: AppStrings.get('profile', 'location_details', lang),
                              icon: Icons.location_on,
                              children: [
                                _buildInfoRow(Icons.home, AppStrings.get('profile', 'village', lang), user.village ?? 'Not specified'),
                                _buildInfoRow(Icons.location_city, AppStrings.get('profile', 'district', lang), user.district ?? 'Not specified'),
                                _buildInfoRow(Icons.map, AppStrings.get('profile', 'state', lang), user.state ?? 'Not specified'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoCard(
                              title: AppStrings.get('profile', 'farm_information', lang),
                              icon: Icons.agriculture,
                              children: [
                                _buildInfoRow(
                                  Icons.landscape,
                                  AppStrings.get('profile', 'farm_size', lang),
                                  user.farmSize != null ? '${user.farmSize} acres' : 'Not specified',
                                ),
                                _buildInfoRow(
                                  Icons.badge,
                                  'Aadhaar',
                                  (user.aadharNumber != null && user.aadharNumber!.length >= 4)
                                      ? '****-****-${user.aadharNumber!.substring(user.aadharNumber!.length - 4)}'
                                      : 'Not provided',
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildSettingsCard(context, lang),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade300.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.green.shade200.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
                Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, String lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.shade300.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.green.shade200.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.settings, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.get('profile', 'settings_support', lang),
                style: GoogleFonts.notoSansDevanagari(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionTile(Icons.language, AppStrings.get('actions', 'change_language', lang), () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()));
          }),
          _buildActionTile(Icons.help_outline, AppStrings.get('profile', 'help_support', lang), () {
            _showHelpDialog(context, lang);
          }),
          const Divider(height: 32),
          _buildActionTile(Icons.logout, AppStrings.get('profile', 'logout', lang), () {
            _showLogoutDialog(context, lang);
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: isDestructive ? Colors.red : Colors.green.shade700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.get('profile', 'help_support', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Helpline'),
              subtitle: const Text('1800-123-4567'),
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('Email'),
              subtitle: const Text('support@krashibandhu.gov.in'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext dialogContext, String lang) {
    showDialog(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('profile', 'logout', lang)),
        content: Text(AppStrings.get('profile', 'are_you_sure_logout', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.get('profile', 'cancel', lang)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await dialogContext.read<AuthProvider>().logout();
              if (mounted) dialogContext.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppStrings.get('profile', 'logout', lang)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, String lang) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/OVERALLBACKGROUND.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade50, Colors.amber.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                );
              },
            ),
          ),

          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.85),
                    Colors.white.withOpacity(0.75),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    Text(
                      AppStrings.get('profile', 'profile', lang),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Message
                    Text(
                      'Please login to view your profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/login'),
                        icon: const Icon(Icons.login, size: 24),
                        label: Text(
                          'Login',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/register'),
                        icon: const Icon(Icons.person_add, size: 24),
                        label: Text(
                          'Create Account',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade700, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Info Cards
                    _buildFeatureCard(
                      icon: Icons.verified_user,
                      title: 'Secure & Private',
                      description: 'Your data is protected',
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      icon: Icons.cloud_done,
                      title: 'Sync Across Devices',
                      description: 'Access from anywhere',
                      color: Colors.purple,
                    ),

                    const SizedBox(height: 12),

                    _buildFeatureCard(
                      icon: Icons.support_agent,
                      title: '24/7 Support',
                      description: 'We\'re here to help',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
