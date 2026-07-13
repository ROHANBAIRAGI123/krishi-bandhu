import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherService {
  static const String _apiKey = 'b6907d289e10d714a6e88b30761fae22';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get city name from coordinates
  Future<String?> getCityFromCoordinates(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon)
          .timeout(const Duration(seconds: 3));

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return place.locality ?? 
               place.subAdministrativeArea ?? 
               place.administrativeArea ?? 
               'Unknown';
      }
      return null;
    } catch (e) {
      print('Error getting city name: $e');
      return null;
    }
  }

  /// Fetch weather data by coordinates
  Future<Map<String, dynamic>?> getWeatherByCoordinates(
    double lat,
    double lon,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      }
      return null;
    } catch (e) {
      print('Error fetching weather by coordinates: $e');
      return null;
    }
  }

  /// Fetch weather data by city name
  Future<Map<String, dynamic>?> getWeatherByCity(String city) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/weather?q=$city,IN&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Weather API timeout'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseWeatherData(data);
      }
      return null;
    } catch (e) {
      print('Error fetching weather by city: $e');
      return null;
    }
  }

  /// Get weather for current location
  Future<Map<String, dynamic>?> getWeatherForCurrentLocation() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        // Fallback to Delhi if location unavailable
        return await getWeatherByCity('Delhi');
      }

      final weather = await getWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );

      if (weather != null) {
        final city = await getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );
        weather['location'] = city ?? 'Unknown';
      }

      return weather;
    } catch (e) {
      print('Error getting weather for current location: $e');
      return await getWeatherByCity('Delhi');
    }
  }

  /// Parse weather data from API response
  Map<String, dynamic> _parseWeatherData(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];

    return {
      'location': json['name'],
      'temp': (main['temp'] as num).round(),
      'feels_like': (main['feels_like'] as num).round(),
      'temp_min': (main['temp_min'] as num).round(),
      'temp_max': (main['temp_max'] as num).round(),
      'humidity': main['humidity'],
      'pressure': main['pressure'],
      'wind_speed': ((wind['speed'] as num) * 3.6).round(), // m/s to km/h
      'wind_deg': wind['deg'] ?? 0,
      'description': weather['description'],
      'icon': weather['icon'],
      'main': weather['main'],
      'visibility': ((json['visibility'] ?? 10000) / 1000).round(),
      'clouds': json['clouds']['all'],
      'sunrise': DateTime.fromMillisecondsSinceEpoch(
        json['sys']['sunrise'] * 1000,
      ),
      'sunset': DateTime.fromMillisecondsSinceEpoch(
        json['sys']['sunset'] * 1000,
      ),
    };
  }

  /// Get weather icon URL
  String getWeatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  /// Get weather icon for Flutter
  static String getWeatherIconLocal(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}
