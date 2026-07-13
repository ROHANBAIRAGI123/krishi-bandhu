import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/complaint_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class CurrentComplaintsScreen extends StatefulWidget {
  const CurrentComplaintsScreen({super.key});

  @override
  State<CurrentComplaintsScreen> createState() => _CurrentComplaintsScreenState();
}

class _CurrentComplaintsScreenState extends State<CurrentComplaintsScreen> {
  late List<Complaint> currentComplaints;
  String _filterStatus = 'all'; // 'all', 'pending', 'approved'

  @override
  void initState() {
    super.initState();
    _loadCurrentComplaints();
  }

  void _loadCurrentComplaints() {
    // Sample data - In real app, fetch from API/database
    currentComplaints = [
      Complaint(
        complaintId: 'CMP-2025-001',
        cropType: 'Wheat',
        damagePercentage: 45.0,
        status: 'pending',
        submissionDate: DateTime.now().subtract(const Duration(days: 5)),
        description: 'Crop damaged due to heavy rainfall and hail',
        insuredAmount: '₹50,000',
        claimAmount: '₹22,500',
        village: 'Nandgaon',
        district: 'Nashik',
        acreage: 2.5,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Under verification. Field inspection scheduled.',
      ),
      Complaint(
        complaintId: 'CMP-2025-002',
        cropType: 'Maize',
        damagePercentage: 60.0,
        status: 'approved',
        submissionDate: DateTime.now().subtract(const Duration(days: 12)),
        description: 'Pest infestation causing crop damage',
        insuredAmount: '₹45,000',
        claimAmount: '₹27,000',
        village: 'Sangamner',
        district: 'Ahmednagar',
        acreage: 3.0,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Claim approved. Processing for disbursement.',
      ),
      Complaint(
        complaintId: 'CMP-2025-003',
        cropType: 'Cotton',
        damagePercentage: 30.0,
        status: 'pending',
        submissionDate: DateTime.now().subtract(const Duration(days: 2)),
        description: 'Disease outbreak in cotton field',
        insuredAmount: '₹60,000',
        claimAmount: '₹18,000',
        village: 'Aurangabad',
        district: 'Aurangabad',
        acreage: 4.0,
        imageUrl: 'assets/images/placeholder.png',
      ),
    ];
  }

  List<Complaint> get _filteredComplaints {
    if (_filterStatus == 'all') {
      return currentComplaints;
    }
    return currentComplaints.where((c) => c.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          body: Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(AppStrings.get('complaints', 'all', lang), 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.get('complaints', 'under_review', lang), 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip(AppStrings.get('complaints', 'approved', lang), 'approved'),
                    ],
                  ),
                ),
              ),
              // Complaints list
              Expanded(
                child: _filteredComplaints.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.get('complaints', 'no_complaints_found', lang),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _filteredComplaints.length,
                        itemBuilder: (context, index) {
                          return _buildComplaintCard(_filteredComplaints[index], lang);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'all';
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint, String lang) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          context.push('/complaints/detail', extra: complaint);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with complaint ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          complaint.complaintId,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          complaint.cropType,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(complaint.status),
                      ),
                    ),
                    child: Text(
                      complaint.statusLabel,
                      style: TextStyle(
                        color: _getStatusColor(complaint.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Details grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(AppStrings.get('complaints', 'damage', lang), '${complaint.damagePercentage}%'),
                  _buildDetailItem(AppStrings.get('complaints', 'claim', lang), complaint.claimAmount),
                  _buildDetailItem(AppStrings.get('complaints', 'days', lang), '${complaint.daysOld}d'),
                ],
              ),
              const SizedBox(height: 12.0),
              // Location and acreage
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${complaint.village}, ${complaint.district} • ${complaint.acreage} ${AppStrings.get('complaints', 'acres', lang)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (complaint.officerComments.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complaint.officerComments,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'resolved':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
