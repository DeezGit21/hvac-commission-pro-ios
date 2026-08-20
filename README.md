# HVAC Commission Pro — iOS

iOS port of the HVAC Commission Pro Android app, built with SwiftUI and SwiftData.

## Features (1:1 parity with Android)

- **Dashboard** — Weekly commission summary with navigable weeks, lifetime metrics, action tiles, today's completion suggestions, week pay entries, recent jobs
- **Pending Pipeline** — Sold jobs awaiting install, with today/overdue badges, search, filter chips, date scheduling, mark-complete
- **Job Editor** — Two-tab editor (Basic Tracking + Advanced Tracking) with live commission calculations, job type selector, PCP spiff checkbox, date pickers, job costing, diagnostic readings, delete/copy
- **All Jobs List** — Searchable, filterable list with status badges, type badges, toggle complete
- **Pay Report** — Weekly pay period statement with earnings breakdown by commission rule, itemized line items
- **HVAC Diagnostics AI** — Live telemetry (superheat, subcooling, delta T, TESP), refrigerant type selector, Gemini AI diagnostic report generation, attach-to-job conversion
- **OCR Scanner** — Photo picker for equipment plates/invoices, Gemini Vision extraction, auto-fill job data

## Commission Rules

| Rule | Description | Payout |
|------|-------------|--------|
| 1(b) | Sold this week, not completed | 10% advance + $25 PCP Spiff |
| 1(c) | Sold prior week, completed this week | 10% final balance |
| 1(d) | Sold & completed same week | Full 20% + $25 PCP Spiff |
| 2(a) | Unit Sale | 10% flat on sold date |

## Tech Stack

- **SwiftUI** (iOS 17+)
- **SwiftData** for local persistence (replaces Android Room)
- **Gemini AI API** for diagnostics and OCR
- **PhotosUI** for image picking
- Dark bento-grid UI theme matching Android design

## Setup

1. Open `HVACCommissionPro.xcodeproj` in Xcode 16+
2. Set `GEMINI_API_KEY` in `Info.plist` or as an environment variable
3. Select your team for signing
4. Build & run on iOS 17+ simulator or device

## Project Structure

```
HVACCommissionPro/
├── HVACCommissionProApp.swift    # App entry point
├── Info.plist                    # App config + API key
├── Models/
│   ├── HvacJob.swift            # SwiftData model + computed properties
│   ├── CommissionEngine.swift    # Commission calculation engine
│   ├── HvacPhysicsCalculator.swift # PT table calculations
│   └── DiagnosticModels.swift    # AI diagnostic data models
├── Services/
│   └── GeminiHvacService.swift   # Gemini API integration
├── ViewModel/
│   └── HvacViewModel.swift       # ObservableObject view model
├── Views/
│   ├── ContentView.swift         # Root view + tab bar
│   ├── DashboardScreen.swift
│   ├── PendingJobsScreen.swift
│   ├── JobEditorScreen.swift
│   ├── DiagnosticScreen.swift
│   ├── ScanInvoiceScreen.swift
│   ├── JobsListScreen.swift
│   └── PayReportScreen.swift
├── Components/
│   └── BentoComponents.swift      # Reusable UI components
└── Theme/
    └── AppTheme.swift             # Colors, formatters, modifiers
```

## Android → iOS Mapping

| Android | iOS |
|---------|-----|
| Jetpack Compose | SwiftUI |
| Room Database | SwiftData (@Model) |
| ViewModel + StateFlow | ObservableObject + @Published |
| Material 3 Components | Custom SwiftUI Views |
| OkHttp + Gemini API | URLSession + Gemini REST API |
| ActivityResultContracts.GetContent | PhotosUI PhotosPicker |
| DatePickerDialog | .sheet with DatePicker |
| NavigationBar | Custom BottomTabBar |
