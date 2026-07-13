import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/language_provider.dart';
import '../../../models/mongodb/feedback_model.dart';
import '../../../services/mongodb_service.dart';
import 'package:intl/intl.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> with TickerProviderStateMixin {
  final MongoDBService _mongoService = MongoDBService.instance;
  List<FeedbackReport> _reports = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _isLoadingStats = true;
  
  String _selectedFilter = 'all'; // all, open, in_progress, resolved
  String _selectedCategory = 'all'; // all, feedback, bug_report, feature_request, complaint
  String _selectedPriority = 'all'; // all, urgent, high, medium, low
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isLoadingStats = true;
    });
    
    try {
      final futures = await Future.wait([
        _loadReports(),
        _loadStatistics(),
      ]);
    } catch (e) {
      print('Error loading admin feedback data: $e');
    }
  }

  Future<void> _loadReports() async {
    try {
      String? statusFilter = _selectedFilter == 'all' ? null : _selectedFilter;
      String? categoryFilter = _selectedCategory == 'all' ? null : _selectedCategory;
      String? priorityFilter = _selectedPriority == 'all' ? null : _selectedPriority;
      
      final reports = await _mongoService.getAllFeedbackReports(
        status: statusFilter,
        category: categoryFilter,
        priority: priorityFilter,
        limit: 100,
      );
      
      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading reports: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _mongoService.getFeedbackStatistics();
      
      if (mounted) {
        setState(() {
          _statistics = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          lang == 'hi' ? 'फीडबैक प्रबंधन' : 'Feedback Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.dashboard),
              text: lang == 'hi' ? 'डैशबोर्ड' : 'Dashboard',
            ),
            Tab(
              icon: const Icon(Icons.list_alt),
              text: lang == 'hi' ? 'सभी रिपोर्ट्स' : 'All Reports',
            ),
            Tab(
              icon: const Icon(Icons.priority_high),
              text: lang == 'hi' ? 'प्राथमिकता' : 'Priority',
            ),
            Tab(
              icon: const Icon(Icons.analytics),
              text: lang == 'hi' ? 'आंकड़े' : 'Analytics',
            ),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: lang == 'hi' ? 'रिफ्रेश करें' : 'Refresh',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(lang),
          _buildAllReportsTab(lang),
          _buildPriorityTab(lang),
          _buildAnalyticsTab(lang),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(String lang) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Statistics Cards
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard(
                  '${_statistics['total'] ?? 0}',
                  lang == 'hi' ? 'कुल रिपोर्ट्स' : 'Total Reports',
                  Icons.assignment,
                  Colors.blue,
                ),
                _buildStatCard(
                  '${(_statistics['byStatus']?['open'] ?? 0) + (_statistics['byStatus']?['in_progress'] ?? 0)}',
                  lang == 'hi' ? 'सक्रिय रिपोर्ट्स' : 'Active Reports',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                _buildStatCard(
                  '${_statistics['byStatus']?['resolved'] ?? 0}',
                  lang == 'hi' ? 'हल की गई' : 'Resolved',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatCard(
                  '${_statistics['recentCount'] ?? 0}',
                  lang == 'hi' ? 'इस हफ्ते' : 'This Week',
                  Icons.schedule,
                  Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Average Rating Card
            if (_statistics['averageRating'] != null && _statistics['averageRating'] > 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_statistics['averageRating'].toStringAsFixed(1)}/5.0',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            lang == 'hi' ? 'औसत रेटिंग' : 'Average Rating',
                            style: GoogleFonts.roboto(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
            const SizedBox(height: 24),
            
            // Recent Reports Section
            Row(
              children: [
                Text(
                  lang == 'hi' ? 'हाल की रिपोर्ट्स' : 'Recent Reports',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(
                    lang == 'hi' ? 'सभी देखें' : 'View All',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
          ],
          
          // Recent Reports List
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reports.isEmpty)
            _buildEmptyState(lang)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reports.take(5).length,
              itemBuilder: (context, index) {
                final report = _reports[index];
                return _buildReportCard(report, lang, isCompact: true);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAllReportsTab(String lang) {
    return Column(
      children: [
        // Filters
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Filter
              Row(
                children: [
                  Text(
                    lang == 'hi' ? 'स्थिति:' : 'Status:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', lang == 'hi' ? 'सभी' : 'All', _selectedFilter == 'all', (selected) {
                            setState(() => _selectedFilter = 'all');
                            _loadReports();
                          }),
                          _buildFilterChip('open', lang == 'hi' ? 'खुला' : 'Open', _selectedFilter == 'open', (selected) {
                            setState(() => _selectedFilter = 'open');
                            _loadReports();
                          }),
                          _buildFilterChip('in_progress', lang == 'hi' ? 'प्रगति में' : 'In Progress', _selectedFilter == 'in_progress', (selected) {
                            setState(() => _selectedFilter = 'in_progress');
                            _loadReports();
                          }),
                          _buildFilterChip('resolved', lang == 'hi' ? 'हल हो गया' : 'Resolved', _selectedFilter == 'resolved', (selected) {
                            setState(() => _selectedFilter = 'resolved');
                            _loadReports();
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Category Filter
              Row(
                children: [
                  Text(
                    lang == 'hi' ? 'श्रेणी:' : 'Category:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', lang == 'hi' ? 'सभी' : 'All', _selectedCategory == 'all', (selected) {
                            setState(() => _selectedCategory = 'all');
                            _loadReports();
                          }),
                          _buildFilterChip('feedback', lang == 'hi' ? 'फीडबैक' : 'Feedback', _selectedCategory == 'feedback', (selected) {
                            setState(() => _selectedCategory = 'feedback');
                            _loadReports();
                          }),
                          _buildFilterChip('bug_report', lang == 'hi' ? 'बग रिपोर्ट' : 'Bug Report', _selectedCategory == 'bug_report', (selected) {
                            setState(() => _selectedCategory = 'bug_report');
                            _loadReports();
                          }),
                          _buildFilterChip('complaint', lang == 'hi' ? 'शिकायत' : 'Complaint', _selectedCategory == 'complaint', (selected) {
                            setState(() => _selectedCategory = 'complaint');
                            _loadReports();
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Reports List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _reports.isEmpty
                  ? _buildEmptyState(lang)
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final report = _reports[index];
                          return _buildReportCard(report, lang);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPriorityTab(String lang) {
    final urgentReports = _reports.where((r) => r.priority == 'urgent' && r.status != 'resolved' && r.status != 'closed').toList();
    final highReports = _reports.where((r) => r.priority == 'high' && r.status != 'resolved' && r.status != 'closed').toList();
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Urgent Reports
          if (urgentReports.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${lang == 'hi' ? 'तत्काल प्राथमिकता' : 'URGENT PRIORITY'} (${urgentReports.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...urgentReports.map((report) => _buildReportCard(report, lang)).toList(),
            const SizedBox(height: 24),
          ],
          
          // High Priority Reports
          if (highReports.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.priority_high, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${lang == 'hi' ? 'उच्च प्राथमिकता' : 'HIGH PRIORITY'} (${highReports.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...highReports.map((report) => _buildReportCard(report, lang)).toList(),
          ],
          
          if (urgentReports.isEmpty && highReports.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  Text(
                    lang == 'hi' ? 'कोई प्राथमिकता रिपोर्ट नहीं!' : 'No priority reports!',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade600,
                    ),
                  ),
                  Text(
                    lang == 'hi' ? 'सभी महत्वपूर्ण मुद्दों पर ध्यान दिया गया है।' : 'All critical issues have been addressed.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(String lang) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add Dummy Data Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              onPressed: _createDummyData,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text(
                lang == 'hi' ? 'नमूना डेटा बनाएं' : 'Create Dummy Data',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Category Distribution with Pie Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'hi' ? 'श्रेणी के अनुसार वितरण' : 'Distribution by Category',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildAnalyticsBar('फीडबैक / Feedback', _statistics['byCategory']?['feedback'] ?? 0, Colors.blue),
                            _buildAnalyticsBar('बग रिपोर्ट / Bug Report', _statistics['byCategory']?['bug_report'] ?? 0, Colors.red),
                            _buildAnalyticsBar('शिकायत / Complaint', _statistics['byCategory']?['complaint'] ?? 0, Colors.orange),
                            _buildAnalyticsBar('नई सुविधा / Feature Request', _statistics['byCategory']?['feature_request'] ?? 0, Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 150,
                          child: _buildCategoryPieChart(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Priority Distribution with Pie Chart
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'hi' ? 'प्राथमिकता के अनुसार वितरण' : 'Distribution by Priority',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildAnalyticsBar('तत्काल / Urgent', _statistics['byPriority']?['urgent'] ?? 0, Colors.red),
                            _buildAnalyticsBar('उच्च / High', _statistics['byPriority']?['high'] ?? 0, Colors.deepOrange),
                            _buildAnalyticsBar('मध्यम / Medium', _statistics['byPriority']?['medium'] ?? 0, Colors.orange),
                            _buildAnalyticsBar('कम / Low', _statistics['byPriority']?['low'] ?? 0, Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 150,
                          child: _buildPriorityPieChart(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isSelected, Function(bool) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: onSelected,
        selectedColor: Colors.blue.withOpacity(0.2),
        checkmarkColor: Colors.blue,
        labelStyle: GoogleFonts.roboto(
          color: isSelected ? Colors.blue : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAnalyticsBar(String label, int value, Color color) {
    final maxValue = _statistics['total'] ?? 1;
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
              ),
              Text(
                '$value',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            lang == 'hi' ? 'कोई रिपोर्ट नहीं मिली' : 'No reports found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            lang == 'hi' ? 'फिल्टर बदलने की कोशिश करें' : 'Try changing the filters',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(FeedbackReport report, String lang, {bool isCompact = false}) {
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: report.priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      report.categoryIcon,
                      size: 18,
                      color: report.priorityColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.farmerName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${report.village}, ${report.district}',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
              
              // Content
              Text(
                report.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: isCompact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (!isCompact) ...[
                const SizedBox(height: 4),
                Text(
                  report.description,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(report.createdAt),
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                  const Spacer(),
                  if (report.status == 'open' || report.status == 'in_progress')
                    IconButton(
                      onPressed: () => _showResponseDialog(report, lang),
                      icon: const Icon(Icons.reply, size: 20),
                      tooltip: lang == 'hi' ? 'जवाब दें' : 'Respond',
                      color: Colors.blue,
                    ),
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
                      report.title,
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
              
              const SizedBox(height: 20),
              
              // Farmer Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.farmerName,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${report.farmerPhone} • ${report.village}, ${report.district}',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              Text(
                lang == 'hi' ? 'विवरण' : 'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Response Section
              if (report.adminResponse != null) ...[
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
                      Text(
                        lang == 'hi' ? 'एडमिन का जवाब' : 'Admin Response',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Action Buttons
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (report.status == 'open' || report.status == 'in_progress')
                      SizedBox(
                        width: 140,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _showResponseDialog(report, lang);
                          },
                          icon: const Icon(Icons.reply, size: 16),
                          label: Text(
                            lang == 'hi' ? 'जवाब दें' : 'Respond',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    if (report.status == 'open' || report.status == 'in_progress') const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        child: Text(
                          lang == 'hi' ? 'बंद करें' : 'Close',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResponseDialog(FeedbackReport report, String lang) {
    final responseController = TextEditingController();
    String selectedStatus = report.status == 'open' ? 'in_progress' : report.status;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          lang == 'hi' ? 'जवाब भेजें' : 'Send Response',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Selection
              Text(
                lang == 'hi' ? 'स्थिति अपडेट करें' : 'Update Status',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'in_progress',
                    child: Text(lang == 'hi' ? 'प्रगति में' : 'In Progress'),
                  ),
                  DropdownMenuItem(
                    value: 'resolved',
                    child: Text(lang == 'hi' ? 'हल हो गया' : 'Resolved'),
                  ),
                  DropdownMenuItem(
                    value: 'closed',
                    child: Text(lang == 'hi' ? 'बंद' : 'Closed'),
                  ),
                ],
                onChanged: (value) => setState(() => selectedStatus = value!),
              ),
              
              const SizedBox(height: 16),
              
              // Response Text
              Text(
                lang == 'hi' ? 'आपका जवाब' : 'Your Response',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: responseController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: lang == 'hi' 
                      ? 'किसान को जवाब लिखें...'
                      : 'Write response to farmer...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang == 'hi' ? 'रद्द करें' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isNotEmpty) {
                try {
                  await _mongoService.updateFeedbackStatus(
                    report.id!,
                    selectedStatus,
                    adminResponse: responseController.text.trim(),
                    adminId: 'admin_user', // Replace with actual admin ID
                  );
                  
                  Navigator.pop(context);
                  _loadReports(); // Refresh the list
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'hi' 
                            ? 'जवाब सफलतापूर्वक भेजा गया'
                            : 'Response sent successfully',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'hi' ? 'त्रुटि: $e' : 'Error: $e',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(lang == 'hi' ? 'भेजें' : 'Send'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChart() {
    final categoryData = _statistics['byCategory'] ?? {};
    final List<PieChartSectionData> sections = [];
    
    final colors = [Colors.blue, Colors.red, Colors.orange, Colors.green];
    final categories = ['feedback', 'bug_report', 'complaint', 'feature_request'];
    
    for (int i = 0; i < categories.length; i++) {
      final value = (categoryData[categories[i]] ?? 0).toDouble();
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[i],
            value: value,
            title: '${value.toInt()}',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    
    if (sections.isEmpty) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 25,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildPriorityPieChart() {
    final priorityData = _statistics['byPriority'] ?? {};
    final List<PieChartSectionData> sections = [];
    
    final colors = [Colors.red, Colors.deepOrange, Colors.orange, Colors.green];
    final priorities = ['urgent', 'high', 'medium', 'low'];
    
    for (int i = 0; i < priorities.length; i++) {
      final value = (priorityData[priorities[i]] ?? 0).toDouble();
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            color: colors[i],
            value: value,
            title: '${value.toInt()}',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    
    if (sections.isEmpty) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 25,
        sectionsSpace: 2,
      ),
    );
  }

  Future<void> _createDummyData() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating dummy data...'),
            ],
          ),
        ),
      );
      
      await _mongoService.createDummyFeedbackReports();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Dummy data created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload data
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error creating dummy data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}