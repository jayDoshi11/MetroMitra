# Metro Mitra

Offline-first iOS app for reporting and triaging metro station problems, built for **GDG Cloud Gandhinagar – Road to DevFest: Metro Hacks** (Metro Operations track).

*Mitra* means "friend" in Gujarati and Hindi. Independent prototype, not affiliated with Gujarat Metro.

## Features
- **Passenger reports** in a few taps, with the nearest station detected from GPS (56 stations, real coordinates, works offline).
- **On-device triage** (Apple NaturalLanguage): category, severity and response team set automatically.
- **Duplicate merging**: repeat reports of the same fault become one escalating ticket ("3 reports" → High).
- **Control room**: SLA timers, overdue escalation with local notifications, assign / resolve workflow, dashboard charts.
- **Station status** for passengers (Normal / Minor / Disrupted), interchanges at Old High Court, GNLU and Koteshwar Road.
- **Assistant chat** in English, ગુજરાતી and हिन्दी that files reports, checks stations and finds your nearest one, fully offline.
- **Full localization** (English / Gujarati / Hindi) with in-app language switcher and onboarding.
- **Offline-first sync queue**: everything is saved locally and pushed when the connection returns (server push is stubbed).

## Tech
SwiftUI · SwiftData · Observation (MVVM + repository/services) · Swift Charts · CoreLocation · NaturalLanguage · UserNotifications · NWPathMonitor. iOS 17+.

## Run
Open `MetroHacks.xcodeproj` in Xcode, select your device and run. Use ⋯ › *Load sample data* and *Demo SLA* for a demo.
