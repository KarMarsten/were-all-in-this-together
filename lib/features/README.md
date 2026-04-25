# `lib/features/`

One folder per feature domain. Each feature is self-contained with its own
`data/`, `domain/`, and `presentation/` or `ui/` subtrees and may depend on
`lib/core/` but
**never on a sibling feature directly** (cross-feature communication goes
through Riverpod providers or shared `core/` services).

| Feature            | Status        | Purpose                                                                                   |
| ------------------ | ------------- | ----------------------------------------------------------------------------------------- |
| `home/`            | implemented   | Tabbed home screen + feature tile grid + persistent Calm button + search entry.          |
| `safety_plan/`     | implemented   | Calm screen: low-stim theme, concrete coping copy, crisis tel/SMS, profile-backed blocks. |
| `settings/`        | implemented   | Settings shell + care summary entry.                                                     |
| `search/`          | implemented   | Cross-domain local search across People, meds, visits, Notes, profile, providers, etc.   |
| `people/`          | implemented   | `Person` CRUD, roster, active-person switcher.                                            |
| `profile/`         | implemented   | Baselines + structured `ProfileEntry` rows, Notes links, archive, Calm contract.          |
| `observations/`    | implemented   | Notes timeline (`Observation`), links to profile entries.                                 |
| `appointments/`    | implemented   | Appointments + local-notification reminders, provider link, Today integration.             |
| `medications/`     | implemented   | Meds + groups + schedule + Today + dose logs + notifications + adherence PDF.             |
| `reports/`         | implemented   | Adherence report PDF + selectable **care summary** PDF with Providers/program/link sections. |
| `providers/`       | implemented   | Care providers, contacts, after-hours info, actions, archive-safe references.              |
| `programs/`        | implemented   | Schools / camps / after-care — encrypted contacts, Provider links, actions, archive.       |
| `apps_sites/`      | implemented   | Categorized URLs + username hints / login notes, Provider/Program links, no passwords.     |
| `milestones/`      | implemented   | Milestones & dates: typed life-log, archive / restore.                                    |

See [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) for the data model
and naming conventions each feature follows.
