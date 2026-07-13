import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/crop_loss_report.dart';
import '../../premium_calculator/data/india_data.dart';
import '../../../providers/language_provider.dart';
import '../../../localization/app_localizations.dart';

class FileCropLossScreen extends StatefulWidget {
  const FileCropLossScreen({super.key});

  @override
  State<FileCropLossScreen> createState() => _FileCropLossScreenState();
}

class _FileCropLossScreenState extends State<FileCropLossScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _villageController = TextEditingController();
  final _areaController = TextEditingController();

  String? _selectedSeason;
  String? _selectedCrop;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedLossType;
  String? _selectedLossPercentage;
  DateTime? _incidentDate;
  Position? _currentPosition;
  List<String> _capturedImages = [];

  final List<String> _seasons = ['Kharif 2024', 'Rabi 2024-25', 'Kharif 2025', 'Rabi 2025-26'];
  final List<String> _lossTypes = [
    'Flood',
    'Drought',
    'Hailstorm',
    'Cyclone',
    'Pest Attack',
    'Disease',
    'Fire',
    'Wild Animal Attack',
    'Other Natural Calamity',
  ];
  final List<String> _lossPercentages = [
    '0-10%',
    '10-20%',
    '20-30%',
    '30-40%',
    '40-50%',
    '50-60%',
    '60-70%',
    '70-80%',
    '80-90%',
    '90-100%',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _villageController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              AppStrings.get('cropLoss', 'file_report_title', lang),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red.shade700,
                  Colors.white,
                ],
                stops: const [0.0, 0.15],
              ),
            ),
            child: Column(
              children: [
                // Progress indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.edit_document, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.get('cropLoss', 'fill_all_required', lang),
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Photo Section
                          _buildSectionHeader('1. ${AppStrings.get('cropLoss', 'crop_damage_photos', lang)}', Icons.camera_alt),
                          const SizedBox(height: 12),
                          _buildPhotoUploadSection(lang),
                          const SizedBox(height: 24),

                          // Crop Details
                          _buildSectionHeader('2. ${AppStrings.get('cropLoss', 'crop_details', lang)}', Icons.eco),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            label: '${AppStrings.get('cropLoss', 'season', lang)} *',
                            value: _selectedSeason,
                            items: _seasons,
                            onChanged: (value) => setState(() => _selectedSeason = value),
                            icon: Icons.calendar_month,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: '${AppStrings.get('cropLoss', 'crop_type', lang)} *',
                            value: _selectedCrop,
                            items: IndiaData.getCrops(),
                            onChanged: (value) => setState(() => _selectedCrop = value),
                            icon: Icons.grass,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _areaController,
                            label: '${AppStrings.get('cropLoss', 'affected_area_hectares', lang)} *',
                            icon: Icons.square_foot,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter affected area';
                              }
                              if (double.tryParse(value) == null || double.parse(value) <= 0) {
                                return 'Please enter valid area';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Loss Details
                          _buildSectionHeader('3. ${AppStrings.get('cropLoss', 'loss_details', lang)}', Icons.warning),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            label: '${AppStrings.get('cropLoss', 'loss_type', lang)} *',
                            value: _selectedLossType,
                            items: _lossTypes,
                            onChanged: (value) => setState(() => _selectedLossType = value),
                            icon: Icons.report_problem,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: '${AppStrings.get('cropLoss', 'estimated_loss', lang)} *',
                            value: _selectedLossPercentage,
                            items: _lossPercentages,
                            onChanged: (value) => setState(() => _selectedLossPercentage = value),
                            icon: Icons.percent,
                          ),
                          const SizedBox(height: 16),
                          _buildDateField(lang),
                          const SizedBox(height: 24),

                          // Location Details
                          _buildSectionHeader('4. ${AppStrings.get('cropLoss', 'location_details', lang)}', Icons.location_on),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            label: '${AppStrings.get('cropLoss', 'state', lang)} *',
                            value: _selectedState,
                            items: IndiaData.getStates(),
                            onChanged: (value) {
                              setState(() {
                                _selectedState = value;
                                _selectedDistrict = null;
                              });
                            },
                            icon: Icons.location_city,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            label: '${AppStrings.get('cropLoss', 'district', lang)} *',
                            value: _selectedDistrict,
                            items: _selectedState != null 
                                ? IndiaData.getDistricts(_selectedState!) 
                                : [],
                            onChanged: (value) => setState(() => _selectedDistrict = value),
                            icon: Icons.map,
                            enabled: _selectedState != null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _villageController,
                            label: '${AppStrings.get('cropLoss', 'village', lang)} *',
                            icon: Icons.home,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter village name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildLocationCard(lang),
                          const SizedBox(height: 24),

                          // Description
                          _buildSectionHeader('5. ${AppStrings.get('cropLoss', 'description', lang)}', Icons.description),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: AppStrings.get('cropLoss', 'describe_damage', lang),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.red.shade700, width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please provide description';
                              }
                              if (value.length < 20) {
                                return 'Description must be at least 20 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Submit Button
                          ElevatedButton(
                            onPressed: () => _submitReport(lang),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
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
                                const Icon(Icons.send),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.get('cropLoss', 'submit_report', lang),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Need Help Button
                          OutlinedButton.icon(
                            onPressed: () {
                              // Show help dialog
                              _showHelpDialog(lang);
                            },
                            icon: const Icon(Icons.help_outline),
                            label: Text(AppStrings.get('cropLoss', 'need_help', lang)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoUploadSection(String lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          if (_capturedImages.isEmpty)
            Column(
              children: [
                Icon(Icons.add_a_photo, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  AppStrings.get('cropLoss', 'no_photos_added', lang),
                  style: GoogleFonts.roboto(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.get('cropLoss', 'add_photos_instruction', lang),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          AppStrings.get('cropLoss', 'auto_compress_info', lang),
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_capturedImages.length} ${AppStrings.get('cropLoss', 'images_ready', lang)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Icon(Icons.image, color: Colors.grey.shade600),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await context.push('/multi-image-capture');
              if (result != null && result is List<String>) {
                setState(() {
                  _capturedImages = result;
                });
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: Text(_capturedImages.isEmpty 
                ? AppStrings.get('cropLoss', 'capture_multiple', lang) 
                : AppStrings.get('cropLoss', 'update_photos', lang)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: enabled ? onChanged : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select $label';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateField(String lang) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            _incidentDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${AppStrings.get('cropLoss', 'incident_date', lang)} *',
          prefixIcon: Icon(Icons.calendar_today, color: Colors.red.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Text(
          _incidentDate != null
              ? DateFormat('dd MMM yyyy').format(_incidentDate!)
              : AppStrings.get('cropLoss', 'select_incident_date', lang),
          style: TextStyle(
            color: _incidentDate != null ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationCard(String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get('cropLoss', 'gps_location', lang),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentPosition != null
                      ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                        'Long: ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : AppStrings.get('cropLoss', 'fetching_location', lang),
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            color: Colors.blue.shade700,
          ),
        ],
      ),
    );
  }

  void _submitReport(String lang) {
    if (_formKey.currentState!.validate()) {
      if (_incidentDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select incident date')),
        );
        return;
      }

      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS location not available. Please refresh.')),
        );
        return;
      }

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 60),
              const SizedBox(height: 16),
              Text(
                AppStrings.get('cropLoss', 'report_submitted', lang),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.get('cropLoss', 'report_success_message', lang),
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reference ID: CLR${DateTime.now().millisecondsSinceEpoch}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/crop-loss-intimation');
              },
              child: Text(AppStrings.get('cropLoss', 'view_my_reports', lang)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
              ),
              child: Text(AppStrings.get('common', 'done', lang)),
            ),
          ],
        ),
      );
    }
  }

  void _showHelpDialog(String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Text(AppStrings.get('cropLoss', 'need_help', lang)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get('cropLoss', 'contact_support', lang),
              style: GoogleFonts.roboto(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Call 14447'),
              subtitle: Text(AppStrings.get('cropLoss', 'toll_free_helpline', lang)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('WhatsApp: 7065514447'),
              subtitle: Text(AppStrings.get('cropLoss', 'chat_support', lang)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('common', 'close', lang)),
          ),
        ],
      ),
    );
  }
}
