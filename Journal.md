# CRM App — Development Journal

## The Big Picture

Imagine you're at a coffee shop, catching up with an old client. You remember their name, their company, maybe that they've got two kids and love fishing. That personal touch is what separates a great relationship from a cold transaction. This app is your digital memory for exactly that — a **personal CRM** that lives on your iPhone.

It's not Salesforce. It's not HubSpot. It's the app you actually *want* to open when you meet someone worth remembering.

---

## Architecture Deep Dive

Think of the app like a well-run restaurant kitchen:

- **SwiftData** is the walk-in fridge — all your ingredients (data) live here, organized and ready to grab
- **Models** are the recipes — `Contact` defines exactly what a contact *is*
- **Views** are the line cooks — they grab from the fridge and put something on the plate
- **`CRMApp.swift`** is the head chef — wires everything together with `modelContainer(for:)`

The `@Query` macro in SwiftUI views is like a waiter who knows exactly which shelf to pull from — sorted, filtered, always fresh. When you add a `Contact` to `modelContext`, SwiftData automatically updates every view watching that data. No manual refresh needed.

---

## The Codebase Map

```
CRM/
  Models/
    Contact.swift              ← The data blueprint
  Features/
    Contacts/
      ContactsView.swift       ← The list screen (+ search)
      ContactDetailView.swift  ← Read the details
      ContactFormView.swift    ← Add or edit a contact
  CRMApp.swift                 ← App entry point + SwiftData setup
```

Rule: each feature gets its own folder under `Features/`. When we add Deals, it gets `Features/Deals/`. Clean and navigable.

---

## Tech Stack & Why

| Technology | Why |
|---|---|
| **SwiftUI** | Declarative UI that reacts to data changes — perfect for a data-driven app |
| **SwiftData** | Apple's modern persistence layer; replaces Core Data with a cleaner API and `@Observable` integration |
| **`@Query`** | Replaces manual fetch requests; live-updating, filter-aware, sorted automatically |
| **`NavigationStack` + `navigationDestination(for:)`** | Type-safe navigation — push a `Contact` object, get the right view |
| **`ContentUnavailableView`** | Native empty-state UI — looks great with zero extra work |

No third-party dependencies. Ever. If Apple ships it, we use it.

---

## The Journey

### 2026-03-20 — Phase 1: Contact CRUD

**What we built:** The foundation. Add, view, edit, delete contacts. Search by name or company.

**Key decisions made:**

- `Contact` is a `@Model` `final class` — SwiftData requires classes, not structs
- `fullName` is a computed property, not stored — keeps the model lean and lets first/last name stay editable independently
- `filteredContacts` lives as a computed property in the view using `localizedStandardContains()` — this handles accents, case, and diacritics correctly (e.g., searching "jose" finds "José")
- The form validates that at least first *or* last name is non-empty — a contact with no name is useless
- `ContentUnavailableView` shows both for empty state and no-results state — two different messages, one component

**Patterns worth noting:**

- `ContactFormView` doubles as both "add" and "edit" via an optional `contact: Contact?` parameter. `nil` = new contact, non-nil = editing. Keeps logic in one place.
- SwiftData auto-saves — no explicit `try modelContext.save()` needed for basic operations

---

## Engineer's Wisdom

**The optional parameter pattern for forms:**
```swift
struct ContactFormView: View {
    var contact: Contact?  // nil = add, non-nil = edit
    ...
    private var isEditing: Bool { contact != nil }
}
```
One view, two modes. Beats duplicating a whole form.

**`@Query` vs manual filtering:**
`@Query` handles database-level filtering efficiently. But for live search (where the filter changes as the user types), a computed property over the `@Query` result works great — the query fetches all contacts once, the filter runs in memory. For large datasets, move the predicate into `@Query` itself.

**Why `localizedStandardContains` matters:**
`"café".contains("cafe")` → `false`
`"café".localizedStandardContains("cafe")` → `true`
Users don't type accents when searching. Always use the localized variant.

### 2026-03-20 — Phase 2a: Interaction Log

**What we built:** Every contact now has a log of interactions — calls, emails, meetings, notes — each with a date, type, and summary. Shown in the contact detail view, sorted newest-first. Swipe to edit or delete.

**Key decisions:**
- `Interaction` is its own `@Model` with an optional `contact: Contact?` back-reference. Optional because SwiftData needs it for the cascade delete to work cleanly from the Contact side
- `@Relationship(deleteRule: .cascade)` on `Contact.interactions` — deleting a contact wipes all its interactions automatically. No orphan cleanup needed
- Interactions sorted in the view via `contact.interactions.sorted { $0.date > $1.date }` — simple, no extra query needed since the relationship is already loaded
- `InteractionType` enum stored as `String` (raw value) so it's human-readable in the SwiftData store

**Gotcha:** Using `===` to find and delete a specific interaction from the relationship array doesn't work reliably with SwiftData model objects. Use `persistentModelID` comparison instead:
```swift
contact.interactions.removeAll { $0.persistentModelID == interaction.persistentModelID }
```

