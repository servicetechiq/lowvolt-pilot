# LowVolt Pilot Starter v0.1

Internal starter for the next Primal Array low-voltage technician app.

## Product principles

- Revenue-first: subscription is part of launch, not a later add-on.
- Full technician lifecycle: Design -> Install -> Configure -> Commission -> Troubleshoot -> Document.
- Cross-vendor first, with deeper manufacturer-specific guidance/integration where practical.
- Core disciplines: cameras, access control, networking, wireless, fire/life-safety references, intrusion later.
- Calculators support workflows; calculators are not the product.
- Fire/life-safety content remains diagnostic/reference focused and does not claim code compliance.

## Included in this starter

- Material 3 app shell
- Home page built around Design / Install / Troubleshoot
- Google Play subscription service shell
- Monthly/annual product IDs
- Subscription/paywall page
- First Camera System Designer screen
- Light/dark theme

## Subscription product IDs

Create these as subscription products in Google Play Console:

- `lowvoltpilot_pro_monthly`
- `lowvoltpilot_pro_annual`

Working launch pricing target:

- Monthly: $5.99
- Annual: $49.99

Pricing should ultimately be set in Play Console, not hardcoded in Flutter. The app displays the localized price returned by Google Play.

## How to use

1. Create a new Flutter project on your Windows machine:

   `flutter create --org com.primalarray --project-name lowvoltpilot lowvolt-pilot`

2. Replace its `lib` folder and `pubspec.yaml` with the versions in this starter.
3. Run:

   `flutter pub get`

4. Run analysis:

   `flutter analyze`

5. Launch on Android:

   `flutter run`

## Important production billing note

The starter marks Pro locally after a Play purchase callback so the UI architecture can be built now. Before production, add trusted server-side purchase verification/entitlement handling rather than relying only on device state.

## Next implementation milestone

1. Replace camera-count heuristic with actual horizontal/vertical FOV geometry.
2. Add pixel-density / target-detail requirements.
3. Draw room and draggable camera coverage cones.
4. Add NVR/storage/PoE/network sizing.
5. Add camera installation/commissioning workflow.
6. Add camera troubleshooting trees.
