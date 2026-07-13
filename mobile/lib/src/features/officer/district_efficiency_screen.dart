import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../localization/app_localizations.dart';

class DistrictEfficiencyScreen extends StatefulWidget {
  const DistrictEfficiencyScreen({super.key});

  @override
  State<DistrictEfficiencyScreen> createState() => _DistrictEfficiencyScreenState();
}

class _DistrictEfficiencyScreenState extends State<DistrictEfficiencyScreen> {
  // Demo statistics
  final double efficiencyScore = 78.0;
  final String rankCategory = 'Top 5% Rank';
  final String state = 'Madhya Pradesh';
  final double avgClaimResolutionDays = 3.2;
  final double industryAvgDays = 4.5;
  final int claimsClearedThisWeek = 31;
  final int claimsNeededToImprove = 50;
  final int weeklyStreak = 9;
  final int goalClearClaims = 19; // more claims to clear
  final int goalTotalClaims = 50; // out of 50
  final int goalCurrentClaims = 31; // currently at 31
  final int goalStreakDays = 5; // more days
  final int goalStreakCurrent = 9; // currently at 9
  final int goalStreakTarget = 14; // target 14
  
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().currentLanguage;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B6EAE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lang == 'hi' ? 'जिला दक्षता स्कोर' : 'District Efficiency Score',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Score Card
            _buildTopScoreCard(),
            
            const SizedBox(height: 8),
            
            // Tip Card
            _buildTipCard(lang),
            
            const SizedBox(height: 16),
            
            // Performance Metrics
            _buildPerformanceMetrics(lang),
            
            const SizedBox(height: 16),
            
            // Statistics Cards Row
            _buildStatisticsRow(lang),
            
            const SizedBox(height: 16),
            
            // Improvement Goals
            _buildImprovementGoals(lang),
            
            const SizedBox(height: 16),
            
