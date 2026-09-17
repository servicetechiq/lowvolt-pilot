import 'dart:math' as math;

enum CameraCoverageGoal {
  detect('Detect', 8, 'Determine that a person or object is present.'),
  observe(
    'Observe',
    20,
    'See characteristic details such as clothing and activity.',
  ),
  recognize(
    'Recognize',
    40,
    'Recognize a known person under suitable conditions.',
  ),
  identify(
    'Identify',
    80,
    'Capture stronger facial/detail evidence for identification.',
  );

  const CameraCoverageGoal(this.label, this.pixelsPerFoot, this.description);

  final String label;
  final double pixelsPerFoot;
  final String description;
}

enum CameraResolutionPreset {
  mp2('2 MP • 1920×1080', 1920),
  mp4('4 MP • 2688 px wide', 2688),
  mp5('5 MP • 2880 px wide', 2880),
  mp8('8 MP / 4K • 3840×2160', 3840);

  const CameraResolutionPreset(this.label, this.horizontalPixels);

  final String label;
  final int horizontalPixels;
}

class CameraDesignInput {
  const CameraDesignInput({
    required this.lengthFeet,
    required this.widthFeet,
    required this.mountHeightFeet,
    required this.goal,
    required this.resolution,
    required this.retentionDays,
    required this.averageBitrateMbps,
    required this.poeWattsPerCamera,
  });

  final double lengthFeet;
  final double widthFeet;
  final double mountHeightFeet;
  final CameraCoverageGoal goal;
  final CameraResolutionPreset resolution;
  final int retentionDays;
  final double averageBitrateMbps;
  final double poeWattsPerCamera;
}

class CameraDesignResult {
  const CameraDesignResult({
    required this.cameraCount,
    required this.maxSceneWidthFeet,
    required this.designSceneWidthFeet,
    required this.requiredHorizontalFovDegrees,
    required this.viewingDistanceFeet,
    required this.wallRunFeet,
    required this.mountingWall,
    required this.targetPixelDensity,
    required this.estimatedPixelDensity,
    required this.tiltDegrees,
    required this.nvrChannels,
    required this.storageTerabytes,
    required this.poeBudgetWatts,
    required this.lensGuidance,
    required this.notes,
  });

  final int cameraCount;
  final double maxSceneWidthFeet;
  final double designSceneWidthFeet;
  final double requiredHorizontalFovDegrees;
  final double viewingDistanceFeet;
  final double wallRunFeet;
  final String mountingWall;
  final double targetPixelDensity;
  final double estimatedPixelDensity;
  final double tiltDegrees;
  final int nvrChannels;
  final double storageTerabytes;
  final double poeBudgetWatts;
  final String lensGuidance;
  final List<String> notes;
}

class CameraDesignEngine {
  const CameraDesignEngine();

  static const double _coverageOverlapFactor = 0.85;
  static const double _maxPracticalHorizontalFovDegrees = 110;
  static const double _targetHeightFeet = 4.5;

