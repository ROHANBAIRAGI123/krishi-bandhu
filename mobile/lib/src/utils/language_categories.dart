/// Language Categories for Indian Languages
/// Organized by regions and language families

class LanguageCategories {
  // 22 Scheduled Languages of India (8th Schedule)
  static const List<String> scheduledLanguages = [
    'as',  // Assamese
    'bn',  // Bengali
    'brx', // Bodo
    'doi', // Dogri
    'gu',  // Gujarati
    'hi',  // Hindi
    'kn',  // Kannada
    'ks',  // Kashmiri
    'kok', // Konkani
    'mai', // Maithili
    'ml',  // Malayalam
    'mni', // Manipuri
    'mr',  // Marathi
    'ne',  // Nepali
    'or',  // Odia
    'pa',  // Punjabi
    'sa',  // Sanskrit
    'sat', // Santali
    'sd',  // Sindhi
    'ta',  // Tamil
    'te',  // Telugu
    'ur',  // Urdu
  ];

  // Major Regional Languages (spoken by millions)
  static const List<String> regionalLanguages = [
    'bho', // Bhojpuri (50M+ speakers)
    'raj', // Rajasthani (25M+ speakers)
    'mag', // Magahi (13M+ speakers)
    'hne', // Chhattisgarhi (16M+ speakers)
    'awa', // Awadhi (38M+ speakers)
    'bgc', // Haryanvi (10M+ speakers)
    'dcc', // Dakhini (13M+ speakers)
    'kfy', // Kumaoni (2M+ speakers)
    'gbm', // Garhwali (2M+ speakers)
    'tcy', // Tulu (2M+ speakers)
    'gom', // Goan Konkani (2.5M+ speakers)
  ];

  // Tribal & North-East Languages
  static const List<String> tribalLanguages = [
    'unr', // Mundari
    'kha', // Khasi
    'lus', // Mizo
    'grt', // Garo
  ];

  // South Indian Languages
  static const List<String> southIndianLanguages = [
    'ta',  // Tamil
    'te',  // Telugu
    'kn',  // Kannada
    'ml',  // Malayalam
    'tcy', // Tulu
  ];

  // North Indian Languages (Hindi Belt)
  static const List<String> northIndianLanguages = [
    'hi',  // Hindi
    'pa',  // Punjabi
    'ur',  // Urdu
    'bho', // Bhojpuri
    'raj', // Rajasthani
    'bgc', // Haryanvi
    'doi', // Dogri
    'kfy', // Kumaoni
    'gbm', // Garhwali
    'mai', // Maithili
    'awa', // Awadhi
    'mag', // Magahi
    'hne', // Chhattisgarhi
  ];

  // East Indian Languages
  static const List<String> eastIndianLanguages = [
    'bn',  // Bengali
    'as',  // Assamese
    'or',  // Odia
    'mni', // Manipuri
    'brx', // Bodo
    'sat', // Santali
    'kha', // Khasi
    'lus', // Mizo
    'grt', // Garo
    'unr', // Mundari
  ];

  // West Indian Languages
  static const List<String> westIndianLanguages = [
    'gu',  // Gujarati
    'mr',  // Marathi
    'kok', // Konkani
    'gom', // Goan Konkani
    'sd',  // Sindhi
  ];

  // Popular Languages (Most Used)
  static const List<String> popularLanguages = [
    'en',  // English
    'hi',  // Hindi
    'bn',  // Bengali
    'te',  // Telugu
    'mr',  // Marathi
    'ta',  // Tamil
    'gu',  // Gujarati
    'ur',  // Urdu
    'kn',  // Kannada
    'ml',  // Malayalam
    'pa',  // Punjabi
    'or',  // Odia
  ];

  // Get category name
  static String getCategoryName(String category) {
    switch (category) {
      case 'scheduled':
        return '📜 Scheduled Languages (22)';
      case 'regional':
        return '🏘️ Regional Languages';
      case 'south':
        return '🌴 South Indian';
      case 'north':
        return '⛰️ North Indian';
      case 'east':
        return '🌅 East Indian';
      case 'west':
        return '🌊 West Indian';
      case 'tribal':
        return '🏔️ Tribal & NE';
      case 'popular':
        return '⭐ Most Popular';
      default:
        return 'Other Languages';
    }
  }

  // Get languages by category
  static List<String> getLanguagesByCategory(String category) {
    switch (category) {
      case 'scheduled':
        return scheduledLanguages;
      case 'regional':
        return regionalLanguages;
      case 'south':
        return southIndianLanguages;
      case 'north':
        return northIndianLanguages;
      case 'east':
        return eastIndianLanguages;
      case 'west':
        return westIndianLanguages;
      case 'tribal':
        return tribalLanguages;
      case 'popular':
        return popularLanguages;
      default:
        return [];
    }
  }

  // All categories
  static const List<String> allCategories = [
    'popular',
    'scheduled',
    'north',
    'south',
    'east',
    'west',
    'regional',
    'tribal',
  ];
}