            // Traffic Light Performance Dashboard
            _buildTrafficLightDashboard(lang),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(lang),
    );
  }

  Widget _buildTopScoreCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'District Efficiency Score: ${efficiencyScore.toInt()}/100',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade200,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: efficiencyScore / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.shade400,
                                      Colors.green.shade600,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, color: Colors.blue.shade700, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                rankCategory,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
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
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Top 5% in $state',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade900,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.amber.shade700),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lang == 'hi' 
                  ? 'टिप: उच्च स्कोर जिलों के बीच आपकी रैंक को बढ़ाता है।'
                  : 'Tip: Higher score boosts your rank among districts.',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue.shade700),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Good - Avg Claim Resolution Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Good ',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                      Text(
                        '(80-100)',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$avgClaimResolutionDays days',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          // Average - Claims Cleared
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up, color: Colors.orange.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Average ',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        Text(
                          '(60-79)',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$claimsClearedThisWeek',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey.shade200,
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: claimsClearedThisWeek / claimsNeededToImprove,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.orange.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$claimsNeededToImprove / $claimsNeededToImprove Needed to Improve',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 14, color: Colors.orange.shade700),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              lang == 'hi' ? 'औसत दावा समाधान समय' : 'Avg. Claim Resolution Time',
              '$avgClaimResolutionDays days',
              lang == 'hi' ? 'उद्योग औसत: $industryAvgDays दिन' : 'Industry Avg. $industryAvgDays days',
              Icons.bolt,
              Colors.green.shade700,
              const Color(0xFFE8F5E9),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              lang == 'hi' ? 'इस सप्ताह दावे समाशोधित' : 'Claims Cleared This Week',
              '$claimsClearedThisWeek',
              '$claimsNeededToImprove / $claimsNeededToImprove ${lang == 'hi' ? 'सुधार की आवश्यकता' : 'Needed to Improve'}',
              Icons.assignment_turned_in,
              Colors.orange.shade700,
              Colors.orange.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              lang == 'hi' ? 'साप्ताहिक स्ट्रीक' : 'Weekly Streak',
              '$weeklyStreak days',
              lang == 'hi' ? 'बैकलॉग से बचने के लिए स्ट्रीक बनाए रखें!' : 'Maintain streak to avoid backlog!',
              Icons.local_fire_department,
              Colors.red.shade700,
              Colors.red.shade50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementGoals(String lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'hi' ? 'सुधार लक्ष्य' : 'Improvement Goals',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3F51B5),
            ),
          ),
          const SizedBox(height: 20),
          
          // Goal 1: Clear more claims
          _buildGoalItem(
            icon: Icons.check_circle_outline,
            iconColor: Colors.blue,
            title: lang == 'hi' ? '$goalClearClaims और दावे साफ करें' : 'Clear $goalClearClaims more claims',
            score: '+6 Score',
            scoreColor: Colors.green.shade700,
            progress: goalCurrentClaims / goalTotalClaims,
            progressText: '$goalCurrentClaims / $goalTotalClaims',
            progressColor: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          // Goal 2: Maintain streak
          _buildGoalItem(
            icon: Icons.local_fire_department,
            iconColor: Colors.orange,
            title: lang == 'hi' ? '$goalStreakDays और दिनों के लिए स्ट्रीक बनाए रखें' : 'Maintain streak for $goalStreakDays more days',
            score: '+4 Score',
            scoreColor: Colors.orange.shade700,
            progress: goalStreakCurrent / goalStreakTarget,
            progressText: '$goalStreakCurrent / $goalStreakTarget',
            progressColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String score,
    required Color scoreColor,
    required double progress,
    required String progressText,
    required Color progressColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    score,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.grey.shade200,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: progressColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    progressText,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrafficLightDashboard(String lang) {
    // Sample data for 6 months and 4 tasks
    final List<List<int>> taskStatus = [
      [0, 1, 0, 2, 0, 1], // Task 1: 0=red, 1=yellow, 2=green
      [2, 0, 2, 1, 2, 1], // Task 2
      [2, 2, 1, 0, 0, 0], // Task 3
      [0, 2, 0, 2, 0, 2], // Task 4
    ];
    
    final List<String> tasks = [
      lang == 'hi' ? 'दावा सत्यापन' : 'Claim Verification',
      lang == 'hi' ? 'किसान पंजीकरण' : 'Farmer Registration',
      lang == 'hi' ? 'क्षेत्र निरीक्षण' : 'Field Inspection',
      lang == 'hi' ? 'रिपोर्ट सबमिशन' : 'Report Submission',
    ];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF455A64),
            const Color(0xFF37474F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with traffic light icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTrafficLightIcon(Colors.red.shade700, 8),
                    const SizedBox(height: 2),
                    _buildTrafficLightIcon(Colors.yellow.shade700, 8),
                    const SizedBox(height: 2),
                    _buildTrafficLightIcon(Colors.green.shade600, 8),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lang == 'hi' ? 'जिला प्रदर्शन डैशबोर्ड' : 'District Performance Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Scrollable table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month headers
                Row(
                  children: [
                    // Empty space for task names
                    Container(
                      width: 100,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A5F),
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    // Month columns
                    for (int i = 1; i <= 6; i++)
                      Container(
                        width: 90,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            lang == 'hi' ? 'महीना $i' : 'MONTH $i',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Task rows
                for (int taskIndex = 0; taskIndex < 4; taskIndex++)
                  Row(
                    children: [
                      // Task name
                      Container(
                        width: 100,
                        height: 65,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A5F),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            tasks[taskIndex],
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // Traffic lights for each month
                      for (int month = 0; month < 6; month++)
                        Container(
                          width: 90,
                          height: 65,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Center(
                            child: _buildTrafficLightIndicator(taskStatus[taskIndex][month]),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(
                  Colors.red.shade700,
                  lang == 'hi' ? 'कार्य पूर्ण नहीं' : 'Task not done',
                ),
                _buildLegendItem(
                  Colors.yellow.shade700,
                  lang == 'hi' ? 'प्रगति में' : 'In progress',
                ),
                _buildLegendItem(
                  Colors.green.shade600,
                  lang == 'hi' ? 'कार्य पूर्ण' : 'Task Done',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLightIcon(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficLightIndicator(int status) {
    Color color;
    switch (status) {
      case 0:
        color = Colors.red.shade700;
        break;
      case 1:
        color = Colors.yellow.shade700;
        break;
      case 2:
        color = Colors.green.shade600;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      width: 60,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status == 0)
            _buildTrafficLightIcon(Colors.red.shade700, 16),
          if (status == 1) ...[
            _buildTrafficLightIcon(Colors.yellow.shade700, 16),
          ],
          if (status == 2) ...[
            _buildTrafficLightIcon(Colors.green.shade600, 16),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTrafficLightIcon(color, 12),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(String lang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF5B6EAE),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.roboto(fontSize: 11),
        onTap: (index) => setState(() => _selectedTabIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: lang == 'hi' ? 'अवलोकन' : 'Overview',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: lang == 'hi' ? 'दावे' : 'Claims',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: lang == 'hi' ? 'विश्लेषण' : 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assessment),
            label: lang == 'hi' ? 'रिपोर्ट' : 'Reports',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events),
            label: lang == 'hi' ? 'प्रभाव' : 'Impact',
          ),
        ],
      ),
    );
  }
}
