import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/user_profile.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/local_storage_service.dart';
import '../../../services/auto_sync_service.dart';
import '../../../services/audio_service.dart';
import '../../claims/claims_list_screen.dart';
import '../../schemes/schemes_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../satellite/enhanced_satellite_screen.dart';
import '../../settings/language_settings_screen.dart';
import '../../../providers/language_provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../widgets/language_selector_widget.dart';
import '../../../widgets/wheat_field_background.dart';
import '../../../widgets/audio_player_dialog.dart';
import 'dart:ui';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  bool _isLoading = true;
  int _pendingUploadsCount = 0;
  final LocalStorageService _localStorageService = LocalStorageService();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      _loadPendingUploads();
      _startAutoSync();
    });
  }

  void _startAutoSync() {
    final autoSyncService = context.read<AutoSyncService>();
    final connectivityService = context.read<ConnectivityService>();
    autoSyncService.startPeriodicSync(connectivityService);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    final autoSyncService = context.read<AutoSyncService>();
    autoSyncService.stopPeriodicSync();
    super.dispose();
  }

  Future<void> _loadPendingUploads() async {
    final count = await _localStorageService.getPendingUploadsCount();
    if (mounted) {
      setState(() => _pendingUploadsCount = count);
    }
  }

  Future<void> _loadUserProfile() async {
    final authService = context.read<FirebaseAuthService>();
    final firestoreService = FirestoreService();
    
    if (authService.currentUser != null) {
      final profile = await firestoreService.getUserProfile(
        authService.currentUser!.uid,
      );
      
      // If profile doesn't exist, create a default one with Anshika's details
      if (profile == null) {
        final newProfile = UserProfile(
          uid: authService.currentUser!.uid,
          name: 'Anshika',
          phoneNumber: authService.currentUser!.phoneNumber ?? '',
          email: 'anshika@krashibandhu.in',
          village: 'Jaitpur',
          district: 'Barabanki',
          state: 'Uttar Pradesh',
          crops: ['धान (Rice)', 'गेहूं (Wheat)', 'गन्ना (Sugarcane)'],
          landAreaAcres: 5.0,
        );
        await firestoreService.createUserProfile(newProfile);
        setState(() {
          _userProfile = newProfile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showExitConfirmationDialog() async {
    final lang = context.read<LanguageProvider>().currentLanguage;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          lang == 'hi' ? 'ऐप बंद करें?' : 'Exit App?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          lang == 'hi' 
              ? 'क्या आप वाकई ऐप से बाहर निकलना चाहते हैं?' 
              : 'Are you sure you want to exit the app?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(lang == 'hi' ? 'नहीं' : 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang == 'hi' ? 'हाँ, बाहर निकलें' : 'Yes, Exit'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final List<Widget> screens = [
          _buildHomeScreen(),
          const ClaimsListScreen(),
          const SchemesScreen(),
          const ProfileScreen(),
        ];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldExit = await _showExitConfirmationDialog();
            if (shouldExit && mounted) {
              SystemNavigator.pop();
            }
          },
          child: Scaffold(
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : screens[_selectedIndex],
            floatingActionButton: _selectedIndex == 0
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Support FAB
                  FloatingActionButton(
                    heroTag: 'support',
                    onPressed: _showHelpDialog,
                    backgroundColor: Colors.blue.shade700,
                    child: const Icon(Icons.support_agent, size: 28),
                  ),
                  const SizedBox(height: 12),
                  // AR Camera FAB (NEW)
                  FloatingActionButton(
                    heroTag: 'ar_camera',
                    onPressed: () => context.push('/ar-camera', extra: {
                      'multiAngleMode': true,
                      'purpose': 'crop_inspection',
                    }),
                    backgroundColor: Colors.purple.shade700,
                    child: const Icon(Icons.view_in_ar, size: 28),
                  ),
                  const SizedBox(height: 12),
                  // Camera FAB
                  FloatingActionButton.extended(
                    heroTag: 'camera',
                    onPressed: () => context.push('/camera'),
                    label: Text(AppStrings.get('dashboard', 'capture_image', context.read<LanguageProvider>().currentLanguage)),
                    icon: const Icon(Icons.camera_alt_rounded),
                    backgroundColor: Colors.green.shade700,
                  ),
                ],
              )
            : null,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF1B5E20),
          unselectedItemColor: const Color(0xFF616161),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          elevation: 0,
          backgroundColor: Colors.white,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: AppStrings.get('navigation', 'home', context.read<LanguageProvider>().currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: AppStrings.get('navigation', 'claims', context.read<LanguageProvider>().currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_balance_outlined),
              activeIcon: const Icon(Icons.account_balance),
              label: AppStrings.get('navigation', 'schemes', context.read<LanguageProvider>().currentLanguage),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: AppStrings.get('navigation', 'profile', context.read<LanguageProvider>().currentLanguage),
            ),
          ],
        ),
      ),
        ),
        );
      },
    );
  }

  Widget _buildHomeScreen() {
    // Calculate blur intensity based on scroll (0 to 10)
    double blurIntensity = (_scrollOffset / 50).clamp(0.0, 10.0);
    // Calculate opacity for fade effect
    double opacity = (1.0 - (_scrollOffset / 100)).clamp(0.0, 1.0);
    
    return WheatFieldBackground(
      overlayOpacity: 0.75,
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar with Transparent Background
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: Colors.green.shade700.withOpacity(0.9),
              actions: [
                // Audio Button (Top-Right) - Direct Play Button
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(
                        Icons.headset_mic,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Play Audio',
                      onPressed: _showAudioPlayer,
                      splashRadius: 28,
                    ),
                  ),
                ),
                // Enhanced Language Selector
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: const LanguageSelectorWidget(showAsButton: true),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PMFBY',
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      AppStrings.get('pmfbyInfo', 'scheme_name', context.read<LanguageProvider>().currentLanguage),
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.shade700.withOpacity(0.8),
                        Colors.green.shade600.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 70, right: 20, bottom: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Apply blur and fade effect to welcome section
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: blurIntensity,
                                  sigmaY: blurIntensity,
                                ),
                                child: AnimatedOpacity(
                                  opacity: opacity,
                                  duration: const Duration(milliseconds: 50),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.verified_user,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              AppStrings.get('greetings', 'welcome', context.read<LanguageProvider>().currentLanguage),
                                              style: GoogleFonts.notoSansDevanagari(
                                                fontSize: 16,
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              _userProfile?.name ?? "किसान भाई",
                                              style: GoogleFonts.notoSans(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Offline Indicator Banner
            SliverToBoxAdapter(
              child: Consumer<ConnectivityService>(
                builder: (context, connectivityService, child) {
                  if (connectivityService.isOnline) {
                    return const SizedBox.shrink();
                  }
                  
                  return Material(
                    color: Colors.orange.shade600,
                    child: InkWell(
                      onTap: () => context.push('/upload-status'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppStrings.get('dashboard', 'offline_mode', context.read<LanguageProvider>().currentLanguage),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _pendingUploadsCount > 0
                                        ? '$_pendingUploadsCount ${AppStrings.get('dashboard', 'photos_pending_sync', context.read<LanguageProvider>().currentLanguage)}'
                                        : AppStrings.get('dashboard', 'data_will_sync', context.read<LanguageProvider>().currentLanguage),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        '5.0',
                        AppStrings.get('dashboard', 'total_land', context.read<LanguageProvider>().currentLanguage),
                        Icons.landscape,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '3',
                        AppStrings.get('dashboard', 'crops', context.read<LanguageProvider>().currentLanguage),
                        Icons.eco,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        '2',
                        AppStrings.get('dashboard', 'active_claims', context.read<LanguageProvider>().currentLanguage),
                        Icons.pending_actions,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main Action Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/capture-image'),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.get('dashboard', 'capture_crop_image', context.read<LanguageProvider>().currentLanguage),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.get('dashboard', 'capture_with_gps', context.read<LanguageProvider>().currentLanguage),
                                    style: GoogleFonts.roboto(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // PMFBY Info Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: InkWell(
                  onTap: () => context.push('/pmfby-info'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('dashboard', 'scheme_info', context.read<LanguageProvider>().currentLanguage),
                                style: GoogleFonts.notoSansDevanagari(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppStrings.get('dashboard', 'premium_rates', context.read<LanguageProvider>().currentLanguage),
                                style: GoogleFonts.notoSansDevanagari(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions Grid
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildListDelegate([
                  _buildActionCard(
                    AppStrings.get('actions', 'file_claim', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('actions', 'file_claim', 'en'),
                    Icons.add_circle_outline,
                    Colors.blue,
                    () => context.push('/file-claim'),
                  ),
                  _buildActionCard(
                    AppStrings.get('dashboard', 'my_claims', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('dashboard', 'my_claims', 'en'),
                    Icons.history,
                    Colors.orange,
                    () => context.push('/claims'),
                  ),
                  _buildActionCard(
                    AppStrings.get('dashboard', 'insurance_schemes', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('dashboard', 'insurance_schemes', 'en'),
                    Icons.policy,
                    Colors.purple,
                    () => setState(() => _selectedIndex = 2),
                  ),
                  _buildActionCardWithBadge(
                    AppStrings.get('dashboard', 'upload_status', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('dashboard', 'upload_status', 'en'),
                    Icons.cloud_upload,
                    Colors.indigo,
                    () => context.push('/upload-status'),
                    _pendingUploadsCount,
                  ),
                  _buildActionCard(
                    AppStrings.get('dashboard', 'crop_loss_intimation', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('dashboard', 'crop_loss_intimation', 'en'),
                    Icons.report_problem,
                    Colors.red.shade700,
                    () => context.push('/crop-loss-intimation'),
                  ),
                  _buildActionCard(
                    AppStrings.get('dashboard', 'premium_calculator', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('dashboard', 'premium_calculator', 'en'),
                    Icons.calculate_outlined,
                    Colors.green.shade600,
                    () => context.push('/premium-calculator'),
                  ),
                  _buildActionCard(
                    AppStrings.get('dashboard', 'help_center', context.read<LanguageProvider>().currentLanguage),
                    AppStrings.get('dashboard', 'help_center', 'en'),
                    Icons.help_outline,
                    Colors.teal,
                    () => _showHelpDialog(),
                  ),
                  _buildActionCard(
                    context.read<LanguageProvider>().currentLanguage == 'hi' ? 'फीडबैक और रिपोर्ट' : 'Feedback & Report',
                    'Feedback & Report Issues',
                    Icons.feedback_outlined,
                    Colors.deepPurple,
                    () => context.push('/feedback-report'),
                  ),
                  _buildActionCard(
                    context.read<LanguageProvider>().currentLanguage == 'hi' ? 'मेरी रिपोर्ट्स' : 'My Reports',
                    'My Reports Status',
                    Icons.assignment_outlined,
                    Colors.cyan,
                    () => context.push('/my-reports'),
                  ),
                ]),
              ),
            ),

            // Recent Activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('dashboard', 'recent_activity', context.read<LanguageProvider>().currentLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildActivityButton(
                      AppStrings.get('dashboard', 'photo_uploaded', context.read<LanguageProvider>().currentLanguage),
                      '2 ${AppStrings.get('dashboard', 'hours_ago', context.read<LanguageProvider>().currentLanguage)}',
                      Icons.check_circle,
                      Colors.green,
                      () => context.push('/upload-status'),
                    ),
                    _buildActivityButton(
                      AppStrings.get('dashboard', 'ai_analysis_complete', context.read<LanguageProvider>().currentLanguage),
                      '3 ${AppStrings.get('dashboard', 'hours_ago', context.read<LanguageProvider>().currentLanguage)}',
                      Icons.analytics,
                      Colors.blue,
                      () => context.push('/satellite'),
                    ),
                    _buildActivityButton(
                      AppStrings.get('dashboard', 'claim_approved', context.read<LanguageProvider>().currentLanguage),
                      '1 ${AppStrings.get('dashboard', 'days_ago', context.read<LanguageProvider>().currentLanguage)}',
                      Icons.verified,
                      Colors.green,
                      () {
                        setState(() => _selectedIndex = 1); // Switch to Claims tab
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String titleHindi,
    String titleEnglish,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                titleHindi,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titleEnglish,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCardWithBadge(
    String titleHindi,
    String titleEnglish,
    IconData icon,
    Color color,
    VoidCallback onTap,
    int badgeCount,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 28, color: color),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                titleHindi,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                titleEnglish,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 9,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityButton(
    String title,
    String time,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppStrings.get('dashboard', 'customer_support', context.read<LanguageProvider>().currentLanguage),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customer Support',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            // Phone Support Card
            InkWell(
              onTap: () => _makePhoneCall('14447'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'कृषि रक्षक पोर्टल',
                            style: GoogleFonts.notoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Call 14447',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Toll-Free Helpline',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.blue.shade700,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // WhatsApp Support Card
            InkWell(
              onTap: () => _openWhatsApp('7065514447'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade50, Colors.green.shade100],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366), // WhatsApp green
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.chat,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PMFBY व्हाट्सएप चैटबॉट',
                            style: GoogleFonts.notoSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chat: 7065514447',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'WhatsApp Support',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.green.shade700,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.amber.shade700,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'सेवा समय: सोमवार-शुक्रवार, 9 AM - 6 PM\nService Hours: Monday-Friday, 9 AM - 6 PM',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppStrings.get('dashboard', 'close', context.read<LanguageProvider>().currentLanguage),
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('कॉल नहीं की जा सकती: $phoneNumber'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: कॉल करने में विफल'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // WhatsApp URL with country code
    final String whatsappUrl = 'https://wa.me/91$phoneNumber';
    final Uri whatsappUri = Uri.parse(whatsappUrl);
    
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(
          whatsappUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('व्हाट्सएप खोलने में विफल'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('त्रुटि: व्हाट्सएप खोलने में विफल'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show Audio Player Dialog
  /// Simple single audio file player
  void _showAudioPlayer() {
    final audioService = AudioService();
    
    showDialog(
      context: context,
      builder: (context) => SimpleAudioPlayer(audioService: audioService),
    );
  }
}
