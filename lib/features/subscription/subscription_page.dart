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
  bool _loading = true;
  String? _error;
  List<ProductDetails> _products = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.initialize();
    final available = await _service.isStoreAvailable();
    if (!available) {
      setState(() {
        _loading = false;
        _error = 'Google Play Billing is not available on this device/build.';
      });
      return;
    }

    final products = await _service.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
      if (products.isEmpty) {
        _error =
            'Subscription products are not available yet. Create the monthly and annual products in Play Console using the IDs in SubscriptionService.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LowVolt Pilot Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Built for field technicians',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock full system design, commissioning, troubleshooting, unlimited jobs, and professional reports.',
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
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
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
          TextButton(
            onPressed: _service.restorePurchases,
            child: const Text('Restore purchases'),
          ),
        ],
      ),
    );
  }

  String _label(String id) {
    if (id == SubscriptionService.monthlyId) return 'Pro Monthly';
    if (id == SubscriptionService.annualId) return 'Pro Annual';
    return id;
  }
}
