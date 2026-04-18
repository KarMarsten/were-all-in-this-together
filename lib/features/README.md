# `lib/features/`

One folder per feature domain. Each feature is self-contained with its own
`data/`, `domain/`, and `ui/` subtrees and may depend on `lib/core/` but
**never on a sibling feature directly** (cross-feature communication goes
through Riverpod providers or shared `core/` services).

| Feature            | Status      | Purpose                                                                                   |
| ------------------ | ----------- | ----------------------------------------------------------------------------------------- |
| `home/`            | implemented | Tabbed home screen + feature tile grid + persistent Calm button.                          |
| `safety_plan/`     | implemented | Calm screen: low-stim coping strategies + crisis contacts. Placeholder content.           |
| `settings/`        | implemented | Settings shell.                                                                           |
| `people/`          | planned     | `Person` CRUD. Root entity — every other feature foreign-keys to a Person.                |
| `profile/`         | planned     | Living profile per Person: stims, preferences (sensory/food/clothing/social), routines, triggers, what helps, early signs, communication, sleep & appetite baseline. Embeds the Notes timeline. |
| `appointments/`    | planned     | Appointments with local-notification reminders, recurrence, attached provider.            |
| `medications/`     | planned     | Current list + history of changes. Medication report PDF export for clinicians.           |
| `providers/`       | planned     | Doctors, therapists, specialists. Phone, address, portal link.                            |
| `programs/`        | planned     | Schools, camps, after-care. Calendars, holidays, contact tree.                            |
| `apps_sites/`      | planned     | Portals, IEP tools, telehealth — URLs + notes (never passwords).                          |
| `milestones/`      | planned     | Milestones & dates: flexible typed life-log, searchable ("when did X happen?").           |

See [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) for the data model
and naming conventions each feature follows.
