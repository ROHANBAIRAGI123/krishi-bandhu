import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/translation_service.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en';
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  final TranslationService _translationService = TranslationService();

  // Cached translations for performance
  final Map<String, Map<String, String>> _translationCache = {};

  String get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  /// Get all supported languages from ML Kit
  List<String> get supportedLanguages => TranslationService.supportedLanguages.keys.toList();
  
  /// Get total count of supported languages
  int get languageCount => supportedLanguages.length;

  // Initialize the provider by loading saved language preference
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs.getString('app_language') ?? 'en';
    _isInitialized = true;
    
    // Pre-download current language model if not already downloaded
    _preloadLanguageModel(_currentLanguage);
    
    notifyListeners();
  }

  /// Preload language model in background
  Future<void> _preloadLanguageModel(String langCode) async {
    try {
      final isDownloaded = await _translationService.isLanguageDownloaded(langCode);
      if (!isDownloaded && langCode != 'en') {
        debugPrint('📥 Pre-downloading language model: $langCode');
        await _translationService.downloadLanguageModel(langCode);
      }
    } catch (e) {
      debugPrint('❌ Error preloading language model: $e');
    }
  }

  // Change language and persist to SharedPreferences
  Future<void> setLanguage(String languageCode) async {
    if (_currentLanguage == languageCode) return;
    
    _currentLanguage = languageCode;
    await _prefs.setString('app_language', languageCode);
    
    // Clear translation cache when language changes
    _translationCache.clear();
    
    // Preload new language model
    _preloadLanguageModel(languageCode);
    
    notifyListeners();
  }

  // Get language name in English
  String getLanguageName(String code) {
    return TranslationService.englishNames[code] ?? 'Unknown';
  }

  // Get language name in native script
  String getNativeLanguageName(String code) {
    return TranslationService.nativeNames[code] ?? 'Unknown';
  }

  /// Translate text to current language
  Future<String> translate(String text, {String sourceLanguage = 'en'}) async {
    if (_currentLanguage == sourceLanguage) return text;
    
    // Check cache first
    final cacheKey = '${sourceLanguage}_${_currentLanguage}_$text';
    if (_translationCache[_currentLanguage]?.containsKey(cacheKey) ?? false) {
      return _translationCache[_currentLanguage]![cacheKey]!;
    }

    try {
      final translated = await _translationService.translate(
        text,
        sourceLanguage,
        _currentLanguage,
      );
      
      // Cache the translation
      _translationCache[_currentLanguage] ??= {};
      _translationCache[_currentLanguage]![cacheKey] = translated;
      
      return translated;
    } catch (e) {
      debugPrint('Translation error: $e');
      return text;
    }
  }

  /// Batch translate multiple strings
  Future<Map<String, String>> batchTranslate(
    Map<String, String> texts, {
    String sourceLanguage = 'en',
  }) async {
    if (_currentLanguage == sourceLanguage) return texts;

    return await _translationService.batchTranslate(
      texts,
      sourceLanguage,
      _currentLanguage,
    );
  }

  /// Check if a language model is downloaded
  Future<bool> isLanguageDownloaded(String langCode) async {
    return await _translationService.isLanguageDownloaded(langCode);
  }

  /// Download a language model
  Future<void> downloadLanguageModel(String langCode) async {
    await _translationService.downloadLanguageModel(langCode);
    notifyListeners();
  }

  /// Get list of downloaded language models
  Future<List<String>> getDownloadedModels() async {
    return await _translationService.getDownloadedModels();
  }

  @override
  void dispose() {
    _translationService.dispose();
    super.dispose();
  }
}
