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
5. `web26_nodes_company`
6. `web26_nodes_page`
7. `web26_nodes_article`
8. `web26_nodes_project`
9. `web26_url_aliases`
10. `web26_menu_links`

Runtime assumptions:

- Drupal has a database connection key named `migrate` pointing at the legacy Drupal 7 database.
- Legacy public files are mounted at `/legacy/sites/default/files` inside the Drupal container.
- The first runnable pass should verify field source shapes before treating these skeletons as final imports.

Custom process plugins:

- `web26_public_uri_to_legacy_path`: converts `public://...` file URIs into the mounted legacy files path.
- `web26_url_with_scheme`: normalises legacy links that were stored without `http://` or `https://`.

Runtime verification:

```bash
./backend/scripts/migration-smoke-test.sh
```

The smoke test imports a small dependency chain, verifies a project node, path alias and main menu links, then rolls the imported records back out.
