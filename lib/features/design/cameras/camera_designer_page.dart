import 'package:flutter/material.dart';

class CameraDesignerPage extends StatefulWidget {
  const CameraDesignerPage({super.key});

  @override
  State<CameraDesignerPage> createState() => _CameraDesignerPageState();
}

class _CameraDesignerPageState extends State<CameraDesignerPage> {
  final _formKey = GlobalKey<FormState>();
  final _lengthController = TextEditingController(text: '40');
  final _widthController = TextEditingController(text: '60');
  final _heightController = TextEditingController(text: '12');
  String _goal = 'General observation';
  _CameraDesignResult? _result;

  static const goals = [
    'General observation',
    'Recognize people',
    'Identify people',
    'Entrance / exit',
    'Detailed activity',
  ];

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  double? _positiveNumber(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final length = _positiveNumber(_lengthController.text)!;
    final width = _positiveNumber(_widthController.text)!;
    final height = _positiveNumber(_heightController.text)!;
    final area = length * width;

    // V0.1 heuristic only. Replace with lens/FOV/pixel-density geometry.
    final densityFactor = switch (_goal) {
      'Identify people' => 450.0,
      'Recognize people' => 650.0,
      'Entrance / exit' => 550.0,
      'Detailed activity' => 500.0,
      _ => 900.0,
    };

    final cameras = (area / densityFactor).ceil().clamp(1, 32);
    final lens = _goal == 'General observation' ? '2.8 mm wide-angle starting point' : 'Consider 4 mm or varifocal for tighter detail';

    setState(() {
      _result = _CameraDesignResult(
        cameras: cameras,
        lensGuidance: lens,
        mountingGuidance: height > 14
            ? 'Mounting is relatively high; verify pixel density at the target before finalizing.'
            : 'Height is workable for a first-pass layout; confirm views on site.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera System Designer')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'First-pass room coverage',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'This starter estimates a planning baseline. The production designer will add lens geometry, pixel density, blind-spot visualization, storage, PoE, and NVR sizing.',
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _dimensionField('Length (ft)', _lengthController)),
                    const SizedBox(width: 10),
                    Expanded(child: _dimensionField('Width (ft)', _widthController)),
                  ],
                ),
                const SizedBox(height: 10),
                _dimensionField('Ceiling / mount height (ft)', _heightController),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  decoration: const InputDecoration(
                    labelText: 'Primary coverage goal',
                    border: OutlineInputBorder(),
                  ),
                  items: goals.map((goal) => DropdownMenuItem(value: goal, child: Text(goal))).toList(),
                  onChanged: (value) => setState(() => _goal = value ?? _goal),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _calculate,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Build First-Pass Design'),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planning baseline', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _resultRow('Estimated cameras', '${_result!.cameras}'),
                    _resultRow('Lens guidance', _result!.lensGuidance),
                    _resultRow('Mounting guidance', _result!.mountingGuidance),
                    const SizedBox(height: 10),
                    const Text(
                      'Not a final coverage certification. V1 production logic will use actual field-of-view and target-detail calculations rather than this starter heuristic.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dimensionField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) => _positiveNumber(value) == null ? 'Enter a number > 0' : null,
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 135, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CameraDesignResult {
  const _CameraDesignResult({
    required this.cameras,
    required this.lensGuidance,
    required this.mountingGuidance,
  });

  final int cameras;
  final String lensGuidance;
  final String mountingGuidance;
}
