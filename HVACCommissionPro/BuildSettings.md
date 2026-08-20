## Build Settings

- **iOS Deployment Target**: 17.0
- **Swift Version**: 5.9
- **Xcode**: 16+
- **Bundle Identifier**: com.hvac.commission-pro
- **Product Name**: HVACCommissionPro

## Dependencies

No external dependencies. Uses only Apple frameworks:
- SwiftUI
- SwiftData
- Foundation
- UIKit
- PhotosUI

## Configuration

Set your Gemini API key in one of:
1. `Info.plist` → `GEMINI_API_KEY` key
2. Environment variable `GEMINI_API_KEY`

The app works without a key in local-fallback mode (sample data + local diagnostic calculations).
