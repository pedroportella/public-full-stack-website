# Local Development

## Pinned Versions

Runtime versions are pinned so security updates are deliberate and reviewable:

| Component | Pinned in | Version |
| --- | --- | --- |
| pnpm | `frontend/package.json` (`packageManager`) | 10.34.9 |
| Next.js / React | `frontend/apps/web/package.json` | 16.4.x / 19.2.x |
| ESLint / eslint-config-next | `frontend/apps/web/package.json`, `eslint.config.mjs` | 10.14.x / 16.4.x |
| Transitive security floors | `frontend/pnpm-workspace.yaml` (`overrides`) | postcss, sharp |
| Drupal core | `docker/drupal/Dockerfile` | 11.4.11 (PHP 8.5) |
| Drush, migrate_plus, migrate_tools | `docker/drupal/Dockerfile` | ^13.8, ^6.0.10, ^6.1.4 |
| MariaDB | `docker-compose.yml` | 11.8 |

The Drupal image build runs `composer audit` and fails on known advisories. After changing a pinned version, check the frontend with `pnpm --dir frontend audit`. For Drupal, rebuild with `docker compose --profile cms build --pull drupal`, then run `drush updatedb`.

`frontend/pnpm-workspace.yaml` also allows ESLint 10 as a peer for `eslint-plugin-import`, `eslint-plugin-jsx-a11y` and `eslint-plugin-react`. `eslint-config-next` 16.4 supports ESLint 10, but these plugins have not widened their declared peer ranges yet.

Do not pin MariaDB to an older line than the one that created the local data volumes.

## Frontend

```bash
pnpm --dir frontend install
pnpm --dir frontend --filter @web26/web dev
```

Checks:

```bash
pnpm --dir frontend lint
pnpm --dir frontend typecheck
pnpm --dir frontend build
```

Frontend URL:

```txt
http://127.0.0.1:3000
```

## Backend

```bash
docker compose --profile cms up -d
```

Drupal URL:

```txt
http://localhost:8080
```

Database URL:

```txt
127.0.0.1:33080
```

Prepare Drupal content-model config for migration testing:

```bash
./backend/scripts/import-content-model-config.sh
```

Refresh migration config after changing `backend/modules/custom/web26_migration`:

```bash
./backend/scripts/refresh-migration-config.sh
```

Run the reversible backend migration smoke test:

```bash
./backend/scripts/migration-smoke-test.sh
```
