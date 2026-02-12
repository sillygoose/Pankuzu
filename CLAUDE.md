# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Pankuzu is an iOS app that monitors and tracks electric vehicle (EV) trips and charging sessions for Ford electric vehicles. It connects via an OBD-Link adapter using CAN bus protocols to display real-time telemetry including battery status, weather, location, and trip/charge data.

## Build Commands

```bash
# Build for iOS (standard Xcode build)
xcodebuild -scheme Pankuzu -destination 'generic/platform=iOS'

# Resolve Swift packages
swift package resolve
```

Development is done in Xcode. The project uses Swift Package Manager for dependencies and modular architecture.

## Architecture

### Modular SPM Structure

The codebase is organized into 12+ discrete Swift packages under the `doko-*` naming convention:

- **doko-core** - Core types, global actor (`@DokoEngineActor`), state machine enums (`VehicleState`, `DokoCommand`, `DokoResponse`)
- **doko-state-engine** - Main state machine orchestrator (`DokoStateEngine.swift`)
- **doko-managers** - Singleton managers for device/service control (CoreLocationManager, DokoLocationManager, DokoVehicleManager, DokoWeatherManager, DokoNotificationManager, DokoPacketManager)
- **doko-schema** - SQLite database models and schema (Vehicle, Trip, Charge, Location types)
- **doko-ui** - UI components split into TripsUI, ChargesUI, SettingsUI, VehiclesUI, LocationsUI, CommonUI
- **doko-vehicle-interface** - Vehicle data parsing with FordElectrics implementation
- **doko-components** - Higher-level component management (ObdLinkManager)
- **doko-sharing** - Shared preferences and settings across app/widget using swift-sharing
- **doko-live-activities** - Live Activity attributes and management for Dynamic Island
- **doko-logging** - OSLog + circular buffer logging
- **obdlink-core** - OBD-Link device protocol types

### Key Patterns

**Concurrency**: Uses Swift 6 strict concurrency with `@globalActor DokoEngineActor` for state engine serialization. All managers are annotated with `@DokoEngineActor`. AsyncStream for reactive packet/response streams.

**State Management**: `@Observable` macro for view models, `@Shared` from swift-sharing for preferences and app/widget synchronization. Managers expose state via computed properties (e.g., `CoreLocationManager.shared.currentLocation`).

**Dependency Injection**: Custom `Dependency` wrapper with `prepareDependencies { }` for bootstrapping and `@Dependency(\.context)` for live vs test contexts.

**Database**: SQLite via sqlite-data package. Supports database seeding for previews.

### Vehicle State Machine

States flow: `reset → protocolCheck → vin → idle`

From idle:
- `pluggedIn → acChargeStarting → acChargeInProgress → acChargeEnding`
- `pluggedIn → dcChargeStarting → dcChargeInProgress → dcChargeEnding`
- `tripStarting → tripInProgress → tripEnding`

### Entry Points

- `Pankuzu/PankuzuApp.swift` - Main app entry, manager initialization
- `Pankuzu/App.swift` - AppView with TabView (Trips, Charges, Settings)
- `LiveActivityWidget/` - Dynamic Island widgets for active trips/charges

### Critical Files

| File | Purpose |
|------|---------|
| `doko-core/Sources/DokoTypes/Doko.swift` | State machine, command/response types |
| `doko-state-engine/Sources/DokoStateEngine/DokoStateEngine.swift` | Core orchestration logic |
| `doko-managers/Sources/DokoPacketManager/DokoPacketManager.swift` | OBD-Link packet streaming |
| `doko-vehicle-interface/Sources/FordElectrics/` | Ford-specific CAN parsing |

## Key Technologies

- SwiftUI with iOS 26+ deployment target
- Swift 6 strict concurrency
- ExternalAccessory framework for OBD-Link communication
- CoreLocation for GPS tracking
- WidgetKit for Live Activities
- SQLite via sqlite-data package

## Development Notes

- All background work must properly isolate with actors due to Swift 6 strict concurrency
- New vehicle types require implementing the `VehicleInterface` protocol
- Adding features typically means creating a new doko-* package
- Views include `#Preview` blocks with dependency mocking via `prepareDependencies`
- App ↔ Widget communication uses `@Shared` via shared preferences
- Managers use start/stop lifecycle pattern (e.g., `DokoWeatherManager.startWeatherService()`, `CoreLocationManager.startLocationUpdates()`)
