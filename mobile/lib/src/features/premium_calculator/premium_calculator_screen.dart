import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'data/india_data.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';

class PremiumCalculatorScreen extends StatefulWidget {
  const PremiumCalculatorScreen({super.key});

  @override
  State<PremiumCalculatorScreen> createState() => _PremiumCalculatorScreenState();
}

class _PremiumCalculatorScreenState extends State<PremiumCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form field values
  String? _selectedSeason;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCrop;
  String? _selectedScheme;
  String? _selectedYear;
  final TextEditingController _areaController = TextEditingController();
  
  // Calculated premium
  double? _calculatedPremium;
  double? _sumInsured;
  
  // Available options
  final List<String> _seasons = ['Kharif (खरीफ)', 'Rabi (रबी)'];
  final List<String> _schemes = [
    'PMFBY (Pradhan Mantri Fasal Bima Yojana)',
    'WBCIS (Weather Based Crop Insurance Scheme)',
    'Modified NAIS',
  ];
  
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _crops = [];
  List<String> _years = [];
  
  @override
  void initState() {
    super.initState();
    _states = IndiaData.getStates();
    _crops = IndiaData.getCrops();
    _generateYears();
  }
  
  void _generateYears() {
    final currentYear = DateTime.now().year;
    _years = List.generate(5, (index) => (currentYear - index).toString());
  }
  
  void _onStateChanged(String? state) {
    setState(() {
      _selectedState = state;
      _selectedDistrict = null;
      _districts = state != null ? IndiaData.getDistricts(state) : [];
    });
  }
  
  void _calculatePremium() {
    if (_formKey.currentState!.validate()) {
      final area = double.tryParse(_areaController.text) ?? 0;
      
      // Premium calculation logic based on PMFBY rates
      double premiumRate = 0;
      double avgYieldPerHectare = 0;
      
      // Season-based rates
      if (_selectedSeason == 'Kharif (खरीफ)') {
        premiumRate = 0.02; // 2% for Kharif
      } else {
        premiumRate = 0.015; // 1.5% for Rabi
      }
      
      // Crop-based average yield (tons per hectare)
      if (_selectedCrop?.contains('Wheat') ?? false) {
        avgYieldPerHectare = 3.5;
      } else if (_selectedCrop?.contains('Rice') ?? false) {
        avgYieldPerHectare = 3.0;
      } else if (_selectedCrop?.contains('Cotton') ?? false) {
        avgYieldPerHectare = 2.5;
      } else if (_selectedCrop?.contains('Sugarcane') ?? false) {
        avgYieldPerHectare = 70.0;
      } else if (_selectedCrop?.contains('Soybean') ?? false) {
        avgYieldPerHectare = 2.0;
      } else {
        avgYieldPerHectare = 2.5; // Default
      }
      
      // Average market price per ton (in ₹)
      double pricePerTon = 25000;
      
      // Calculate sum insured (area × yield × price)
      _sumInsured = area * avgYieldPerHectare * pricePerTon;
      
      // Calculate premium (sum insured × premium rate)
      _calculatedPremium = _sumInsured! * premiumRate;
      
      setState(() {});
      
      _showResultDialog(context.read<LanguageProvider>().currentLanguage);
    }
  }
  
  void _showResultDialog(String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calculate, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            Text(
              AppStrings.get('premium', 'premium_calculated', lang),
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow(AppStrings.get('premium', 'sum_insured', lang) + ':', '₹${_sumInsured!.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildResultRow(
              AppStrings.get('premium', 'premium_amount', lang) + ':',
              '₹${_calculatedPremium!.toStringAsFixed(2)}',
              highlight: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get('premium', 'coverage_details', lang) + ':',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(AppStrings.get('premium', 'season', lang), _selectedSeason ?? '-'),
                  _buildInfoRow(lang == 'hi' ? 'फसल' : 'Crop', _selectedCrop?.split('(')[0].trim() ?? '-'),
                  _buildInfoRow(lang == 'hi' ? 'क्षेत्र' : 'Area', '${_areaController.text} hectares'),
                  _buildInfoRow(lang == 'hi' ? 'राज्य' : 'State', _selectedState ?? '-'),
                  _buildInfoRow(lang == 'hi' ? 'जिला' : 'District', _selectedDistrict ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lang == 'hi' 
                  ? 'नोट: यह एक अनुमानित गणना है। वास्तविक प्रीमियम सरकारी सब्सिडी और स्थानीय कारकों के आधार पर भिन्न हो सकता है।'
                  : 'Note: This is an estimated calculation. Actual premium may vary based on government subsidies and local factors.',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              AppStrings.get('premium', 'close', lang),
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              _resetForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppStrings.get('premium', 'calculate_again', context.read<LanguageProvider>().currentLanguage),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: highlight ? 16 : 14,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
              color: highlight ? Colors.green.shade700 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: highlight ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _selectedSeason = null;
      _selectedState = null;
      _selectedDistrict = null;
      _selectedCrop = null;
      _selectedScheme = null;
      _selectedYear = null;
      _areaController.clear();
      _calculatedPremium = null;
      _sumInsured = null;
      _districts = [];
    });
  }
  
  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('premium', 'premium_calculator', lang),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade700,
                  Colors.white,
                ],
                stops: const [0.0, 0.3],
              ),
            ),
            child: Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        size: 60,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.get('premium', 'insurance_premium_calculator', lang),
                        style: GoogleFonts.notoSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.get('premium', 'calculate_crop_insurance', lang),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Form section
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        
                        // Season dropdown
                        _buildDropdownField(
                          label: '${AppStrings.get('premium', 'season', lang)} (${lang == 'hi' ? 'मौसम' : 'Season'})',
                          icon: Icons.wb_sunny_outlined,
                          value: _selectedSeason,
                          items: _seasons,
                          onChanged: (value) => setState(() => _selectedSeason = value),
                          validator: (value) => value == null ? (lang == 'hi' ? 'कृपया मौसम चुनें' : 'Please select season') : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Year dropdown
                        _buildDropdownField(
                          label: '${AppStrings.get('premium', 'year', lang)} (${lang == 'hi' ? 'वर्ष' : 'Year'})',
                          icon: Icons.calendar_today,
                          value: _selectedYear,
                          items: _years,
                          onChanged: (value) => setState(() => _selectedYear = value),
                          validator: (value) => value == null ? (lang == 'hi' ? 'कृपया वर्ष चुनें' : 'Please select year') : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Scheme dropdown
                        _buildDropdownField(
                          label: '${AppStrings.get('premium', 'insurance_scheme', lang)} (${lang == 'hi' ? 'योजना' : 'Scheme'})',
                          icon: Icons.policy,
                          value: _selectedScheme,
                          items: _schemes,
                          onChanged: (value) => setState(() => _selectedScheme = value),
                          validator: (value) => value == null ? (lang == 'hi' ? 'कृपया योजना चुनें' : 'Please select scheme') : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // State dropdown
                        _buildDropdownField(
                          label: '${AppStrings.get('premium', 'select_state', lang)} (${lang == 'hi' ? 'राज्य' : 'State'})',
                          icon: Icons.location_city,
                          value: _selectedState,
                          items: _states,
                          onChanged: _onStateChanged,
                          validator: (value) => value == null ? (lang == 'hi' ? 'कृपया राज्य चुनें' : 'Please select state') : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // District dropdown
                        _buildDropdownField(
                          label: '${AppStrings.get('premium', 'select_district', lang)} (${lang == 'hi' ? 'जिला' : 'District'})',
                          icon: Icons.place_outlined,
                          value: _selectedDistrict,
                          items: _districts,
                          onChanged: (value) => setState(() => _selectedDistrict = value),
                          validator: (value) => value == null ? (lang == 'hi' ? 'कृपया जिला चुनें' : 'Please select district') : null,
                          enabled: _selectedState != null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Crop dropdown
                        _buildDropdownField(
                          label: '${AppStrings.get('premium', 'crop_type', lang)} (${lang == 'hi' ? 'फसल का प्रकार' : 'Crop Type'})',
                          icon: Icons.eco,
                          value: _selectedCrop,
                          items: _crops,
                          onChanged: (value) => setState(() => _selectedCrop = value),
                          validator: (value) => value == null ? (lang == 'hi' ? 'कृपया फसल चुनें' : 'Please select crop') : null,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Area text field
                        _buildTextField(
                          label: '${AppStrings.get('premium', 'crop_area', lang)} (${lang == 'hi' ? 'फसल क्षेत्र' : 'Crop Area'})',
                          icon: Icons.square_foot,
                          controller: _areaController,
                          hint: AppStrings.get('premium', 'enter_area_hectares', lang),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return lang == 'hi' ? 'कृपया फसल क्षेत्र दर्ज करें' : 'Please enter crop area';
                            }
                            if (double.tryParse(value) == null) {
                              return lang == 'hi' ? 'कृपया मान्य संख्या दर्ज करें' : 'Please enter valid number';
                            }
                            if (double.parse(value) <= 0) {
                              return lang == 'hi' ? 'क्षेत्र 0 से अधिक होना चाहिए' : 'Area must be greater than 0';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Calculate button
                        ElevatedButton(
                          onPressed: _calculatePremium,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.calculate, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                AppStrings.get('premium', 'calculate_premium', lang),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Reset button
                        OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                            side: BorderSide(color: Colors.green.shade700, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppStrings.get('premium', 'reset_form', lang),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Premium Rates',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• Kharif crops: 2% of sum insured\n'
                                      '• Rabi crops: 1.5% of sum insured\n'
                                      '• Horticulture crops: 5% of sum insured',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.blue.shade900,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
  
  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green.shade700),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: items.isEmpty
              ? null
              : items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: GoogleFonts.roboto(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
          onChanged: enabled ? onChanged : null,
          validator: validator,
          isExpanded: true,
          hint: Text(
            enabled ? 'Select $label' : 'Select state first',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green.shade700),
            hintText: hint,
            hintStyle: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
