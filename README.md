# Spendly

A personal finance tracker built with Flutter. Set a monthly income, split it
into budget categories by percentage, log expenses with a purpose-built
keypad, and see where the money goes — with smart auto-categorization,
budget-health alerts, insights charts, and CSV export.

## Features

- **Percentage-based budgeting** — allocate income across up to 8 categories
  (50/30/20, 70/20/10, and zero-based presets included).
- **Fast expense entry** — bottom sheet with a thumb-zone keypad, one-line
  category/subcategory pickers, and a combined label + date row.
- **Smart categorization** — free-text labels ("milk", "Netflix") are matched
  to subcategories by keyword; the user's own history takes priority.
- **Emoji subcategories** — every built-in subcategory has a default emoji
  (🛒 Groceries, ✈️ Travel…); custom subcategories get a user-picked one.
- **Budget health** — per-category status (on track / near limit / over /
  target reached), with savings-type categories treated as goals, not caps.
- **Insights** — donut chart and per-category breakdowns over week / month /
  year / custom ranges.
- **CSV export** — share transaction history from the Activity tab.
- **Multi-currency** — currency catalog with symbol rendering throughout.
- **Local persistence** — everything is stored on-device.

## Getting started

```bash
flutter pub get
flutter run          # pick a device, or:
flutter run -d chrome
flutter test         # 109 unit tests
```

The app seeds demo transactions on first launch so every screen has data.
Sign-in is a local mock (any password); no backend is involved.

## Architecture

Spendly is a single-package Flutter app using **Provider (ChangeNotifier)**
for state management and **SharedPreferences** for persistence. There is no
backend; all data lives on-device.

```
lib/
├── main.dart                  # Entry point; wires ChangeNotifierProvider
├── app.dart                   # MaterialApp, routes (/signin, /setup, /main)
│
├── core/                      # Pure logic + design system (no widgets w/ state)
│   ├── colors.dart            #   Design tokens: palette, semantic colors
│   ├── text_styles.dart       #   Typography scale (editorial serif + sans)
│   ├── constants.dart         #   Card decoration, budget presets
│   ├── currencies.dart        #   Currency catalog (code → name, symbol)
│   ├── categorizer.dart       #   SmartCategorizer: keyword → subcategory,
│   │                          #   history-first matching, default emojis
│   ├── budget_status.dart     #   BudgetHealth: on-track/near-limit/over/
│   │                          #   achieved; savings categories are goals
│   └── csv_exporter.dart      #   Transactions → escaped CSV text
│
├── models/
│   ├── category_model.dart    # Category: id, name, pct of income, color
│   └── transaction_model.dart # Transaction: amount, categoryId, label,
│                              # subcategory, createdAt (JSON round-trip)
│
├── state/
│   └── app_state.dart         # Single ChangeNotifier holding all app state
│
├── screens/
│   ├── signin_screen.dart     # Mock local auth
│   ├── setup_screen.dart      # Onboarding + settings (Profile/Income/Budget)
│   ├── main_shell.dart        # Scaffold: tab bar + FAB + IndexedStack
│   ├── home_screen.dart       # Overview card, category budget cards
│   ├── activity_screen.dart   # Filterable history, CSV export
│   └── insights_screen.dart   # Donut chart + category breakdown (fl_chart)
│
└── widgets/
    ├── add_transaction_sheet.dart  # Modal sheet: amount, keypad, pickers
    └── filter_chip.dart            # Shared period filter chip
```

### State management

`AppState` (in `state/app_state.dart`) is the single source of truth,
exposed at the root via `ChangeNotifierProvider`. Screens read it with
`context.watch` (rebuild on change) and mutate it with `context.read`.
It owns:

- **Auth/session** — `signedIn`, `isOnboarding`, `UserProfile`
  (name, email, currency).
- **Budget** — `income`, `paySchedule`, `cycleStart`, and the category list
  (`totalPct` must equal 100 to finish setup).
- **Transactions** — the full list plus period filtering (`week` / `month` /
  `year` / `custom` / `all`) used by Home, Activity, and Insights.
- **Draft** — `DraftTx` models the in-progress transaction while the add/edit
  sheet is open (keypad input, category, auto-suggested subcategory, date).
- **UI state** — active tab, per-tab period selections.

Every mutation calls `_save()` then `notifyListeners()`, so persistence is
write-through and the UI is always consistent with disk.

### Persistence

`SharedPreferences` stores: income, categories (JSON), transactions (JSON),
custom subcategories, custom subcategory emojis (JSON map), user profile
(name/email/currency), pay schedule, and cycle start. On first launch (no
saved data) the default 50/30/20 preset is applied and demo transactions are
seeded. A small migration backfills subcategories on transactions saved
before smart categorization existed.

### Smart categorization

`SmartCategorizer.suggest(label, history)` resolves a subcategory in two
passes: (1) the most recent transaction with the same normalized label wins —
the app learns user corrections; (2) otherwise keyword matching with word
boundaries ("gas" matches "gas station", not "vegas"). Suggestions appear as
"auto-detected" in the sheet and never overwrite a manual choice.

### Budget health

`BudgetHealth.statusFor(spent, limit)` yields `onTrack` (< 80%),
`nearLimit` (80–99%), or `over` (≥ 100%). Categories whose names look like
savings/investments are treated as goals: reaching the limit reports
`achieved` instead of `over`.

### Design system

No Material theme defaults: colors come from `AppColors` (warm paper
background, ink text, 8-color category palette, semantic success/warning/
danger sets with on-dark variants), and typography from `AppTextStyles`
(editorial serif display + sans body, tabular figures for money).

### Dependencies

| Package | Use |
|---|---|
| `provider` | State management |
| `shared_preferences` | Local persistence |
| `intl` | Date and number formatting |
| `fl_chart` | Insights donut chart |
| `google_fonts` | Editorial serif + sans typography |
| `uuid` | Stable ids for categories and transactions |
| `share_plus` / `path_provider` | CSV export sharing |

### Scaling

The app is local-only by design. For the roadmap to multi-device sync, real
auth, and thousands of users — with current-vs-target architecture diagrams —
see [SCALING.md](SCALING.md).

## Testing

`test/widget_test.dart` holds 109 unit tests covering state initialization,
auth, budget math, transaction CRUD and editing, keypad input rules, period
filtering, smart categorization, custom subcategories and emojis, budget
status, CSV escaping, and persistence round-trips.

```bash
flutter test
```