  CameraDesignResult calculate(CameraDesignInput input) {
    _validate(input);

    // For a simple rectangular room, place cameras along the longer wall and
    // aim across the shorter dimension. This keeps the baseline predictable,
    // easy to explain, and easy to draw. Future layout modes can add corner,
    // corridor, perimeter, and custom floor-plan placement.
    final wallRun = math.max(input.lengthFeet, input.widthFeet);
    final viewingDistance = math.min(input.lengthFeet, input.widthFeet);
    final mountingWall = input.lengthFeet >= input.widthFeet
        ? 'Long wall (${_format(input.lengthFeet)} ft)'
        : 'Long wall (${_format(input.widthFeet)} ft)';

    final maxSceneWidth =
        input.resolution.horizontalPixels / input.goal.pixelsPerFoot;

    final maxWidthFromFov =
        2 *
        viewingDistance *
        math.tan(_degreesToRadians(_maxPracticalHorizontalFovDegrees / 2));

    final usableWidthPerCamera =
        math.min(maxSceneWidth, maxWidthFromFov) * _coverageOverlapFactor;

    var cameraCount = math.max(1, (wallRun / usableWidthPerCamera).ceil());

    // A pixel-density calculation alone can suggest one very wide overview
    // camera for a large room. For a practical room baseline, require at least
    // two viewpoints when the space is large enough that occlusion/blind spots
    // are likely to matter. This is intentionally a planning heuristic, not a
    // coverage guarantee.
    final area = input.lengthFeet * input.widthFeet;
    final minimumViewpoints =
        (math.min(input.lengthFeet, input.widthFeet) > 20 || area > 1000)
        ? 2
        : 1;
    cameraCount = math.max(cameraCount, minimumViewpoints);

    // Increase count until each camera can cover its assigned segment without
    // exceeding the practical wide-angle FOV limit.
    while (cameraCount < 64) {
      final segmentWidth = wallRun / cameraCount;
      final requiredFov = _horizontalFovDegrees(
        segmentWidth: segmentWidth,
        distance: viewingDistance,
      );
      if (requiredFov <= _maxPracticalHorizontalFovDegrees) break;
      cameraCount++;
    }

    final designSceneWidth = wallRun / cameraCount;
    final requiredFov = _horizontalFovDegrees(
      segmentWidth: designSceneWidth,
      distance: viewingDistance,
    );
    final estimatedPixelDensity =
        input.resolution.horizontalPixels / designSceneWidth;

    final verticalDrop = math.max(
      0.0,
      input.mountHeightFeet - _targetHeightFeet,
    );
    final tiltDegrees =
        math.atan2(verticalDrop, viewingDistance) * 180 / math.pi;

    final nvrChannels = _recommendedNvrChannels(cameraCount);
    final storageTerabytes = _storageTerabytes(
      cameras: cameraCount,
      averageBitrateMbps: input.averageBitrateMbps,
      retentionDays: input.retentionDays,
    );
    final poeBudgetWatts = cameraCount * input.poeWattsPerCamera * 1.20;

    final notes = <String>[
      'Baseline assumes cameras are spaced evenly along the longer wall and aimed across the room. Larger rooms use at least two viewpoints to reduce obvious single-view blind spots.',
      'The ${input.goal.label.toLowerCase()} target is ${_format(input.goal.pixelsPerFoot)} px/ft. Lighting, motion, compression, focus, lens distortion, and camera angle can reduce usable detail.',
      'Allowing about 15% overlap reduces edge gaps between adjacent camera views.',
      'Storage is an estimate using ${_format(input.averageBitrateMbps)} Mbps average bitrate per camera for ${input.retentionDays} days. Actual VBR/event recording can differ substantially.',
      'PoE budget includes 20% headroom and should still be checked against the selected camera datasheets and switch per-port limits.',
    ];

    if (input.mountHeightFeet > 14) {
      notes.add(
        'The entered mounting height is relatively high. Verify face/detail angle at the target area before finalizing placement.',
      );
    }

    if (requiredFov > 95) {
      notes.add(
        'This layout needs a very wide view. Consider an additional camera if edge distortion or identification quality matters.',
      );
    }

    return CameraDesignResult(
      cameraCount: cameraCount,
      maxSceneWidthFeet: maxSceneWidth,
      designSceneWidthFeet: designSceneWidth,
      requiredHorizontalFovDegrees: requiredFov,
      viewingDistanceFeet: viewingDistance,
      wallRunFeet: wallRun,
      mountingWall: mountingWall,
      targetPixelDensity: input.goal.pixelsPerFoot,
      estimatedPixelDensity: estimatedPixelDensity,
      tiltDegrees: tiltDegrees,
      nvrChannels: nvrChannels,
      storageTerabytes: storageTerabytes,
      poeBudgetWatts: poeBudgetWatts,
      lensGuidance: _lensGuidance(requiredFov),
      notes: notes,
    );
  }

  void _validate(CameraDesignInput input) {
    if (input.lengthFeet <= 0 ||
        input.widthFeet <= 0 ||
        input.mountHeightFeet <= 0 ||
        input.retentionDays <= 0 ||
        input.averageBitrateMbps <= 0 ||
        input.poeWattsPerCamera <= 0) {
      throw ArgumentError('All design inputs must be greater than zero.');
    }
  }

  double _horizontalFovDegrees({
    required double segmentWidth,
    required double distance,
  }) {
    return 2 * math.atan(segmentWidth / (2 * distance)) * 180 / math.pi;
  }

  int _recommendedNvrChannels(int cameras) {
    const channelSizes = [4, 8, 16, 32, 64];
    for (final size in channelSizes) {
      if (cameras <= size) return size;
    }
    return ((cameras / 16).ceil()) * 16;
  }

  double _storageTerabytes({
    required int cameras,
    required double averageBitrateMbps,
    required int retentionDays,
  }) {
    const secondsPerDay = 86400;
    final totalBits =
        cameras * averageBitrateMbps * 1000000 * secondsPerDay * retentionDays;
    return totalBits / 8 / 1000000000000;
  }

  String _lensGuidance(double horizontalFovDegrees) {
    if (horizontalFovDegrees >= 95) {
      return 'Very wide view. Start by evaluating a wide-angle lens (often around 2.8 mm on many common camera formats), but confirm the actual camera datasheet/FOV.';
    }
    if (horizontalFovDegrees >= 75) {
      return 'Wide view. Many fixed-lens cameras in the roughly 2.8–4 mm range may fit, depending on sensor size. Match the published horizontal FOV.';
    }
    if (horizontalFovDegrees >= 50) {
      return 'Moderate view. Consider a narrower fixed lens or varifocal camera and match the published horizontal FOV to the design.';
    }
    return 'Tighter view. A varifocal/telephoto option is likely more appropriate; select by published horizontal FOV rather than focal length alone.';
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  String _format(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }
}
