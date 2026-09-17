import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'camera_design_engine.dart';

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
  final _retentionController = TextEditingController(text: '30');
  final _bitrateController = TextEditingController(text: '4');
  final _poeController = TextEditingController(text: '8');

  final _engine = const CameraDesignEngine();

  CameraCoverageGoal _goal = CameraCoverageGoal.observe;
  CameraResolutionPreset _resolution = CameraResolutionPreset.mp4;
  CameraDesignResult? _result;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _retentionController.dispose();
    _bitrateController.dispose();
    _poeController.dispose();
    super.dispose();
  }

  double? _positiveDouble(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  int? _positiveInt(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final input = CameraDesignInput(
      lengthFeet: _positiveDouble(_lengthController.text)!,
      widthFeet: _positiveDouble(_widthController.text)!,
      mountHeightFeet: _positiveDouble(_heightController.text)!,
      goal: _goal,
      resolution: _resolution,
      retentionDays: _positiveInt(_retentionController.text)!,
      averageBitrateMbps: _positiveDouble(_bitrateController.text)!,
      poeWattsPerCamera: _positiveDouble(_poeController.text)!,
    );

    setState(() => _result = _engine.calculate(input));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera System Designer')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            'Plan the coverage before you pick the cameras',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'LowVolt Pilot uses target pixel density, room geometry, resolution, storage, and PoE assumptions to build a first-pass camera plan.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: '1. Area',
                  subtitle: 'Rectangular room/area baseline',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(
                              'Length (ft)',
                              _lengthController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _numberField('Width (ft)', _widthController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _numberField(
                        'Camera mounting height (ft)',
                        _heightController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '2. Required detail',
                  subtitle:
                      'What must the image let the technician/customer do?',
                  child: Column(
                    children: [
                      DropdownButtonFormField<CameraCoverageGoal>(
                        initialValue: _goal,
                        decoration: const InputDecoration(
                          labelText: 'Coverage objective',
                          border: OutlineInputBorder(),
                        ),
                        items: CameraCoverageGoal.values
                            .map(
                              (goal) => DropdownMenuItem(
                                value: goal,
                                child: Text(
                                  '${goal.label} • ${goal.pixelsPerFoot.toInt()} px/ft',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _goal = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _goal.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CameraResolutionPreset>(
                        initialValue: _resolution,
                        decoration: const InputDecoration(
                          labelText: 'Candidate camera resolution',
                          border: OutlineInputBorder(),
                        ),
                        items: CameraResolutionPreset.values
                            .map(
                              (resolution) => DropdownMenuItem(
                                value: resolution,
                                child: Text(resolution.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _resolution = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '3. Recording & power assumptions',
                  subtitle: 'Used for NVR, storage, and PoE planning',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _integerField(
                              'Retention (days)',
                              _retentionController,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _numberField(
                              'Avg bitrate (Mbps)',
                              _bitrateController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _numberField('PoE draw per camera (W)', _poeController),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Build Camera Plan'),
                  ),
                ),
              ],
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _DesignResults(result: _result!),
          ],
        ],
      ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          _positiveDouble(value) == null ? 'Enter a value > 0' : null,
    );
  }

  Widget _integerField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          _positiveInt(value) == null ? 'Enter a whole number > 0' : null,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _DesignResults extends StatelessWidget {
  const _DesignResults({required this.result});

  final CameraDesignResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'First-pass design',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Chip(
              label: Text(
                '${result.cameraCount} camera${result.cameraCount == 1 ? '' : 's'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.8,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(
                painter: _RoomPlanPainter(result: result),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _metric(
                  context,
                  'Placement baseline',
                  '${result.cameraCount} evenly spaced on the ${result.mountingWall.toLowerCase()}',
                ),
                _metric(
                  context,
                  'Target detail',
                  '${_one(result.targetPixelDensity)} px/ft minimum • ${_one(result.estimatedPixelDensity)} px/ft estimated',
                ),
                _metric(
                  context,
                  'View per camera',
                  '${_one(result.designSceneWidthFeet)} ft segment at ~${_one(result.viewingDistanceFeet)} ft viewing distance',
                ),
                _metric(
                  context,
                  'Required horizontal FOV',
                  '${_one(result.requiredHorizontalFovDegrees)}°',
                ),
                _metric(context, 'Lens direction', result.lensGuidance),
                _metric(
                  context,
                  'Aim / tilt baseline',
                  '~${_one(result.tiltDegrees)}° down toward a 4.5 ft target height at the far side',
                ),
                _metric(
                  context,
                  'Recorder',
                  '${result.nvrChannels}-channel NVR minimum standard size',
                ),
                _metric(
                  context,
                  'Estimated storage',
                  '~${_two(result.storageTerabytes)} TB before RAID/reserve/headroom',
                ),
                _metric(
                  context,
                  'PoE switch budget',
                  'At least ${result.poeBudgetWatts.ceil()} W total camera budget including 20% headroom',
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Design notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final note in result.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.info_outline, size: 17),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note)),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Planning aid only — final camera selection and placement must be verified against the actual camera datasheet, lighting, scene, mounting constraints, and required evidentiary detail.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value, {
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Align(alignment: Alignment.centerLeft, child: Text(value)),
        if (!isLast) const Divider(height: 22),
      ],
    );
  }

  String _one(double value) => value.toStringAsFixed(1);
  String _two(double value) => value.toStringAsFixed(2);
}

class _RoomPlanPainter extends CustomPainter {
  _RoomPlanPainter({required this.result});

  final CameraDesignResult result;

  @override
  void paint(Canvas canvas, Size size) {
    final room = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final scheme = Colors.blueGrey;
    final border = Paint()
      ..color = scheme.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..color = scheme.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    canvas.drawRect(room, fill);
    canvas.drawRect(room, border);

    final cameraPaint = Paint()
      ..color = scheme.shade800
      ..style = PaintingStyle.fill;
    final conePaint = Paint()
      ..color = scheme.withValues(alpha: 0.14)
      ..style = PaintingStyle.fill;
    final coneBorder = Paint()
      ..color = scheme.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final count = result.cameraCount.clamp(1, 12);
    final segment = room.width / count;
    final farY = room.bottom;

    for (var i = 0; i < count; i++) {
      final x = room.left + segment * (i + 0.5);
      final camera = Offset(x, room.top + 4);
      final halfSegment = segment * 0.55;
      final cone = Path()
        ..moveTo(camera.dx, camera.dy)
        ..lineTo(math.max(room.left, x - halfSegment), farY)
        ..lineTo(math.min(room.right, x + halfSegment), farY)
        ..close();
      canvas.drawPath(cone, conePaint);
      canvas.drawPath(cone, coneBorder);
      canvas.drawCircle(camera, 5, cameraPaint);
    }

    if (result.cameraCount > 12) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '+${result.cameraCount - 12} additional cameras not shown',
          style: TextStyle(color: scheme.shade700, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(room.center.dx - textPainter.width / 2, room.bottom - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoomPlanPainter oldDelegate) =>
      oldDelegate.result != result;
}
