# Sandman macOS App

This directory contains the macOS application that embeds the Phoenix web application.

## Prerequisites

- **Xcode** installed (from Mac App Store)
- **Elixir and Phoenix release** built

## Building the App

1. **First, ensure the Phoenix release is built:**
   ```bash
   cd ../../..  # Go to the project root
   mix release
   ```

2. **Run the build script:**
   ```bash
   ./build.sh
   ```

The build script will:
- Build the macOS app using Xcode (includes all icons and resources)
- Embed the Phoenix release into the app bundle
- Make the Phoenix binary executable
- Test the Phoenix integration
- Output the final app to `sandman/build/Release/sandman.app`

## Testing Without Xcode

If you want to test the Phoenix integration without building the full macOS app:

```bash
./test_phoenix_integration.sh
```

This script will:
- Copy the Phoenix release to a test sandbox
- Start the Phoenix app
- Test that it responds on port 7000
- Clean up the test environment

## How It Works

The macOS app automatically starts the Phoenix web application when launched:

- The Phoenix app runs on port 7000 by default
- The app shows a status indicator in the top-right corner
- Green dot = Phoenix is running
- Red dot = Phoenix is stopped
- The Phoenix process is automatically managed by the macOS app

## File Structure

```
sandman/
├── sandman/                    # Xcode project
│   ├── sandman/
│   │   ├── sandmanApp.swift    # Main app with Phoenix integration
│   │   └── views/              # SwiftUI views
│   └── sandman.xcodeproj/      # Xcode project file
├── build_macos_app.sh          # Build script
└── README.md                   # This file
```

## Development

The Phoenix app is embedded in the macOS app bundle at:
`build/Release/sandman.app/Contents/Resources/phoenix_release/`

You can modify the Phoenix app and rebuild the release, then run the build script again to update the embedded version.
