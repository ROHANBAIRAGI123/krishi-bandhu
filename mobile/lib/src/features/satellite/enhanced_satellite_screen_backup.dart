import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';
import '../weather/weather_screen.dart';

class EnhancedSatelliteScreen extends StatefulWidget {
  const EnhancedSatelliteScreen({super.key});

  @override
  State<EnhancedSatelliteScreen> createState() => _EnhancedSatelliteScreenState();
}

class _EnhancedSatelliteScreenState extends State<EnhancedSatelliteScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late TabController _tabController;
  bool _showCropHealth = true;
  bool _showWeather = true;
  bool _showDistricts = true;
  bool _showNDVI = false;
  String _selectedLayer = 'satellite';
  String _selectedDataLayer = 'none'; // none, soil_moisture, ndvi, soil_texture
  Map<String, dynamic>? _selectedFeature;
  
  // Satellite data layer info with enhanced details
  final Map<String, Map<String, dynamic>> dataLayerInfo = {
    'soil_moisture': {
      'name': '💧 मृदा नमी विश्लेषण',
      'nameEn': 'Soil Moisture Analysis',
      'icon': Icons.water_drop,
      'gradient': [Color(0xFF0288D1), Color(0xFF0277BD), Color(0xFF01579B)],
      'color': Color(0xFF0277BD),
      'description': 'NASA SMAP उपग्रह से रीयल-टाइम मृदा नमी डेटा • सिंचाई योजना के लिए आवश्यक',
      'detailedDesc': 'जमीन की सतह से 5-10 सेमी गहराई तक मृदा में उपस्थित पानी की मात्रा को मापता है। फसल की सिंचाई आवश्यकता और सूखे की भविष्यवाणी के लिए महत्वपूर्ण।',
      'unit': '% आयतन',
      'source': 'NASA SMAP L4 Satellite',
      'resolution': '9 km',
      'frequency': 'Daily',
      'emoji': '💧',
    },
    'ndvi': {
      'name': '🌿 वनस्पति स्वास्थ्य सूचकांक',
      'nameEn': 'Vegetation Health (NDVI)',
      'icon': Icons.eco,
      'gradient': [Color(0xFF388E3C), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      'color': Color(0xFF2E7D32),
      'description': 'Sentinel-2 से फसल स्वास्थ्य मूल्यांकन • उत्पादन पूर्वानुमान',
      'detailedDesc': 'पौधों की क्लोरोफिल सामग्री और स्वास्थ्य को मापता है। -1 से +1 तक का मान, जहाँ उच्च मान स्वस्थ वनस्पति को दर्शाता है। फसल की वृद्धि निगरानी के लिए अत्यंत उपयोगी।',
      'unit': 'सूचकांक (-1 से +1)',
      'source': 'Sentinel-2 MSI ESA',
      'resolution': '10-20 m',
      'frequency': '5 days',
      'emoji': '🌿',
    },
    'soil_texture': {
      'name': '🏜️ मृदा संरचना मानचित्र',
      'nameEn': 'Soil Composition Map',
      'icon': Icons.terrain,
      'gradient': [Color(0xFF8D6E63), Color(0xFF6D4C41), Color(0xFF5D4037)],
      'color': Color(0xFF6D4C41),
      'description': 'ISRO भुवन से मिट्टी की बनावट और संरचना • फसल उपयुक्तता',
      'detailedDesc': 'मिट्टी में मौजूद रेत, गाद और मिट्टी के कणों का अनुपात। विभिन्न फसलों के लिए उपयुक्त मिट्टी का चयन करने में सहायक। उर्वरक और जल प्रबंधन के लिए आवश्यक।',
      'unit': 'प्रकार',
      'source': 'ISRO Bhuvan NRSC',
      'resolution': '250 m',
      'frequency': 'Static',
      'emoji': '🏜️',
    },
  };

  // District-wise crop data
  final List<Map<String, dynamic>> districts = [
    {
      'name': 'Hisar, Haryana',
      'location': LatLng(29.1492, 75.7217),
      'totalFarmers': 4589,
      'insuredArea': '12,450 हेक्टेयर',
      'mainCrop': 'गेहूं',
      'cropHealth': 'उत्तम',
      'avgNDVI': 0.82,
      'rainfall': '45mm',
      'temp': '26°C',
      'alerts': 0,
    },
    {
      'name': 'Amravati, Maharashtra',
      'location': LatLng(20.9333, 77.7667),
      'totalFarmers': 8765,
      'insuredArea': '18,900 हेक्टेयर',
      'mainCrop': 'कपास',
      'cropHealth': 'अच्छा',
      'avgNDVI': 0.75,
      'rainfall': '32mm',
      'temp': '32°C',
      'alerts': 1,
    },
    {
      'name': 'Warangal, Telangana',
      'location': LatLng(18.0, 79.5833),
      'totalFarmers': 6543,
      'insuredArea': '15,670 हेक्टेयर',
      'mainCrop': 'धान',
      'cropHealth': 'उत्तम',
      'avgNDVI': 0.88,
      'rainfall': '78mm',
      'temp': '29°C',
      'alerts': 0,
    },
    {
      'name': 'Bikaner, Rajasthan',
      'location': LatLng(28.0229, 73.3119),
      'totalFarmers': 3214,
      'insuredArea': '8,900 हेक्टेयर',
      'mainCrop': 'बाजरा',
      'cropHealth': 'मध्यम',
      'avgNDVI': 0.58,
      'rainfall': '12mm',
      'temp': '38°C',
      'alerts': 2,
    },
    {
      'name': 'Ludhiana, Punjab',
      'location': LatLng(30.9010, 75.8573),
      'totalFarmers': 5896,
      'insuredArea': '16,780 हेक्टेयर',
      'mainCrop': 'गेहूं',
      'cropHealth': 'उत्तम',
      'avgNDVI': 0.85,
      'rainfall': '38mm',
      'temp': '24°C',
      'alerts': 0,
    },
    {
      'name': 'Nashik, Maharashtra',
      'location': LatLng(19.9975, 73.7898),
      'totalFarmers': 4321,
      'insuredArea': '11,230 हेक्टेयर',
      'mainCrop': 'अंगूर',
      'cropHealth': 'अच्छा',
      'avgNDVI': 0.72,
      'rainfall': '28mm',
      'temp': '31°C',
      'alerts': 0,
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
    switch (health) {
      case 'उत्तम':
        return const Color(0xFF2E7D32);
      case 'अच्छा':
        return const Color(0xFF66BB6A);
      case 'मध्यम':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFFC62828);
    }
  }

  Color _getAlertColor(String severity) {
    switch (severity) {
      case 'उच्च':
        return const Color(0xFFC62828);
      case 'मध्यम':
        return const Color(0xFFF57C00);
      default:
        return const Color(0xFFFFA000);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          backgroundColor: const Color(0xFFFAFAFA),
          appBar: AppBar(
            title: Text(
              AppStrings.get('satellite', 'satellite_weather', lang),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
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
              initialCenter: const LatLng(23.5937, 78.9629),
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
              // Satellite Data Overlay Layers
              if (_selectedDataLayer == 'soil_moisture')
                Opacity(
                  opacity: 0.7,
                  child: TileLayer(
                    urlTemplate: 'https://gibs.earthdata.nasa.gov/wmts/epsg3857/best/SMAP_L4_Analyzed_Root_Zone_Soil_Moisture/default/{time}/GoogleMapsCompatible_Level6/{z}/{y}/{x}.png',
                    additionalOptions: const {
                      'time': '2024-12-01', // Dynamic date
                    },
                    userAgentPackageName: 'com.pmfby.app',
                  ),
                ),
              if (_selectedDataLayer == 'ndvi')
                Opacity(
                  opacity: 0.7,
                  child: TileLayer(
                    urlTemplate: 'https://services.sentinel-hub.com/ogc/wms/YOUR_INSTANCE_ID?REQUEST=GetMap&LAYERS=NDVI&WIDTH=256&HEIGHT=256&BBOX={bbox}&FORMAT=image/png',
                    userAgentPackageName: 'com.pmfby.app',
                  ),
                ),
              if (_selectedDataLayer == 'soil_texture')
                Opacity(
                  opacity: 0.6,
                  child: TileLayer(
                    urlTemplate: 'https://bhuvan-vec1.nrsc.gov.in/bhuvan/gwc/service/wms?SERVICE=WMS&VERSION=1.1.1&REQUEST=GetMap&LAYERS=india3&BBOX={bbox}&WIDTH=256&HEIGHT=256&FORMAT=image/png',
                    userAgentPackageName: 'com.pmfby.app',
                  ),
                ),
              // District markers
              if (_showDistricts)
                MarkerLayer(
                  markers: districts.map((district) {
                    return Marker(
                      point: district['location'] as LatLng,
                      width: 60,
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFeature = district;
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
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
                              ),
                              child: const Icon(
                                Icons.agriculture,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            if (district['alerts'] > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '⚠${district['alerts']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
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
                        onTap: () {
                          setState(() {
                            _selectedFeature = alert;
                          });
                        },
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
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          // Top Controls
          Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.satellite_alt,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.get('satellite', 'bhuvan_satellite', lang),
                                  style: GoogleFonts.notoSansDevanagari(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  AppStrings.get('satellite', 'isro_realtime', lang),
                                  style: GoogleFonts.notoSans(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _showFilterBottomSheet(context, lang);
                            },
                            icon: const Icon(
                              Icons.tune,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            AppStrings.get('satellite', 'total_farmers', lang),
                            '${districts.fold(0, (sum, d) => sum + (d['totalFarmers'] as int))}',
                            Icons.people,
                            const Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            AppStrings.get('satellite', 'active_alerts', lang),
                            '${weatherAlerts.length}',
                            Icons.warning,
                            const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          // Satellite Data Layer Selector (Left side) - Enhanced
          Positioned(
                left: 16,
                bottom: _selectedFeature != null ? 320 : 100,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: const Color(0xFF1B5E20).withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with gradient
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.satellite_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.get('satellite', 'satellite_data', lang),
                                    style: GoogleFonts.notoSansDevanagari(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.get('satellite', 'realtime_analysis', lang),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Buttons container
                      Container(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildDataLayerButton('soil_moisture'),
                            const SizedBox(height: 10),
                            _buildDataLayerButton('ndvi'),
                            const SizedBox(height: 10),
                            _buildDataLayerButton('soil_texture'),
                            if (_selectedDataLayer != 'none') ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedDataLayer = 'none';
                                  });
                                },
                                icon: const Icon(Icons.layers_clear, size: 18),
                                label: Text(
                                  AppStrings.get('satellite', 'remove_all_layers', lang),
                                  style: GoogleFonts.notoSansDevanagari(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red.shade700,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.red.shade200),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          // Bottom Sheet for selected feature
          if (_selectedFeature != null)
            Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 16,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle
                        Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: _selectedFeature!.containsKey('totalFarmers')
                              ? _buildDistrictDetails(_selectedFeature!, lang)
                              : _buildAlertDetails(_selectedFeature!, lang),
                        ),
                        // Close button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFeature = null;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(AppStrings.get('satellite', 'close', lang)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          // Zoom controls
          Positioned(
                right: 16,
                bottom: _selectedFeature != null ? 320 : 100,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1,
                        );
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.add, color: Color(0xFF1B5E20)),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1,
                        );
                      },
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.remove, color: Color(0xFF1B5E20)),
                    ),
                  ],
                ),
              ),
        ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF212121),
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 11,
                    color: const Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictDetails(Map<String, dynamic> district, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  Text(
                    '${AppStrings.get('satellite', 'main_crop', lang)}: ${district['mainCrop']}',
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 13,
                      color: const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDetailRow(AppStrings.get('satellite', 'total_farmers', lang), '${district['totalFarmers']}', Icons.people),
        _buildDetailRow(AppStrings.get('satellite', 'insured_area', lang), district['insuredArea'], Icons.landscape),
        _buildDetailRow(AppStrings.get('satellite', 'crop_health', lang), district['cropHealth'], Icons.eco),
        _buildDetailRow(AppStrings.get('satellite', 'ndvi_index', lang), district['avgNDVI'].toStringAsFixed(2), Icons.analytics),
        _buildDetailRow(AppStrings.get('satellite', 'rainfall', lang), district['rainfall'], Icons.water_drop),
        _buildDetailRow(AppStrings.get('satellite', 'temperature', lang), district['temp'], Icons.thermostat),
        if (district['alerts'] > 0)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF57C00)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFF57C00), size: 20),
                const SizedBox(width: 8),
                Text(
                  AppStrings.get('satellite', 'active_warning', lang).replaceAll('{count}', '${district['alerts']}'),
                  style: GoogleFonts.notoSansDevanagari(
                    color: const Color(0xFFF57C00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAlertDetails(Map<String, dynamic> alert, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                size: 28,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  Text(
                    alert['district'],
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: const Color(0xFF616161),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getAlertColor(alert['severity']),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                alert['severity'],
                style: GoogleFonts.notoSansDevanagari(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            alert['description'],
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 14,
              color: const Color(0xFF212121),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Color(0xFF616161)),
            const SizedBox(width: 6),
            Text(
              '${AppStrings.get('satellite', 'date_label', lang)}: ${alert['date']}',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 13,
                color: const Color(0xFF616161),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataLayerButton(String layerKey) {
    final layer = dataLayerInfo[layerKey]!;
    final isSelected = _selectedDataLayer == layerKey;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedDataLayer = isSelected ? 'none' : layerKey;
            });
            if (!isSelected) {
              _showDataLayerInfo(layerKey);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: layer['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [Colors.grey.shade50, Colors.white],
                    ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? layer['color'] : Colors.grey.shade300,
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: layer['color'].withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: layer['color'].withOpacity(0.2),
                        blurRadius: 24,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : layer['color'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    layer['icon'],
                    color: isSelected ? Colors.white : layer['color'],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layer['name'],
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        layer['nameEn'],
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade600,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'सक्रिय',
                                style: GoogleFonts.notoSansDevanagari(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isSelected)
                  Icon(
                    Icons.add_circle_outline,
                    color: layer['color'],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDataLayerInfo(String layerKey) {
    final layer = dataLayerInfo[layerKey]!;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 16,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [Colors.white, layer['color'].withOpacity(0.05)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: layer['gradient'],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: layer['color'].withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        layer['icon'],
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
                            layer['name'],
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            layer['nameEn'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      layer['description'],
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Detailed Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: layer['color'].withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: layer['color'].withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        layer['detailedDesc'],
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Technical Details
                    Text(
                      '📊 तकनीकी विवरण',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTechDetail(Icons.satellite_alt, 'स्रोत', layer['source']),
                    _buildTechDetail(Icons.straighten, 'रिज़ॉल्यूशन', layer['resolution']),
                    _buildTechDetail(Icons.update, 'अपडेट', layer['frequency']),
                    _buildTechDetail(Icons.speed, 'इकाई', layer['unit']),
                    
                    const SizedBox(height: 20),
                    
                    // Legend
                    Text(
                      '🎨 रंग संकेत',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: _buildLegend(layerKey),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        label: Text(
                          'बंद करें',
                          style: GoogleFonts.notoSansDevanagari(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
    );
  }
  
  Widget _buildTechDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF616161)),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 13,
              color: const Color(0xFF616161),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF212121),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String layerKey) {
    switch (layerKey) {
      case 'soil_moisture':
        return Column(
          children: [
            _buildLegendItem(Colors.brown.shade900, '0-10%', 'बहुत शुष्क'),
            _buildLegendItem(Colors.orange.shade700, '10-20%', 'शुष्क'),
            _buildLegendItem(Colors.yellow.shade600, '20-30%', 'मध्यम'),
            _buildLegendItem(Colors.lightGreen.shade600, '30-40%', 'नम'),
            _buildLegendItem(Colors.blue.shade700, '40%+', 'बहुत नम'),
          ],
        );
      case 'ndvi':
        return Column(
          children: [
            _buildLegendItem(Colors.red.shade700, '-1 to 0', 'जल/बंजर'),
            _buildLegendItem(Colors.orange.shade600, '0-0.2', 'खराब'),
            _buildLegendItem(Colors.yellow.shade600, '0.2-0.4', 'मध्यम'),
            _buildLegendItem(Colors.lightGreen.shade600, '0.4-0.6', 'अच्छा'),
            _buildLegendItem(Colors.green.shade800, '0.6-1.0', 'उत्कृष्ट'),
          ],
        );
      case 'soil_texture':
        return Column(
          children: [
            _buildLegendItem(Colors.brown.shade900, 'Clay', 'चिकनी मिट्टी'),
            _buildLegendItem(Colors.brown.shade600, 'Loam', 'दोमट'),
            _buildLegendItem(Colors.brown.shade400, 'Sandy Loam', 'रेतीली दोमट'),
            _buildLegendItem(Colors.brown.shade200, 'Sandy', 'रेतीली'),
          ],
        );
      default:
        return Container();
    }
  }

  Widget _buildLegendItem(Color color, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF616161)),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 14,
              color: const Color(0xFF616161),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, String lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('satellite', 'map_filters', lang),
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  title: Text(AppStrings.get('satellite', 'show_districts', lang), style: GoogleFonts.notoSansDevanagari()),
                  value: _showDistricts,
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (value) {
                    setModalState(() => _showDistricts = value);
                    setState(() => _showDistricts = value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppStrings.get('satellite', 'weather_alerts', lang), style: GoogleFonts.notoSansDevanagari()),
                  value: _showWeather,
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (value) {
                    setModalState(() => _showWeather = value);
                    setState(() => _showWeather = value);
                  },
                ),
                SwitchListTile(
                  title: Text(AppStrings.get('satellite', 'ndvi_analysis', lang), style: GoogleFonts.notoSansDevanagari()),
                  value: _showNDVI,
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (value) {
                    setModalState(() => _showNDVI = value);
                    setState(() => _showNDVI = value);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('satellite', 'map_layer', lang),
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setModalState(() => _selectedLayer = 'satellite');
                          setState(() => _selectedLayer = 'satellite');
                        },
                        icon: const Icon(Icons.satellite),
                        label: Text(AppStrings.get('satellite', 'satellite_layer', lang), style: GoogleFonts.notoSansDevanagari()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedLayer == 'satellite'
                              ? const Color(0xFF1B5E20)
                              : Colors.grey.shade300,
                          foregroundColor: _selectedLayer == 'satellite'
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setModalState(() => _selectedLayer = 'terrain');
                          setState(() => _selectedLayer = 'terrain');
                        },
                        icon: const Icon(Icons.terrain),
                        label: Text(AppStrings.get('satellite', 'terrain_layer', lang), style: GoogleFonts.notoSansDevanagari()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedLayer == 'terrain'
                              ? const Color(0xFF1B5E20)
                              : Colors.grey.shade300,
                          foregroundColor: _selectedLayer == 'terrain'
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
