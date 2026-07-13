import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/firebase_auth_service.dart';
import '../../models/user_profile.dart';
import 'package:intl/intl.dart';
import '../satellite/enhanced_satellite_screen.dart';
import '../settings/language_settings_screen.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/weather_service.dart';
import '../feedback/presentation/admin_feedback_screen.dart';

enum OfficerLevel {
  national,
  state,
  district,
}

class OfficerDashboardScreen extends StatefulWidget {
  const OfficerDashboardScreen({super.key});

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  int _selectedIndex = 0;

  OfficerLevel _officerLevel = OfficerLevel.district; // Demo: District officer
  String _selectedState = 'Punjab';
  String _selectedDistrict = 'Ludhiana';

  // From master branch → keep for location services
  String? _currentLocation;
  bool _isLoadingLocation = true;
  
  // Weather data
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  final WeatherService _weatherService = WeatherService();

  // From other branch → keep filter option
  String _selectedClaimFilter = 'all'; // all, pending, approved, rejected

  // Demo statistics data
  final Map<String, dynamic> _stats = {
    'total_claims': 1247,
    'pending_claims': 342,
    'approved_claims': 785,
    'rejected_claims': 120,
    'total_farmers': 5680,
    'active_policies': 4532,
    'total_premium': 125400000,
    'total_payout': 89500000,
    'crop_loss_reports': 456,
    'pending_assessments': 89,
    'avg_claim_time': 12.5, // days
    'approval_rate': 86.5, // percentage
  };

