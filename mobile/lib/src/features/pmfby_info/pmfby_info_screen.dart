import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PMFBYInfoScreen extends StatelessWidget {
  const PMFBYInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PMFBY जानकारी',
          style: GoogleFonts.notoSansDevanagari(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF138808),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Government of India Header
            _buildGovernmentHeader(),
            const SizedBox(height: 24),
            
            // About PMFBY
            _buildSectionCard(
              'योजना के बारे में',
              'About the Scheme',
              Icons.info_outline,
              _buildAboutContent(),
            ),
            const SizedBox(height: 16),
            
            // Key Features
            _buildSectionCard(
              'मुख्य विशेषताएं',
              'Key Features',
              Icons.star_outline,
              _buildFeaturesContent(),
            ),
            const SizedBox(height: 16),
            
            // Premium Rates
            _buildSectionCard(
              'प्रीमियम दरें',
              'Premium Rates',
              Icons.currency_rupee,
              _buildPremiumContent(),
            ),
            const SizedBox(height: 16),
            
            // Helpline Numbers
            _buildSectionCard(
              'हेल्पलाइन नंबर',
              'Helpline Numbers',
              Icons.phone,
              _buildHelplineContent(),
            ),
            const SizedBox(height: 16),
            
            // Official Links
            _buildSectionCard(
              'आधिकारिक लिंक',
              'Official Links',
              Icons.link,
              _buildLinksContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGovernmentHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF9933),
              Color(0xFFFFFFFF),
              Color(0xFF138808),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.account_balance, size: 48, color: Color(0xFF000080)),
            const SizedBox(height: 12),
            Text(
              'भारत सरकार',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF000080),
              ),
            ),
            Text(
              'Government of India',
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF000080),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'कृषि एवं किसान कल्याण मंत्रालय',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            Text(
              'Ministry of Agriculture & Farmers Welfare',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String hindiTitle, String englishTitle, IconData icon, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF138808), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hindiTitle,
                        style: GoogleFonts.notoSansDevanagari(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        englishTitle,
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBulletPoint(
          'प्रधानमंत्री फसल बीमा योजना (PMFBY) भारत सरकार की महत्वाकांक्षी योजना है।',
          'Pradhan Mantri Fasal Bima Yojana (PMFBY) is an ambitious scheme by the Government of India.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'इसका उद्देश्य किसानों को प्राकृतिक आपदाओं से सुरक्षा प्रदान करना है।',
          'It aims to provide protection to farmers against natural calamities.',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'वर्ष 2016 में शुरू की गई यह योजना सभी राज्यों में लागू है।',
          'Launched in 2016, this scheme is implemented in all states.',
        ),
      ],
    );
  }

  Widget _buildFeaturesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeature('✓', 'सभी खाद्य और तिलहन फसलों के लिए बीमा', 'Insurance for all food and oilseed crops'),
        _buildFeature('✓', 'बुवाई से कटाई तक सुरक्षा', 'Protection from sowing to harvesting'),
        _buildFeature('✓', 'कम प्रीमियम, अधिकतम कवर', 'Low premium, maximum cover'),
        _buildFeature('✓', 'तकनीकी आधारित दावा निपटान', 'Technology-based claim settlement'),
        _buildFeature('✓', 'स्मार्टफोन से दावा दर्ज करें', 'File claims via smartphone'),
      ],
    );
  }

  Widget _buildPremiumContent() {
    return Column(
      children: [
        _buildPremiumRow('खरीफ फसलें / Kharif', '2%', 'धान, कपास, सोयाबीन'),
        const Divider(),
        _buildPremiumRow('रबी फसलें / Rabi', '1.5%', 'गेहूं, चना, सरसों'),
        const Divider(),
        _buildPremiumRow('बागवानी / Horticulture', '5%', 'फल, सब्जियां'),
      ],
    );
  }

  Widget _buildHelplineContent() {
    return Column(
      children: [
        _buildHelplineRow('राष्ट्रीय हेल्पलाइन', 'National Helpline', '📞 1800-180-1551', true),
        const SizedBox(height: 12),
        _buildHelplineRow('किसान कॉल सेंटर', 'Kisan Call Center', '📞 1800-180-1551', true),
        const SizedBox(height: 12),
        _buildHelplineRow('ईमेल सहायता', 'Email Support', '📧 pmfby@gov.in', false),
      ],
    );
  }

  Widget _buildLinksContent() {
    return Column(
      children: [
        _buildLinkButton('PMFBY पोर्टल', 'https://pmfby.gov.in', Icons.language),
        const SizedBox(height: 8),
        _buildLinkButton('किसान मोबाइल ऐप', 'https://play.google.com/store/apps/details?id=in.nic.pmfby.mobile', Icons.android),
        const SizedBox(height: 8),
        _buildLinkButton('कृषि मंत्रालय', 'https://agricoop.nic.in', Icons.account_balance),
      ],
    );
  }

  Widget _buildBulletPoint(String hindi, String english) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hindi,
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          english,
          style: GoogleFonts.notoSans(
            fontSize: 13,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(String bullet, String hindi, String english) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bullet,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF138808),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hindi,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  english,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
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

  Widget _buildPremiumRow(String crop, String rate, String examples) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop,
                  style: GoogleFonts.notoSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  examples,
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF138808).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rate,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF138808),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineRow(String hindiLabel, String englishLabel, String number, bool isPhone) {
    return InkWell(
      onTap: () async {
        if (isPhone) {
          final uri = Uri.parse('tel:${number.replaceAll(RegExp(r'[^\d]'), '')}');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hindiLabel,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    englishLabel,
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              number,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkButton(String label, String url, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF138808),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
