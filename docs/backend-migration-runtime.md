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
- imports users, selected files, selected media, selected taxonomy terms, selected taxonomy term translations, selected companies, all pages, selected articles, selected projects, node translations, selected URL aliases, the main menu links and translated main menu labels;
- verifies page, company, article and project translations, selected taxonomy term translations, translated media, bilingual aliases, shared taxonomy aliases, project `15`, alias `/portfolio/destination-nz`, the five main menu page links and their Portuguese labels;
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
- Main menu link translations import into Drupal 11 menu link content translations from legacy i18n/Locale rows.

## Taxonomy Translation Reconciliation

Run:

```bash
./backend/scripts/taxonomy-translation-reconciliation.sh
```

The reconciliation imports all taxonomy terms and all taxonomy term translations, compares Drupal 11 translated labels and descriptions against the legacy taxonomy Locale rows, rolls the taxonomy records back out and prints migration status.

The current source contains 25 taxonomy term translation rows for the migrated vocabularies.

## Node Count Reconciliation

Run:

```bash
./backend/scripts/node-count-reconciliation.sh
```

The reconciliation imports all in-scope node dependencies, all page, company, article and project nodes, and all node translations, compares Drupal 11 node language rows against the legacy source counts, rolls the imported records back out and prints migration status.

The current source contains 42 in-scope base nodes and 22 node translation rows, for 64 expected Drupal node language rows after import.

## File And Media Reconciliation

Run:

```bash
./backend/scripts/file-media-reconciliation.sh
```

The reconciliation imports all managed files and image media entities, verifies source disk presence, Drupal file metadata and media image references, rolls the imported records back out and prints migration status.

The current source contains 97 managed image files: 38 JPEG files and 59 PNG files.

## Known Follow-Up

The remaining content types need equivalent translation and alias verification before a full migration run.
