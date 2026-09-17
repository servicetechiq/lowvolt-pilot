import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/billing/subscription_service.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final _service = SubscriptionService.instance;

  StreamSubscription<bool>? _proSubscription;
  bool _loading = true;
  bool _restoring = false;
  bool _isPro = false;
  String? _error;
  String? _notice;
  String? _restoreMessage;
  List<ProductDetails> _products = const [];

  @override
  void initState() {
    super.initState();
    _isPro = _service.isPro;
    _proSubscription = _service.proChanges.listen((value) {
      if (!mounted) return;
      setState(() => _isPro = value);
    });
    _load();
  }

  @override
  void dispose() {
    _proSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _service.initialize();

      if (!mounted) return;
      setState(() => _isPro = _service.isPro);

      final available = await _service.isStoreAvailable();

      if (!mounted) return;

      if (!available) {
        setState(() {
          _loading = false;
          _notice =
              'Google Play Billing is not available on this device or build.';
        });
        return;
      }

      final products = await _service.loadProducts();
      if (!mounted) return;

      setState(() {
        _products = products;
        _loading = false;

        if (products.isEmpty) {
          _notice =
              'LowVolt Pilot subscriptions have not been published for this '
              'Google Play build yet.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load subscription information right now.';
      });
    }
  }

  Future<void> _restore() async {
    if (_restoring) return;

    setState(() {
      _restoring = true;
      _restoreMessage = null;
    });

    final result = await _service.restorePurchases();

    if (!mounted) return;
    setState(() {
      _restoring = false;
      _restoreMessage = result.message;
      _isPro = _service.isPro;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _service.refreshServerEntitlement();
          if (mounted) {
            setState(() => _isPro = _service.isPro);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  _isPro ? Icons.workspace_premium : Icons.person_outline,
                ),
                title: const Text('Current plan'),
                subtitle: Text(
                  _isPro ? 'LowVolt Pilot Pro${_sourceLabel()}' : 'Free',
                ),
                trailing: _isPro
                    ? const Chip(label: Text('PRO'))
                    : const Chip(label: Text('FREE')),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'LowVolt Pilot Pro',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Unlock the complete technician workflow for system design, '
              'installation, commissioning, troubleshooting, documentation, '
              'and professional reporting.',
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro includes',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text('• Full camera/access/network/wireless workflows'),
                    Text('• Advanced system design tools'),
                    Text('• Unlimited jobs and device history'),
                    Text('• Commissioning and troubleshooting flows'),
                    Text('• PDF field reports'),
                    Text('• Expanded vendor guidance'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_notice != null)
              _MessageCard(icon: Icons.info_outline, message: _notice!),
            if (_error != null)
              _MessageCard(
                icon: Icons.error_outline,
                message: _error!,
                color: colorScheme.error,
              ),
            if (!_isPro)
              for (final product in _products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton(
                    onPressed: () => _service.buy(product),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text('${_label(product.id)} — ${product.price}'),
                    ),
                  ),
                ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _restoring ? null : _restore,
              icon: _restoring
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Text(
                  _restoring ? 'Checking purchases...' : 'Restore purchases',
                ),
              ),
            ),
            if (_restoreMessage != null) ...[
              const SizedBox(height: 10),
              _MessageCard(
                icon: _isPro ? Icons.check_circle_outline : Icons.info_outline,
                message: _restoreMessage!,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Pro access is controlled by your LowVolt Pilot account '
              'entitlement. Google Play purchases will be verified server-side '
              'before production release.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _sourceLabel() {
    final source = _service.entitlementSource;
    if (source == 'internal') return ' · Internal';
    if (source == 'servicetechiq') return ' · ServiceTechIQ';
    if (source == 'google_play') return ' · Google Play';
    return '';
  }

  String _label(String id) {
    if (id == SubscriptionService.monthlyId) return 'Pro Monthly';
    if (id == SubscriptionService.annualId) return 'Pro Annual';
    return id;
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message, this.color});

  final IconData icon;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: effectiveColor),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }
}
