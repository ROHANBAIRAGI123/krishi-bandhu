import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/language_provider.dart';
import '../../../models/mongodb/feedback_model.dart';
import '../../../services/mongodb_service.dart';
import '../../../services/firebase_auth_service.dart';
import 'package:intl/intl.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final MongoDBService _mongoService = MongoDBService.instance;
  List<FeedbackReport> _reports = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, open, resolved
  
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = context.read<FirebaseAuthService>();
      if (authService.currentUser != null) {
        final reports = await _mongoService.getFarmerFeedback(
          authService.currentUser!.uid,
        );
        
        if (mounted) {
          setState(() {
            _reports = reports;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<FeedbackReport> get _filteredReports {
    switch (_selectedFilter) {
      case 'open':
        return _reports.where((r) => r.status == 'open' || r.status == 'in_progress').toList();
      case 'resolved':
        return _reports.where((r) => r.status == 'resolved' || r.status == 'closed').toList();
      default:
        return _reports;
    }
  }

  Future<void> _refreshReports() async {
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    final filteredReports = _filteredReports;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          lang == 'hi' ? 'मेरी रिपोर्ट्स' : 'My Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          IconButton(
            onPressed: _refreshReports,
            icon: const Icon(Icons.refresh),
            tooltip: lang == 'hi' ? 'रिफ्रेश करें' : 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterTab(
                    'all',
                    lang == 'hi' ? 'सभी' : 'All',
                    _reports.length,
                  ),
                ),
                Expanded(
                  child: _buildFilterTab(
                    'open',
                    lang == 'hi' ? 'खुली' : 'Open',
                    _reports.where((r) => r.status == 'open' || r.status == 'in_progress').length,
                  ),
                ),
                Expanded(
                  child: _buildFilterTab(
                    'resolved',
                    lang == 'hi' ? 'हल की गई' : 'Resolved',
                    _reports.where((r) => r.status == 'resolved' || r.status == 'closed').length,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filteredReports.isEmpty
                    ? _buildEmptyState(lang)
                    : RefreshIndicator(
                        onRefresh: _refreshReports,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReports.length,
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return _buildReportCard(report, lang);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/feedback-report'),
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: lang == 'hi' ? 'नई रिपोर्ट' : 'New Report',
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' 
                ? (lang == 'hi' ? 'कोई रिपोर्ट नहीं मिली' : 'No reports found')
                : (lang == 'hi' ? 'इस श्रेणी में कोई रिपोर्ट नहीं' : 'No reports in this category'),
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lang == 'hi' 
                ? 'अपनी पहली रिपोर्ट भेजने के लिए + बटन दबाएं'
                : 'Tap + button to submit your first report',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(FeedbackReport report, String lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showReportDetails(report, lang),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      report.categoryIcon,
                      size: 18,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.categoryDisplayName,
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: report.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      report.statusDisplayName,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: report.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title
              Text(
                report.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Description preview
              Text(
                report.description,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Footer with date and priority
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(report.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: report.priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.priorityDisplayName,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: report.priorityColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (report.rating != null) ...[
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        Text(
                          ' ${report.rating!.toInt()}/5',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(FeedbackReport report, String lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Icon(report.categoryIcon, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lang == 'hi' ? 'रिपोर्ट विवरण' : 'Report Details',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: report.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: report.statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      report.statusDisplayName,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: report.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Details
              _buildDetailRow(Icons.category, lang == 'hi' ? 'श्रेणी' : 'Category', report.categoryDisplayName),
              _buildDetailRow(Icons.title, lang == 'hi' ? 'शीर्षक' : 'Title', report.title),
              _buildDetailRow(Icons.description, lang == 'hi' ? 'विवरण' : 'Description', report.description),
              _buildDetailRow(Icons.priority_high, lang == 'hi' ? 'प्राथमिकता' : 'Priority', report.priorityDisplayName),
              _buildDetailRow(Icons.schedule, lang == 'hi' ? 'सबमिट किया गया' : 'Submitted', DateFormat('dd MMM yyyy, hh:mm a').format(report.createdAt)),
              
              if (report.rating != null)
                _buildDetailRow(Icons.star, lang == 'hi' ? 'रेटिंग' : 'Rating', '${report.rating!.toInt()}/5 ⭐'),
              
              if (report.adminResponse != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.green.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            lang == 'hi' ? 'एडमिन का जवाब' : 'Admin Response',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.adminResponse!,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.green.shade800,
                          height: 1.4,
                        ),
                      ),
                      if (report.resolvedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${lang == 'hi' ? 'हल किया गया' : 'Resolved on'}: ${DateFormat('dd MMM yyyy').format(report.resolvedAt!)}',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    lang == 'hi' ? 'बंद करें' : 'Close',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}