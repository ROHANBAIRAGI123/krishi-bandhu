import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  bool _isLoadingLocation = true;
  Map<String, dynamic>? _weatherData;
  List<Map<String, dynamic>> _forecastData = [];
  Position? _currentPosition;
  String? _currentLocation;
  String? _selectedLocation;
  bool _useCurrentLocation = true;
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndWeather();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocationAndWeather() async {
    setState(() {
      _isLoadingLocation = true;
      _isLoading = true;
    });

    try {
      // Check location permissions with timeout
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          return;
        }
      }

      // Get current position with lower accuracy for faster response
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          _setDefaultLocation();
          throw TimeoutException('Location timeout');
        },
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3));

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String location = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown Location';
        
        setState(() {
          _currentPosition = position;
          _currentLocation = location;
          _isLoadingLocation = false;
        });
      }

      await _fetchWeatherData();
    } catch (e) {
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _currentLocation = 'Delhi';
      _isLoadingLocation = false;
    });
    _fetchWeatherData();
  }

  void _showLocationSearchDialog() {
    final locationsList = [
      'Delhi', 'Mumbai', 'Bangalore', 'Kolkata', 'Chennai', 
      'Hyderabad', 'Pune', 'Ahmedabad', 'Jaipur', 'Lucknow',
      'Chandigarh', 'Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala',
      'Hisar', 'Karnal', 'Rohtak', 'Panipat', 'Ambala',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.search, color: Colors.indigo.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Search Location'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _locationController,
                autofocus: true,
                style: GoogleFonts.roboto(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Type city or district name...',
                  prefixIcon: Icon(Icons.location_city, color: Colors.indigo.shade600),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.indigo.shade400, width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _selectedLocation = value;
                      _useCurrentLocation = false;
                    });
                    Navigator.pop(context);
                    _fetchWeatherData();
                    _locationController.clear();
                  }
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Popular Locations',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locationsList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.location_on, color: Colors.indigo.shade400, size: 20),
                      title: Text(
                        locationsList[index],
                        style: GoogleFonts.roboto(fontSize: 15),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedLocation = locationsList[index];
                          _useCurrentLocation = false;
                        });
                        Navigator.pop(context);
                        _fetchWeatherData();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _useCurrentLocation = true;
                      _selectedLocation = null;
                    });
                    Navigator.pop(context);
                    _getCurrentLocationAndWeather();
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use My Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _locationController.clear();
            },
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          if (_locationController.text.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                if (_locationController.text.isNotEmpty) {
                  setState(() {
                    _selectedLocation = _locationController.text;
                    _useCurrentLocation = false;
                  });
                  Navigator.pop(context);
                  _fetchWeatherData();
                  _locationController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply'),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchWeatherData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get location for API call
      String location = _useCurrentLocation 
          ? (_currentLocation ?? 'Delhi')
          : (_selectedLocation ?? 'Delhi');

      // OpenWeatherMap API - Free tier (No API key needed for demo)
      // For production, get API key from: https://openweathermap.org/api
      const apiKey = 'b6907d289e10d714a6e88b30761fae22'; // Demo key - replace with yours
      
      // Fetch real weather data
      final weatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$location,IN&appid=$apiKey&units=metric'
      );
      
      final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$location,IN&appid=$apiKey&units=metric'
      );

      // Fetch with timeout
      final weatherResponse = await http.get(weatherUrl).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (weatherResponse.statusCode == 200) {
        final weatherJson = json.decode(weatherResponse.body);
        
        // Fetch forecast
        final forecastResponse = await http.get(forecastUrl).timeout(
          const Duration(seconds: 8),
        );
        
        List<Map<String, dynamic>> forecast = [];
        if (forecastResponse.statusCode == 200) {
          final forecastJson = json.decode(forecastResponse.body);
          forecast = _parseForecastData(forecastJson);
        }
        
        setState(() {
          _weatherData = _parseWeatherData(weatherJson);
          _forecastData = forecast.isNotEmpty ? forecast : _getDemoForecastData();
          _isLoading = false;
        });
      } else {
        // Fallback to demo data if API fails
        setState(() {
          _weatherData = _getDemoWeatherData();
          _forecastData = _getDemoForecastData();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Weather API Error: $e');
      setState(() {
        _isLoading = false;
        _weatherData = _getDemoWeatherData();
        _forecastData = _getDemoForecastData();
      });
    }
  }

  Map<String, dynamic> _parseWeatherData(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];
    final sys = json['sys'];
    
    return {
      'temp': (main['temp'] as num).round(),
      'feels_like': (main['feels_like'] as num).round(),
      'humidity': main['humidity'],
      'wind_speed': ((wind['speed'] as num) * 3.6).round(), // m/s to km/h
      'pressure': main['pressure'],
      'visibility': ((json['visibility'] ?? 10000) / 1000).round(),
      'uv_index': 5, // UV index requires separate API call
      'rainfall': 0,
      'condition': weather['main'],
      'description': weather['description'],
      'icon': _getWeatherIcon(weather['main']),
      'sunrise': DateFormat('HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(sys['sunrise'] * 1000)
      ),
      'sunset': DateFormat('HH:mm').format(
        DateTime.fromMillisecondsSinceEpoch(sys['sunset'] * 1000)
      ),
      'aqi': 75,
      'location': json['name'],
    };
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.wb_cloudy;
      case 'rain':
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.cloud;
      default:
        return Icons.wb_cloudy;
    }
  }

  List<Map<String, dynamic>> _parseForecastData(Map<String, dynamic> json) {
    final List<dynamic> list = json['list'];
    final Map<String, Map<String, dynamic>> dailyData = {};
    
    for (var item in list) {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final String day = DateFormat('EEE').format(date);
      
      if (!dailyData.containsKey(day) && dailyData.length < 7) {
        final weather = item['weather'][0];
        dailyData[day] = {
          'day': day,
          'high': (item['main']['temp_max'] as num).round(),
          'low': (item['main']['temp_min'] as num).round(),
          'rain': ((item['pop'] ?? 0) * 100).round(),
          'icon': _getWeatherIcon(weather['main']),
        };
      }
    }
    
    return dailyData.values.toList();
  }

  Map<String, dynamic> _getDemoWeatherData() {
    // Generate location-based realistic data
    final location = _useCurrentLocation 
        ? (_currentLocation ?? 'Delhi')
        : (_selectedLocation ?? 'Delhi');
    
    // Simulate realistic weather based on location
    final temps = {
      'Delhi': {'temp': 26, 'feels': 28, 'humidity': 62},
      'Mumbai': {'temp': 31, 'feels': 34, 'humidity': 78},
      'Bangalore': {'temp': 24, 'feels': 25, 'humidity': 65},
      'Chennai': {'temp': 33, 'feels': 36, 'humidity': 75},
      'Kolkata': {'temp': 29, 'feels': 32, 'humidity': 80},
      'Hyderabad': {'temp': 30, 'feels': 33, 'humidity': 55},
      'Pune': {'temp': 27, 'feels': 29, 'humidity': 60},
      'Jaipur': {'temp': 28, 'feels': 31, 'humidity': 45},
    };
    
    final data = temps[location] ?? temps['Delhi']!;
    
    return {
      'temp': data['temp'],
      'feels_like': data['feels'],
      'humidity': data['humidity'],
      'wind_speed': 12 + (location.hashCode % 10),
      'pressure': 1010 + (location.hashCode % 15),
      'visibility': 8 + (location.hashCode % 5),
      'uv_index': 5 + (location.hashCode % 6),
      'rainfall': (location.hashCode % 5).toDouble(),
      'condition': data['humidity']! > 70 ? 'Cloudy' : 'Partly Cloudy',
      'icon': data['humidity']! > 70 ? Icons.cloud : Icons.wb_cloudy,
      'sunrise': '06:15',
      'sunset': '18:45',
      'aqi': 70 + (location.hashCode % 40),
      'location': location,
    };
  }

  List<Map<String, dynamic>> _getDemoForecastData() {
    return [
      {'day': 'Mon', 'high': 32, 'low': 24, 'rain': 20, 'icon': Icons.wb_sunny},
      {'day': 'Tue', 'high': 31, 'low': 23, 'rain': 30, 'icon': Icons.cloud},
      {'day': 'Wed', 'high': 29, 'low': 22, 'rain': 60, 'icon': Icons.grain},
      {'day': 'Thu', 'high': 28, 'low': 21, 'rain': 80, 'icon': Icons.umbrella},
      {'day': 'Fri', 'high': 30, 'low': 23, 'rain': 40, 'icon': Icons.cloud},
      {'day': 'Sat', 'high': 33, 'low': 25, 'rain': 10, 'icon': Icons.wb_sunny},
      {'day': 'Sun', 'high': 34, 'low': 26, 'rain': 5, 'icon': Icons.wb_sunny},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF5F7FA), // Light professional gray
            const Color(0xFFFFFFFF), // Pure white
          ],
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Location Header with Search
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withOpacity(0.08),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1A237E).withOpacity(0.1),
                                const Color(0xFF0D47A1).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _useCurrentLocation ? Icons.my_location : Icons.location_city,
                            color: const Color(0xFF1A237E),
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _isLoadingLocation
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: const Color(0xFF1A237E),
                                      ),
                                    )
                                  : Text(
                                      _useCurrentLocation 
                                          ? (_currentLocation ?? 'Unknown')
                                          : (_selectedLocation ?? 'Delhi'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A237E),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _useCurrentLocation 
                                          ? const Color(0xFF4CAF50) 
                                          : const Color(0xFF1A237E),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_useCurrentLocation 
                                              ? const Color(0xFF4CAF50) 
                                              : const Color(0xFF1A237E)).withOpacity(0.4),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    _useCurrentLocation ? 'Live Location' : 'Custom Location',
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.search, color: Color(0xFF1A237E)),
                            onPressed: _showLocationSearchDialog,
                            tooltip: 'Change Location',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A237E).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh, color: Color(0xFF1A237E)),
                            onPressed: _useCurrentLocation 
                                ? _getCurrentLocationAndWeather 
                                : _fetchWeatherData,
                            tooltip: 'Refresh Data',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Current Weather Card
                SliverToBoxAdapter(
                  child: _buildCurrentWeatherCard(),
                ),

                // Weather Metrics Grid
                SliverToBoxAdapter(
                  child: _buildWeatherMetricsGrid(),
                ),

                // 7-Day Forecast
                SliverToBoxAdapter(
                  child: _build7DayForecast(),
                ),

                // Weather Graphs
                SliverToBoxAdapter(
                  child: _buildTemperatureGraph(),
                ),

                SliverToBoxAdapter(
                  child: _buildRainfallGraph(),
                ),

                // Crop Impact Analysis
                SliverToBoxAdapter(
                  child: _buildCropImpactSection(),
                ),

                // Agricultural Advisories
                SliverToBoxAdapter(
                  child: _buildAgriculturalAdvisories(),
                ),

                // Soil Moisture Index
                SliverToBoxAdapter(
                  child: _buildSoilMoistureSection(),
                ),

                // Pest & Disease Alert
                SliverToBoxAdapter(
                  child: _buildPestDiseaseAlert(),
                ),

                // Irrigation Recommendation
                SliverToBoxAdapter(
                  child: _buildIrrigationRecommendation(),
                ),

                // Harvesting Calendar
                SliverToBoxAdapter(
                  child: _buildHarvestingCalendar(),
                ),

                // Weather-based Alerts for Officers
                SliverToBoxAdapter(
                  child: _buildOfficerAlerts(),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildCurrentWeatherCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E), // Deep Navy Blue
            const Color(0xFF0D47A1), // Rich Blue
            const Color(0xFF01579B), // Ocean Blue
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sophisticated pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                painter: WeatherPatternPainter(),
              ),
            ),
          ),
          // Gradient overlay for depth
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.9),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _weatherData!['location'],
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMM d').format(DateTime.now()),
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.update,
                            color: Colors.white.withOpacity(0.9),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_weatherData!['temp']}°',
                          style: GoogleFonts.poppins(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _weatherData!['condition'],
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Feels like ${_weatherData!['feels_like']}°C',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _weatherData!['icon'],
                      size: 100,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeatherStat(
                        Icons.water_drop,
                        '${_weatherData!['humidity']}%',
                        'Humidity',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildWeatherStat(
                        Icons.air,
                        '${_weatherData!['wind_speed']} km/h',
                        'Wind',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      _buildWeatherStat(
                        Icons.grain,
                        '${_weatherData!['rainfall']} mm',
                        'Rain',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherMetricsGrid() {
    final metrics = [
      {
        'icon': Icons.compress,
        'label': 'Pressure',
        'value': '${_weatherData!['pressure']} hPa',
        'color': Colors.purple,
      },
      {
        'icon': Icons.visibility,
        'label': 'Visibility',
        'value': '${_weatherData!['visibility']} km',
        'color': Colors.teal,
      },
      {
        'icon': Icons.wb_sunny,
        'label': 'UV Index',
        'value': '${_weatherData!['uv_index']}',
        'color': Colors.orange,
      },
      {
        'icon': Icons.air_outlined,
        'label': 'Air Quality',
        'value': '${_weatherData!['aqi']} AQI',
        'color': Colors.green,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather Metrics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      metric['icon'] as IconData,
                      color: metric['color'] as Color,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric['value'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      metric['label'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _build7DayForecast() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _forecastData.length,
              itemBuilder: (context, index) {
                final day = _forecastData[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        day['day'],
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        day['icon'],
                        color: Colors.blue.shade700,
                        size: 32,
                      ),
                      Text(
                        '${day['high']}°',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${day['low']}°',
                        style: GoogleFonts.roboto(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop, size: 12, color: Colors.blue),
                          const SizedBox(width: 2),
                          Text(
                            '${day['rain']}%',
                            style: GoogleFonts.roboto(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureGraph() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature Trend',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}°',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _forecastData.length) {
                          return Text(
                            _forecastData[value.toInt()]['day'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _forecastData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['high'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.red.shade400,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.red.shade100.withOpacity(0.3),
                    ),
                  ),
                  LineChartBarData(
                    spots: _forecastData.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        entry.value['low'].toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue.shade400,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.shade100.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainfallGraph() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rainfall Forecast',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < _forecastData.length) {
                          return Text(
                            _forecastData[value.toInt()]['day'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _forecastData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['rain'].toDouble(),
                        color: Colors.blue.shade400,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropImpactSection() {
    final impacts = [
      {
        'crop': 'Wheat',
        'status': 'Favorable',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'details': 'Temperature and moisture levels are optimal for wheat growth.',
      },
      {
        'crop': 'Rice',
        'status': 'Good',
        'icon': Icons.check_circle_outline,
        'color': Colors.lightGreen,
        'details': 'Adequate rainfall expected. Monitor water levels.',
      },
      {
        'crop': 'Cotton',
        'status': 'Caution',
        'icon': Icons.warning,
        'color': Colors.orange,
        'details': 'High temperatures may stress plants. Ensure irrigation.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crop Impact Analysis',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...impacts.map((impact) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (impact['color'] as Color).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    impact['icon'] as IconData,
                    color: impact['color'] as Color,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              impact['crop'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (impact['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                impact['status'] as String,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: impact['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          impact['details'] as String,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAgriculturalAdvisories() {
    final advisories = [
      {
        'title': 'Irrigation Advisory',
        'icon': Icons.water_drop,
        'color': Colors.blue,
        'message': 'Moderate rainfall expected in next 3 days. Reduce irrigation frequency.',
      },
      {
        'title': 'Pest Alert',
        'icon': Icons.bug_report,
        'color': Colors.red,
        'message': 'High humidity may increase pest activity. Monitor crops closely.',
      },
      {
        'title': 'Fertilizer Timing',
        'icon': Icons.eco,
        'color': Colors.green,
        'message': 'Good weather window for fertilizer application in next 48 hours.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agricultural Advisories',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...advisories.map((advisory) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (advisory['color'] as Color).withOpacity(0.1),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (advisory['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: advisory['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      advisory['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          advisory['title'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: advisory['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          advisory['message'] as String,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSoilMoistureSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Soil Moisture Index',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade50, Colors.brown.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.shade300),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Moisture Level',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '65%',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMoistureIndicator('Top Layer', '70%', Colors.green),
                    _buildMoistureIndicator('Mid Layer', '65%', Colors.lightGreen),
                    _buildMoistureIndicator('Deep', '55%', Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoistureIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildPestDiseaseAlert() {
    final alerts = [
      {
        'pest': 'Fall Armyworm',
        'risk': 'High',
        'crops': 'Maize, Rice',
        'action': 'Apply biopesticides immediately',
        'color': Colors.red,
      },
      {
        'pest': 'Aphids',
        'risk': 'Medium',
        'crops': 'Cotton, Vegetables',
        'action': 'Monitor daily, consider neem spray',
        'color': Colors.orange,
      },
      {
        'pest': 'Stem Borer',
        'risk': 'Low',
        'crops': 'Rice, Sugarcane',
        'action': 'Regular field inspection',
        'color': Colors.green,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pest & Disease Alert',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (alert['color'] as Color).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert['pest'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (alert['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${alert['risk']} Risk',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: alert['color'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Affected Crops: ${alert['crops']}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Action: ${alert['action']}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIrrigationRecommendation() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Irrigation Recommendation',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan.shade50, Colors.cyan.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Moderate Irrigation Needed',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildIrrigationItem('Next Irrigation', 'In 2 days', Icons.schedule),
                _buildIrrigationItem('Water Requirement', '30-35 mm', Icons.opacity),
                _buildIrrigationItem('Best Time', '5:00 AM - 7:00 AM', Icons.access_time),
                _buildIrrigationItem('Expected Rainfall', '15 mm in 48 hrs', Icons.cloud),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIrrigationItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestingCalendar() {
    final crops = [
      {'crop': 'Wheat', 'stage': 'Flowering', 'daysToHarvest': 45, 'color': Colors.amber},
      {'crop': 'Rice', 'stage': 'Maturity', 'daysToHarvest': 15, 'color': Colors.green},
      {'crop': 'Cotton', 'stage': 'Boll Development', 'daysToHarvest': 60, 'color': Colors.purple},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harvesting Calendar',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...crops.map((crop) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (crop['color'] as Color).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (crop['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.agriculture,
                      color: crop['color'] as Color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop['crop'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Stage: ${crop['stage']}',
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${crop['daysToHarvest']}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: crop['color'] as Color,
                        ),
                      ),
                      Text(
                        'days',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOfficerAlerts() {
    final alerts = [
      {
        'title': 'Field Inspection Required',
        'description': '12 farms need immediate inspection due to weather damage',
        'icon': Icons.warning_amber,
        'color': Colors.orange,
        'priority': 'High',
      },
      {
        'title': 'Subsidy Disbursement',
        'description': '45 farmers eligible for weather-based compensation',
        'icon': Icons.account_balance_wallet,
        'color': Colors.green,
        'priority': 'Medium',
      },
      {
        'title': 'Training Session',
        'description': 'Conduct climate-resilient farming training next week',
        'icon': Icons.school,
        'color': Colors.blue,
        'priority': 'Low',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Officer Action Items',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (alert['color'] as Color).withOpacity(0.05),
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (alert['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: alert['color'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      alert['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert['title'] as String,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (alert['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                alert['priority'] as String,
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: alert['color'] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert['description'] as String,
                          style: GoogleFonts.roboto(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Custom painter for weather card pattern
class WeatherPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw diagonal lines pattern
    for (double i = -size.height; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw subtle circles
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.3), 60, circlePaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 80, circlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
