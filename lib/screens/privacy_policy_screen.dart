import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final soundService = SoundService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('PRIVACY POLICY'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            soundService.playClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2125) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.indigo.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Last updated: April 26, 2026',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildText(
                'AH Digital built the IQ Vault app as an Ad Supported app. This SERVICE is provided by AH Digital at no cost and is intended for use as is.\n\n'
                'This page is used to inform visitors regarding our policies with the collection, use, and disclosure of Personal Information if anyone decided to use our Service.\n\n'
                'If you choose to use our Service, then you agree to the collection and use of information in relation to this policy. The Personal Information that we collect is used for providing and improving the Service. We will not use or share your information with anyone except as described in this Privacy Policy.',
                isDark,
              ),
              _buildHeading('Information Collection and Use', isDark),
              _buildText(
                'For a better experience, while using our Service, we may require you to provide us with certain personally identifiable information. The information that we request will be retained by us and used as described in this privacy policy.\n\n'
                'The app does use third-party services that may collect information used to identify you, such as Google Play Services and AdMob.',
                isDark,
              ),
              _buildHeading('Log Data', isDark),
              _buildText(
                'We want to inform you that whenever you use our Service, in a case of an error in the app we collect data and information (through third-party products) on your phone called Log Data. This Log Data may include information such as your device Internet Protocol ("IP") address, device name, operating system version, the configuration of the app when utilizing our Service, the time and date of your use of the Service, and other statistics.',
                isDark,
              ),
              _buildHeading('Cookies', isDark),
              _buildText(
                'Cookies are files with a small amount of data that are commonly used as anonymous unique identifiers. These are sent to your browser from the websites that you visit and are stored on your device\'s internal memory.\n\n'
                'This Service does not use these "cookies" explicitly. However, the app may use third-party code and libraries that use "cookies" to collect information and improve their services.',
                isDark,
              ),
              _buildHeading('Service Providers', isDark),
              _buildText(
                'We may employ third-party companies and individuals to facilitate our Service, to provide the Service on our behalf, to perform Service-related services, or to assist us in analyzing how our Service is used. These third parties have access to your Personal Information to perform the tasks assigned to them on our behalf. However, they are obligated not to disclose or use the information for any other purpose.',
                isDark,
              ),
              _buildHeading('Security', isDark),
              _buildText(
                'We value your trust in providing us your Personal Information, thus we are striving to use commercially acceptable means of protecting it. But remember that no method of transmission over the internet, or method of electronic storage is 100% secure and reliable, and we cannot guarantee its absolute security.',
                isDark,
              ),
              _buildHeading('Links to Other Sites', isDark),
              _buildText(
                'This Service may contain links to other sites. If you click on a third-party link, you will be directed to that site. Note that these external sites are not operated by us. Therefore, we strongly advise you to review the Privacy Policy of these websites.',
                isDark,
              ),
              _buildHeading('Children\'s Privacy', isDark),
              _buildText(
                'These Services do not address anyone under the age of 13. We do not knowingly collect personally identifiable information from children under 13.',
                isDark,
              ),
              _buildHeading('Changes to This Privacy Policy', isDark),
              _buildText(
                'We may update our Privacy Policy from time to time. Thus, you are advised to review this page periodically for any changes. We will notify you of any changes by posting the new Privacy Policy on this page.',
                isDark,
              ),
              _buildHeading('Contact Us', isDark),
              _buildText(
                'If you have any questions or suggestions about our Privacy Policy, do not hesitate to contact us at shamilsohaib@gmail.com.',
                isDark,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.indigoAccent : Colors.indigo,
        ),
      ),
    );
  }

  Widget _buildText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isDark ? Colors.grey[400] : Colors.grey[800],
      ),
    );
  }
}
