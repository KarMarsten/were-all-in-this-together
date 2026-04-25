# We're All In This Together

A private, end-to-end encrypted life-admin app for families supporting a
neurodivergent child, a neurodivergent parent, or both. One household. Any
number of neurodivergent people in it. Any number of trusted people with
access.

> **Status:** Phase 1 (local-only MVP) in progress. Crypto, encrypted
> local database, People, Medications, **Profile** (baselines + structured
> lines + Calm surfacing), **Notes** (observations timeline), **Care summary
> PDF**, **global search** (people, meds, appointments, notes, profile entries,
> providers, programs, apps/sites), **Programs**, and **Apps & Sites** are in
> the app. Multi-device sync is
> Phase 2. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the plan.

---

## What works today

- **People roster** — add, edit, archive. Encrypted per-person records with
  per-person keys in the iOS Keychain. Free-form display name, pronouns,
  preferred-framing notes — no fixed roles.
- **Medications** for each person:
  - Create / edit / archive / restore with name, dose, schedule.
  - Daily or specific-days-of-week schedules with any number of times.
  - **Medication groups** — bundle several meds under one time slot so
    they appear as a single Today row and ACK together.
  - **Prescribed by** — optional link to a saved `CareProvider`, so a
    name or phone change on the provider flows through every
    medication they prescribed. Archived providers stay selectable so
    historical links don't break; a free-text fallback covers one-off
    prescribers that aren't in the Providers list.
  - **History timeline** — every create / edit / archive / restore is
    auto-logged as a `MedicationEvent`, so regimen changes over time
    (dose up/down, schedule tweaks, prescriber swaps, start/end date
    changes) become a first-class record rather than overwrites. A
    **History** button on the edit screen opens a reverse-chron
    timeline scoped to that medication. **Manual backfill** lets you
    add free-text notes dated to any day in the past (or future —
    "new dose starts next Monday"), and any event can be swiped away
    to correct a mistake.
- **Today's doses** — the one screen a caregiver opens in the morning.
  Shows every dose due on the current local day (solo + group), with
  Taken / Skip / Undo, all stored as encrypted dose logs.
- **Reminders you can act on from the lock screen** — one-shot local
  notifications with **Taken** and **Skip** action buttons. Tapping either
  cancels the nag chain and queues the ACK silently; the app doesn't need
  to launch. Unacknowledged doses get a configurable **nag chain**
  (interval + cap), with a global default and optional per-medication
  override.
- **Adherence report** — four-column report (Time · Medication · Person ·
  ACK'd by) over any date range, with per-person filter and **PDF export
  / Print** for doctor visits. Archived meds still render with their real
  name.
- **Providers** — PCPs, specialists, therapists, dentists, and catch-all
  "other" kinds, grouped by kind, per-Person scoped. Each provider has
  phone, address, portal URL, free-text specialty, and notes, with
  one-tap actions to call, open the portal, or open the address in
  Maps. Archive preserves the record so historical references (e.g.
  `prescriberId` on meds, `providerId` on appointments) still resolve.
- **Appointments** — per-Person list with upcoming visits grouped by
  day ("Today", "Tomorrow", weekday, ISO date) and a collapsible past
  section. Each appointment has a title, scheduled time, optional
  provider link (archived providers still selectable), location,
  duration, notes, and reminder lead. Picking a lead schedules a
  one-shot local notification (e.g. "In 30 min · Clinic A") that
  self-heals on edits — move the visit or change the lead and the
  OS registration is replaced on the next reconcile pass. Today's
  appointments also interleave chronologically with doses on the
  Today screen, so a 09:00 specialist visit renders between the
  08:00 and 10:00 pills without any context-switch. Archive /
  restore mirrors the other domain forms.
- **Milestones & dates** — per-Person life-log of dated events that
  don't fit the medication / appointment schema: diagnoses,
  vaccines, developmental firsts, health events, life moves.
  Category (diagnosis, vaccine, development, health, life, other)
  drives icon and colour; per-entry **precision** (year / month /
  day / day-and-time) lets users log what they actually remember —
  "sometime in 2019" is a legitimate answer. Reverse-chronological
  list grouped by year, optional provider link (archived providers
  still resolve), free-text notes, archive / restore.
- **Profile** — one encrypted baseline row per Person (**communication**,
  **sleep**, **appetite / eating**) plus **structured entries** (stims,
  sensory/food/clothing/social preferences, routine blocks & steps,
  triggers, what helps, early signs, other) with status, optional dates,
  archive/restore, and Calm surfacing for the in-the-moment screen. **Notes**
  (observations) are a separate timeline with optional links to profile lines.
- **Care summary (PDF)** — from **Settings**, export a selectable handoff:
  Calm quick guide (early signs / triggers / what helps), baselines, active
  structured profile lines, Providers, Programs, Apps & Sites (no passwords),
  and support resources for babysitters, grandparents, and respite (same
  `printing` path as the adherence report).
- **Search** — app-bar entry on Home; searches People, medications,
  appointments, Notes, profile entries, providers, Programs, and Apps & Sites,
  with stronger matches ranked first, highlighted in results, and linked
  provider/program context included where available.
- **Providers** — per-person encrypted care-team records with specialty/role,
  contact person, phone, email, fax, address, portal label/URL, after-hours
  instructions, notes, and one-tap call/email/portal/map actions.
- **Programs** and **Apps & Sites** — per-person encrypted lists. Programs
  cover school / camp / after-care with contact name/role, phone, email,
  address, website/portal URL, schedule/hours, notes, and one-tap actions.
  Apps & Sites track categorized portal/app URLs, username hints, login notes,
  and notes (explicitly no passwords) with open-in-browser. Programs can link
  to Providers; Apps & Sites can link to Providers and Programs so handoffs,
  PDFs, and search show the relationship context. Archive and restore match
  other domains.
- **Calm** — in-the-moment coping strategies and crisis contacts, reachable
  in one tap from anywhere, rendered in a dedicated low-stimulation theme.

## What's still to come

Priorities **0–5** for Phase 1 (see recent commits and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) § Phase plan):

