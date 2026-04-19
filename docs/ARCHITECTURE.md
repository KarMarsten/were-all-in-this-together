# Architecture

This document is the decision log for the project. Every non-trivial choice
about what we're building and how we're building it should end up here so
future-us (or a collaborator) can understand *why*, not just *what*.

- [Principles](#principles)
- [Audiences](#audiences)
- [Feature scope (v1)](#feature-scope-v1)
- [Relationships & access](#relationships--access)
- [Data model](#data-model)
- [Privacy & compliance posture](#privacy--compliance-posture)
- [Naming conventions](#naming-conventions)
- [Technology choices](#technology-choices)
- [Phase plan](#phase-plan)
- [Open questions](#open-questions)

---

## Principles

1. **Most-sensitive data wins.** Medical and mental-health information about
   minors is the worst-case data class this app will ever touch. Architecture
   defaults are set for that case, not for an average case.
2. **End-to-end encrypted by default.** The server stores ciphertext. Keys
   live only on authorised devices. A full server breach yields unusable data.
3. **Offline-first.** Every feature must function with no network. The Calm
   screen, specifically, must also function under cognitive load — no auth
   gate, no spinner, no notifications.
4. **Many people, many caregivers.** One household may track multiple
   neurodivergent people, and each of them may have multiple people in their
   circle with access. Single-person, single-caregiver is a special case, not
   the design centre.
5. **GDPR-shaped globally.** We assume EU residents will use the app and
   design to that bar from the start.
6. **Neurodiversity-affirming framing.** We do not pathologise. We use
   community-native vocabulary (stims, dysregulation, meltdown, etc.). We do
   not use ABA-derived language (compliance, reinforcers, interventions,
   behavior modification). See [Naming conventions](#naming-conventions).

## Audiences

| Audience                                           | Ship phase |
| -------------------------------------------------- | ---------- |
| Parent(s) supporting a neurodivergent child        | Phase 1    |
| A neurodivergent adult self-supporting             | Phase 1    |
| A neurodivergent parent supporting themselves *and* a neurodivergent child in the same household | Phase 1 (primary case) |

The data model is identical for all three. The UI flows are 95% shared; the
remaining 5% is tone, pronouns, and defaults, chosen by the person using the
app, not hardcoded by role.

## Feature scope (v1)

- **Appointments** — with local-notification reminders and optional recurrence.
- **Medications** — current list *and* a full history of dose/med changes,
  with one-tap PDF **medication report** export for doctors.
- **Providers** — PCP, specialists, therapists, dentists.
- **Programs** — schools, camps, after-care; contact tree, calendars, holidays.
- **Apps & Sites** — portals, IEP systems, telehealth. URLs + notes, never
  passwords.
- **Milestones & dates** — flexible typed life-log, globally searchable
  ("when did X get their last flu shot?", "when did diagnosis happen?").
- **Profile** — a living document per Person:
  - Stims
  - Preferences (sensory · food & eating · clothing · social)
  - Routines
  - Triggers
  - What helps *(clinical synonym: "regulators")*
  - Early signs *(clinical synonym: "warning signs" / "red flags")*
  - Communication (preferred channels, AAC, scripts, non-verbal cues,
    "when stressed, don't ask questions — just sit with them")
  - Sleep & appetite baseline
  - Embedded **Notes** timeline — timestamped short observations; this is how
    we answer "when did X start / stop / change?"
- **Calm** — in-the-moment coping strategies + crisis contacts; dedicated
  low-stimulation theme; reachable in one tap from anywhere.
- **Global search** — across all of the above.
- **Exports** — two PDFs:
  - **Medication report** for clinicians (med history, current regimen,
    allergies).
  - **Care summary** for babysitters / respite / grandparents / subs
    (Profile sections + current routines + what-helps + early-signs +
    crisis contacts).

## Relationships & access

Two distinct concepts — conflating them was a design bug caught early:

| Concept     | What it is                                                     | Can be the same human? |
| ----------- | -------------------------------------------------------------- | ---------------------- |
| **Person**  | Someone the app tracks data *about* (subject of data)          | Yes                    |
| **User**    | Someone who logs into the app (accessor of data)               | Yes                    |

Relationships:

- A **Household** contains zero or more Persons and one or more Users.
- A User may link to a Person (self-management: the User is also tracked).
- A User may also have **AccessGrant**s to other Persons (caregiving).
- A Person has no required User (a child might never log in).
- A User has no required Person (a caregiver might not track their own data).

Example cast:

| Human   | User? | Person? | Grants                                 |
| ------- | ----- | ------- | -------------------------------------- |
| Mom     | yes   | yes     | `owner(Mom's Person)`, `caregiver(Son's Person)` |
| Son (8) | no    | yes     | —                                      |
| Dad     | yes   | no      | `caregiver(Son's Person)`              |
| Grandma | yes   | no      | `viewer(Son's Person)`                 |

This cleanly supports single-subject households, multi-ND-person households,
and per-Person privacy ("Mom can share Son with Dad without sharing her own
records").

**Phase-1 simplification.** On a single local-only device we don't need
`User` or `AccessGrant` tables yet — the device holder sees everything. We
*do* design `Person` to be role-neutral from day one so Phase 2 is additive,
not destructive.

## Data model

```text
Household            (Phase 2)
  id
  name
  createdAt

Person
  id
  householdId?            -- null in Phase 1 (single implicit household)
  displayName
  dob?
  pronouns?
  avatar?
  preferredFramingNotes?  -- identity-first vs person-first, self-selected

User                 (Phase 2)
  id
  authUserId              -- Supabase auth id
  householdId
  personId?               -- non-null if this User is ALSO a tracked Person

AccessGrant          (Phase 2)
  id
  userId
  personId
  role                    -- owner | caregiver | viewer
  createdAt

-- ─────────────────────────────────────────────────────────────────
-- Domain entities — all foreign-key to Person, never to User.
-- ─────────────────────────────────────────────────────────────────

Appointment
  id, personId, providerId?, title, startAt, endAt, location, notes,
  reminderOffsets[] (e.g. [-24h, -1h]), recurrenceRule?, status

Medication
  id, personId, name, activeIngredient?, strength, form, route
MedicationEvent                                   -- the history
  id, medicationId, type (start|stop|dose-change|note),
  effectiveAt, dose?, frequency?, prescriberId?, reason?, notes

Provider
  id, personId, kind (pcp|specialist|therapist|dentist|other),
  name, phone, address, portalUrl, notes

Program
  id, personId, name, contactPhone, addresses[], calendarEvents[], notes

AppSite
  id, personId, name, url, notes               -- passwords never stored

MilestoneOrDate
  id, personId, category (diagnosis|shot|milestone|other),
  label, date, notes

-- ─────────────────────────────────────────────────────────────────
-- Profile — living document per Person
-- ─────────────────────────────────────────────────────────────────

Profile
  id, personId                                   -- 1:1 with Person
  communicationNotes
  sleepBaseline
  appetiteBaseline
  -- sections below are 1:many children of Profile

ProfileEntry
  id, profileId, section, label, details,
  status (active|paused|resolved), firstNoted?, lastNoted?
  -- `section` is one of:
  --   stim
  --   preference_sensory
  --   preference_food
  --   preference_clothing
  --   preference_social
  --   routine_block       -- grouped: Morning / School / Afternoon / Evening / Bedtime
  --   routine_step        -- child of a routine_block via `parentEntryId`
  --   trigger
  --   what_helps
  --   early_sign
  parentEntryId?

Observation                                     -- "Notes" in the UI
  id, personId, observedAt, category, label, notes, tags[]

-- ─────────────────────────────────────────────────────────────────
-- Safety plan
-- ─────────────────────────────────────────────────────────────────

SafetyPlan
  id, personId,
  rightNow[],                                    -- "Right now" quick list
  copingStrategies[ordered],
  reasonsToStay[],
  safePeopleIds[],                               -- refs to Provider-like rows
  crisisContacts[]
SafetyPlanEvent                                  -- optional usage log
  id, safetyPlanId, usedAt, trigger?, whatHelped?, durationMinutes?
```

Every record also carries `createdAt`, `updatedAt`, `deletedAt?`
(soft-delete for sync merge), a `lastWriterDeviceId`, and a `rowVersion`.
IDs are client-generated UUID v4 so they are stable across devices.

## Privacy & compliance posture

### Regulatory assumptions

- **HIPAA (US)** — Not expected to apply. We are not a covered entity or
  business associate. Consumer apps tracking personal medical information
  generally aren't HIPAA-regulated. This changes the day we integrate with a
  provider.
- **GDPR (EU)** — Binding. Lawful basis = explicit consent. We will implement:
  access, export, rectification, and deletion rights; privacy policy; DPA
  with each processor (e.g. Supabase); breach-notification readiness.
- **COPPA (US)** — Relevant because we store information *about* minors.
  The parent is the user; the child is the data subject. Privacy policy
  addresses this directly.
- **Not legal advice.** Before any public launch, a real lawyer reviews this.

### Chosen path: zero-knowledge server (Path A)

- Data is encrypted **on device** with **per-Person symmetric keys**
  (XChaCha20-Poly1305 / AES-GCM equivalent).
  - *Why per-Person and not per-Household?* Because within a household a
    parent may legitimately want to share one Person's records (their child)
    while keeping another Person's records (their own self-management)
    private. Household-scoped keys make that impossible; per-Person keys
    make it natural.
- The server (Supabase, EU region) stores encrypted blobs indexed by opaque
  IDs. The server never sees plaintext names, medications, diagnoses,
  appointments, stims, or safety-plan content.
- **Joining an existing household** (e.g. Dad being added to Son's care
  circle) happens via a QR pairing code from the inviting User's device,
  which transfers only the specific Person key(s) being granted.
- **Key recovery:** device keys are persisted to the iOS Keychain
  (hardware-backed, auto-syncs across the user's Apple devices via iCloud
  Keychain). An optional printable **recovery phrase** lets the user restore
  access on a fresh device lineage. If all authorised devices are lost *and*
  no recovery phrase exists, data is unrecoverable by design.
- **Search is client-side.** At this scale (dozens to low hundreds of records
  per Person) this is fine.
- **Analytics & crash reporting** — disabled by default, opt-in, scrubbed.
  Never a third-party SDK that transmits content.

### What deliberately is *not* in scope for v1

- Real-time collaboration (CRDT, OT). Last-writer-wins is good enough.
- Server-side search / indexing.
- Staff / admin access to user content (there is none; we literally cannot
  read it).
- Web client. Browsers don't have a secure hardware keychain, which
  complicates key handling; we'll tackle it separately.

## Naming conventions

This project handles identity-sensitive material. Words matter. Establishing
and holding a consistent vocabulary is a feature, not a polish task.

### General rules

1. **Identity-first as the default** ("autistic person", not "person with
   autism"), *but* allow each Person to set their own `preferredFramingNotes`
   and honour it in UI where we refer to them.
2. **No pathologising framing.** Avoid: *suffering from*, *afflicted*,
   *symptoms*, *disorder* (where avoidable), *high/low functioning*, *cure*,
   *recovery*, *case*, *abnormal*.
3. **No ABA-derived language.** Avoid: *compliance*, *reinforcers*,
   *interventions*, *behavior modification*, *extinction*, *prompting
   hierarchy*. These have real trauma history in the community.
4. **Prefer "support" over "manage"** when speaking about people. *Manage*
   keeps its slot for administrative things (managing appointments,
   managing a medication list) but not for humans.
5. **Use community-native terms** where they exist: *stims, stimming,
   meltdown, shutdown, dysregulated, co-regulation, masking, hyperfocus,
   demand avoidance*.

### Canonical UI / copy vocabulary

| Concept                              | UI label               | Data-model / dev term   |
| ------------------------------------ | ---------------------- | ----------------------- |
| The feature domain for profile       | **Profile**            | `profile`               |
| Stateful traits sub-section          | Sensory / Food / etc.  | `preference_*`          |
| Early warning signs                  | **Early signs**        | `early_sign`            |
| Self-regulation strategies           | **What helps**         | `what_helps`            |
| Observation timeline                 | **Notes**              | `Observation`           |
| Flexible life-log feature            | **Milestones & dates** | `MilestoneOrDate`       |
| The babysitter/respite export        | **Care summary**       | *handoff doc*           |
| The clinician export                 | **Medication report**  | *med history export*    |
| Safety plan screen                   | **Calm**               | `SafetyPlan`            |
| First calming block on Calm screen   | **Right now**          | `rightNow[]`            |
| People in a Person's circle          | "People with access"   | `User` + `AccessGrant`  |
| Roles in AccessGrant                 | owner / caregiver / viewer | same                |

### Words we *don't* use

*Behavior* (as a euphemism for "problem"), *difficult*, *challenging*,
*rigid*, *obsessed* (→ *intensely interested*), *outburst*, *tantrum*
(→ *meltdown*, when accurate), *refusing* (→ *unable/struggling*),
*non-compliant*, *manipulation*, *attention-seeking* (→ *connection-seeking*),
*special needs* in app copy (fine in feature docs when quoting parent usage).

## Technology choices

| Area            | Choice                                    | Notes                                                       |
| --------------- | ----------------------------------------- | ----------------------------------------------------------- |
| SDK             | Flutter stable (via `fvm`, pinned)        | `.fvmrc` pins the version per repo.                         |
| Language        | Dart 3.11+                                |                                                             |
| State mgmt      | `flutter_riverpod` 3.x                    | Hand-written providers; generator skipped for now.          |
| Navigation      | `go_router` 17.x                          | Declarative, deep-link friendly.                            |
| Local DB        | `drift` + `sqlite3_flutter_libs`          | Type-safe SQLite. Encrypted via our own layer.              |
| Crypto          | `cryptography` + `cryptography_flutter`   | Native-accelerated on iOS/Android. XChaCha20-Poly1305.      |
| Key storage     | `flutter_secure_storage`                  | Wraps iOS Keychain / Android Keystore.                      |
| Reminders       | `flutter_local_notifications` + `timezone`| Local only. No push server.                                 |
| PDF             | `pdf` + `printing`                        | Exports → share sheet / AirDrop / email / print.            |
| Data classes    | `freezed` + `json_serializable`           | Immutable models.                                            |
| Lints           | `very_good_analysis` 10.x                 | Strict.                                                     |
| Sync backend    | **Supabase, EU region** (Phase 2)         | Dumb encrypted blob store + auth + realtime.                |
| Auth            | Sign in with Apple + email magic link     | Identifier only. Auth does *not* unlock content; the Person key does. |
| Biometric lock  | `local_auth` (Phase 1+)                   | Optional; never required for the Calm screen.               |

### Deferred tooling

- **`riverpod_generator` / `riverpod_lint` / `custom_lint`** — currently
  incompatible with the `drift_dev` → `source_gen` version pins and with
  `riverpod` 3.2. Re-evaluate when the ecosystem catches up.

## Phase plan

### Phase 0 — Scaffold *(done)*

- Flutter project pinned via fvm.
- Feature-first folder layout.
- Material 3 theme + dedicated Calm theme.
- Walking skeleton: Home → Calm → Settings.
- Strict linting. Architecture doc.

### Phase 1 — Local-only MVP

- `Person` CRUD (role-neutral; multiple Persons per device).
- Encrypted local database (per-Person keys in Keychain, no sync yet).
- Appointments + local notifications.
- Providers.
- Medications + history + **Medication report** PDF.
- Milestones & dates.
- Apps & Sites (placeholder routes + copy; encrypted URL list next).
- Programs (placeholder routes + copy; contact tree / calendar next).
- Profile + Notes — **shipped** locally (structured entries, Calm surfacing,
  observation timeline, profile-line links).
- Safety plan (Calm: authored coping + crisis + profile blocks) — iterate on
  copy as needed.
- **Care summary** PDF — **shipped** (baselines + active structured + crisis
  lines); deepen with locale-specific hotlines when vetted.
- Global search — **partial** (People names); extend to meds / appointments /
  notes / profile labels.

### Phase 2 — Multi-device + multi-user

- Supabase backend (EU).
- `User`, `AccessGrant`, `Household` tables.
- E2E-encrypted sync protocol (per-Person keys).
- Pairing flow (QR / short code) that transfers only the granted Person key(s).
- Recovery phrase.
- Privacy policy, ToS, data export, account deletion.

### Phase 3 — Self-management polish

- Alternate UI defaults tuned for an adult managing their own data.
- Customisable Calm plan that reads from Profile → "What helps".
- Possibly Android launch.

### Phase 4 — Later

- Apple Watch complication (meds due, next appointment).
- Respite-caregiver short-lived read-only share links.
- Localisation.
- Web (once a secure browser-side key story exists).

## Open questions

- Final bundle ID / Apple Developer team.
- Branding / app icon.
- Is "Calm" the right in-app label for every user, or should it be
  user-configurable per Person? (Tentative: configurable, default "Calm".)
- Multi-household support: is one household per account plenty, or do we
  need a User to belong to multiple households (e.g. divorced co-parents
  with separate children)? Tentative: one household per account in v1,
  revisit in Phase 3.
