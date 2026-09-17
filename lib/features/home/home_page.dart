import 'package:flutter/material.dart';

import '../account/account_page.dart';
import '../design/cameras/camera_designer_page.dart';
import '../install/cameras/camera_install_page.dart';
import '../subscription/subscription_page.dart';
import '../troubleshoot/cameras/camera_troubleshoot_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LowVolt Pilot'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SubscriptionPage())),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Plans'),
          ),
          IconButton(
            tooltip: 'Account',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AccountPage())),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'What are you doing today?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _PrimaryAction(
            icon: Icons.design_services_outlined,
            title: 'Design a System',
            subtitle: 'Plan coverage, equipment, network, power, and capacity.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CameraDesignerPage()),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryAction(
            icon: Icons.build_circle_outlined,
            title: 'Install / Commission',
            subtitle: 'Step-by-step setup and final commissioning checks.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CameraInstallPage()),
            ),
          ),
          const SizedBox(height: 12),
          _PrimaryAction(
            icon: Icons.troubleshoot_outlined,
            title: 'Troubleshoot',
            subtitle: 'Start with the symptom and work toward the cause.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CameraTroubleshootPage()),
            ),
          ),
          const SizedBox(height: 24),
          Text('Workspace', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.assignment_outlined),
                  title: Text('Jobs'),
                  subtitle: Text(
                    'Save sites, devices, tests, notes, and reports.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.handyman_outlined),
                  title: Text('Quick Tools'),
                  subtitle: Text(
                    'Network, PoE, voltage, storage, and field tools.',
                  ),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.menu_book_outlined),
                  title: Text('Reference'),
                  subtitle: Text('Vendor and system guidance for the field.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 34),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
