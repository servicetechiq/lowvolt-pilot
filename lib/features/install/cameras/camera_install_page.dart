import 'package:flutter/material.dart';

class CameraInstallPage extends StatefulWidget {
  const CameraInstallPage({super.key});

  @override
  State<CameraInstallPage> createState() => _CameraInstallPageState();
}

class _CameraInstallPageState extends State<CameraInstallPage> {
  final _nvrIpController = TextEditingController(text: '192.168.1.100');
  final _gatewayController = TextEditingController(text: '192.168.1.1');
  final _firstCameraIpController = TextEditingController(text: '192.168.1.201');
  final _cameraCountController = TextEditingController(text: '8');
  final _nvrChannelsController = TextEditingController(text: '16');

  String _manufacturer = 'Tiandy';
  String _topology = 'NVR PoE ports';
  String _addressing = 'Static camera IPs';

  final Map<String, bool> _checks = {};

  static const _stages = <_CommissionStage>[
    _CommissionStage(
      title: '1. Plan the system',
      icon: Icons.account_tree_outlined,
      items: [
        'Confirm camera count and NVR channel capacity',
        'Confirm PoE topology and available power budget',
        'Reserve NVR and camera IP addresses',
        'Confirm subnet, gateway, DNS, and internet requirements',
        'Label cameras and cable runs before commissioning',
      ],
    ),
    _CommissionStage(
      title: '2. Physical installation',
      icon: Icons.cable_outlined,
      items: [
        'Verify every cable run passes continuity/performance testing',
        'Confirm PoE/link at each camera location',
        'Mount cameras securely and weather-seal exterior penetrations',
        'Aim cameras for the intended scene and avoid obvious IR reflection',
        'Confirm switch/NVR uplinks and network path are connected',
      ],
    ),
    _CommissionStage(
      title: '3. Discover & activate devices',
      icon: Icons.radar_outlined,
      items: [
        'Discover each camera on the local network',
        'Activate devices and set unique secure credentials',
        'Resolve duplicate/default IP addresses before adding cameras',
        'Assign the planned IP address to every camera',
        'Verify every camera responds from the commissioning network',
      ],
    ),
    _CommissionStage(
      title: '4. Configure cameras',
      icon: Icons.videocam_outlined,
      items: [
        'Set camera name/location consistently',
        'Set date, time zone, NTP, and daylight-saving behavior',
        'Set resolution, frame rate, codec, and bitrate',
        'Configure main/sub streams for recording and remote viewing',
        'Configure motion/event rules required for this job',
      ],
    ),
    _CommissionStage(
      title: '5. Configure the NVR',
      icon: Icons.dns_outlined,
      items: [
        'Add all cameras and confirm stable online status',
        'Verify HDD/storage status is healthy',
        'Configure recording schedule for every channel',
        'Verify motion/event recording rules match the design',
        'Set NVR time/NTP and confirm camera clocks agree',
      ],
    ),
    _CommissionStage(
      title: '6. Commission the system',
      icon: Icons.fact_check_outlined,
      items: [
        'Verify live video from every camera',
        'Verify recording on every required channel',
        'Search and play back newly recorded video',
        'Trigger and verify motion/event recording where required',
        'Verify camera names, timestamps, and image orientation',
        'Check night/IR image where practical',
        'Verify remote access only if required by the job',
      ],
    ),
  ];

  @override
  void dispose() {
    _nvrIpController.dispose();
    _gatewayController.dispose();
    _firstCameraIpController.dispose();
    _cameraCountController.dispose();
    _nvrChannelsController.dispose();
    super.dispose();
  }

  int get _completed => _checks.values.where((value) => value).length;

  int get _total => _stages.fold(0, (sum, stage) => sum + stage.items.length);

  double get _progress => _total == 0 ? 0 : _completed / _total;

