# We're All In This Together

A private, end-to-end encrypted life-admin app for families supporting a
neurodivergent child, a neurodivergent parent, or both. One household. Any
number of neurodivergent people in it. Any number of trusted people with
access.

> **Status:** early scaffold. Walking skeleton only. Data model, database,
> encryption, and sync are not yet implemented. See
> [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the plan.

---

## What it will do

- **Appointments & reminders** — calendar + local push notifications.
- **Medications** — current list *and* a full history of dose/med changes,
  with one-tap **Medication report** PDF for doctors.
- **Providers** — PCP, specialists, therapists, dentists: phone, address,
  portal link, notes.
- **Programs** — schools, camps, after-care: calendars, holidays, contact
  trees, key phone numbers.
- **Apps & Sites** — portals (IEP, telehealth, insurance): URLs + notes
  (never passwords).
- **Milestones & dates** — diagnoses, shots, milestones. Flexible life-log,
  globally searchable ("when did X get their last flu shot?").
- **Profile** — a living document per person: stims, preferences (sensory,
  food & eating, clothing, social), routines, triggers, what helps, early
  signs, communication, sleep & appetite baseline. Includes an embedded
  **Notes** timeline for quickly jotting what changed and when.
- **Care summary** — a second PDF export built from Profile + routines + what
  helps + early signs + crisis contacts. The "here's how to spend a weekend
  with them" handoff doc for babysitters, grandparents, and respite.
- **Calm** — in-the-moment coping strategies and crisis contacts, reachable
  in one tap from anywhere, rendered in a dedicated low-stimulation theme.

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
├── app.dart               MaterialApp.router wiring
├── core/                  cross-cutting infra (theme, router, crypto, db, notif)
└── features/              one folder per feature domain
    ├── home/              tabbed home + persistent Calm button
    ├── safety_plan/       Calm screen (low-stim theme)
    ├── settings/
    ├── people/            planned: Person CRUD (root entity)
    ├── profile/           planned: stims, routines, preferences + Notes timeline
    ├── appointments/      planned
    ├── medications/       planned (+ Medication report PDF)
    ├── providers/         planned
    ├── programs/          planned
    ├── apps_sites/        planned
    └── milestones/        planned (Milestones & dates)
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
