# Repository Guidelines

## Project Structure & Module Organization
This repository contains one iOS app project under `GoogleTVRemote/`. Main application code lives in `GoogleTVRemote/GoogleTVRemote`, organized by concern: `App/`, `Models/`, `Services/`, `ViewModels/`, `Views/`, `Utilities/`, and `Extensions/`. Unit tests live in `GoogleTVRemote/GoogleTVRemoteTests`. Treat `GoogleTVRemote/Build/` as generated output and do not edit it. Project configuration is defined in `GoogleTVRemote/project.yml`; regenerate the Xcode project from that file instead of hand-editing `project.pbxproj` when structure changes.

## Build, Test, and Development Commands
Run commands from the repository root unless noted.

- `cd GoogleTVRemote && xcodegen generate` regenerates `GoogleTVRemote.xcodeproj` from `project.yml`.
- `xcodebuild -project GoogleTVRemote/GoogleTVRemote.xcodeproj -scheme GoogleTVRemote -configuration Debug build` performs a local Debug build.
- `xcodebuild test -project GoogleTVRemote/GoogleTVRemote.xcodeproj -scheme GoogleTVRemote -destination 'platform=iOS Simulator,name=iPhone 15'` runs the XCTest suite.

If XcodeGen or simulator dependencies change, regenerate the project before opening it in Xcode.

## Coding Style & Naming Conventions
Follow existing Swift style: 4-space indentation, one top-level type per file when practical, and `UpperCamelCase` for types with `lowerCamelCase` for methods and properties. Keep SwiftUI views suffixed with `View`, view models with `ViewModel`, and service types with `Service`. Prefer small, focused extensions such as `Data+Extensions.swift`. No formatter or linter config is committed here, so match surrounding code and use Xcode’s default formatting consistently.

## Testing Guidelines
Tests use `XCTest`. Add new unit tests to `GoogleTVRemote/GoogleTVRemoteTests` and name files after the subject under test, for example `WakeOnLANServiceTests.swift`. Prefer method names that describe behavior, such as `testValidPINs`. Add tests for service logic, certificate handling, persistence, and network edge cases before merging feature work.

## Commit & Pull Request Guidelines
Git history is not available in this workspace, so no repository-specific commit convention can be inferred. Use short imperative commit subjects such as `Add manual IP validation`. Pull requests should summarize user-visible changes, note any `project.yml` updates, list tested devices or simulator targets, and include screenshots for SwiftUI UI changes.