---

### 2026-03-20 — Phase 2b: Tags

**What we built:** Many-to-many tags. Contacts can have multiple colored tags (Lead, Client, Partner, VIP, etc.). Tags show as colored capsule chips on the contact list rows and detail view. A `TagPickerView` sheet lets you toggle tags and create new ones inline.

**Key decisions:**
- `Tag` has `@Relationship(inverse: \Contact.tags)` — SwiftData needs the inverse declared on one side to properly manage the join table
- `TagColor` is a `String`-backed enum so it serializes cleanly into SwiftData without a custom transformer
- `TagPickerView` takes `@Binding<[Tag]>` — the parent form owns the selection state, picker just mutates it
- `persistentModelID` used for equality checks in the picker (`isSelected`, `toggle`, `deleteTags`) — SwiftData model objects are reference types but shouldn't be compared with `===` or `==` without a custom conformance

**Gotcha — SwiftUI type inference in `List`:** Mixing a bare `ForEach` (with `.onDelete`) and a `Section` as direct children of `List` caused the compiler to pick the wrong `ForEach` overload (`Range<Int>` instead of collection). Fix: wrap the `ForEach` in its own `Section`, and use explicit `id: \.persistentModelID`. Also: complex view hierarchies inside `List` can cause cascading type errors — extract sub-views into dedicated `View` structs to keep each `body` simple enough for the type checker.

---

### 2026-03-20 — Phase 2c: Follow-up Reminders

**What we built:** Schedule a local notification to remind you to follow up with a contact. Set a date, time, and optional note. The contact detail view shows the scheduled reminder (grayed out if past). Edit or clear at any time.

**Key decisions:**
- Stored `notificationID: UUID` on `Contact` as a stable identifier for `UNUserNotificationCenter`. Don't use `persistentModelID` for this — it's not easily converted to a stable String, and `hashValue` isn't guaranteed stable across launches. A dedicated UUID is the right tool
- `NotificationService` is `@MainActor` because `UNUserNotificationCenter` callbacks and SwiftData model access both want the main actor
- Permission is requested once on app launch via `.task` in `CRMApp` — lazy permission requests (only when the user tries to set a reminder) are friendlier UX but this keeps the code simpler for now
- Reminder date shown with `.foregroundStyle(reminderDate > .now ? .primary : .secondary)` — past reminders are visually dimmed without extra state

---

### 2026-03-20 — Phase 3: Deals / Pipeline

**What we built:** A full deal pipeline. Deals are linked to contacts, have a stage (Lead → Qualified → Proposal → Negotiation → Won/Lost), a value, optional close date, and notes. `DealsView` shows deals grouped by stage with an active pipeline total at the top. Overdue close dates show in red. A new Deals tab was added via `TabView` using the modern `Tab` API.

**Key decisions:**
- `deleteRule: .nullify` on `Contact.deals` — deleting a contact orphans its deals rather than deleting them. Deals have standalone value (pipeline history) even without the contact
- `DealStage.isActive` computed var (`self != .won && self != .lost`) — used in multiple places. Single source of truth beats repeating the condition everywhere
- `value: Double` not `Decimal` — simpler for SwiftUI's `TextField(value:format:)` and good enough for a CRM
- Currency formatted with `Locale.current.currency?.identifier ?? "USD"` — respects the user's locale without hardcoding
- Grouping by stage in the view (`DealStage.allCases.compactMap`) rather than multiple `@Query` calls — one query, group in memory

**Navigation — cross-feature links:** `DealDetailView` links to `ContactDetailView` with a destination-based `NavigationLink { ContactDetailView(...) }`, avoiding the need for `navigationDestination(for: Contact.self)` in the Deals stack. Each tab stays self-contained.

**`RootView` pattern:** `CRMApp.swift` can't have `#Preview` (it's `@main`). Solution: extract `TabView` into `RootView.swift`, use it from `CRMApp`, and put the full-app `#Preview` in `RootView.swift`.

---

## Engineer's Wisdom

**The optional parameter pattern for forms:**
```swift
struct ContactFormView: View {
    var contact: Contact?  // nil = add, non-nil = edit
    ...
    private var isEditing: Bool { contact != nil }
}
```
One view, two modes. Beats duplicating a whole form.

**`@Query` vs manual filtering:**
`@Query` handles database-level filtering efficiently. But for live search (where the filter changes as the user types), a computed property over the `@Query` result works great — the query fetches all contacts once, the filter runs in memory. For large datasets, move the predicate into `@Query` itself.

**Why `localizedStandardContains` matters:**
`"café".contains("cafe")` → `false`
`"café".localizedStandardContains("cafe")` → `true`
Users don't type accents when searching. Always use the localized variant.

**SwiftData identity:**
Never use `===` or `==` to compare `@Model` instances unless you've implemented `Equatable`. Use `persistentModelID` for equality checks. For notification IDs and other external identifiers, store a dedicated `UUID` — don't derive it from SwiftData internals.

