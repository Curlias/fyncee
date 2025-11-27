# Fyncee

Fyncee is a minimalist finance tracker built with Flutter and Material 3. It helps you record incomes and expenses quickly while keeping the interface clean and focused on the essentials.

## ☁️ Supabase Cloud Backend

**NEW:** Fyncee now uses Supabase (PostgreSQL) for cloud persistence! 

- ✅ Cloud sync across devices
- ✅ Automatic backup  
- ✅ Offline support with local cache (Hive)
- ✅ Real-time sync capabilities
- ✅ Free tier (500MB, 50K users)

**Setup Guide:**
- 📚 [Supabase Setup Instructions](SUPABASE_SETUP.md) - Step-by-step guide to configure your cloud backend

## Features

- 📅 Home view with a dynamic "Fyncee — Mes Año" title.
- ✨ Delightful empty state that guides first-time users.
- ➕ Dedicated form for capturing ingresos and gastos with category, amount, and optional notes.
- 💳 Transaction cards that highlight type, amount, category, note, and date at a glance.
- 🎯 Goals tracking with monthly progress
- 📊 Statistics and charts
- 🔔 Notifications for goal progress
- 📤 Export to PDF and CSV
- ☁️ **Cloud sync with Supabase (PostgreSQL)**
- 💾 Local storage with Hive (offline support)

## Design System

| Token | Value |
| ----- | ----- |
| Primary | `#0052CC` |
| Light Blue | `#4DA6FF` |
| Mid Blue | `#1E90FF` |
| Text Dark | `#1C2B39` |
| Surface | `#FFFFFF` |

- Material 3 (`useMaterial3: true`).
- White app bar with deep-blue text and elevated title weight.
- Floating action button in deep blue with a white add icon.
- Clean default sans-serif typography.

## Project Structure

```
lib/
├── main.dart                # App entry point and theme wiring
├── theme.dart               # Material 3 theme configuration and palette
├── models/
│   └── transaction.dart     # Transaction entity definition
├── screens/
│   ├── home_page.dart       # Dashboard with empty state and transaction list
│   └── add_transaction_page.dart # Form to capture new movements
└── widgets/
	└── transaction_item.dart # Card component for list rows
```

## Getting Started

```sh
flutter pub get
flutter run
```

## Testing

```sh
flutter test
```

## Roadmap

- [ ] Charts powered by `fl_chart` for cashflow insights.
- [ ] Local persistence using Isar or Drift.
- [ ] Biometric authentication for quick unlock.
- [ ] Voice input for rapid expense capture.
- [ ] Backend synchronization for multi-device access.
