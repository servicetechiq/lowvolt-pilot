import 'package:flutter/material.dart';

class CameraTroubleshootPage extends StatefulWidget {
  const CameraTroubleshootPage({super.key});

  @override
  State<CameraTroubleshootPage> createState() => _CameraTroubleshootPageState();
}

class _CameraTroubleshootPageState extends State<CameraTroubleshootPage> {
  String _manufacturer = 'Generic / ONVIF';
  _DiagnosticIssue? _issue;
  String? _currentNodeId;
  _DiagnosticResult? _result;
  final List<_HistoryEntry> _history = [];

  void _selectIssue(_DiagnosticIssue issue) {
    setState(() {
      _issue = issue;
      _currentNodeId = issue.startNodeId;
      _result = null;
      _history.clear();
    });
  }

  void _resetIssue() {
    setState(() {
      _issue = null;
      _currentNodeId = null;
      _result = null;
      _history.clear();
    });
  }

  void _answer(bool yes) {
    final issue = _issue;
    final nodeId = _currentNodeId;
    if (issue == null || nodeId == null) return;

    final node = issue.nodes[nodeId];
    if (node == null) return;

    final target = yes ? node.yesTarget : node.noTarget;
    setState(() {
      _history.add(_HistoryEntry(nodeId: nodeId, answeredYes: yes));
      if (target.startsWith('result:')) {
        _result = issue.results[target.substring('result:'.length)];
      } else {
        _currentNodeId = target;
      }
    });
  }