---

## If I Were Starting Over...

*(This section grows as we learn. Check back after each major feature.)*

- Start with the data model before any UI — get `Contact` right first, the views are easy after
- Think about relationships early: a contact belongs to a company, a deal belongs to a contact. Add those foreign keys before you have thousands of records to migrate
- Add `notificationID: UUID` to any model that might need a stable external identifier — retrofitting it later requires a schema migration
- Dashboard views need no new models — just three `@Query` properties and computed properties for stats. Don't over-architect analytics; derive everything from existing data first

---

### 2026-03-20 — Phase 4: Dashboard

**What we built:** A home screen tab that surfaces the most important numbers at a glance — pipeline value, win rate, deal distribution by stage, upcoming follow-up reminders, and recent interaction activity.

**Architecture:** `DashboardView` owns three `@Query` properties (contacts, deals, interactions) and computes all stats as private vars. Sub-views (`PipelineSummaryCard`, `StageBreakdownCard`, `UpcomingRemindersCard`, `RecentActivityCard`) are passed only the data they need as plain values — they contain no queries themselves. This keeps each card dumb, testable, and reusable.

**`DashboardCard<Content>`** — a generic container view that takes a title, SF Symbol, and `@ViewBuilder` content. Removes the boilerplate of padding/background/clip from every card. Generic views with `@ViewBuilder` are one of SwiftUI's most underused patterns.

**Key decisions:**
- `ProgressView(value:total:)` for the stage bar chart — built-in, tintable, zero GeometryReader needed. Don't reach for GeometryReader when a standard component does the job
- `upcomingReminders` uses `.prefix(3).map { $0 }` — `prefix` returns an `ArraySlice`, not an `Array`. The `.map { $0 }` converts it. Alternatively use `Array(contacts.prefix(3))`
- Win rate only shown as green when `> 0` — `0%` defaults to `.secondary` so it doesn't look like a bad metric when there's simply no data yet
- Empty state handled with `ContentUnavailableView` only when *both* contacts and deals are empty — a dashboard with just contacts (no deals yet) should still show what it can
- Tab order: Dashboard first, then Contacts, then Deals — dashboard is the natural landing screen once there's data

---

### 2026-03-27 — Phase 5: iCloud Sync via CloudKit

**What we built:** Enabled CloudKit sync so data is shared across all of the user's devices automatically. Also fixed a warning in `NotificationService` and added a PLN currency hint to the Deal value field.

**CloudKit + SwiftData — the rules:**

SwiftData's CloudKit integration sounds simple but has three strict constraints that will silently break sync if violated:

1. **No `@Attribute(.unique)`** — CloudKit can't enforce uniqueness constraints across devices. Fine for a CRM; don't use it.
2. **All properties must have default values or be optional** — when CloudKit syncs a new record to a device, it may create a model object without calling your designated initializer. If a property has no default and isn't optional, you get a crash. Fixed by adding `= ""`, `= .now`, `= 0`, etc. to every stored property.
3. **All relationships must be optional** — same reason. CloudKit may sync the parent record before the children arrive. A `[Interaction]` relationship becomes `[Interaction]?` (may be nil until data arrives).

**Model changes:**
All four models (`Contact`, `Interaction`, `Tag`, `Deal`) got explicit defaults on every stored property. Array relationships (`interactions`, `tags`, `deals`, `contacts`) changed from `= []` to optional `?`. This cascaded into ~10 view changes swapping `.array` access for `?? []` fallbacks.

**App setup:**
The `.modelContainer(for:)` convenience modifier doesn't accept a `cloudKitDatabase` argument — that lives on `ModelConfiguration`. Switched to building the container explicitly:

```swift
let schema = Schema([Contact.self, Interaction.self, Tag.self, Deal.self])
let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
let container = try! ModelContainer(for: schema, configurations: config)
```

`.automatic` means: use CloudKit if the entitlement is present, fall back to local storage if not. Safe to ship without the capability configured yet.

**Entitlements:**
Created `CRM/CRM.entitlements` with `iCloud.com.TosiaChaga.CRM` as the container ID. **The entitlements file alone isn't enough** — you must also enable the iCloud capability in Xcode (Signing & Capabilities → + → iCloud → tick CloudKit → pick the container). Without that, Xcode won't code-sign the entitlement and CloudKit will silently fall back to local.

**PLN hint in DealFormView:**
Wrapped the Value `TextField` in an `HStack` with a `Text("PLN")` trailing label. Simple, looks native in a Form row.

**Warning fixed:**
`try? await UNUserNotificationCenter.requestAuthorization(...)` returns a `Bool` that was being discarded. Fixed with `_ = try? await ...`.

**Gotcha — optional relationships and SwiftUI:**
`ForEach(contact.tags)` doesn't compile when `tags` is `[Tag]?`. The fix everywhere is `ForEach(contact.tags ?? [])`. The `removeAll` mutation on an optional also needs `?`: `contact.interactions?.removeAll { ... }`. It's mechanical but necessary.
