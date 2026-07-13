import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';
import '../../services/sentinel_hub_service.dart';
import '../weather/weather_screen.dart';

class EnhancedSatelliteScreen extends StatefulWidget {
  const EnhancedSatelliteScreen({super.key});

  @override
  State<EnhancedSatelliteScreen> createState() => _EnhancedSatelliteScreenState();
}

class _EnhancedSatelliteScreenState extends State<EnhancedSatelliteScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  final SentinelHubService _sentinelService = SentinelHubService();
  
  bool _showCropHealth = true;
  bool _showWeather = true;
  bool _showDistricts = true;
  bool _showNDVI = false;
  bool _isLoadingData = false;
  String _selectedLayer = 'satellite';
  String _selectedDataLayer = 'none';
  Map<String, dynamic>? _selectedFeature;
  
  // Real satellite data from Sentinel Hub
  Map<String, NdviStatistics?> _districtNdviData = {};
  List<SatelliteScene> _recentScenes = [];
  
  // Sentinel Hub data layers configuration  
  final Map<String, Map<String, dynamic>> dataLayerInfo = {
    'ndvi': {
      'name': '🌿 वनस्पति सूचकांक (NDVI)',
      'nameEn': 'NDVI - Vegetation Health',
      'icon': Icons.eco,
      'gradient': [const Color(0xFF388E3C), const Color(0xFF2E7D32), const Color(0xFF1B5E20)],
      'color': const Color(0xFF2E7D32),
      'description': 'Sentinel-2 से फसल स्वास्थ्य • रीयल-टाइम उपग्रह डेटा',
      'detailedDesc': 'NDVI पौधों की क्लोरोफिल सामग्री मापता है। -1 से +1 मान, 0.6+ उत्कृष्ट स्वास्थ्य।',
      'unit': '-1 to +1',
      'source': 'Sentinel-2 MSI (ESA)',
      'resolution': '10 m',
      'frequency': '5 दिन',
      'sentinelLayer': 'NDVI',
      'emoji': '🌿',
    },
    'evi': {
      'name': '🌱 उन्नत वनस्पति सूचकांक',
      'nameEn': 'EVI - Enhanced Vegetation',
      'icon': Icons.park,
      'gradient': [const Color(0xFF43A047), const Color(0xFF388E3C), const Color(0xFF2E7D32)],
      'color': const Color(0xFF388E3C),
      'description': 'NDVI का उन्नत संस्करण • घने वनस्पति क्षेत्रों के लिए',
      'detailedDesc': 'EVI वायुमंडलीय प्रभावों को कम करता है।',
      'unit': '-1 to +1',
      'source': 'Sentinel-2 MSI (ESA)',
      'resolution': '10 m',
      'frequency': '5 दिन',
      'sentinelLayer': 'EVI',
      'emoji': '🌱',
    },
    'moisture': {
      'name': '💧 नमी सूचकांक',
      'nameEn': 'Moisture Index',
      'icon': Icons.water_drop,
      'gradient': [const Color(0xFF0288D1), const Color(0xFF0277BD), const Color(0xFF01579B)],
      'color': const Color(0xFF0277BD),
      'description': 'वनस्पति नमी सामग्री • सिंचाई निर्णय',
      'detailedDesc': 'Sentinel-2 SWIR बैंड से नमी सूचकांक।',
      'unit': '-1 to +1',
      'source': 'Sentinel-2 MSI (ESA)',
      'resolution': '20 m',
      'frequency': '5 दिन',
      'sentinelLayer': 'MOISTURE-INDEX',
      'emoji': '💧',
    },
    'true_color': {
      'name': '📷 वास्तविक रंग',
      'nameEn': 'True Color RGB',
      'icon': Icons.image,
      'gradient': [const Color(0xFF5C6BC0), const Color(0xFF3F51B5), const Color(0xFF303F9F)],
      'color': const Color(0xFF3F51B5),
      'description': 'प्राकृतिक रंग छवि • जैसा आंखों को दिखता है',
      'detailedDesc': 'Sentinel-2 के B4-B3-B2 बैंड से प्राकृतिक RGB छवि।',
      'unit': 'RGB',
      'source': 'Sentinel-2 MSI (ESA)',
      'resolution': '10 m',
      'frequency': '5 दिन',
      'sentinelLayer': 'TRUE-COLOR',
      'emoji': '📷',
    },
    'false_color': {
      'name': '🔴 फॉल्स कलर (NIR)',
      'nameEn': 'False Color - Vegetation',
      'icon': Icons.gradient,
      'gradient': [const Color(0xFFE91E63), const Color(0xFFC2185B), const Color(0xFFAD1457)],
      'color': const Color(0xFFC2185B),
      'description': 'वनस्पति लाल रंग में • फसल क्षेत्र पहचान',
      'detailedDesc': 'NIR बैंड का उपयोग। स्वस्थ वनस्पति चमकीले लाल रंग में।',
      'unit': 'NIR-RGB',
      'source': 'Sentinel-2 MSI (ESA)',
      'resolution': '10 m',
      'frequency': '5 दिन',
      'sentinelLayer': 'FALSE-COLOR',
      'emoji': '🔴',
    },
    'cloud_mask': {
      'name': '☁️ बादल मास्क',
      'nameEn': 'Cloud Mask',
      'icon': Icons.cloud,
      'gradient': [const Color(0xFF78909C), const Color(0xFF607D8B), const Color(0xFF546E7A)],
      'color': const Color(0xFF607D8B),
      'description': 'बादलों की पहचान • स्वच्छ छवि चयन',
      'detailedDesc': 'बादल आवरण का पता लगाता है।',
      'unit': '%',
      'source': 'Sentinel-2 SCL',
      'resolution': '20 m',
      'frequency': '5 दिन',
      'sentinelLayer': 'CLM',
      'emoji': '☁️',
    },
  };

  // District-wise crop data - will be updated with real Sentinel data
  List<Map<String, dynamic>> districts = [
    {
      'name': 'Hisar, Haryana',
      'location': LatLng(29.1492, 75.7217),
      'totalFarmers': 4589,
      'insuredArea': '12,450 हेक्टेयर',
      'mainCrop': 'गेहूं',
      'cropHealth': 'लोड हो रहा...',
      'avgNDVI': 0.0,
      'rainfall': '45mm',
      'temp': '26°C',
      'alerts': 0,
      'bbox': [75.5, 28.9, 75.9, 29.4],
    },
    {
      'name': 'Amravati, Maharashtra',
      'location': LatLng(20.9333, 77.7667),
      'totalFarmers': 8765,
      'insuredArea': '18,900 हेक्टेयर',
      'mainCrop': 'कपास',
      'cropHealth': 'लोड हो रहा...',
      'avgNDVI': 0.0,
      'rainfall': '32mm',
      'temp': '32°C',
      'alerts': 1,
      'bbox': [77.5, 20.7, 78.0, 21.2],
    },
    {
      'name': 'Warangal, Telangana',
      'location': LatLng(18.0, 79.5833),
      'totalFarmers': 6543,
      'insuredArea': '15,670 हेक्टेयर',
      'mainCrop': 'धान',
      'cropHealth': 'लोड हो रहा...',
      'avgNDVI': 0.0,
      'rainfall': '78mm',
      'temp': '29°C',
      'alerts': 0,
      'bbox': [79.3, 17.8, 79.9, 18.2],
    },
    {
      'name': 'Bikaner, Rajasthan',
      'location': LatLng(28.0229, 73.3119),
      'totalFarmers': 3214,
      'insuredArea': '8,900 हेक्टेयर',
      'mainCrop': 'बाजरा',
      'cropHealth': 'लोड हो रहा...',
      'avgNDVI': 0.0,
      'rainfall': '12mm',
      'temp': '38°C',
      'alerts': 2,
      'bbox': [73.1, 27.8, 73.5, 28.3],
    },
    {
      'name': 'Ludhiana, Punjab',
      'location': LatLng(30.9010, 75.8573),
      'totalFarmers': 5896,
      'insuredArea': '16,780 हेक्टेयर',
      'mainCrop': 'गेहूं',
      'cropHealth': 'लोड हो रहा...',
      'avgNDVI': 0.0,
      'rainfall': '38mm',
      'temp': '24°C',
      'alerts': 0,
      'bbox': [75.6, 30.7, 76.1, 31.1],
    },
    {
      'name': 'Nashik, Maharashtra',
      'location': LatLng(19.9975, 73.7898),
      'totalFarmers': 4321,
      'insuredArea': '11,230 हेक्टेयर',
      'mainCrop': 'अंगूर',
      'cropHealth': 'लोड हो रहा...',
      'avgNDVI': 0.0,
      'rainfall': '28mm',
      'temp': '31°C',
      'alerts': 0,
      'bbox': [73.5, 19.8, 74.0, 20.2],
    },
  ];

  // Weather alerts
  final List<Map<String, dynamic>> weatherAlerts = [
    {
      'location': LatLng(20.9333, 77.7667),
      'district': 'Amravati',
      'type': 'कीट प्रकोप चेतावनी',
      'severity': 'मध्यम',
      'description': 'कपास में गुलाबी सुंडी का प्रकोप संभावित',
      'date': '29-11-2025',
    },
    {
      'location': LatLng(28.0229, 73.3119),
      'district': 'Bikaner',
      'type': 'सूखा चेतावनी',
      'severity': 'उच्च',
      'description': 'अगले 10 दिनों में वर्षा की संभावना कम',
      'date': '28-11-2025',
    },
  ];

  Color _getHealthColor(String health) {
    switch (health.toLowerCase()) {
      case 'उत्तम':
      case 'उत्कृष्ट':
      case 'excellent':
        return const Color(0xFF2E7D32);
      case 'अच्छा':
      case 'good':
        return const Color(0xFF66BB6A);
      case 'मध्यम':
      case 'सामान्य':
      case 'fair':
        return const Color(0xFFF57C00);
      case 'खराब':
      case 'poor':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF757575);
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'उच्च':
      case 'High':
        return const Color(0xFFC62828);
      case 'मध्यम':
      case 'Medium':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFFFFA000);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSatelliteData();
  }
  
  /// Load real satellite data from Sentinel Hub
  Future<void> _loadSatelliteData() async {
    setState(() => _isLoadingData = true);
    
    try {
      // Load NDVI data for each district
      for (int i = 0; i < districts.length; i++) {
        final district = districts[i];
        if (district['bbox'] == null) continue;
        
        final bbox = district['bbox'] as List<dynamic>;
        
        final ndviStats = await _sentinelService.fetchNdviStatistics(
          minLat: (bbox[1] as num).toDouble(),
          minLon: (bbox[0] as num).toDouble(),
          maxLat: (bbox[3] as num).toDouble(),
          maxLon: (bbox[2] as num).toDouble(),
        );
        
        if (ndviStats != null && mounted) {
          setState(() {
            districts[i] = {
              ...district,
              'avgNDVI': ndviStats.mean,
              'cropHealth': ndviStats.healthStatus,
            };
            _districtNdviData[district['name'] as String] = ndviStats;
          });
        }
      }
      
      // Load recent satellite scenes for India
      final scenes = await _sentinelService.searchScenes(
        minLat: 8.0,
        minLon: 68.0,
        maxLat: 37.0,
        maxLon: 97.0,
      );
      
      if (mounted) {
        setState(() {
          _recentScenes = scenes;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading satellite data: $e');
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1B5E20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('satellite', 'satellite_weather', lang),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Sentinel-2 • NASA SMAP',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            actions: [
              if (_isLoadingData)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadSatelliteData,
                  tooltip: 'रीफ्रेश',
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: const Icon(Icons.satellite_alt),
                  text: AppStrings.get('satellite', 'satellite_tab', lang),
                ),
                Tab(
                  icon: const Icon(Icons.cloud),
                  text: AppStrings.get('satellite', 'weather_tab', lang),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSatelliteView(lang),
              const WeatherScreen(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSatelliteView(String lang) {
    return Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(22.5937, 78.9629),
              initialZoom: 5.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              // Base layer
              TileLayer(
                urlTemplate: _selectedLayer == 'satellite'
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.pmfby.app',
              ),
              // Sentinel Hub Data Overlay Layers
              if (_selectedDataLayer != 'none' && dataLayerInfo.containsKey(_selectedDataLayer))
                _buildSentinelDataOverlay(),
              // District markers with real NDVI data
              if (_showDistricts)
                MarkerLayer(
                  markers: districts.map((district) {
                    final ndviData = _districtNdviData[district['name']];
                    return Marker(
                      point: district['location'] as LatLng,
                      width: 70,
                      height: 85,
                      child: GestureDetector(
                        onTap: () => _showDistrictDetailsSheet(district, lang),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getHealthColor(district['cropHealth']),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                ndviData != null
                                    ? 'NDVI: ${ndviData.mean.toStringAsFixed(2)}'
                                    : district['avgNDVI'] > 0 
                                        ? 'NDVI: ${(district['avgNDVI'] as double).toStringAsFixed(2)}'
                                        : 'लोड...',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if ((district['alerts'] as int) > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⚠ ${district['alerts']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // Weather alert markers
              if (_showWeather)
                MarkerLayer(
                  markers: weatherAlerts.map((alert) {
                    return Marker(
                      point: alert['location'] as LatLng,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showAlertDetailsSheet(alert, lang),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getAlertColor(alert['severity']),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getAlertColor(alert['severity']).withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          // Top Stats Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildTopStatsBar(lang),
          ),
          // Sentinel Hub Data Layers Panel
          Positioned(
            left: 16,
            bottom: 100,
            child: _buildDataLayersPanel(lang),
          ),
          // Zoom controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _buildZoomButton(Icons.add, () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                }),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.remove, () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                }),
                const SizedBox(height: 8),
                _buildZoomButton(Icons.my_location, () {
                  _mapController.move(const LatLng(22.5937, 78.9629), 5.0);
                }),
              ],
            ),
          ),
          // Legend for selected layer
          if (_selectedDataLayer != 'none')
            Positioned(
              right: 16,
              top: 100,
              child: _buildLegendCard(),
            ),
          // Recent Scenes Info
          if (_recentScenes.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 80,
              child: _buildRecentScenesBar(),
            ),
        ],
    );
  }

  Widget _buildSentinelDataOverlay() {
    final layerInfo = dataLayerInfo[_selectedDataLayer];
    if (layerInfo == null) return const SizedBox.shrink();
    
    // Colored overlay to indicate data layer is active
    return Opacity(
      opacity: 0.4,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          (layerInfo['color'] as Color).withOpacity(0.3),
          BlendMode.srcOver,
        ),
        child: TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.pmfby.app',
        ),
      ),
    );
  }

  Widget _buildTopStatsBar(String lang) {
    final totalFarmers = districts.fold(0, (sum, d) => sum + (d['totalFarmers'] as int));
    final validNdvi = districts.where((d) => (d['avgNDVI'] as double) > 0);
    final avgNdvi = validNdvi.isEmpty
        ? 0.0
        : validNdvi.map((d) => d['avgNDVI'] as double).reduce((a, b) => a + b) / validNdvi.length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              Icons.satellite_alt,
              'Sentinel-2',
              _isLoadingData ? 'लोड...' : 'लाइव',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildStatItem(
              Icons.eco,
              'NDVI',
              _isLoadingData ? '...' : avgNdvi.toStringAsFixed(2),
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildStatItem(
              Icons.people,
              'किसान',
              '$totalFarmers',
            ),
          ),
          _buildVerticalDivider(),
          Expanded(
            child: _buildStatItem(
              Icons.warning_amber,
              'चेतावनी',
              '${weatherAlerts.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.notoSansDevanagari(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white24,
    );
  }

  Widget _buildDataLayersPanel(String lang) {
    return Container(
      width: 240,
      constraints: const BoxConstraints(maxHeight: 350),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.satellite_alt, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sentinel Hub',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'उपग्रह डेटा परतें',
                        style: GoogleFonts.notoSansDevanagari(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Layer buttons
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: dataLayerInfo.entries.map((entry) {
                  return _buildLayerButton(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ),
          // Clear button
          if (_selectedDataLayer != 'none')
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedDataLayer = 'none'),
                  icon: const Icon(Icons.layers_clear, size: 14),
                  label: Text(
                    'परतें हटाएं',
                    style: GoogleFonts.notoSansDevanagari(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLayerButton(String key, Map<String, dynamic> layer) {
    final isSelected = _selectedDataLayer == key;
    final color = layer['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedDataLayer = isSelected ? 'none' : key;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    layer['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer['nameEn'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        layer['source'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
        ),
      ),
    );
  }

  Widget _buildLegendCard() {
    final layer = dataLayerInfo[_selectedDataLayer];
    if (layer == null) return const SizedBox.shrink();
    
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            layer['nameEn'] as String,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (_selectedDataLayer == 'ndvi' || _selectedDataLayer == 'evi')
            ..._buildNdviLegend()
          else if (_selectedDataLayer == 'moisture')
            ..._buildMoistureLegend()
          else
            Text(
              layer['unit'] as String,
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildNdviLegend() {
    return [
      _buildLegendRow(Colors.green.shade800, '0.6+', 'उत्कृष्ट'),
      _buildLegendRow(Colors.lightGreen, '0.4-0.6', 'अच्छा'),
      _buildLegendRow(Colors.yellow.shade700, '0.2-0.4', 'मध्यम'),
      _buildLegendRow(Colors.orange, '0-0.2', 'कमजोर'),
      _buildLegendRow(Colors.red.shade700, '<0', 'खराब'),
    ];
  }

  List<Widget> _buildMoistureLegend() {
    return [
      _buildLegendRow(Colors.blue.shade800, '40%+', 'नम'),
      _buildLegendRow(Colors.blue.shade400, '25-40%', 'सामान्य'),
      _buildLegendRow(Colors.yellow.shade600, '15-25%', 'कम'),
      _buildLegendRow(Colors.orange, '<15%', 'शुष्क'),
    ];
  }

  Widget _buildLegendRow(Color color, String value, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              '$value $label',
              style: GoogleFonts.notoSansDevanagari(fontSize: 8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScenesBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.history, size: 14, color: Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _recentScenes.isNotEmpty
                  ? 'नवीनतम: ${_recentScenes.first.platform} • ${_formatDate(_recentScenes.first.datetime)} • ${_recentScenes.first.cloudCover.toStringAsFixed(0)}% बादल'
                  : 'उपग्रह डेटा लोड हो रहा...',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  void _showDistrictDetailsSheet(Map<String, dynamic> district, String lang) async {
    final ndviData = _districtNdviData[district['name']];
    
    // Fetch crop health assessment
    CropHealthAssessment? healthAssessment;
    if (district['bbox'] != null) {
      final bbox = district['bbox'] as List<dynamic>;
      healthAssessment = await _sentinelService.assessCropHealth(
        minLat: (bbox[1] as num).toDouble(),
        minLon: (bbox[0] as num).toDouble(),
        maxLat: (bbox[3] as num).toDouble(),
        maxLon: (bbox[2] as num).toDouble(),
        cropType: district['mainCrop'] ?? 'wheat',
      );
    }
    
    if (!mounted) return;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // District Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getHealthColor(district['cropHealth']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: _getHealthColor(district['cropHealth']),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          district['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'मुख्य फसल: ${district['mainCrop']}',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Sentinel Hub Data Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.satellite_alt, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Sentinel-2 विश्लेषण',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSentinelStat(
                            'NDVI',
                            ndviData?.mean.toStringAsFixed(2) ?? 
                              (district['avgNDVI'] as double > 0 ? (district['avgNDVI'] as double).toStringAsFixed(2) : '--'),
                            ndviData?.healthStatus ?? district['cropHealth'],
                          ),
                        ),
                        Expanded(
                          child: _buildSentinelStat(
                            'स्वास्थ्य',
                            healthAssessment != null
                                ? '${healthAssessment.overallScore.toStringAsFixed(0)}%'
                                : '--',
                            healthAssessment?.status ?? 'लोड...',
                          ),
                        ),
                        Expanded(
                          child: _buildSentinelStat(
                            'नमी',
                            healthAssessment?.soilMoisture != null
                                ? '${(healthAssessment!.soilMoisture * 100).toStringAsFixed(0)}%'
                                : '--',
                            (healthAssessment?.soilMoisture ?? 0) > 0.3 ? 'पर्याप्त' : 'कम',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Recommendations
              if (healthAssessment != null && healthAssessment.recommendations.isNotEmpty) ...[
                Text(
                  '💡 सिफारिशें',
                  style: GoogleFonts.notoSansDevanagari(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                ...healthAssessment.recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, color: Color(0xFF1B5E20), size: 18),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          rec,
                          style: GoogleFonts.notoSansDevanagari(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              // District Info Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
                children: [
                  _buildInfoTile(Icons.people, 'किसान', '${district['totalFarmers']}'),
                  _buildInfoTile(Icons.landscape, 'बीमित क्षेत्र', district['insuredArea']),
                  _buildInfoTile(Icons.water_drop, 'वर्षा', district['rainfall']),
                  _buildInfoTile(Icons.thermostat, 'तापमान', district['temp']),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentinelStat(String label, String value, String status) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            status,
            style: GoogleFonts.notoSansDevanagari(
              color: Colors.white,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B5E20), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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

  void _showAlertDetailsSheet(Map<String, dynamic> alert, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Alert Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert['severity']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning,
                    color: _getAlertColor(alert['severity']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['type'],
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        alert['district'],
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAlertColor(alert['severity']),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    alert['severity'],
                    style: GoogleFonts.notoSansDevanagari(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _getAlertColor(alert['severity']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                alert['description'],
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'दिनांक: ${alert['date']}',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
