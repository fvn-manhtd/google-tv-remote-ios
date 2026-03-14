# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GoogleTVRemote is an iOS app (Swift/SwiftUI) that turns an iPhone into a remote control for Google TV / Android TV devices. It communicates over the local network using Bonjour discovery, TLS-secured pairing, and the Google TV remote protocol.

## Build & Development

**Prerequisites:** Xcode 15.0+, iOS 16.0+ deployment target, Swift 5.9

**Project generation:** Uses XCGen with `project.yml` — run `xcodegen generate` from `GoogleTVRemote/` to regenerate `GoogleTVRemote.xcodeproj`.

**Build:**
```bash
cd GoogleTVRemote
xcodebuild -project GoogleTVRemote.xcodeproj -scheme GoogleTVRemote -sdk iphoneos build
```

**Run tests:**
```bash
xcodebuild -project GoogleTVRemote.xcodeproj -scheme GoogleTVRemote -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15' test
```

**Dependencies:** Single SPM dependency — `AndroidTVRemoteControl` (v2.4.13) from `https://github.com/odyshewroman/AndroidTVRemoteControl`. Provides TLS, crypto, and protocol handling for TV communication. Resolved automatically by Xcode.

## Architecture

**Pattern:** MVVM with a Service Layer

```
App/            → Entry point, AppState (ObservableObject tracking last connected TV)
Models/         → TVDevice, ConnectionStatus, PairingStatus, ResolutionStatus
Services/       → Domain-specific business logic (see below)
ViewModels/     → @Published state + Combine, one per major screen
Views/          → SwiftUI views organized by feature (Discovery, Pairing, Remote, Keyboard, Settings)
```

**App flow:** Discovery → Pairing (if needed) → Remote Control

### Services

| Service | Purpose | Network |
|---------|---------|---------|
| `TVDiscoveryService` | Bonjour mDNS scan for `_androidtvremote2._tcp`, resolves IPs via NWBrowser | UDP |
| `TVPairingService` | TLS handshake on port 6467, cert exchange, 6-char hex PIN validation | TLS:6467 |
| `TVRemoteService` | Sends key presses and deep links via RemoteManager, auto-reconnect (3 retries) | TLS:6466 |
| `CertificateGenerator` | RSA 2048-bit self-signed X.509 cert with manual ASN.1 DER encoding | — |
| `KeychainService` | Persists certs and private keys (service: `com.googletv-remote`) | — |
| `WakeOnLANService` | Magic packets on UDP:9, polls TCP:6466 for device wake confirmation | UDP:9 |

### Key Constants

- Pairing port: 6467, Remote port: 6466, WoL port: 9
- Discovery interval: 30s, Resolution timeout: 5s
- Reconnect: max 3 retries at 2s intervals
- WoL: 3 retries at 1s, poll timeout 30s

## Testing

4 test files in `GoogleTVRemoteTests/`: CertificateGenerator, KeychainService, WakeOnLAN, PINValidation. Uses XCTest with `@testable import GoogleTVRemote`.

## Key Implementation Details

- **Device persistence:** Paired devices stored as JSON in UserDefaults, merged with live Bonjour discoveries
- **Certificate lifecycle:** Generated once during first pairing, stored in Keychain, reused for all subsequent remote connections
- **PIN validation:** Must be exactly 6 hex characters (0-9, A-F)
- **Keyboard input:** `KeyboardViewModel` maps 100+ characters to TV key codes, sent sequentially
- **Info.plist:** Requires NSLocalNetworkUsageDescription, NSBonjourServices, and LSApplicationQueriesSchemes (Google Home)
