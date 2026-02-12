# Pankuzu

An iOS app for monitoring and tracking electric vehicle trips and charging sessions for Ford electric vehicles. Connects via OBD-Link adapter using CAN bus protocols to display real-time telemetry including battery status, weather, location, and trip/charge data.

## Requirements

- iOS 26+
- Xcode 16+
- OBD-Link MX+ or compatible adapter
- Ford electric vehicle (Mustang Mach-E, F-150 Lightning)

## Building

```bash
# Resolve Swift packages
swift package resolve

# Build for iOS
xcodebuild -scheme Pankuzu -destination 'generic/platform=iOS'
```

## Architecture

The codebase uses a modular Swift Package Manager structure:

| Package | Purpose |
|---------|---------|
| **doko-core** | Core types, global actor, state machine enums |
| **doko-state-engine** | Main state machine orchestrator |
| **doko-managers** | Singleton managers for device/service control |
| **doko-schema** | SQLite database models and schema |
| **doko-ui** | UI components (Trips, Charges, Settings, Vehicles) |
| **doko-vehicle-interface** | Vehicle data parsing with Ford implementation |
| **doko-components** | Higher-level component management |
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
