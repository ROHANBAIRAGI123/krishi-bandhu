import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/complaint_model.dart';
import '../../../../providers/language_provider.dart';
import '../../../../localization/app_localizations.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final Complaint complaint;

  const ComplaintDetailScreen({
    super.key,
    required this.complaint,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;
        return Scaffold(
          appBar: AppBar(
            title: Text(AppStrings.get('complaints', 'complaint_details', lang)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                _buildStatusCard(context),
                const SizedBox(height: 24.0),

                // Complaint ID and dates
                _buildSection(
                  context,
                  'Complaint Information',
                  [
                    _buildInfoRow('Complaint ID', complaint.complaintId),
                    _buildInfoRow(
                      'Submitted',
                      _formatDate(complaint.submissionDate),
                    ),
                    if (complaint.resolvedDate != null)
                      _buildInfoRow(
                        'Resolved',
                        _formatDate(complaint.resolvedDate!),
                      ),
                    _buildInfoRow('${AppStrings.get('complaints', 'days', lang)} Pending', '${complaint.daysOld} ${AppStrings.get('complaints', 'days', lang)}'),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Crop and damage details
                _buildSection(
                  context,
                  'Crop Details',
                  [
                    _buildInfoRow('Crop Type', complaint.cropType),
                    _buildInfoRow(AppStrings.get('complaints', 'damage', lang), '${complaint.damagePercentage}%'),
                    _buildInfoRow('Acreage', '${complaint.acreage} ${AppStrings.get('complaints', 'acres', lang)}'),
                    _buildInfoRow('Location',
                        '${complaint.village}, ${complaint.district}'),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Financial details
                _buildSection(
                  context,
                  'Financial Information',
                  [
                    _buildInfoRow('Insured Amount', complaint.insuredAmount),
                    _buildInfoRow(AppStrings.get('complaints', 'claim', lang), complaint.claimAmount),
                    _buildInfoRow(
                      'Settlement Rate',
                      '${((double.parse(complaint.claimAmount.replaceAll('₹', '').replaceAll(',', '')) / double.parse(complaint.insuredAmount.replaceAll('₹', '').replaceAll(',', ''))) * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),

                // Description
                _buildDescriptionSection(context, lang),
                const SizedBox(height: 24.0),

                // Officer comments
                if (complaint.officerComments.isNotEmpty)
                  _buildCommentsSection(context),

                const SizedBox(height: 24.0),

                // Action buttons
                _buildActionButtons(context, lang),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getStatusColor(complaint.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(complaint.status),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(complaint.status),
            size: 32,
            color: _getStatusColor(complaint.status),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.statusLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _getStatusColor(complaint.status),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(complaint.status),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.get('complaints', 'description', lang),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            complaint.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Officer Comments',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Colors.blue[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  complaint.officerComments,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String lang) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Complaint downloaded!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: complaint.isActive
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Appeal ${AppStrings.get('complaints', 'feature_coming_soon', lang)}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.flag),
            label: const Text('Appeal'),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'resolved':
        return Icons.task_alt;
      default:
        return Icons.info;
    }
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

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Your complaint is under review by our team';
      case 'approved':
        return 'Your claim has been approved and is being processed';
      case 'rejected':
        return 'Your claim could not be approved';
      case 'resolved':
        return 'Your complaint has been resolved and settled';
      default:
        return 'Status unknown';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
