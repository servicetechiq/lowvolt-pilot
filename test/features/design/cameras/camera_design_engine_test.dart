import 'package:flutter_test/flutter_test.dart';
import 'package:lowvoltpilot/features/design/cameras/camera_design_engine.dart';

void main() {
  const engine = CameraDesignEngine();

  test('builds a practical observation plan for a 40x60 room', () {
    final result = engine.calculate(
      const CameraDesignInput(
        lengthFeet: 40,
        widthFeet: 60,
        mountHeightFeet: 12,
        goal: CameraCoverageGoal.observe,
        resolution: CameraResolutionPreset.mp4,
        retentionDays: 30,
        averageBitrateMbps: 4,
        poeWattsPerCamera: 8,
      ),
    );

    expect(result.cameraCount, greaterThanOrEqualTo(1));
    expect(
      result.estimatedPixelDensity,
      greaterThanOrEqualTo(CameraCoverageGoal.observe.pixelsPerFoot),
    );
    expect(result.requiredHorizontalFovDegrees, lessThanOrEqualTo(110));
    expect(result.nvrChannels, greaterThanOrEqualTo(result.cameraCount));
    expect(result.storageTerabytes, greaterThan(0));
    expect(result.poeBudgetWatts, greaterThan(0));
  });

  test('identification requires at least as many cameras as detection', () {
    CameraDesignResult run(CameraCoverageGoal goal) => engine.calculate(
      CameraDesignInput(
        lengthFeet: 40,
        widthFeet: 60,
        mountHeightFeet: 12,
        goal: goal,
        resolution: CameraResolutionPreset.mp4,
        retentionDays: 30,
        averageBitrateMbps: 4,
        poeWattsPerCamera: 8,
      ),
    );

    final detection = run(CameraCoverageGoal.detect);
    final identification = run(CameraCoverageGoal.identify);

    expect(
      identification.cameraCount,
      greaterThanOrEqualTo(detection.cameraCount),
    );
  });

  test('rejects zero or negative dimensions', () {
    expect(
      () => engine.calculate(
        const CameraDesignInput(
          lengthFeet: 0,
          widthFeet: 60,
          mountHeightFeet: 12,
          goal: CameraCoverageGoal.observe,
          resolution: CameraResolutionPreset.mp4,
          retentionDays: 30,
          averageBitrateMbps: 4,
          poeWattsPerCamera: 8,
        ),
      ),
      throwsArgumentError,
    );
  });
}
