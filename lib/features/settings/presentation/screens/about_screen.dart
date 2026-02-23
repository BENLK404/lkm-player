import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'LKM Player',
    packageName: 'lkm.player',
    version: '1.0.2',
    buildNumber: 'Available',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir le lien: $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('À propos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section App Info
          _buildAppInfoSection(),
          const Divider(height: 32),

          // Section Développeur
          _buildDeveloperSection(),
          const Divider(height: 32),

          // Section Liens Utiles
          _buildLinksSection(),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: const DecorationImage(
              image: AssetImage('assets/icon/app.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _packageInfo.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Version ${_packageInfo.version} (${_packageInfo.buildNumber})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Développeur'),
        const SizedBox(height: 8),
        const Text(
          'Cette application a été développée avec passion par LK Fondation.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Un lecteur de musique simple, open-source et respectueux de la vie privée pour Android.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Liens utiles'),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Code Source'),
          subtitle: const Text('Voir le projet sur GitHub'),
          onTap: () => _launchUrl('https://github.com/BENLK404'),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report_outlined),
          title: const Text('Signaler un problème'),
          subtitle: const Text('Ouvrir une issue sur GitHub'),
          onTap: () => _launchUrl('https://github.com/BENLK404/lkm-player/issues'),
        ),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Politique de confidentialité'),
          onTap: () {
            // TODO: Ajouter un lien vers la politique de confidentialité
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