  void _backOneStep() {
    if (_history.isEmpty) return;
    setState(() {
      final previous = _history.removeLast();
      _currentNodeId = previous.nodeId;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Troubleshooting')),
      body: _issue == null
          ? _buildIssuePicker(context)
          : _buildDiagnostic(context),
    );
  }

  Widget _buildIssuePicker(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Troubleshoot Existing System',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Start with what the technician can observe. LowVolt Pilot will narrow the fault one check at a time.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _manufacturer,
          decoration: const InputDecoration(
            labelText: 'Manufacturer / ecosystem',
            border: OutlineInputBorder(),
          ),
          items:
              const [
                    'Generic / ONVIF',
                    'Tiandy',
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
        _VendorNote(manufacturer: _manufacturer),
        const SizedBox(height: 20),
        Text(
          'What is the symptom?',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final issue in _issues) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Icon(issue.icon),
              title: Text(issue.title),
              subtitle: Text(issue.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _selectIssue(issue),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildDiagnostic(BuildContext context) {
    final issue = _issue!;
    final node = _currentNodeId == null ? null : issue.nodes[_currentNodeId];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(issue.icon, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_manufacturer • ${_history.length} checks answered',
                      ),
                    ],
                  ),
                ),
                TextButton(onPressed: _resetIssue, child: const Text('Change')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_result != null)
          _ResultCard(result: _result!)
        else if (node != null)
          _QuestionCard(
            stepNumber: _history.length + 1,
            node: node,
            onYes: () => _answer(true),
            onNo: () => _answer(false),
          ),
        const SizedBox(height: 12),
        if (_history.isNotEmpty)
          OutlinedButton.icon(
            onPressed: _backOneStep,
            icon: const Icon(Icons.undo),
            label: const Text('Back one check'),
          ),
        if (_result != null) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _resetIssue,
            icon: const Icon(Icons.troubleshoot_outlined),
            label: const Text('Troubleshoot another symptom'),
          ),
        ],
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.stepNumber,
    required this.node,
    required this.onYes,
    required this.onNo,
  });

  final int stepNumber;
  final _DecisionNode node;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHECK $stepNumber',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              node.question,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(node.detail),
            if (node.howToCheck.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'How to check',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final item in node.howToCheck)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_circle_outline, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onYes,
                    child: const Text('Yes'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onNo,
                    child: const Text('No'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _DiagnosticResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.flag_outlined, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Likely fault area',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(result.summary),
            const SizedBox(height: 16),
            Text(
              'Next actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < result.actions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(result.actions[i])),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VendorNote extends StatelessWidget {
  const _VendorNote({required this.manufacturer});

  final String manufacturer;

  @override
  Widget build(BuildContext context) {
    final text = switch (manufacturer) {
      'Tiandy' =>
        'Tiandy note: cameras connected directly to some NVR PoE ports may live on the NVR\'s private camera network. A camera can be healthy and recording even when it is not directly reachable from the customer LAN.',
      'Hikvision' =>
        'Hikvision note: activation state, SADP-visible addressing, channel protocol, and NVR PoE private-network behavior can all affect discovery and adding cameras.',
      'Dahua' =>
        'Dahua note: check device initialization, IP/subnet, credentials, and whether the NVR channel is using the expected private/custom protocol or ONVIF.',
      'Axis' =>
        'Axis note: verify network reachability, credentials, time, and stream/profile compatibility before treating an NVR-side failure as a camera hardware fault.',
      _ =>
        'Cross-vendor workflow: verify power, link, addressing, credentials, protocol, time, recording, and storage in that order. Manufacturer-specific menus may use different names.',
    };

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

class _DiagnosticIssue {
  const _DiagnosticIssue({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startNodeId,
    required this.nodes,
    required this.results,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String startNodeId;
  final Map<String, _DecisionNode> nodes;
  final Map<String, _DiagnosticResult> results;
}

class _DecisionNode {
  const _DecisionNode({
    required this.question,
    required this.detail,
    required this.yesTarget,
    required this.noTarget,
    this.howToCheck = const [],
  });

  final String question;
  final String detail;
  final String yesTarget;
  final String noTarget;
  final List<String> howToCheck;
}

class _DiagnosticResult {
  const _DiagnosticResult({
    required this.title,
    required this.summary,
    required this.actions,
  });

  final String title;
  final String summary;
  final List<String> actions;
}

class _HistoryEntry {
  const _HistoryEntry({required this.nodeId, required this.answeredYes});

  final String nodeId;
  final bool answeredYes;
}

const _issues = <_DiagnosticIssue>[
  _DiagnosticIssue(
    title: 'Camera offline',
    subtitle: 'No live image or the NVR reports the camera offline.',
    icon: Icons.videocam_off_outlined,
    startNodeId: 'power',
    nodes: {
      'power': _DecisionNode(
        question: 'Is the camera receiving power?',
        detail:
            'Start at the physical layer before changing IP or NVR settings.',
        howToCheck: [
          'Check PoE status or camera power indicator.',
          'If possible, verify the port is delivering PoE and is not disabled.',
          'For 12 VDC cameras, verify voltage at the camera end under load.',
        ],
        yesTarget: 'link',
        noTarget: 'result:power',
      ),
      'link': _DecisionNode(
        question: 'Do you have an Ethernet link for this camera?',
        detail:
            'Power without link usually points to cabling, termination, port, or camera NIC trouble.',
        howToCheck: [
          'Check link/activity LEDs on the switch or NVR PoE port.',
          'Try a known-good patch lead/port if practical.',
        ],
        yesTarget: 'ping',
        noTarget: 'result:link',
      ),
      'ping': _DecisionNode(
        question: 'Can you ping the camera from the same network?',
        detail:
            'A successful ping confirms basic IP reachability but not credentials or video protocol.',
        yesTarget: 'nvr',
        noTarget: 'discover',
      ),
      'discover': _DecisionNode(
        question:
            'Can you discover the camera IP/MAC with a vendor or network discovery tool?',
        detail:
            'Discovery can reveal a wrong subnet, default address, DHCP address, or duplicate-IP situation.',
        yesTarget: 'result:addressing',
        noTarget: 'result:path',
      ),
      'nvr': _DecisionNode(
        question: 'Does the NVR show an authentication or protocol error?',
        detail:
            'If the camera is reachable but the NVR still shows it offline, move up to credentials/protocol compatibility.',
        yesTarget: 'result:auth',
        noTarget: 'result:nvrchannel',
      ),
    },
    results: {
      'power': _DiagnosticResult(
        title: 'Power / PoE problem',
        summary:
            'The camera is not getting usable power, so network troubleshooting should wait.',
        actions: [
          'Verify the switch/NVR PoE port is enabled and has enough remaining PoE budget.',
          'Test the cable and terminations, then try a known-good PoE port or injector.',
          'If 12 VDC powered, measure voltage at the camera while connected.',
          'If power is present but the camera never boots, suspect the camera or its power input.',
        ],
      ),
      'link': _DiagnosticResult(
        title: 'Physical Ethernet path',
        summary:
            'The camera appears powered but the Ethernet link is not establishing.',
        actions: [
          'Test the cable run and both terminations.',
          'Try a known-good short cable and known-good switch/NVR port.',
          'Confirm the port speed/duplex is not manually forced to an incompatible setting.',
          'If link still never comes up on known-good infrastructure, suspect the camera NIC.',
        ],
      ),
      'addressing': _DiagnosticResult(
        title: 'IP addressing / subnet mismatch',
        summary:
            'The camera exists on the network but is not reachable at the address you expected.',
        actions: [
          'Record the discovered IP and MAC before changing anything.',
          'Check for a default IP, DHCP-assigned IP, wrong subnet mask, or duplicate address.',
          'Temporarily place the commissioning laptop on the camera subnet if needed.',
          'Assign the planned static address and verify ping before re-adding it to the NVR.',
        ],
      ),
      'path': _DiagnosticResult(
        title: 'Network path or failed camera',
        summary:
            'There is power/link evidence but the device cannot be found or reached.',
        actions: [
          'Connect locally on the same switch/PoE segment and remove routers/VLANs from the test path.',
          'Check VLAN membership, port isolation, ACLs, and NVR private-PoE behavior.',
          'Factory-reset only when credentials/configuration are known to be recoverable.',
          'Test the camera on a known-good bench network to separate infrastructure from device failure.',
        ],
      ),
      'auth': _DiagnosticResult(
        title: 'Credentials / protocol mismatch',
        summary:
            'The camera is reachable, but the NVR cannot authenticate or negotiate the expected camera protocol.',
        actions: [
          'Verify username/password by logging directly into the camera.',
          'Confirm the camera is activated and ONVIF is enabled if the NVR uses ONVIF.',
          'Verify the NVR channel protocol and port match the camera.',
          'Remove and re-add the channel only after recording the existing settings.',
        ],
      ),
      'nvrchannel': _DiagnosticResult(
        title: 'NVR channel / stream configuration',
        summary:
            'The camera is network-reachable and no clear authentication fault is reported.',
        actions: [
          'Verify the NVR channel points to the correct IP and protocol.',
          'Check whether the requested codec/resolution/profile is supported by the NVR.',
          'Test the camera main and sub stream directly if possible.',
          'Try a fresh unused NVR channel to rule out a stale channel configuration.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Power but no network',
    subtitle: 'Camera powers up, but there is no usable network connection.',
    icon: Icons.lan_outlined,
    startNodeId: 'link',
    nodes: {
      'link': _DecisionNode(
        question: 'Does the switch/NVR port show Ethernet link?',
        detail: 'This separates cabling/PHY problems from IP-layer problems.',
        yesTarget: 'discover',
        noTarget: 'result:physical',
      ),
      'discover': _DecisionNode(
        question: 'Can the camera be discovered by MAC/vendor discovery?',
        detail:
            'Discovery may work even when the camera is on the wrong IP subnet.',
        yesTarget: 'ping',
        noTarget: 'result:segment',
      ),
      'ping': _DecisionNode(
        question: 'After using the discovered address, can you ping it?',
        detail:
            'If discovery works but ping does not, check your own adapter/subnet and duplicate IPs.',
        yesTarget: 'result:reachable',
        noTarget: 'result:ip',
      ),
    },
    results: {
      'physical': _DiagnosticResult(
        title: 'Cable / port / camera NIC',
        summary: 'Power is present but Ethernet link is not negotiating.',
        actions: [
          'Test the cable and terminations.',
          'Try a known-good port and patch cable.',
          'Check for water damage or damaged RJ45 hardware at the camera.',
          'Bench-test the camera before replacing it.',
        ],
      ),
      'segment': _DiagnosticResult(
        title: 'Wrong network segment or isolated port',
        summary:
            'The camera is not visible to discovery from the current commissioning network.',
        actions: [
          'Confirm the camera is not behind an NVR private PoE network.',
          'Check VLAN, port isolation, wireless bridge path, and switch uplinks.',
          'Connect a laptop directly to the local camera segment and scan again.',
        ],
      ),
      'ip': _DiagnosticResult(
        title: 'Local IP configuration problem',
        summary:
            'The device can be discovered but IP communication is failing.',
        actions: [
          'Put the laptop in the same subnet as the discovered camera.',
          'Check subnet mask and duplicate IP conflicts.',
          'Assign a known-good static IP, then retest ping and web access.',
        ],
      ),
      'reachable': _DiagnosticResult(
        title: 'Network is working',
        summary:
            'Basic Ethernet and IP communication are good. Continue with application/protocol checks.',
        actions: [
          'Test the camera web interface.',
          'Verify ONVIF/vendor protocol and credentials.',
          'If the NVR still cannot connect, troubleshoot the NVR channel configuration.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Camera will not add to NVR',
    subtitle:
        'Camera is installed, but the recorder will not bring the channel online.',
    icon: Icons.add_to_queue_outlined,
    startNodeId: 'ping',
    nodes: {
      'ping': _DecisionNode(
        question: 'Can the NVR network reach the camera IP?',
        detail:
            'Do not chase credentials until the recorder and camera can actually route to each other.',
        yesTarget: 'login',
        noTarget: 'result:network',
      ),
      'login': _DecisionNode(
        question:
            'Can you log directly into the camera with the same credentials?',
        detail: 'This verifies the account before entering it into the NVR.',
        yesTarget: 'protocol',
        noTarget: 'result:credentials',
      ),
      'protocol': _DecisionNode(
        question: 'Is the NVR using the correct protocol/port for this camera?',
        detail:
            'Use the native vendor protocol when supported; otherwise verify ONVIF is enabled and configured.',
        yesTarget: 'result:compat',
        noTarget: 'result:protocol',
      ),
    },
    results: {
      'network': _DiagnosticResult(
        title: 'Recorder-to-camera network path',
        summary: 'The NVR cannot reach the camera at the IP layer.',
        actions: [
          'Verify both sides are on routable subnets and the camera IP is correct.',
          'Check NVR dual-NIC/private-PoE addressing and switch VLANs.',
          'Ping from the closest equivalent network segment and correct routing/addressing first.',
        ],
      ),
      'credentials': _DiagnosticResult(
        title: 'Activation / credentials',
        summary: 'The camera account cannot be authenticated directly.',
        actions: [
          'Confirm the camera is activated/initialized.',
          'Correct the username/password or recover/reset credentials using the supported vendor process.',
          'Verify account lockout has not occurred after repeated failed logins.',
        ],
      ),
      'protocol': _DiagnosticResult(
        title: 'Wrong channel protocol or port',
        summary:
            'The NVR channel is not using a connection method that matches the camera.',
        actions: [
          'Select the native vendor protocol when the recorder supports it.',
          'For cross-vendor cameras, enable ONVIF and use a dedicated ONVIF account if required.',
          'Confirm HTTP/HTTPS, RTSP, server, and ONVIF ports are not being confused.',
        ],
      ),
      'compat': _DiagnosticResult(
        title: 'Stream / compatibility settings',
        summary:
            'Network, credentials, and protocol appear correct, leaving stream compatibility or recorder limits.',
        actions: [
          'Temporarily lower resolution/frame rate and choose a broadly supported codec such as H.264.',
          'Check the NVR per-channel and total incoming-bandwidth limits.',
          'Try a new unused channel to eliminate stale configuration.',
          'Check vendor firmware compatibility before updating production equipment.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Live view works, but no recording',
    subtitle: 'Video is visible now, but playback has no recorded footage.',
    icon: Icons.video_file_outlined,
    startNodeId: 'disk',
    nodes: {
      'disk': _DecisionNode(
        question: 'Does the NVR report the recording disk/storage as healthy?',
        detail:
            'A working live stream does not prove the recorder has writable storage.',
        yesTarget: 'schedule',
        noTarget: 'result:storage',
      ),
      'schedule': _DecisionNode(
        question: 'Is a recording schedule enabled for this channel right now?',
        detail:
            'Check the correct day, time block, and record type for the affected channel.',
        yesTarget: 'manual',
        noTarget: 'result:schedule',
      ),
      'manual': _DecisionNode(
        question:
            'If you start manual/continuous recording, does new playback appear?',
        detail:
            'This separates the recording engine/storage path from schedule/event logic.',
        yesTarget: 'result:event',
        noTarget: 'result:recordengine',
      ),
    },
    results: {
      'storage': _DiagnosticResult(
        title: 'Recorder storage',
        summary:
            'The live camera path works, but the NVR does not have healthy writable storage.',
        actions: [
          'Check HDD status, initialization/format state, SMART/error warnings, and available capacity.',
          'Confirm overwrite/retention behavior is configured as intended.',
          'Do not format a disk containing needed evidence without authorization and backup considerations.',
        ],
      ),
      'schedule': _DiagnosticResult(
        title: 'Recording schedule',
        summary:
            'The channel is online but the current schedule is not telling the NVR to record.',
        actions: [
          'Enable continuous or event recording for the required periods.',
          'Confirm the schedule was copied/applied to the intended channel.',
          'Verify the NVR clock/time zone so the active schedule matches real local time.',
        ],
      ),
      'event': _DiagnosticResult(
        title: 'Event / schedule logic',
        summary:
            'Manual recording works, so storage and the basic recording engine are functional.',
        actions: [
          'Review motion/event enablement and channel linkage.',
          'Check event arming schedule and recording schedule.',
          'Trigger an event while watching the NVR event/status indicators, then verify playback.',
        ],
      ),
      'recordengine': _DiagnosticResult(
        title: 'NVR recording path',
        summary: 'Even forced/manual recording is not producing playback.',
        actions: [
          'Recheck disk health and channel record status.',
          'Confirm the stream codec/resolution is supported for recording, not just live display.',
          'Test another channel/camera to determine whether the fault is channel-specific or recorder-wide.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Motion recording not working',
    subtitle:
        'Continuous/live video is fine, but motion events are not being recorded.',
    icon: Icons.directions_run_outlined,
    startNodeId: 'base',
    nodes: {
      'base': _DecisionNode(
        question: 'Does continuous or manual recording work for this camera?',
        detail:
            'Confirm the base recording path before troubleshooting motion logic.',
        yesTarget: 'detect',
        noTarget: 'result:base',
      ),
      'detect': _DecisionNode(
        question:
            'Does the camera/NVR show a motion event when you move in the scene?',
        detail:
            'Look for the motion indicator or event log while testing a clearly visible movement.',
        yesTarget: 'linkage',
        noTarget: 'result:detection',
      ),
      'linkage': _DecisionNode(
        question: 'Is that motion event linked to recording for this channel?',
        detail: 'Detection and recording are often separate settings.',
        yesTarget: 'result:schedule',
        noTarget: 'result:linkage',
      ),
    },
    results: {
      'base': _DiagnosticResult(
        title: 'Base recording problem',
        summary: 'Motion cannot work until normal recording/storage works.',
        actions: [
          'Fix disk health, stream compatibility, and recording schedule first.',
          'Verify manual recording produces searchable playback before returning to motion setup.',
        ],
      ),
      'detection': _DiagnosticResult(
        title: 'Motion detection configuration',
        summary: 'The system is not detecting the motion event.',
        actions: [
          'Enable motion detection and confirm the active detection region covers the test area.',
          'Adjust sensitivity/threshold conservatively and verify the arming schedule.',
          'For smart/AI events, confirm the selected event type is supported by both camera and NVR.',
        ],
      ),
      'linkage': _DiagnosticResult(
        title: 'Event-to-record linkage',
        summary:
            'Motion is detected, but the event is not commanding the channel to record.',
        actions: [
          'Enable record-channel linkage for the motion event.',
          'Confirm the linked channel number is correct.',
          'Check whether configuration exists in the camera, NVR, or both and avoid conflicting duplicate rules.',
        ],
      ),
      'schedule': _DiagnosticResult(
        title: 'Motion arming / record schedule',
        summary:
            'Detection and linkage appear correct; the remaining common cause is schedule/time logic.',
        actions: [
          'Verify the motion arming schedule and event-recording schedule include the current time.',
          'Confirm camera and NVR clocks, time zones, and DST settings agree.',
          'Trigger a test event and immediately search playback around the exact timestamp.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Playback is missing',
    subtitle:
        'Recording may exist, but searches are not showing the expected footage.',
    icon: Icons.history_outlined,
    startNodeId: 'indicator',
    nodes: {
      'indicator': _DecisionNode(
        question: 'Does the NVR show that this channel is currently recording?',
        detail:
            'Check the record icon/status before assuming the search function is wrong.',
        yesTarget: 'time',
        noTarget: 'result:notrecording',
      ),
      'time': _DecisionNode(
        question: 'Are the NVR and camera date/time correct?',
        detail:
            'A one-day or time-zone error can make valid footage appear to be missing.',
        yesTarget: 'filter',
        noTarget: 'result:time',
      ),
      'filter': _DecisionNode(
        question:
            'Are you searching the correct channel and record type without restrictive filters?',
        detail:
            'Event-only, smart-event, or channel filters can hide otherwise valid recordings.',
        yesTarget: 'result:index',
        noTarget: 'result:filter',
      ),
    },
    results: {
      'notrecording': _DiagnosticResult(
        title: 'Channel is not recording now',
        summary:
            'The missing playback is probably a recording configuration/storage issue, not a search issue.',
        actions: [
          'Check disk health and channel recording schedule.',
          'Start manual recording and verify that fresh playback appears.',
          'Then correct continuous/event schedule settings as needed.',
        ],
      ),
      'time': _DiagnosticResult(
        title: 'Clock / time-zone mismatch',
        summary:
            'Footage may be stored under a different timestamp than the technician expects.',
        actions: [
          'Correct NVR time zone, date, NTP, and DST settings.',
          'Correct camera time/NTP where cameras timestamp their own stream.',
          'Search the old/incorrect time range before assuming historical footage is gone.',
        ],
      ),
      'filter': _DiagnosticResult(
        title: 'Playback search filters',
        summary: 'The search is excluding the footage you are trying to find.',
        actions: [
          'Clear event/smart filters and search all recording types.',
          'Verify the selected camera/channel and date range.',
          'Zoom the timeline around a known test recording.',
        ],
      ),
      'index': _DiagnosticResult(
        title: 'Playback index / storage anomaly',
        summary:
            'The recorder says it is recording and the search inputs are correct, but footage still does not appear.',
        actions: [
          'Create a new manual test recording and search for it immediately.',
          'Compare playback from local NVR UI versus web/mobile client.',
          'Review disk errors and recorder logs; a damaged index/database may require vendor-specific recovery steps.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Wrong date or time',
    subtitle: 'Camera or recorded video timestamps are incorrect.',
    icon: Icons.schedule_outlined,
    startNodeId: 'nvr',
    nodes: {
      'nvr': _DecisionNode(
        question: 'Is the NVR clock itself correct?',
        detail:
            'Use the recorder as the first reference point because it often provides or controls time for the system.',
        yesTarget: 'camera',
        noTarget: 'result:nvrtime',
      ),
      'camera': _DecisionNode(
        question:
            'Does the affected camera show the same correct time when viewed directly?',
        detail:
            'This separates recorder overlay/search time from the camera clock embedded in the stream.',
        yesTarget: 'result:overlay',
        noTarget: 'result:cameratime',
      ),
    },
    results: {
      'nvrtime': _DiagnosticResult(
        title: 'NVR time configuration',
        summary:
            'The recorder clock is wrong, so schedules and playback searches may also be shifted.',
        actions: [
          'Set the correct time zone first, then configure reliable NTP.',
          'Verify DST behavior for the site.',
          'After synchronization, confirm recording schedules still match intended local time.',
        ],
      ),
      'cameratime': _DiagnosticResult(
        title: 'Camera time / NTP configuration',
        summary:
            'The recorder is correct but the camera has its own incorrect clock.',
        actions: [
          'Set camera time zone and NTP source.',
          'If supported, synchronize camera time from the NVR or common site NTP server.',
          'Check whether an isolated NVR PoE camera network can actually reach the configured NTP server.',
        ],
      ),
      'overlay': _DiagnosticResult(
        title: 'Overlay / client / playback presentation',
        summary:
            'Both device clocks are correct, so the visible wrong time may be an overlay or client interpretation issue.',
        actions: [
          'Check camera OSD overlay configuration.',
          'Check mobile/web client time-zone behavior.',
          'Confirm whether the complaint concerns the burned-in camera timestamp or the NVR playback timeline.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Poor night image',
    subtitle: 'Image is dark, noisy, washed out, foggy, or unusable at night.',
    icon: Icons.nightlight_outlined,
    startNodeId: 'ir',
    nodes: {
      'ir': _DecisionNode(
        question: 'Is IR/white-light illumination turning on as expected?',
        detail:
            'A night image cannot be evaluated properly until the intended illuminator is operating.',
        yesTarget: 'reflection',
        noTarget: 'result:illumination',
      ),
      'reflection': _DecisionNode(
        question: 'Is the image washed out, hazy, or bright around the edges?',
        detail:
            'Nearby surfaces, dirty domes, spider webs, soffits, or glass commonly reflect IR back into the lens.',
        yesTarget: 'result:reflection',
        noTarget: 'detail',
      ),
      'detail': _DecisionNode(
        question:
            'Is the image mostly dark/noisy rather than reflected or washed out?',
        detail:
            'This points toward insufficient scene light, exposure limits, distance, or camera capability.',
        yesTarget: 'result:lowlight',
        noTarget: 'result:focus',
      ),
    },
    results: {
      'illumination': _DiagnosticResult(
        title: 'Night illuminator / mode',
        summary:
            'The camera is not entering or powering the intended night mode correctly.',
        actions: [
          'Check day/night mode, IR/white-light settings, and schedules.',
          'Verify PoE/power is adequate when illuminators switch on.',
          'Check for stuck IR-cut filter behavior or hardware failure.',
        ],
      ),
      'reflection': _DiagnosticResult(
        title: 'IR reflection / contamination',
        summary:
            'The camera is illuminating something close to the lens and reflecting light back into the image.',
        actions: [
          'Clean the dome/lens cover and remove protective film.',
          'Remove spider webs and check for moisture/condensation.',
          'Re-aim away from walls, soffits, poles, glass, or other close reflective surfaces.',
          'Reduce built-in IR or use external illumination when the scene geometry requires it.',
        ],
      ),
      'lowlight': _DiagnosticResult(
        title: 'Insufficient usable light / exposure',
        summary:
            'The camera has entered night mode, but the scene does not have enough usable light for the required detail.',
        actions: [
          'Review exposure/shutter, gain, WDR, noise-reduction, and smart-IR settings.',
          'Check whether the target is beyond the practical IR range.',
          'Add or reposition illumination, or use a camera designed for the required low-light distance/detail.',
        ],
      ),
      'focus': _DiagnosticResult(
        title: 'Focus / motion / scene setting',
        summary:
            'Illumination is present and there is no obvious washout, so check focus and night exposure behavior.',
        actions: [
          'Verify focus at night; some lenses shift slightly between visible and IR wavelengths.',
          'Check shutter speed for motion blur.',
          'Compare a stationary target with a moving target to separate focus from exposure issues.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Intermittent camera connection',
    subtitle: 'Camera drops offline, freezes, or reconnects unpredictably.',
    icon: Icons.sync_problem_outlined,
    startNodeId: 'power',
    nodes: {
      'power': _DecisionNode(
        question:
            'Do drops correlate with IR/night mode, heaters, PTZ movement, or other higher-power operation?',
        detail:
            'Intermittent PoE budget or voltage drop can look exactly like a network problem.',
        yesTarget: 'result:power',
        noTarget: 'packet',
      ),
      'packet': _DecisionNode(
        question: 'Do you see packet loss or link flaps during the failure?',
        detail:
            'A continuous ping and switch-port counters can reveal a marginal physical/network path.',
        yesTarget: 'result:network',
        noTarget: 'load',
      ),
      'load': _DecisionNode(
        question:
            'Do failures happen mainly when many cameras/streams are active?',
        detail:
            'Load-dependent faults point toward bandwidth, switch uplink, NVR ingest, or decode limits.',
        yesTarget: 'result:bandwidth',
        noTarget: 'result:device',
      ),
    },
    results: {
      'power': _DiagnosticResult(
        title: 'Marginal PoE / power',
        summary: 'The camera becomes unstable when its power draw increases.',
        actions: [
          'Check switch PoE budget and per-port power class/output.',
          'Test voltage/power with a shorter known-good cable or closer injector.',
          'Inspect long runs, poor terminations, corrosion, and underspec cable.',
        ],
      ),
      'network': _DiagnosticResult(
        title: 'Physical network instability',
        summary:
            'Packet loss or link renegotiation is occurring when the camera drops.',
        actions: [
          'Inspect switch port errors, CRCs, link events, and cable test results.',
          'Replace suspect patch leads/terminations and test another port.',
          'For wireless bridges, check RSSI/SNR, interference, alignment, and capacity.',
        ],
      ),
      'bandwidth': _DiagnosticResult(
        title: 'Bandwidth / recorder capacity',
        summary: 'The fault appears when aggregate system load increases.',
        actions: [
          'Calculate aggregate camera bitrate against switch uplinks and NVR incoming-bandwidth limits.',
          'Reduce unnecessary frame rate/bitrate or use appropriate sub streams for live multi-view.',
          'Check NVR decode/display limits separately from recording ingest limits.',
        ],
      ),
      'device': _DiagnosticResult(
        title: 'Camera / firmware / environmental instability',
        summary:
            'Power and network symptoms are not obvious, so isolate the device itself.',
        actions: [
          'Bench-test the camera on a short known-good cable and stable PoE source.',
          'Review camera/NVR logs around the disconnect time.',
          'Check temperature, moisture, connectors, and firmware release notes before considering an update.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Cannot open camera web page',
    subtitle:
        'Camera may be online, but its local configuration page will not load.',
    icon: Icons.web_asset_off_outlined,
    startNodeId: 'ping',
    nodes: {
      'ping': _DecisionNode(
        question: 'Can you ping the camera IP?',
        detail:
            'First confirm that the address is reachable from the device you are using.',
        yesTarget: 'port',
        noTarget: 'result:network',
      ),
      'port': _DecisionNode(
        question: 'Does HTTP or HTTPS respond on the expected management port?',
        detail:
            'Some cameras move HTTPS/HTTP to non-default ports or disable one of them.',
        yesTarget: 'result:browser',
        noTarget: 'result:service',
      ),
    },
    results: {
      'network': _DiagnosticResult(
        title: 'IP reachability',
        summary:
            'The browser cannot work until the commissioning device can route to the camera.',
        actions: [
          'Verify IP/subnet and whether the camera is on an NVR private PoE network.',
          'Move the laptop/phone onto the correct local segment if needed.',
          'Check VLANs and duplicate IP conflicts.',
        ],
      ),
      'service': _DiagnosticResult(
        title: 'Management port / web service',
        summary:
            'The camera answers at the IP layer but not on the expected web-management port.',
        actions: [
          'Confirm the configured HTTP/HTTPS port using vendor discovery/configuration tools.',
          'Try HTTPS if HTTP is disabled, or the documented custom management port.',
          'Check ACL/firewall settings and verify the device has completed booting.',
        ],
      ),
      'browser': _DiagnosticResult(
        title: 'Browser / certificate / legacy UI issue',
        summary:
            'The management service responds, so the remaining problem is likely browser-side or UI compatibility.',
        actions: [
          'Try both the explicit http:// and https:// address with the correct port.',
          'Check certificate warnings and browser security blocks.',
          'For legacy camera interfaces, try a vendor-supported browser/client rather than assuming the camera is offline.',
        ],
      ),
    },
  ),
  _DiagnosticIssue(
    title: 'Bandwidth or stream problem',
    subtitle:
        'Video stutters, multi-view struggles, or streams fail under load.',
    icon: Icons.speed_outlined,
    startNodeId: 'single',
    nodes: {
      'single': _DecisionNode(
        question: 'Does a single camera main stream work smoothly by itself?',
        detail:
            'A good single stream but poor multi-camera performance points toward aggregate capacity rather than one camera.',
        yesTarget: 'multi',
        noTarget: 'result:camera',
      ),
      'multi': _DecisionNode(
        question:
            'Does the problem appear mainly when multiple cameras are displayed or recorded?',
        detail: 'Compare aggregate bitrate with network and recorder limits.',
        yesTarget: 'result:aggregate',
        noTarget: 'result:client',
      ),
    },
    results: {
      'camera': _DiagnosticResult(
        title: 'Single-camera stream / network quality',
        summary:
            'Even one stream is unstable, so troubleshoot that camera/path before system-wide capacity.',
        actions: [
          'Check packet loss and link errors.',
          'Temporarily reduce bitrate/frame rate and compare behavior.',
          'Verify codec/profile support and test a sub stream.',
        ],
      ),
      'aggregate': _DiagnosticResult(
        title: 'Aggregate bandwidth / NVR capacity',
        summary: 'The system degrades as more streams are active.',
        actions: [
          'Add camera bitrates and compare with switch uplinks and NVR incoming-bandwidth specifications.',
          'Use sub streams for multi-view and reserve main streams for recording/full-screen viewing.',
          'Check NVR decode-output limits separately from record bandwidth.',
        ],
      ),
      'client': _DiagnosticResult(
        title: 'Viewing client / decode path',
        summary:
            'The symptom is not strongly tied to aggregate recording load.',
        actions: [
          'Compare local NVR HDMI output, web client, and mobile app behavior.',
          'Check client hardware decode, browser compatibility, and requested stream type.',
          'Verify the issue is not remote-WAN bandwidth rather than the camera LAN.',
        ],
      ),
    },
  ),
];