  final List<Map<String, dynamic>> _recentClaims = [
    {
      'id': 'CLM2024001',
      'farmer': 'Ram Singh',
      'crop': 'Wheat',
      'amount': 45000,
      'status': 'pending',
      'date': DateTime(2024, 11, 20),
      'district': 'Ludhiana',
    },
    {
      'id': 'CLM2024002',
      'farmer': 'Sita Devi',
      'crop': 'Rice',
      'amount': 68000,
      'status': 'approved',
      'date': DateTime(2024, 11, 19),
      'district': 'Ludhiana',
    },
    {
      'id': 'CLM2024003',
      'farmer': 'Mohan Kumar',
      'crop': 'Cotton',
      'amount': 32000,
      'status': 'under_review',
      'date': DateTime(2024, 11, 18),
      'district': 'Patiala',
    },
  ];

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
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchWeatherData();
  }
  
  Future<void> _fetchWeatherData() async {
    setState(() => _isLoadingWeather = true);
    
    try {
      final weatherData = await _weatherService.getWeatherForCurrentLocation();
      
      if (mounted) {
        setState(() {
          _weatherData = weatherData;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Location services disabled';
          _isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String location = '';
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          location = place.locality!;
        } else if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) {
          location = place.subAdministrativeArea!;
        } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          location = place.administrativeArea!;
        }

        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (location.isNotEmpty && location != place.administrativeArea) {
            location = '$location, ${place.administrativeArea}';
          } else {
            location = place.administrativeArea!;
          }
        }

        setState(() {
          _currentLocation = location.isNotEmpty ? location : 'Location found';
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentLocation = 'Location found';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Unable to get location';
        _isLoadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final List<Widget> screens = [
          _buildOverviewScreen(languageProvider),
          _buildClaimsManagementScreen(),
          _buildAnalyticsScreen(),
          _buildReportsScreen(),
          const EnhancedSatelliteScreen(),
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
            body: screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.indigo.shade700,
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              onTap: (index) => setState(() => _selectedIndex = index),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard),
                  label: AppStrings.get('navigation', 'overview', languageProvider.currentLanguage),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.assignment),
                  label: AppStrings.get('navigation', 'claims', languageProvider.currentLanguage),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.analytics),
                  label: AppStrings.get('navigation', 'analytics', languageProvider.currentLanguage),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.assessment),
                  label: AppStrings.get('navigation', 'reports', languageProvider.currentLanguage),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.satellite_outlined),
                  activeIcon: const Icon(Icons.satellite),
                  label: AppStrings.get('navigation', 'satellite', languageProvider.currentLanguage),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewScreen(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.indigo.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: Colors.indigo.shade700,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return PopupMenuButton<String>(
                        icon: const Icon(Icons.language, color: Colors.white),
                        onSelected: (String languageCode) async {
                          await languageProvider.setLanguage(languageCode);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Language changed to ${languageProvider.getLanguageName(languageCode)}',
                                  style: GoogleFonts.roboto(),
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: Colors.green.shade700,
                              ),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return AppLanguages.supportedLanguages.map((lang) {
                            return PopupMenuItem<String>(
                              value: lang.code,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (languageProvider.currentLanguage == lang.code)
                                    const Icon(Icons.check, size: 16, color: Colors.green),
                                  if (languageProvider.currentLanguage == lang.code)
                                    const SizedBox(width: 8),
                                  Text(lang.nativeName),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      );
                    },
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('officer', 'officer_dashboard', languageProvider.currentLanguage),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getOfficerLevelText(languageProvider.currentLanguage),
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.9),
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
                        Colors.indigo.shade700,
                        Colors.indigo.shade500,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: 20,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            _isLoadingLocation
                                ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  )
                                : Text(
                                    _currentLocation ?? _getLocationText(),
                                    style: GoogleFonts.roboto(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                            const SizedBox(width: 8),
                            if (!_isLoadingLocation)
                              GestureDetector(
                                onTap: _getCurrentLocation,
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 16,
                                ),
                              ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _showLevelSelector,
                              icon: const Icon(Icons.tune, color: Colors.white, size: 16),
                              label: Text(
                                'Change',
                                style: TextStyle(color: Colors.white, fontSize: 12),
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

            // Quick Stats Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('dashboard', 'key_metrics', languageProvider.currentLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          AppStrings.get('officer', 'total_claims', languageProvider.currentLanguage),
                          _stats['total_claims'].toString(),
                          Icons.assignment,
                          Colors.blue,
                          '+12% from last month',
                        ),
                        _buildPendingClaimsWidget(languageProvider.currentLanguage),
                        _buildStatCard(
                          AppStrings.get('officer', 'active_farmers', languageProvider.currentLanguage),
                          _stats['total_farmers'].toString(),
                          Icons.people,
                          Colors.green,
                          '${_stats['active_policies']} policies',
                        ),
                        _buildStatCard(
                          AppStrings.get('officer', 'approval_rate', languageProvider.currentLanguage),
                          '${_stats['approval_rate']}%',
                          Icons.check_circle,
                          Colors.purple,
                          'Industry average: 82%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Weather & Satellite Section (Placeholder)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('officer', 'environmental_monitoring', languageProvider.currentLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildWeatherPlaceholder(languageProvider.currentLanguage),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSatellitePlaceholder(languageProvider.currentLanguage),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Recent Claims
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get('officer', 'recent_claims', languageProvider.currentLanguage),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedIndex = 1),
                          child: Text(AppStrings.get('officer', 'view_all', languageProvider.currentLanguage)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._recentClaims.take(3).map((claim) => _buildClaimCard(claim, languageProvider.currentLanguage)),
                  ],
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('officer', 'quick_actions', languageProvider.currentLanguage),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            AppStrings.get('officer', 'review_claims', languageProvider.currentLanguage),
                            Icons.rate_review,
                            Colors.blue,
                            () => setState(() => _selectedIndex = 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            AppStrings.get('officer', 'view_analytics', languageProvider.currentLanguage),
                            Icons.bar_chart,
                            Colors.purple,
                            () => setState(() => _selectedIndex = 2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            AppStrings.get('officer', 'export_report', languageProvider.currentLanguage),
                            Icons.file_download,
                            Colors.green,
                            () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            AppStrings.get('officer', 'field_inspection', languageProvider.currentLanguage),
                            Icons.location_searching,
                            Colors.orange,
                            () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            AppStrings.get('actions', 'change_language', languageProvider.currentLanguage),
                            Icons.language,
                            Colors.indigo,
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const LanguageSettingsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            AppStrings.get('officer', 'settings', languageProvider.currentLanguage),
                            Icons.settings,
                            Colors.teal,
                            () {},
                          ),
                        ),
                      ],
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

  Widget _buildClaimsManagementScreen() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('officer', 'claims_management', languageProvider.currentLanguage),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.grey.shade100,
            child: Row(
              children: [
                _buildFilterChip(AppStrings.get('officer', 'all_claims', languageProvider.currentLanguage), _stats['total_claims'], 'all'),
                _buildFilterChip(AppStrings.get('status', 'pending', languageProvider.currentLanguage), _stats['pending_claims'], 'pending'),
                _buildFilterChip(AppStrings.get('claims', 'approved_claims', languageProvider.currentLanguage), _stats['approved_claims'], 'approved'),
                _buildFilterChip(AppStrings.get('officer', 'rejected', languageProvider.currentLanguage), _stats['rejected_claims'], 'rejected'),
              ],
            ),
          ),

          // Claims List
          Expanded(
            child: Builder(
              builder: (context) {
                // Filter claims based on selected filter
                final filteredClaims = _selectedClaimFilter == 'all'
                    ? _recentClaims
                    : _recentClaims.where((claim) {
                        final status = claim['status'] as String;
                        if (_selectedClaimFilter == 'pending') {
                          return status == 'pending' || status == 'under_review';
                        } else if (_selectedClaimFilter == 'approved') {
                          return status == 'approved';
                        } else if (_selectedClaimFilter == 'rejected') {
                          return status == 'rejected';
                        }
                        return true;
                      }).toList();

                if (filteredClaims.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.get('claims', 'no_claims_found', languageProvider.currentLanguage),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredClaims.length,
                  itemBuilder: (context, index) {
                    return _buildDetailedClaimCard(filteredClaims[index], languageProvider.currentLanguage);
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildAnalyticsScreen() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('officer', 'analytics_dashboard', languageProvider.currentLanguage),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Period Selector
            Row(
              children: [
                Text(
                  AppStrings.get('officer', 'period', languageProvider.currentLanguage),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(AppStrings.get('officer', 'week', languageProvider.currentLanguage)),
                  selected: true,
                  onSelected: (selected) {},
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(AppStrings.get('officer', 'month', languageProvider.currentLanguage)),
                  selected: false,
                  onSelected: (selected) {},
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(AppStrings.get('officer', 'year', languageProvider.currentLanguage)),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Claims Trend Chart Placeholder
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.get('officer', 'claims_trend_chart', languageProvider.currentLanguage),
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppStrings.get('officer', 'chart_integration_pending', languageProvider.currentLanguage),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Crop-wise Distribution
            Text(
              AppStrings.get('officer', 'crop_distribution', languageProvider.currentLanguage),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCropDistributionCard('Wheat', 345, Colors.amber),
            _buildCropDistributionCard('Rice', 289, Colors.green),
            _buildCropDistributionCard('Cotton', 198, Colors.blue),
            _buildCropDistributionCard('Sugarcane', 156, Colors.orange),
            _buildCropDistributionCard('Others', 259, Colors.grey),

            const SizedBox(height: 24),

            // Performance Metrics
            Text(
              AppStrings.get('officer', 'performance_metrics', languageProvider.currentLanguage),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    AppStrings.get('officer', 'avg_processing_time', languageProvider.currentLanguage),
                    '${_stats['avg_claim_time']} ${AppStrings.get('officer', 'days', languageProvider.currentLanguage)}',
                    Icons.timer,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    AppStrings.get('officer', 'total_payout', languageProvider.currentLanguage),
                    '₹${(_stats['total_payout'] / 10000000).toStringAsFixed(1)}Cr',
                    Icons.currency_rupee,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildReportsScreen() {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            AppStrings.get('officer', 'reports_export', languageProvider.currentLanguage),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.indigo.shade700,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          _buildReportCard(
            AppStrings.get('officer', 'monthly_claims_report', languageProvider.currentLanguage),
            AppStrings.get('officer', 'detailed_claims_summary', languageProvider.currentLanguage),
            Icons.calendar_month,
            Colors.blue,
          ),
          _buildReportCard(
            AppStrings.get('officer', 'financial_summary', languageProvider.currentLanguage),
            AppStrings.get('officer', 'budget_disbursement', languageProvider.currentLanguage),
            Icons.account_balance,
            Colors.green,
          ),
          _buildReportCard(
            AppStrings.get('officer', 'farmer_database', languageProvider.currentLanguage),
            AppStrings.get('officer', 'registered_farmers', languageProvider.currentLanguage),
            Icons.people,
            Colors.orange,
          ),
          _buildReportCard(
            AppStrings.get('officer', 'crop_loss_analysis', languageProvider.currentLanguage),
            AppStrings.get('officer', 'loss_patterns_weather', languageProvider.currentLanguage),
            Icons.agriculture,
            Colors.red,
          ),
          _buildReportCard(
            AppStrings.get('officer', 'performance_dashboard', languageProvider.currentLanguage),
            AppStrings.get('officer', 'team_kpi_tracking', languageProvider.currentLanguage),
            Icons.assessment,
            Colors.purple,
          ),
          _buildFeedbackManagementCard(
            languageProvider.currentLanguage == 'hi' ? 'फीडबैक प्रबंधन' : 'Feedback Management',
            languageProvider.currentLanguage == 'hi' 
                ? 'किसानों की रिपोर्ट्स और सुझाव देखें' 
                : 'View farmer reports and suggestions',
            Icons.feedback,
            Colors.deepPurple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminFeedbackScreen(),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Helper Widgets

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingClaimsWidget(String lang) {
    final int pendingClaims = _stats['pending_claims'];
    final int totalClaims = _stats['total_claims'];
    final double riskPercentage = (pendingClaims / totalClaims) * 100;
    
    return GestureDetector(
      onTap: () {
        // Navigate to District Efficiency Screen
        context.push('/district-efficiency');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.notifications_active, color: Colors.red.shade700, size: 20),
                ),
              ],
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$pendingClaims',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lang == 'hi' ? 'लंबित दावे' : 'Pending Claims',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        lang == 'hi' ? 'जोखिम: ' : 'Risk: ',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'HIGH',
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.grey.shade200,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          flex: 33,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                bottomLeft: Radius.circular(2),
                              ),
                              color: Colors.red.shade600,
                            ),
                          ),
                        ),
                        Flexible(
                          flex: 33,
                          child: Container(
                            color: Colors.orange.shade500,
                          ),
                        ),
                        Flexible(
                          flex: 34,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(2),
                                bottomRight: Radius.circular(2),
                              ),
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

>>>>>>> 7714536 (Added Traffic Light Dashboard Feature - District Efficiency Score Screen with gamified pending claims widget)
  Widget _buildWeatherPlaceholder(String lang) {
    if (_isLoadingWeather) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    if (_weatherData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.get('officer', 'weather_api', lang),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load weather data',
              style: GoogleFonts.roboto(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Display actual weather data
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _weatherData!['location'] ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white, size: 20),
                onPressed: _fetchWeatherData,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_weatherData!['temp']}°',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          WeatherService.getWeatherIconLocal(_weatherData!['main']),
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _weatherData!['description'].toString().toUpperCase(),
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildWeatherDetail(
                    Icons.water_drop,
                    '${_weatherData!['humidity']}%',
                  ),
                  const SizedBox(height: 4),
                  _buildWeatherDetail(
                    Icons.air,
                    '${_weatherData!['wind_speed']} km/h',
                  ),
                  const SizedBox(height: 4),
                  _buildWeatherDetail(
                    Icons.thermostat,
                    '${_weatherData!['feels_like']}°C',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSatellitePlaceholder(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.satellite_alt, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                AppStrings.get('officer', 'satellite_api', lang),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('officer', 'integration_pending', lang),
            style: GoogleFonts.roboto(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.get('officer', 'crop_monitoring_data', lang),
            style: GoogleFonts.roboto(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> claim, String lang) {
    Color statusColor = _getStatusColor(claim['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.assignment, color: statusColor),
        ),
        title: Text(
          claim['farmer'],
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${claim['crop']} • ₹${claim['amount']}',
          style: GoogleFonts.roboto(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            _getStatusLabel(claim['status'], lang),
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        onTap: () => _showClaimDetails(claim),
      ),
    );
  }

  Widget _buildDetailedClaimCard(Map<String, dynamic> claim, String lang) {
    Color statusColor = _getStatusColor(claim['status']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  claim['id'],
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getStatusLabel(claim['status'], lang),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  claim['farmer'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.agriculture, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('${AppStrings.get('officer', 'crop', lang)} ${claim['crop']}', style: GoogleFonts.roboto(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.currency_rupee, size: 14, color: Colors.grey.shade600),
                Text('₹${claim['amount']}', style: GoogleFonts.roboto(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('${claim['district']}', style: GoogleFonts.roboto(fontSize: 13)),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  DateFormat('dd MMM yyyy').format(claim['date']),
                  style: GoogleFonts.roboto(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showClaimDetails(claim),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text(AppStrings.get('officer', 'view_details', lang)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: Text(AppStrings.get('officer', 'review', lang)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, String filterValue) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: FilterChip(
          label: Text('$label ($count)', style: TextStyle(fontSize: 11)),
          selected: _selectedClaimFilter == filterValue,
          onSelected: (selected) {
            setState(() {
              _selectedClaimFilter = filterValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCropDistributionCard(String crop, int count, Color color) {
    final total = _stats['total_claims'];
    final percentage = (count / total * 100).toStringAsFixed(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.agriculture, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: count / total,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.roboto(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download),
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildFeedbackManagementCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.roboto(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ),
      ),
    );
  }

  // Helper Methods

  String _getOfficerLevelText(String lang) {
    switch (_officerLevel) {
      case OfficerLevel.national:
        return AppStrings.get('officer', 'national_level_officer', lang);
      case OfficerLevel.state:
        return AppStrings.get('officer', 'state_level_officer', lang);
      case OfficerLevel.district:
        return AppStrings.get('officer', 'district_level_officer', lang);
    }
  }

  String _getLocationText() {
    switch (_officerLevel) {
      case OfficerLevel.national:
        return 'All India';
      case OfficerLevel.state:
        return _selectedState;
      case OfficerLevel.district:
        return '$_selectedDistrict, $_selectedState';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status, String lang) {
    switch (status) {
      case 'pending':
        return AppStrings.get('status', 'pending', lang);
      case 'approved':
        return AppStrings.get('claims', 'approved_claims', lang);
      case 'rejected':
        return AppStrings.get('officer', 'rejected', lang);
      case 'under_review':
        return AppStrings.get('officer', 'under_review', lang);
      default:
        return status;
    }
  }

  void _showLevelSelector() {
    final lang = context.read<LanguageProvider>().currentLanguage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('officer', 'select_officer_level', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<OfficerLevel>(
              title: Text(AppStrings.get('officer', 'national_level_officer', lang)),
              subtitle: Text(lang == 'hi' ? 'अखिल भारतीय डेटा देखें' : 'View all India data'),
              value: OfficerLevel.national,
              groupValue: _officerLevel,
              onChanged: (value) {
                setState(() => _officerLevel = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<OfficerLevel>(
              title: Text(AppStrings.get('officer', 'state_level_officer', lang)),
              subtitle: Text(lang == 'hi' ? 'राज्य-विशिष्ट डेटा देखें' : 'View state-specific data'),
              value: OfficerLevel.state,
              groupValue: _officerLevel,
              onChanged: (value) {
                setState(() => _officerLevel = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<OfficerLevel>(
              title: Text(AppStrings.get('officer', 'district_level_officer', lang)),
              subtitle: Text(lang == 'hi' ? 'जिला-विशिष्ट डेटा देखें' : 'View district-specific data'),
              value: OfficerLevel.district,
              groupValue: _officerLevel,
              onChanged: (value) {
                setState(() => _officerLevel = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    final lang = context.read<LanguageProvider>().currentLanguage;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.get('officer', 'filter_claims', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(AppStrings.get('officer', 'all_claims', lang)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('${AppStrings.get('status', 'pending', lang)} ${lang == 'hi' ? 'केवल' : 'Only'}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('${AppStrings.get('claims', 'approved_claims', lang)} ${lang == 'hi' ? 'केवल' : 'Only'}'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('${AppStrings.get('officer', 'rejected', lang)} ${lang == 'hi' ? 'केवल' : 'Only'}'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showClaimDetails(Map<String, dynamic> claim) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.get('claims', 'claim_details', lang),
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text('${lang == 'hi' ? 'दावा आईडी' : 'Claim ID'}: ${claim['id']}', style: GoogleFonts.roboto()),
              Text('${lang == 'hi' ? 'किसान' : 'Farmer'}: ${claim['farmer']}', style: GoogleFonts.roboto()),
              Text('${lang == 'hi' ? 'फसल' : 'Crop'}: ${claim['crop']}', style: GoogleFonts.roboto()),
              Text('${lang == 'hi' ? 'राशि' : 'Amount'}: ₹${claim['amount']}', style: GoogleFonts.roboto()),
              Text('${lang == 'hi' ? 'जिला' : 'District'}: ${claim['district']}', style: GoogleFonts.roboto()),
              Text(
                '${lang == 'hi' ? 'तारीख' : 'Date'}: ${DateFormat('dd MMM yyyy').format(claim['date'])}',
                style: GoogleFonts.roboto(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.indigo.shade700,
                ),
                child: Text(AppStrings.get('premium', 'close', lang)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
