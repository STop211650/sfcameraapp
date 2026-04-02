# SF Speed Alert

An iOS app that warns you when you're approaching San Francisco speed cameras and driving over the speed limit.

## Features

- **Driving detection** via CoreMotion — only activates alerts when you're driving
- **Real-time GPS tracking** with speed monitoring
- **33 speed camera locations** from SF's automated speed enforcement program
- **Three alert levels:**
  - **Approaching** (500m) — gentle heads-up with camera location and speed limit
  - **In Zone** (150m) — you're in the enforcement zone, shows speed limit
  - **Speeding** (11+ mph over limit) — urgent warning to slow down
- **Spoken alerts** via text-to-speech (works with CarPlay audio)
- **Push notifications** with critical alerts for speeding
- **Optional fine estimates** — toggle in Settings to see potential ticket costs

## Speed Camera Data

All 33 camera locations from the SFMTA automated speed enforcement program (AB 645), sourced from [DataSF](https://data.sfgov.org/Transportation/Automated-Speed-Enforcement-Citations/d5uh-bk84) and [SFMTA](https://www.sfmta.com/projects/speed-safety-cameras).

Citations are issued for driving **11+ mph** over the posted speed limit.

### Fine schedule
| Speed over limit | Fine |
|---|---|
| 11–15 mph | $50 |
| 16–25 mph | $100 |
| 26+ mph | $200 |
| School zone | Up to $500 |

## Requirements

- iOS 17.0+
- Xcode 15+
- Location permissions (Always or When In Use)
- Motion & Fitness permissions

## Building

```bash
cd SFSpeedAlert
# If you need to regenerate the Xcode project:
brew install xcodegen
xcodegen generate
# Then open in Xcode:
open SFSpeedAlert.xcodeproj
```

## Architecture

```
SFSpeedAlert/
├── App/
│   ├── SFSpeedAlertApp.swift    # App entry point, wires up managers
│   └── Info.plist               # Privacy keys, background modes
├── Models/
│   └── SpeedCamera.swift        # Camera data model, alert types
├── Services/
│   ├── LocationManager.swift    # GPS + speed + driving detection
│   ├── CameraAlertEngine.swift  # Proximity/speed evaluation logic
│   └── AlertManager.swift       # Notifications + spoken alerts
├── Views/
│   ├── ContentView.swift        # Map + alert overlay
│   └── SettingsView.swift       # Fine estimate toggle
└── Resources/
    └── sf_speed_cameras.json    # All 33 camera locations
```

## Notes

- Critical alert entitlement (`com.apple.developer.usernotifications.critical-alerts`) requires Apple approval for App Store distribution
- Background location updates are enabled for continuous monitoring while driving
- The app uses `automotiveNavigation` accuracy for best GPS performance while driving
