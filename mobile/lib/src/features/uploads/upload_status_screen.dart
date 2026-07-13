import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../services/local_storage_service.dart';

class UploadStatusScreen extends StatefulWidget {
  const UploadStatusScreen({super.key});

  @override
  State<UploadStatusScreen> createState() => _UploadStatusScreenState();
}

class _UploadStatusScreenState extends State<UploadStatusScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  List<PendingUpload> _uploads = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUploads();
  }

  Future<void> _loadUploads() async {
    setState(() => _isLoading = true);
    
    final uploads = await _storageService.getPendingUploads();
    final stats = await _storageService.getStorageStats();
    final lastSync = await _storageService.getLastSyncTime();
    
    setState(() {
      _uploads = uploads;
      _stats = {...stats, 'lastSync': lastSync};
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'अपलोड स्थिति',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUploads,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearSynced,
            tooltip: 'Clear Synced',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUploads,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  if (_uploads.isEmpty)
                    _buildEmptyState()
                  else
                    ..._uploads.map((upload) => _buildUploadCard(upload)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'स्टोरेज सारांश',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                _stats!['pendingUploads'].toString(),
                'लंबित',
                Icons.schedule,
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem(
                _stats!['syncedUploads'].toString(),
                'समन्वयित',
                Icons.check_circle,
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
              _buildStatItem(
                _stats!['failedUploads'].toString(),
                'विफल',
                Icons.error,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'कुल आकार',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${_stats!['totalSizeMB']} MB',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (_stats!['lastSync'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'अंतिम समन्वयन',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      _formatTime(_stats!['lastSync'] as DateTime),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(PendingUpload upload) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(upload.imagePath),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image, color: Colors.grey.shade400),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        upload.cropType,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(upload.capturedAt),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(upload.status),
              ],
            ),
            if (upload.latitude != null && upload.longitude != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'GPS: ${upload.latitude!.toStringAsFixed(6)}, ${upload.longitude!.toStringAsFixed(6)}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
            if (upload.description != null && upload.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                upload.description!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (upload.status == SyncStatus.failed && upload.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'पुनः प्रयास: ${upload.retryCount}/3',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SyncStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case SyncStatus.pending:
        color = Colors.orange;
        text = 'लंबित';
        icon = Icons.schedule;
        break;
      case SyncStatus.uploading:
        color = Colors.blue;
        text = 'अपलोड हो रहा है';
        icon = Icons.cloud_upload;
        break;
      case SyncStatus.synced:
        color = Colors.green;
        text = 'समन्वयित';
        icon = Icons.check_circle;
        break;
      case SyncStatus.failed:
        color = Colors.red;
        text = 'विफल';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.cloud_done,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'कोई लंबित अपलोड नहीं',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'सभी चित्र सर्वर पर समन्वयित हैं',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'अभी';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} मिनट पहले';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} घंटे पहले';
    } else {
      return DateFormat('dd MMM, HH:mm').format(time);
    }
  }

  Future<void> _clearSynced() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('समन्वयित अपलोड साफ़ करें?', style: GoogleFonts.poppins()),
        content: const Text('यह सभी सफलतापूर्वक समन्वयित चित्रों को हटा देगा।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('रद्द करें'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('हटाएं'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.clearSyncedUploads();
      await _loadUploads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('समन्वयित अपलोड साफ़ किए गए')),
        );
      }
    }
  }
}