  int _parsePositive(TextEditingController controller, {int fallback = 1}) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value < 1) return fallback;
    return value;
  }

  List<String> _plannedCameraIps() {
    final count = _parsePositive(_cameraCountController);
    final raw = _firstCameraIpController.text.trim();
    final parts = raw.split('.');
    if (parts.length != 4) return const [];
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((v) => v == null || v < 0 || v > 255)) return const [];

    final prefix = '${octets[0]}.${octets[1]}.${octets[2]}.';
    final start = octets[3]!;
    final result = <String>[];
    for (var i = 0; i < count; i++) {
      final host = start + i;
      if (host > 254) break;
      result.add('$prefix$host');
    }
    return result;
  }

  String _keyFor(String stage, String item) => '$stage::$item';

  @override
  Widget build(BuildContext context) {
    final cameraCount = _parsePositive(_cameraCountController);
    final nvrChannels = _parsePositive(_nvrChannelsController);
    final ips = _plannedCameraIps();
    final capacityOk = nvrChannels >= cameraCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Camera System Setup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'New Camera System',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Build the plan first, then work through installation, configuration, and final commissioning.',
          ),
          const SizedBox(height: 16),
          _ProgressCard(
            progress: _progress,
            completed: _completed,
            total: _total,
          ),
          const SizedBox(height: 16),
          _sectionTitle(context, 'System setup'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _manufacturer,
                    decoration: const InputDecoration(
                      labelText: 'Manufacturer / ecosystem',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'Tiandy',
                              'Generic ONVIF',
                              'Hikvision',
                              'Dahua',
                              'Axis',
                              'Hanwha',
                              'Uniview',
                              'InVid',
                              'Other',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _manufacturer = value ?? _manufacturer),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cameraCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Camera count',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _nvrChannelsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'NVR channels',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _topology,
                    decoration: const InputDecoration(
                      labelText: 'Camera network topology',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'NVR PoE ports',
                              'External PoE switch',
                              'Mixed NVR PoE + external switch',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _topology = value ?? _topology),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _addressing,
                    decoration: const InputDecoration(
                      labelText: 'Addressing plan',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        const [
                              'Static camera IPs',
                              'DHCP reservations',
                              'NVR-managed private camera network',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _addressing = value ?? _addressing),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _VendorGuidance(manufacturer: _manufacturer, topology: _topology),
          const SizedBox(height: 16),
          _sectionTitle(context, 'IP plan'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nvrIpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'NVR LAN IP',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _gatewayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Gateway',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _firstCameraIpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'First camera IP',
                      helperText:
                          'LowVolt Pilot will increment the last octet.',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      capacityOk
                          ? '$cameraCount cameras fit within the $nvrChannels-channel NVR.'
                          : 'Warning: $cameraCount cameras exceed the $nvrChannels-channel NVR.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: capacityOk
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  if (ips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Planned addresses',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text('NVR: ${_nvrIpController.text.trim()}'),
                          Text('Gateway: ${_gatewayController.text.trim()}'),
                          const SizedBox(height: 6),
                          for (var i = 0; i < ips.length; i++)
                            Text('Camera ${i + 1}: ${ips[i]}'),
                          if (ips.length < cameraCount)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'Address range exceeded .254. Choose an earlier first camera IP.',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Guided commissioning'),
          const SizedBox(height: 8),
          for (final stage in _stages)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: Icon(stage.icon),
                title: Text(
                  stage.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${_stageCompleted(stage)}/${stage.items.length} complete',
                ),
                children: [
                  for (final item in stage.items)
                    CheckboxListTile(
                      value: _checks[_keyFor(stage.title, item)] ?? false,
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (value) {
                        setState(() {
                          _checks[_keyFor(stage.title, item)] = value ?? false;
                        });
                      },
                    ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Commissioning status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _completed == _total
                        ? 'All commissioning checks are complete. The next LowVolt Pilot milestone will save this result to a Job and generate the field report.'
                        : '$_completed of $_total checks complete. Work through each stage before closing out the system.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  int _stageCompleted(_CommissionStage stage) {
    return stage.items
        .where((item) => _checks[_keyFor(stage.title, item)] ?? false)
        .length;
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.completed,
    required this.total,
  });

  final double progress;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Commissioning progress',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$completed / $total'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

class _VendorGuidance extends StatelessWidget {
  const _VendorGuidance({required this.manufacturer, required this.topology});

  final String manufacturer;
  final String topology;

  @override
  Widget build(BuildContext context) {
    String text;
    if (manufacturer == 'Tiandy' && topology == 'NVR PoE ports') {
      text =
          'Tiandy note: some Tiandy PoE NVRs can activate, address, and add directly connected Tiandy cameras automatically. Verify the behavior of the exact NVR model before manually changing camera addresses.';
    } else if (manufacturer == 'Generic ONVIF') {
      text =
          'ONVIF note: confirm ONVIF is enabled on the camera, create/verify the ONVIF user if the manufacturer requires one, then verify stream compatibility before final recording tests.';
    } else {
      text =
          'Vendor-specific programming will be layered onto this workflow. For now, follow the universal network, recording, and commissioning checks and use the manufacturer interface for proprietary settings.';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _CommissionStage {
  const _CommissionStage({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;
}
