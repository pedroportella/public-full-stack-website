# Backend

Drupal 11 headless CMS baseline for Web26.

- `docker-compose.yml` defines a local Drupal 11 and MariaDB runtime.
- Drupal public files mount to `backend/files`.
- Drupal private files mount to `backend/private-files`.
- Drupal config, custom modules and migration definitions should live under this backend boundary.

Key folders:

- `config/sync`: exported Drupal configuration for content types, fields, media, vocabularies, language settings and API-related config.
- `modules/custom`: custom Drupal modules owned by this project.
- `modules/custom/web26_migration`: migration definitions and custom process plugins for importing the legacy Drupal 7 content.
- `scripts`: repeatable backend runtime commands for configuration import and migration verification.

Migration runtime:

- Drupal settings expose the legacy source database as `$databases['migrate']['default']`.
- The `legacy_database` service imports the frozen Drupal 7 SQL dump on first startup.
- Legacy public files mount read-only at `/legacy/sites/default/files`.
- Exported config mounts at `/var/www/config/sync`.
- Custom modules mount at `/var/www/html/modules/custom`.

Start the local CMS baseline from the repository root:

```bash
docker compose --profile cms up -d
```

Local Drupal URL:

```txt
http://localhost:8080
```

Import the backend content model config used by the migration runtime:

```bash
./backend/scripts/import-content-model-config.sh
```

Refresh migration definitions after changing the custom migration module:

```bash
./backend/scripts/refresh-migration-config.sh
```

Run the reversible migration smoke test:

```bash
./backend/scripts/migration-smoke-test.sh
```
