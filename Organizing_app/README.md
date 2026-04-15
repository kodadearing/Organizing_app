# Organize Today

`Organize Today` is a professional SwiftUI organization app for managing daily priorities, upcoming tasks, and lightweight project tracking in a focused dashboard.

The app is designed to feel clean, structured, and intentional rather than like a starter template. The current version includes a polished home screen, quick task capture, task filtering, progress tracking, and local persistence.

## Current Features

- Professional SwiftUI dashboard with a branded visual style
- Quick capture for new tasks
- Task organization across `Today`, `Upcoming`, and `Completed`
- Completion tracking with visible progress metrics
- Agenda section for daily schedule context
- Project summary cards with progress indicators
- Local persistence using `UserDefaults`
- Responsive layout that adapts across iPhone and iPad sizes

## Tech Stack

- Swift
- SwiftUI
- Xcode
- Local state management with `ObservableObject`
- Persistence with `UserDefaults`

## Project Structure

```text
Organizing_app/
├── Organizing_app.xcodeproj
├── Organizing_app/
│   ├── Assets.xcassets
│   ├── ContentView.swift
│   ├── OrganizeTodayApp.swift
│   └── OrganizeTodayStore.swift
└── README.md
```

## Running The App

1. Open `Organizing_app.xcodeproj` in Xcode.
2. Select the `Organizing_app` scheme.
3. Choose an iPhone or iPad simulator, or a connected device.
4. Press `Run`.

## Build From Terminal

```bash
xcodebuild -project Organizing_app.xcodeproj \
  -scheme Organizing_app \
  -destination 'generic/platform=iOS' \
  -derivedDataPath /tmp/OrganizeTodayDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

## Notes

- The app display name is `Organize Today`.
- The Xcode project and scheme are still named `Organizing_app`.
- The current deployment target in the project is `iOS 26.2`.
- Sample data is included to make the interface immediately useful during development.

## Roadmap

- Full Xcode project rename from `Organizing_app` to `Organize Today`
- Replace `UserDefaults` storage with `SwiftData`
- Add editing, deleting, and reordering for tasks
- Add custom app icon and final brand assets
- Add tests for task filtering and persistence behavior

## Status

This project is currently in active development and already has a strong UI foundation for a production-quality organization app.
