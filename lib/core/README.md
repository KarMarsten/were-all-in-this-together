# `lib/core/`

Cross-cutting infrastructure shared by every feature. Nothing here should
depend on anything in `lib/features/`.

| Module          | Status      | Purpose                                                                |
| --------------- | ----------- | ---------------------------------------------------------------------- |
| `router/`       | implemented | `go_router` config + route constants.                                  |
| `theme/`        | implemented | Material 3 light/dark themes + dedicated low-stim Calm theme.          |
| `database/`     | planned     | `drift` schema, encrypted-at-rest SQLite, migrations.                  |
| `crypto/`       | planned     | E2E encryption primitives (X25519 key agreement, XChaCha20-Poly1305).  |
| `notifications/`| planned     | `flutter_local_notifications` wrapper for appointment/med reminders.   |
| `widgets/`      | planned     | Shared UI atoms (custom form fields, date pickers, etc.).              |
