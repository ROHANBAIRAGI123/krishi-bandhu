import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/language_provider.dart';
import '../utils/language_categories.dart';
import '../services/translation_service.dart';

class LanguageSelectorWidget extends StatefulWidget {
  final bool showAsButton;
  final VoidCallback? onLanguageChanged;

  const LanguageSelectorWidget({
    super.key,
    this.showAsButton = false,
    this.onLanguageChanged,
  });

  @override
  State<LanguageSelectorWidget> createState() => _LanguageSelectorWidgetState();
}

class _LanguageSelectorWidgetState extends State<LanguageSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        if (widget.showAsButton) {
          return _buildLanguageButton(langProvider);
        }
        return _buildLanguageDropdown(langProvider);
      },
    );
  }

  Widget _buildLanguageButton(LanguageProvider langProvider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showLanguageBottomSheet(context, langProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.shade600,
                Colors.green.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                langProvider.getNativeLanguageName(langProvider.currentLanguage),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown(LanguageProvider langProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: DropdownButton<String>(
        value: langProvider.currentLanguage,
        isExpanded: true,
        underline: const SizedBox(),
        items: langProvider.supportedLanguages.map((code) {
          return DropdownMenuItem(
            value: code,
            child: Text(
              langProvider.getNativeLanguageName(code),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          );
        }).toList(),
        onChanged: (code) async {
          if (code != null) {
            await langProvider.setLanguage(code);
            widget.onLanguageChanged?.call();
          }
        },
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, LanguageProvider langProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: langProvider,
        child: _LanguageBottomSheet(
          currentLanguage: langProvider.currentLanguage,
          onLanguageSelected: (code) async {
            await langProvider.setLanguage(code);
            widget.onLanguageChanged?.call();
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _LanguageBottomSheet extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageSelected;

  const _LanguageBottomSheet({
    required this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  State<_LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends State<_LanguageBottomSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'popular';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProvider, child) {
        final languages = _getFilteredLanguages(langProvider);

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select Language | भाषा चुनें',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '50+ Languages',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.flag, size: 14, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '22 Scheduled + Regional',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search language...',
                    prefixIcon: Icon(Icons.search, color: Colors.green.shade700),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Category Chips (only if no search)
              if (_searchQuery.isEmpty)
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: LanguageCategories.allCategories.length,
                    itemBuilder: (context, index) {
                      final category = LanguageCategories.allCategories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            LanguageCategories.getCategoryName(category),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.green.shade800,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          selectedColor: Colors.green.shade600,
                          backgroundColor: Colors.green.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Colors.green.shade600 : Colors.green.shade300,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Language List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: languages.length,
                  itemBuilder: (context, index) {
                    final code = languages[index];
                    final isSelected = code == widget.currentLanguage;

                    return _buildLanguageItem(
                      langProvider,
                      code,
                      isSelected,
                      index,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<String> _getFilteredLanguages(LanguageProvider langProvider) {
    if (_searchQuery.isNotEmpty) {
      return langProvider.supportedLanguages
          .where((code) {
            final nativeName = TranslationService.nativeNames[code]?.toLowerCase() ?? '';
            final englishName = TranslationService.englishNames[code]?.toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return nativeName.contains(query) || englishName.contains(query);
          })
          .toList();
    } else {
      return LanguageCategories.getLanguagesByCategory(_selectedCategory);
    }
  }

  Widget _buildLanguageItem(
    LanguageProvider langProvider,
    String code,
    bool isSelected,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onLanguageSelected(code),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.shade50
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Colors.green.shade600
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Flag Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getLanguageFlag(code),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Language Names
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.nativeNames[code] ?? code,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? Colors.green.shade900 : Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        TranslationService.englishNames[code] ?? code,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Selected Indicator
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageFlag(String code) {
    const Map<String, String> flags = {
      'en': '🇬🇧',
      'hi': '🇮🇳',
      'bn': '🇮🇳',
      'te': '🇮🇳',
      'mr': '🇮🇳',
      'ta': '🇮🇳',
      'gu': '🇮🇳',
      'kn': '🇮🇳',
      'ml': '🇮🇳',
      'pa': '🇮🇳',
      'ur': '🇵🇰',
    };
    return flags[code] ?? '🌐';
  }
}
