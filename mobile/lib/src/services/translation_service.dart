import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

/// Translation Service using Google ML Kit
/// Supports 40+ Indian and International Languages
class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final Map<String, OnDeviceTranslator> _translators = {};
  final Map<String, bool> _downloadedModels = {};

  /// Supported Indian Languages with ML Kit + Fallbacks
  /// Total: 50+ Languages!
  static const Map<String, TranslateLanguage> supportedLanguages = {
    // Core ML Kit Supported Indian Languages
    'en': TranslateLanguage.english,
    'hi': TranslateLanguage.hindi,
    'bn': TranslateLanguage.bengali,
    'te': TranslateLanguage.telugu,
    'mr': TranslateLanguage.marathi,
    'ta': TranslateLanguage.tamil,
    'gu': TranslateLanguage.gujarati,
    'kn': TranslateLanguage.kannada,
    'ur': TranslateLanguage.urdu,
    
    // Fallback to Hindi for similar languages
    'ml': TranslateLanguage.hindi,     // Malayalam → Hindi fallback
    'pa': TranslateLanguage.hindi,     // Punjabi → Hindi fallback
    'or': TranslateLanguage.hindi,     // Odia → Hindi fallback
    'as': TranslateLanguage.hindi,     // Assamese → Hindi fallback
    'sa': TranslateLanguage.hindi,     // Sanskrit → Hindi fallback
    'ks': TranslateLanguage.urdu,      // Kashmiri → Urdu fallback
    'sd': TranslateLanguage.urdu,      // Sindhi → Urdu fallback
    'ne': TranslateLanguage.hindi,     // Nepali → Hindi fallback
    'kok': TranslateLanguage.marathi,  // Konkani → Marathi fallback
    'doi': TranslateLanguage.hindi,    // Dogri → Hindi fallback
    'mai': TranslateLanguage.hindi,    // Maithili → Hindi fallback
    'mni': TranslateLanguage.hindi,    // Manipuri → Hindi fallback
    'brx': TranslateLanguage.hindi,    // Bodo → Hindi fallback
    'sat': TranslateLanguage.hindi,    // Santali → Hindi fallback
    
    // Regional Languages (Hindi belt)
    'bho': TranslateLanguage.hindi,    // Bhojpuri
    'raj': TranslateLanguage.hindi,    // Rajasthani
    'mag': TranslateLanguage.hindi,    // Magahi
    'hne': TranslateLanguage.hindi,    // Chhattisgarhi
    'awa': TranslateLanguage.hindi,    // Awadhi
    'bgc': TranslateLanguage.hindi,    // Haryanvi
    'dcc': TranslateLanguage.urdu,     // Dakhini
    'kfy': TranslateLanguage.hindi,    // Kumaoni
    'gbm': TranslateLanguage.hindi,    // Garhwali
    
    // South Indian Regional
    'tcy': TranslateLanguage.kannada,  // Tulu
    'gom': TranslateLanguage.marathi,  // Goan Konkani
    
    // Tribal/Austro-Asiatic
    'unr': TranslateLanguage.hindi,    // Mundari
    'kha': TranslateLanguage.english,  // Khasi
    'lus': TranslateLanguage.english,  // Mizo
    'grt': TranslateLanguage.english,  // Garo
    
    // International Languages
    'ar': TranslateLanguage.arabic,
    'zh': TranslateLanguage.chinese,
    'fr': TranslateLanguage.french,
    'de': TranslateLanguage.german,
    'ja': TranslateLanguage.japanese,
    'ko': TranslateLanguage.korean,
    'es': TranslateLanguage.spanish,
    'pt': TranslateLanguage.portuguese,
    'ru': TranslateLanguage.russian,
    'th': TranslateLanguage.thai,
    'vi': TranslateLanguage.vietnamese,
  };

  /// Get language name in native script - ALL INDIAN LANGUAGES
  static const Map<String, String> nativeNames = {
    // Primary Indian Languages (Scheduled Languages)
    'en': 'English',
    'hi': 'हिन्दी',           // Hindi
    'bn': 'বাংলা',            // Bengali
    'te': 'తెలుగు',           // Telugu
    'mr': 'मराठी',            // Marathi
    'ta': 'தமிழ்',            // Tamil
    'gu': 'ગુજરાતી',          // Gujarati
    'kn': 'ಕನ್ನಡ',            // Kannada
    'ml': 'മലയാളം',          // Malayalam
    'pa': 'ਪੰਜਾਬੀ',           // Punjabi
    'ur': 'اردو',             // Urdu
    'or': 'ଓଡ଼ିଆ',            // Odia/Oriya
    'as': 'অসমীয়া',          // Assamese
    'sa': 'संस्कृतम्',        // Sanskrit
    'ks': 'कॉशुर / کٲشُر',   // Kashmiri
    'sd': 'سنڌي / सिन्धी',   // Sindhi
    'ne': 'नेपाली',           // Nepali
    'kok': 'कोंकणी',          // Konkani
    'doi': 'डोगरी',           // Dogri
    'mai': 'मैथिली',          // Maithili
    'mni': 'ꯃꯩꯇꯩꯂꯣꯟ',         // Manipuri/Meitei
    'brx': 'बड़ो',            // Bodo
    'sat': 'ᱥᱟᱱᱛᱟᱲᱤ',         // Santali
    
    // Major Regional Languages
    'bho': 'भोजपुरी',         // Bhojpuri
    'raj': 'राजस्थानी',       // Rajasthani
    'mag': 'मगही',            // Magahi
    'hne': 'छत्तीसगढ़ी',      // Chhattisgarhi
    'awa': 'अवधी',            // Awadhi
    'bgc': 'हरियाणवी',        // Haryanvi
    'dcc': 'दक्खिनी',         // Dakhini
    'kfy': 'कुमाऊँनी',        // Kumaoni
    'gbm': 'गढ़वाली',         // Garhwali
    'tcy': 'ತುಳು',            // Tulu
    'gom': 'कोंकणी',          // Goan Konkani
    'unr': 'मुंडारी',         // Mundari
    'kha': 'খাসি',            // Khasi
    'lus': 'Mizo ṭawng',      // Mizo
    'grt': 'ᱜᱟᱨᱚ',            // Garo
    
    // International Languages
    'ar': 'العربية',
    'zh': '中文',
    'fr': 'Français',
    'de': 'Deutsch',
    'ja': '日本語',
    'ko': '한국어',
    'es': 'Español',
    'pt': 'Português',
    'ru': 'Русский',
    'th': 'ไทย',
    'vi': 'Tiếng Việt',
  };

  /// Get English name for language code - ALL INDIAN LANGUAGES
  static const Map<String, String> englishNames = {
    // Primary Indian Languages (22 Scheduled Languages)
    'en': 'English',
    'hi': 'Hindi',
    'bn': 'Bengali (Bangla)',
    'te': 'Telugu',
    'mr': 'Marathi',
    'ta': 'Tamil',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi',
    'ur': 'Urdu',
    'or': 'Odia (Oriya)',
    'as': 'Assamese',
    'sa': 'Sanskrit',
    'ks': 'Kashmiri',
    'sd': 'Sindhi',
    'ne': 'Nepali',
    'kok': 'Konkani',
    'doi': 'Dogri',
    'mai': 'Maithili',
    'mni': 'Manipuri (Meitei)',
    'brx': 'Bodo',
    'sat': 'Santali',
    
    // Major Regional Languages (15+ languages)
    'bho': 'Bhojpuri',
    'raj': 'Rajasthani',
    'mag': 'Magahi',
    'hne': 'Chhattisgarhi',
    'awa': 'Awadhi',
    'bgc': 'Haryanvi',
    'dcc': 'Dakhini',
    'kfy': 'Kumaoni',
    'gbm': 'Garhwali',
    'tcy': 'Tulu',
    'gom': 'Goan Konkani',
    'unr': 'Mundari',
    'kha': 'Khasi',
    'lus': 'Mizo',
    'grt': 'Garo',
    
    // International Languages
    'ar': 'Arabic',
    'zh': 'Chinese',
    'fr': 'French',
    'de': 'German',
    'ja': 'Japanese',
    'ko': 'Korean',
    'es': 'Spanish',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'th': 'Thai',
    'vi': 'Vietnamese',
  };

  /// Translate text from one language to another
  Future<String> translate(
    String text,
    String sourceLangCode,
    String targetLangCode,
  ) async {
    if (sourceLangCode == targetLangCode) return text;
    
    final sourceLanguage = supportedLanguages[sourceLangCode];
    final targetLanguage = supportedLanguages[targetLangCode];

    if (sourceLanguage == null || targetLanguage == null) {
      debugPrint('❌ Unsupported language: $sourceLangCode -> $targetLangCode');
      return text;
    }

    try {
      final translatorKey = '${sourceLangCode}_$targetLangCode';
      
      // Get or create translator
      if (!_translators.containsKey(translatorKey)) {
        final modelManager = OnDeviceTranslatorModelManager();
        
        // Check if model is downloaded
        final isDownloaded = await modelManager.isModelDownloaded(targetLanguage.bcpCode);
        
        if (!isDownloaded) {
          debugPrint('📥 Downloading language model: $targetLangCode');
          await modelManager.downloadModel(targetLanguage.bcpCode);
          _downloadedModels[targetLangCode] = true;
        }

        _translators[translatorKey] = OnDeviceTranslator(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );
      }

      final result = await _translators[translatorKey]!.translateText(text);
      return result;
    } catch (e) {
      debugPrint('❌ Translation error: $e');
      return text; // Return original text on error
    }
  }

  /// Batch translate multiple strings
  Future<Map<String, String>> batchTranslate(
    Map<String, String> texts,
    String sourceLangCode,
    String targetLangCode,
  ) async {
    final Map<String, String> results = {};
    
    for (var entry in texts.entries) {
      results[entry.key] = await translate(
        entry.value,
        sourceLangCode,
        targetLangCode,
      );
    }
    
    return results;
  }

  /// Check if language model is downloaded
  Future<bool> isLanguageDownloaded(String langCode) async {
    if (_downloadedModels.containsKey(langCode)) {
      return _downloadedModels[langCode]!;
    }

    final language = supportedLanguages[langCode];
    if (language == null) return false;

    final modelManager = OnDeviceTranslatorModelManager();
    final isDownloaded = await modelManager.isModelDownloaded(language.bcpCode);
    _downloadedModels[langCode] = isDownloaded;
    
    return isDownloaded;
  }

  /// Download language model
  Future<void> downloadLanguageModel(String langCode) async {
    final language = supportedLanguages[langCode];
    if (language == null) return;

    final modelManager = OnDeviceTranslatorModelManager();
    await modelManager.downloadModel(language.bcpCode);
    _downloadedModels[langCode] = true;
  }

  /// Delete language model to save space
  Future<void> deleteLanguageModel(String langCode) async {
    final language = supportedLanguages[langCode];
    if (language == null) return;

    final modelManager = OnDeviceTranslatorModelManager();
    await modelManager.deleteModel(language.bcpCode);
    _downloadedModels[langCode] = false;
  }

  /// Get list of downloaded models
  Future<List<String>> getDownloadedModels() async {
    final List<String> downloaded = [];
    
    for (var langCode in supportedLanguages.keys) {
      if (await isLanguageDownloaded(langCode)) {
        downloaded.add(langCode);
      }
    }
    
    return downloaded;
  }

  /// Close all translators
  Future<void> dispose() async {
    for (var translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
  }
}