0. **Doc sync** — keep this README, `lib/features/README.md`, and the repo
   layout tree aligned with shipped routes and schema bumps.
1. **Care summary depth** — keep expanding export options and add
   locale-specific hotlines where we can cite them safely.
2. **Calm** — continue replacing any remaining generic copy with concrete,
   profile-aware guidance where it helps.
3. **Global search depth** — filters and more relationship-aware navigation.
4. **Phase 2 — Multi-device, multi-caregiver sync** — Supabase (EU), per-person
   key shares, QR pairing, first-ACK-wins attribution. Not started; see
   architecture doc for privacy and pairing design.

## Principles

1. **Medical and mental-health data for minors is the most sensitive data
   this app will ever touch.** Every architectural choice defers to that.
2. **End-to-end encrypted from day one.** The server stores only ciphertext.
   Keys never leave devices. Keys are scoped per person, so sharing one
   person's record with a co-parent doesn't share everyone's.
3. **Offline-first.** The Calm screen in particular must work with zero
   network, no login, and no latency.
4. **Many people, many caregivers.** A household may track several
   neurodivergent people; each may have several trusted people in their
   circle with access.
5. **GDPR-shaped from the start** — even for US launch. EU residency is
   the stricter bar; designing to it now avoids a painful migration later.
6. **Neurodiversity-affirming framing.** See
   [Naming conventions](docs/ARCHITECTURE.md#naming-conventions) in the
   architecture doc. Words matter here, and we hold a consistent vocabulary.

## Repo layout

```
lib/
├── main.dart              app entry (ProviderScope → App)
├── app.dart               MaterialApp.router wiring + pending-ACK drainer
├── core/
│   ├── crypto/            XChaCha20-Poly1305 envelope + Keychain key storage
│   ├── database/          Drift schema + migrations (v1–v12)
│   ├── notifications/     local notifications + background ACK queue
│   ├── router/            go_router config
│   └── theme/             Material 3 + Calm low-stim theme
└── features/
    ├── home/              tabbed home + persistent Calm button
    ├── safety_plan/       Calm screen (low-stim theme)
    ├── settings/          settings, care summary entry, reminder-nag prefs
    ├── people/            Person CRUD + active-Person switcher
    ├── medications/       meds + groups + schedule + Today + dose logs + notifications
    ├── reports/           adherence report + care summary PDFs
    ├── providers/         care-provider CRUD + detail with tap actions
    ├── profile/           baselines + structured entries + Notes / Calm hooks
    ├── observations/      Notes timeline (Observation)
    ├── appointments/      visits + local reminders + Today integration
    ├── programs/          schools, camps, after-care + contacts/actions
    ├── apps_sites/        portal URLs + notes (encrypted)
    ├── search/            cross-domain local search
    └── milestones/        per-Person life-log of dated events
docs/
└── ARCHITECTURE.md        decision log + data model + phases + naming conventions
```

## Getting started

### Prerequisites

- **macOS** with Xcode 15+ (currently tested against Xcode 26.4).
- **CocoaPods** (`pod --version` should work).
- **fvm** — this repo pins a specific Flutter SDK via `.fvmrc`.

### Install fvm (one time)

```bash
curl -fsSL https://fvm.app/install.sh | bash
echo 'export PATH="$HOME/fvm/bin:$PATH"' >> ~/.zprofile
exec zsh -l
```

### Bootstrap the project

```bash
git clone <this repo>
cd were-all-in-this-together
fvm install            # installs the pinned Flutter SDK
fvm flutter pub get
cd ios && pod install && cd ..
```

### Run it

```bash
fvm flutter run                  # on the default device
fvm flutter run -d "iPhone 15"   # on a specific simulator
```

### Tests / analysis

```bash
fvm flutter analyze
fvm flutter test
```

### Shortcut

If typing `fvm flutter` gets tiresome, add to your shell profile:

```bash
alias flutter="fvm flutter"
alias dart="fvm dart"
```

## Privacy posture (short version)

This app handles medical information about minors. The long-term plan is
**zero-knowledge on the server**: every record is encrypted on-device before
it ever touches the network, using **per-person keys** that live only in the
devices of authorised caregivers. If our server database were ever
exfiltrated, the attacker would get ciphertext.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for details.

## License

TBD. Not yet open-source.
