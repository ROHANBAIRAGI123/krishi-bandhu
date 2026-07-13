import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/complaint_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class PastComplaintsScreen extends StatefulWidget {
  const PastComplaintsScreen({super.key});

  @override
  State<PastComplaintsScreen> createState() => _PastComplaintsScreenState();
}

class _PastComplaintsScreenState extends State<PastComplaintsScreen> {
  late List<Complaint> pastComplaints;
  String _filterStatus = 'all'; // 'all', 'resolved', 'rejected'
  String _sortBy = 'recent'; // 'recent', 'oldest'

  @override
  void initState() {
    super.initState();
    _loadPastComplaints();
  }

  void _loadPastComplaints() {
    // Sample data - In real app, fetch from API/database
    pastComplaints = [
      Complaint(
        complaintId: 'CMP-2024-045',
        cropType: 'Rice',
        damagePercentage: 75.0,
        status: 'resolved',
        submissionDate: DateTime(2024, 8, 15),
        resolvedDate: DateTime(2024, 9, 20),
        description: 'Flood damage to rice fields',
        insuredAmount: '₹80,000',
        claimAmount: '₹60,000',
        village: 'Rahuri',
        district: 'Ahmednagar',
        acreage: 5.0,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Claim approved and disbursed on 2024-09-20.',
      ),
      Complaint(
        complaintId: 'CMP-2024-044',
        cropType: 'Sugarcane',
        damagePercentage: 50.0,
        status: 'resolved',
        submissionDate: DateTime(2024, 7, 10),
        resolvedDate: DateTime(2024, 8, 15),
        description: 'Pest infestation and disease',
        insuredAmount: '₹100,000',
        claimAmount: '₹50,000',
        village: 'Phaltan',
        district: 'Satara',
        acreage: 3.5,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Partial claim approved.',
      ),
      Complaint(
        complaintId: 'CMP-2024-043',
        cropType: 'Groundnut',
        damagePercentage: 20.0,
        status: 'rejected',
        submissionDate: DateTime(2024, 6, 20),
        resolvedDate: DateTime(2024, 7, 30),
        description: 'Minor frost damage',
        insuredAmount: '₹35,000',
        claimAmount: '₹7,000',
        village: 'Solapur',
        district: 'Solapur',
        acreage: 1.5,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Claim rejected. Damage below threshold (20% threshold).',
      ),
      Complaint(
        complaintId: 'CMP-2024-042',
        cropType: 'Jowar',
        damagePercentage: 85.0,
        status: 'resolved',
        submissionDate: DateTime(2024, 5, 15),
        resolvedDate: DateTime(2024, 6, 25),
        description: 'Severe drought and plant wilting',
        insuredAmount: '₹40,000',
        claimAmount: '₹34,000',
        village: 'Karveer',
        district: 'Kolhapur',
        acreage: 2.0,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Full claim approved and processed.',
      ),
      Complaint(
        complaintId: 'CMP-2024-041',
        cropType: 'Soybean',
        damagePercentage: 15.0,
        status: 'rejected',
        submissionDate: DateTime(2024, 4, 10),
        resolvedDate: DateTime(2024, 5, 20),
        description: 'Light hail damage',
        insuredAmount: '₹30,000',
        claimAmount: '₹4,500',
        village: 'Indore',
        district: 'Indore',
        acreage: 1.0,
        imageUrl: 'assets/images/placeholder.png',
        officerComments: 'Rejected - damage percentage below policy threshold.',
      ),
    ];

    // Sort based on filter
    _sortComplaints();
  }

  void _sortComplaints() {
    if (_sortBy == 'recent') {
      pastComplaints.sort((a, b) =>
          (b.resolvedDate ?? b.submissionDate)
              .compareTo(a.resolvedDate ?? a.submissionDate));
    } else {
      pastComplaints.sort((a, b) =>
          (a.resolvedDate ?? a.submissionDate)
              .compareTo(b.resolvedDate ?? b.submissionDate));
    }
  }

  List<Complaint> get _filteredComplaints {
    if (_filterStatus == 'all') {
      return pastComplaints;
    }
    return pastComplaints.where((c) => c.status == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          body: Column(
            children: [
              // Filters and sort
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status filters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(AppStrings.get('complaints', 'all', lang), 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip(AppStrings.get('complaints', 'resolved', lang), 'resolved'),
                          const SizedBox(width: 8),
                          _buildFilterChip(AppStrings.get('complaints', 'rejected', lang), 'rejected'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Sort option
                    Row(
                      children: [
                        Icon(Icons.sort, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortBy,
                          underline: SizedBox.shrink(),
                          items: const [
                            DropdownMenuItem(
                              value: 'recent',
                              child: Text('Most Recent'),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Oldest First'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortBy = value;
                                _sortComplaints();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
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
                              Icons.history,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppStrings.get('complaints', 'no_past_complaints', lang),
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
    final isResolved = complaint.status == 'resolved';
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
              // Header
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
              // Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDetailItem(AppStrings.get('complaints', 'damage', lang), '${complaint.damagePercentage}%'),
                  _buildDetailItem(AppStrings.get('complaints', 'claim', lang), complaint.claimAmount),
                  _buildDetailItem(
                    'Settled',
                    _formatDate(complaint.resolvedDate ??
                        DateTime.now()), // Placeholder if null
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Settlement info
              if (isResolved && complaint.resolvedDate != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Settled on ${_formatDate(complaint.resolvedDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[700],
                            ),
                      ),
                    ],
                  ),
                )
              else if (!isResolved)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 16,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejected on ${_formatDate(complaint.resolvedDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.red[700],
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
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
