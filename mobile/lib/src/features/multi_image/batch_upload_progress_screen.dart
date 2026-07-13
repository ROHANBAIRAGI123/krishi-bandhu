import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/image_upload_service.dart';
import 'package:intl/intl.dart';
import '../../services/image_upload_service.dart';

class BatchUploadProgressScreen extends StatefulWidget {
  const BatchUploadProgressScreen({super.key});

  @override
  State<BatchUploadProgressScreen> createState() => _BatchUploadProgressScreenState();
}

class _BatchUploadProgressScreenState extends State<BatchUploadProgressScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Upload Progress',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ImageUploadService>(
        builder: (context, uploadService, child) {
          final stats = uploadService.getUploadStats();
          
          return Column(
            children: [
              // Overall Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade500],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Overall Progress',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: stats['progress'] as double,
                            strokeWidth: 12,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${((stats['progress'] as double) * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${stats['completed']}/${stats['total']} images',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBadge(
                          'Pending',
                          stats['pending'].toString(),
                          Icons.pending,
                          Colors.orange,
                        ),
                        _buildStatBadge(
                          'Uploading',
                          stats['uploading'].toString(),
                          Icons.cloud_upload,
                          Colors.blue,
                        ),
                        _buildStatBadge(
                          'Failed',
                          stats['failed'].toString(),
                          Icons.error,
                          Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upload Queue List
              Expanded(
                child: uploadService.uploadQueue.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: uploadService.uploadQueue.length,
                        itemBuilder: (context, index) {
                          final item = uploadService.uploadQueue[index];
                          return _buildUploadItemCard(item);
                        },
                      ),
              ),

              // Action Buttons
              if (uploadService.uploadQueue.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        if (stats['failed'] > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: uploadService.isUploading
                                  ? null
                                  : () => _retryFailedUploads(uploadService),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry Failed'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (stats['failed'] > 0) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: uploadService.isUploading
                                ? () => uploadService.cancelUpload()
                                : stats['completed'] == stats['total']
                                    ? () => uploadService.clearCompleted()
                                    : () => _startUpload(uploadService),
                            icon: Icon(
                              uploadService.isUploading
                                  ? Icons.stop
                                  : stats['completed'] == stats['total']
                                      ? Icons.check
                                      : Icons.cloud_upload,
                            ),
                            label: Text(
                              uploadService.isUploading
                                  ? 'Cancel'
                                  : stats['completed'] == stats['total']
                                      ? 'Clear'
                                      : 'Start Upload',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: uploadService.isUploading
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadItemCard(ImageUploadItem item) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (item.status) {
      case UploadStatus.pending:
        statusColor = Colors.grey;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case UploadStatus.uploading:
        statusColor = Colors.blue;
        statusIcon = Icons.cloud_upload;
        statusText = 'Uploading...';
        break;
      case UploadStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case UploadStatus.failed:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image, color: Colors.grey.shade600),
        ),
        title: Text(
          'Image ${item.imageNumber}',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${item.fileSizeMB.toStringAsFixed(2)} MB',
              style: GoogleFonts.roboto(fontSize: 12),
            ),
            if (item.uploadedAt != null)
              Text(
                'Uploaded: ${DateFormat('hh:mm a').format(item.uploadedAt!)}',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            if (item.errorMessage != null)
              Text(
                item.errorMessage!,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.red.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_done,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No Uploads in Queue',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture images to start uploading',
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startUpload(ImageUploadService uploadService) async {
    await uploadService.startBatchUpload(
      uploadFunction: (item) async {
        // Simulate upload (replace with actual Firebase Storage upload)
        await Future.delayed(const Duration(seconds: 2));
        return true; // Return true if upload successful
      },
      onComplete: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('All images uploaded successfully!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload error: $error'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
    );
  }

  Future<void> _retryFailedUploads(ImageUploadService uploadService) async {
    await uploadService.retryFailedUploads(
      uploadFunction: (item) async {
        // Simulate upload (replace with actual Firebase Storage upload)
        await Future.delayed(const Duration(seconds: 2));
        return true;
      },
      onComplete: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Retry completed!'),
              backgroundColor: Colors.green.shade700,
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Retry error: $error'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      },
    );
  }
}
