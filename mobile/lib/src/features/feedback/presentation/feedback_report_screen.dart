import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/language_provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/mongodb/feedback_model.dart';
import '../../../services/mongodb_service.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../services/firestore_service.dart';
import '../../../models/user_profile.dart';

class FeedbackReportScreen extends StatefulWidget {
  const FeedbackReportScreen({super.key});

  @override
  State<FeedbackReportScreen> createState() => _FeedbackReportScreenState();
}

class _FeedbackReportScreenState extends State<FeedbackReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'feedback';
  String _selectedPriority = 'medium';
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  double _rating = 0;
  
  UserProfile? _userProfile;
  final MongoDBService _mongoService = MongoDBService.instance;
  
  final List<Map<String, dynamic>> _categories = [
    {
      'value': 'feedback',
      'label': 'फीडबैक / Feedback',
      'icon': Icons.feedback,
      'color': Colors.blue,
    },
    {
      'value': 'bug_report',
      'label': 'तकनीकी समस्या / Bug Report',
      'icon': Icons.bug_report,
      'color': Colors.red,
    },
    {
      'value': 'feature_request',
      'label': 'नई सुविधा / Feature Request',
      'icon': Icons.lightbulb,
      'color': Colors.orange,
    },
    {
      'value': 'complaint',
      'label': 'शिकायत / Complaint',
      'icon': Icons.report_problem,
      'color': Colors.deepOrange,
    },
  ];

  final List<Map<String, dynamic>> _priorities = [
    {
      'value': 'low',
      'label': 'कम / Low',
      'color': Colors.green,
    },
    {
      'value': 'medium',
      'label': 'मध्यम / Medium',
      'color': Colors.orange,
    },
    {
      'value': 'high',
      'label': 'उच्च / High',
      'color': Colors.deepOrange,
    },
    {
      'value': 'urgent',
      'label': 'तत्काल / Urgent',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final authService = context.read<FirebaseAuthService>();
    final firestoreService = FirestoreService();
    
    if (authService.currentUser != null) {
      final profile = await firestoreService.getUserProfile(
        authService.currentUser!.uid,
      );
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_userProfile == null) {
      _showErrorSnackBar('कृपया पहले अपनी प्रोफ़ाइल पूरी करें / Please complete your profile first');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final feedback = FeedbackReport(
        farmerId: _userProfile!.uid,
        farmerName: _isAnonymous ? 'Anonymous' : _userProfile!.name,
        farmerPhone: _isAnonymous ? '' : _userProfile!.phoneNumber,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        createdAt: DateTime.now(),
        village: _userProfile!.village ?? '',
        district: _userProfile!.district ?? '',
        state: _userProfile!.state ?? '',
        rating: _selectedCategory == 'feedback' ? _rating : null,
        isAnonymous: _isAnonymous,
        metadata: {
          'appVersion': '1.0.0',
          'deviceInfo': 'Android',
          'submittedVia': 'mobile_app',
        },
      );

      final result = await _mongoService.insertFeedback(feedback);
      
      if (result != null) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar('सबमिशन में त्रुटि / Submission failed');
      }
    } catch (e) {
      _showErrorSnackBar('नेटवर्क त्रुटि / Network error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    final lang = context.read<LanguageProvider>().currentLanguage;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('सफलतापूर्वक भेजा गया!', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang == 'hi'
                  ? 'आपका फीडबैक/रिपोर्ट सफलतापूर्वक भेजा गया है। हमारी टीम जल्द ही आपसे संपर्क करेगी।'
                  : 'Your feedback/report has been submitted successfully. Our team will contact you soon.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang == 'hi'
                          ? 'आप अपनी रिपोर्ट की स्थिति "मेरी रिपोर्ट्स" में देख सकते हैं।'
                          : 'You can track your report status in "My Reports".',
                      style: const TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to dashboard
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(lang == 'hi' ? 'ठीक है' : 'OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          lang == 'hi' ? 'फीडबैक और रिपोर्ट' : 'Feedback & Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.feedback, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    lang == 'hi'
                        ? 'हमें बताएं कि हम कैसे बेहतर हो सकते हैं'
                        : 'Tell us how we can improve',
                    style: GoogleFonts.notoSansDevanagari(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == 'hi'
                        ? 'आपका फीडबैक हमारे लिए महत्वपूर्ण है'
                        : 'Your feedback is important to us',
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Category Selection
            Text(
              lang == 'hi' ? 'श्रेणी चुनें / Select Category' : 'Select Category',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
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
                childAspectRatio: 2.5,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['value'];
                
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = category['value']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? category['color'].withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? category['color'] : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected ? category['color'] : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            category['label'],
                            style: GoogleFonts.notoSansDevanagari(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? category['color'] : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Title Field
            Text(
              lang == 'hi' ? 'शीर्षक / Title' : 'Title',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: lang == 'hi' 
                    ? 'संक्षेप में अपनी समस्या/सुझाव का शीर्षक लिखें'
                    : 'Brief title of your issue/suggestion',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang == 'hi' ? 'कृपया शीर्षक लिखें' : 'Please enter title';
                }
                if (value.trim().length < 5) {
                  return lang == 'hi' ? 'शीर्षक कम से कम 5 अक्षर का होना चाहिए' : 'Title must be at least 5 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Description Field
            Text(
              lang == 'hi' ? 'विवरण / Description' : 'Description',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: lang == 'hi' 
                    ? 'विस्तार से बताएं कि आप क्या सुझाना/रिपोर्ट करना चाहते हैं...'
                    : 'Describe in detail what you want to suggest/report...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return lang == 'hi' ? 'कृपया विवरण लिखें' : 'Please enter description';
                }
                if (value.trim().length < 10) {
                  return lang == 'hi' ? 'विवरण कम से कम 10 अक्षर का होना चाहिए' : 'Description must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Priority Selection
            Text(
              lang == 'hi' ? 'प्राथमिकता / Priority' : 'Priority',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: _priorities.map((priority) {
                final isSelected = _selectedPriority == priority['value'];
                
                return FilterChip(
                  label: Text(priority['label']),
                  selected: isSelected,
                  selectedColor: priority['color'].withOpacity(0.2),
                  checkmarkColor: priority['color'],
                  labelStyle: GoogleFonts.notoSansDevanagari(
                    color: isSelected ? priority['color'] : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedPriority = priority['value']);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Rating (only for feedback)
            if (_selectedCategory == 'feedback') ...[
              Text(
                lang == 'hi' ? 'रेटिंग / Rating' : 'Rating',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Text(
                      lang == 'hi' 
                          ? 'PMFBY ऐप का अपना अनुभव बताएं'
                          : 'Rate your experience with PMFBY app',
                      style: GoogleFonts.notoSansDevanagari(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () => setState(() => _rating = index + 1.0),
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    Text(
                      _rating == 0 
                          ? (lang == 'hi' ? 'कृपया रेटिंग दें' : 'Please give rating')
                          : '${_rating.toInt()}/5',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Anonymous Option
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CheckboxListTile(
                title: Text(
                  lang == 'hi' ? 'गुमनाम रूप से भेजें' : 'Submit Anonymously',
                  style: GoogleFonts.notoSansDevanagari(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  lang == 'hi' 
                      ? 'आपका नाम और फ़ोन नंबर छुपाया जाएगा'
                      : 'Your name and phone number will be hidden',
                  style: GoogleFonts.roboto(fontSize: 12, color: Colors.grey.shade600),
                ),
                value: _isAnonymous,
                onChanged: (value) => setState(() => _isAnonymous = value ?? false),
                activeColor: Colors.blue,
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        lang == 'hi' ? 'सबमिट करें' : 'Submit',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Help Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang == 'hi' 
                          ? 'आपकी रिपोर्ट हमारी टीम द्वारा 24-48 घंटों में देखी जाएगी। महत्वपूर्ण मुद्दों के लिए कृपया तत्काल प्राथमिकता चुनें।'
                          : 'Your report will be reviewed by our team within 24-48 hours. For critical issues, please select urgent priority.',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}