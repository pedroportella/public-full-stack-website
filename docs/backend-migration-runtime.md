# Backend Migration Runtime

## Purpose

The backend migration runtime imports the legacy Drupal 7 content into the Drupal 11 CMS while keeping local verification repeatable and rollback-friendly.

## Runtime Services

Run the CMS profile from the repository root:

```bash
docker compose --profile cms up -d
```

The runtime includes:

- `drupal`: Drupal 11 application container.
- `database`: Drupal 11 MariaDB database.
- `legacy_database`: migration source loaded from the frozen Drupal 7 SQL dump.

Legacy public files mount read-only at:

```txt
/legacy/sites/default/files
```

## Content Model Config

The current config baseline is a curated content-model subset. Import it before migration verification:

```bash
./backend/scripts/import-content-model-config.sh
```

This imports content types, media type, taxonomy vocabularies, fields and language content settings from `backend/config/sync`.

## Migration Config

Refresh active migration definitions after changing `backend/modules/custom/web26_migration`:

```bash
./backend/scripts/refresh-migration-config.sh
```

This enables required migration modules, imports the custom migration module config and rebuilds Drupal caches.

## Smoke Test

Run:

```bash
./backend/scripts/migration-smoke-test.sh
```

The smoke test:

- imports the content model config;
- refreshes migration definitions;
- rolls back any existing sample records;
- imports users, selected files, selected media, selected taxonomy terms, selected taxonomy term translations, selected companies, all pages, selected articles, selected projects, node translations, selected URL aliases and the main menu links;
- verifies page, company, article and project translations, selected taxonomy term translations, translated media, bilingual aliases, shared taxonomy aliases, project `15`, alias `/portfolio/destination-nz` and the five main menu page links;
- rolls the sample records back out;
- prints migration status.

## Current Verified Surface

The tested chain proves:

- Drupal can read the legacy database through the `migrate` connection.
- Legacy public files copy from the mounted source path.
- Media images reference migrated file entities.
- Taxonomy term translations import into Drupal 11 content translations from legacy Locale rows.
- Page translations import into Drupal 11 content translations.
- Company, article and project translations import into Drupal 11 content translations.
- Translated page media references resolve independently from default-language media references.
- Translated project and article references resolve through migrated media, company and taxonomy entities.
- Project content references migrated company, media and taxonomy records.
- Project links are normalised when the source value has no URL scheme.
- Drupal 7 URL aliases import into Drupal 11 `path_alias` entities.
- Taxonomy URL aliases keep the source `und` language as shared aliases.
- The main menu imports into Drupal 11 menu link content with enabled internal page links.

## Known Follow-Up

The remaining content types need equivalent translation and alias verification before a full migration run.
