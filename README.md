# Pankuzu

An iOS app for monitoring and tracking electric vehicle trips and charging sessions. Connects via an OBD-Link adapter using CAN bus protocols to display real-time telemetry including battery status, weather, location, and trip/charge data.

## Supported Vehicles

- Ford Mustang Mach-E
- Ford F-150 Lightning
- Volkswagen ID.4

## Requirements

- iOS 26+
- Xcode 26+
- OBD-Link MX+ or compatible adapter
- A supported electric vehicle

## Building

### 1. Clone and configure

After forking and cloning the repository, create a `Local.xcconfig` file in the project root (it is git-ignored):

```
// Local.xcconfig — personal build settings, do not commit

DEVELOPMENT_TEAM = XXXXXXXXXX        // Your Apple Developer Team ID
ABRP_API_KEY = your-abrp-api-key     // Optional: A Better Route Planner API key
```

Your **Team ID** can be found in the [Apple Developer portal](https://developer.apple.com/account) under Membership Details.

An **ABRP API key** is only required if you want to enable A Better Route Planner integration. You can leave the value empty or omit the line entirely to build without it.

The `Shared.xcconfig` already includes `Local.xcconfig` via `#include? "Local.xcconfig"` so no project changes are needed.

### 2. Bundle identifiers

The project uses the following bundle identifiers. If you need to change them (e.g. to match your own App Store account) update the targets in Xcode:

| Target | Bundle ID |
|--------|-----------|
| Pankuzu | `com.unchan.pankuzu.Pankuzu` |
| LiveActivityWidget | `com.unchan.pankuzu.Pankuzu.LiveActivityWidget` |

### 3. Build

```bash
# Resolve Swift packages
swift package resolve

# Build for iOS
xcodebuild -scheme Pankuzu -destination 'generic/platform=iOS'
```

Or open `Pankuzu.xcodeproj` in Xcode and build normally.

## Architecture

The codebase uses a modular Swift Package Manager structure under the `doko-*` naming convention:

| Package | Purpose |
|---------|---------|
| **doko-core** | Core types, global actor, state machine enums |
| **doko-state-engine** | Main state machine orchestrator |
| **doko-managers** | Singleton managers for device/service control |
| **doko-schema** | SQLite database models and schema |
| **doko-ui** | UI components (Trips, Charges, Settings, Vehicles) |
| **doko-vehicle-interface** | Vehicle data parsing (Ford, VW implementations) |
| **doko-components** | Higher-level component management (ObdLinkManager) |
| **doko-sharing** | Shared preferences via swift-sharing |
| **doko-live-activities** | Live Activity attributes for Dynamic Island |
| **doko-logging** | OSLog + circular buffer logging |
| **doko-debug** | Debugging utilities |

## Vehicle State Machine

```
reset → protocolCheck → vin → idle
                              ├── pluggedIn → acChargeStarting → acChargeInProgress → acChargeEnding
                              ├── pluggedIn → dcChargeStarting → dcChargeInProgress → dcChargeEnding
                              └── tripStarting → tripInProgress → tripEnding
```

## Adding a New Vehicle

Implement the `VehicleInterface` protocol in `doko-vehicle-interface` and add a new target following the pattern of `FordElectrics` or `VwElectrics`.

## Key Technologies

- SwiftUI with Swift 6 strict concurrency
- ExternalAccessory framework for OBD-Link communication
- CoreLocation for GPS tracking
- WidgetKit for Live Activities
- SQLite via sqlite-data package

## License

MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
