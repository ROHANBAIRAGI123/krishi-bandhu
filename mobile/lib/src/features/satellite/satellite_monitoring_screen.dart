import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SatelliteMonitoringScreen extends StatefulWidget {
  const SatelliteMonitoringScreen({super.key});

  @override
  State<SatelliteMonitoringScreen> createState() => _SatelliteMonitoringScreenState();
}

class _SatelliteMonitoringScreenState extends State<SatelliteMonitoringScreen> {
  final MapController _mapController = MapController();
  bool _showFarmers = true;
  bool _showWeather = true;
  bool _showAlerts = true;
  String _selectedLayer = 'satellite';

  // Farmer locations data
  final List<Map<String, dynamic>> farmers = [
    {
      'name': 'Rajesh Kumar',
      'location': LatLng(28.6139, 77.2090),
      'village': 'Nangloi, Delhi',
      'crop': 'Wheat',
      'area': '5 acres',
      'health': 'Good',
      'ndvi': 0.78,
    },
    {
      'name': 'Suresh Patel',
      'location': LatLng(23.0225, 72.5714),
      'village': 'Vastral, Ahmedabad',
      'crop': 'Cotton',
      'area': '8 acres',
      'health': 'Excellent',
      'ndvi': 0.85,
    },
    {
      'name': 'Lakshmi Devi',
      'location': LatLng(17.3850, 78.4867),
      'village': 'Medchal, Hyderabad',
      'crop': 'Rice',
      'area': '4 acres',
      'health': 'Good',
      'ndvi': 0.72,
    },
    {
      'name': 'Ramesh Singh',
      'location': LatLng(26.9124, 75.7873),
      'village': 'Chomu, Jaipur',
      'crop': 'Bajra',
      'area': '10 acres',
      'health': 'Fair',
      'ndvi': 0.65,
    },
    {
      'name': 'Priya Sharma',
      'location': LatLng(19.0760, 72.8777),
      'village': 'Goregaon, Mumbai',
      'crop': 'Vegetables',
      'area': '3 acres',
      'health': 'Good',
      'ndvi': 0.70,
    },
  ];

  // Weather stations
  final List<Map<String, dynamic>> weatherStations = [
    {
      'name': 'Delhi Station',
      'location': LatLng(28.7041, 77.1025),
      'temp': '28°C',
      'humidity': '65%',
      'rainfall': '2mm',
    },
    {
      'name': 'Mumbai Station',
      'location': LatLng(19.0896, 72.8656),
      'temp': '31°C',
      'humidity': '78%',
      'rainfall': '5mm',
    },
  ];

  // Damage alerts
  final List<Map<String, dynamic>> damageAlerts = [
    {
      'location': LatLng(26.9124, 75.7873),
      'severity': 'Medium',
      'type': 'Drought Stress',
      'date': '2025-11-25',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🛰️ Satellite Monitoring'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers),
            onSelected: (value) {
              setState(() => _selectedLayer = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'satellite',
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt, 
                      color: _selectedLayer == 'satellite' ? colorScheme.primary : null),
                    const SizedBox(width: 8),
                    const Text('Satellite View'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'terrain',
                child: Row(
                  children: [
                    Icon(Icons.terrain, 
                      color: _selectedLayer == 'terrain' ? colorScheme.primary : null),
                    const SizedBox(width: 8),
                    const Text('Terrain View'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.5937, 78.9629), // Center of India
              initialZoom: 5.0,
              minZoom: 4.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapUrl(),
                userAgentPackageName: 'com.example.krashi_bandhu',
              ),
              if (_showFarmers) _buildFarmerMarkers(),
              if (_showWeather) _buildWeatherMarkers(),
              if (_showAlerts) _buildAlertMarkers(),
            ],
          ),

          // Filter Controls
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip('Farmers', _showFarmers, Icons.person, Colors.green,
                      (value) => setState(() => _showFarmers = value)),
                    const SizedBox(height: 4),
                    _buildFilterChip('Weather', _showWeather, Icons.cloud, Colors.blue,
                      (value) => setState(() => _showWeather = value)),
                    const SizedBox(height: 4),
                    _buildFilterChip('Alerts', _showAlerts, Icons.warning, Colors.red,
                      (value) => setState(() => _showAlerts = value)),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Positioned(
            bottom: 100,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildLegendItem(Icons.location_on, Colors.green, 'Farmers'),
                    _buildLegendItem(Icons.cloud, Colors.blue, 'Weather'),
                    _buildLegendItem(Icons.warning, Colors.red, 'Alerts'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoom_in',
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
            child: const Icon(Icons.add),
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
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'my_location',
            onPressed: () {
              _mapController.move(const LatLng(20.5937, 78.9629), 5.0);
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  String _getMapUrl() {
    switch (_selectedLayer) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      default:
        return 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  Widget _buildFarmerMarkers() {
    return MarkerLayer(
      markers: farmers.map((farmer) {
        return Marker(
          point: farmer['location'],
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showFarmerDetails(farmer),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeatherMarkers() {
    return MarkerLayer(
      markers: weatherStations.map((station) {
        return Marker(
          point: station['location'],
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showWeatherDetails(station),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.cloud, color: Colors.white, size: 20),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlertMarkers() {
    return MarkerLayer(
      markers: damageAlerts.map((alert) {
        return Marker(
          point: alert['location'],
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showAlertDetails(alert),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.warning, color: Colors.white, size: 20),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterChip(String label, bool value, IconData icon, Color color,
      Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: value ? color : Colors.grey, size: 20),
          const SizedBox(width: 4),
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v!),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _showFarmerDetails(Map<String, dynamic> farmer) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(farmer['name'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow('Village', farmer['village']),
            _detailRow('Crop', farmer['crop']),
            _detailRow('Area', farmer['area']),
            _detailRow('Health', farmer['health']),
            _detailRow('NDVI', farmer['ndvi'].toString()),
          ],
        ),
      ),
    );
  }

  void _showWeatherDetails(Map<String, dynamic> station) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(station['name'],
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow('Temperature', station['temp']),
            _detailRow('Humidity', station['humidity']),
            _detailRow('Rainfall', station['rainfall']),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Damage Alert',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
            const Divider(),
            _detailRow('Severity', alert['severity']),
            _detailRow('Type', alert['type']),
            _detailRow('Date', alert['date']),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
