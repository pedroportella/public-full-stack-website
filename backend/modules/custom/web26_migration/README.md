# Web26 Migration Module

Custom Drupal migration module for importing the legacy Drupal 7 website into Drupal 11.

This module owns:

- migration group and migration definitions;
- field and reference transforms;
- source ID preservation;
- custom migrate process plugins;
- migration dependency ordering.

Expected structure:

```txt
config/install
src/Plugin/migrate/process
src/Plugin/migrate/source
```

The migration imports files before media, media before content, taxonomy before node references, and aliases after their target entities exist.

Migration group:

```txt
web26
```

Initial migration order:

1. `web26_users`
2. `web26_files`
3. `web26_media_images`
4. `web26_taxonomy_terms`
5. `web26_taxonomy_term_translations`
6. `web26_nodes_company`
7. `web26_nodes_company_translations`
8. `web26_nodes_page`
9. `web26_nodes_page_translations`
10. `web26_nodes_article`
11. `web26_nodes_article_translations`
12. `web26_nodes_project`
13. `web26_nodes_project_translations`
14. `web26_url_aliases`
15. `web26_menu_links`
16. `web26_menu_link_translations`

Runtime assumptions:

- Drupal has a database connection key named `migrate` pointing at the legacy Drupal 7 database.
- Legacy public files are mounted at `/legacy/sites/default/files` inside the Drupal container.
- The first runnable pass should verify field source shapes before treating these skeletons as final imports.

Custom process plugins:

- `web26_public_uri_to_legacy_path`: converts `public://...` file URIs into the mounted legacy files path.
- `web26_url_with_scheme`: normalises legacy links that were stored without `http://` or `https://`.

Custom source plugins:

- `web26_node_entity_translation`: reads legacy node entity translations from current Drupal 7 field tables, including rows whose `entity_translation.revision_id` is empty.
- `web26_taxonomy_term_translation`: reads legacy taxonomy term labels and descriptions from Drupal 7 Locale rows keyed by taxonomy contexts.
- `web26_menu_link_translation`: reads legacy menu link labels from Drupal 7 i18n/Locale rows keyed by menu item contexts.

Runtime verification:

```bash
./backend/scripts/migration-smoke-test.sh
```

The smoke test imports a small dependency chain, verifies page, company, article and project translations, translated media, bilingual aliases, a project node, path alias, main menu links and translated main menu labels, then rolls the imported records back out.
It also verifies selected taxonomy term translations and shared taxonomy aliases.

Taxonomy translation reconciliation:

```bash
./backend/scripts/taxonomy-translation-reconciliation.sh
```

The taxonomy reconciliation imports all taxonomy terms and all taxonomy term translations, compares translated labels and descriptions against the legacy Locale source rows, then rolls the taxonomy records back out.

Node count reconciliation:

```bash
./backend/scripts/node-count-reconciliation.sh
```

The node reconciliation imports all in-scope node dependencies, all page, company, article and project nodes, and all node translations, compares Drupal 11 node language rows against the legacy source counts, then rolls the imported records back out.

File and media reconciliation:

```bash
./backend/scripts/file-media-reconciliation.sh
```

The file and media reconciliation imports all managed files and image media entities, verifies source disk presence, Drupal file metadata and media image references, then rolls the imported records back out.

URL alias reconciliation:

```bash
./backend/scripts/alias-reconciliation.sh
```

The alias reconciliation imports all alias target dependencies and all URL aliases, compares mapped Drupal path aliases against the legacy source rows by path, alias, language and source type, then rolls the imported records back out.
