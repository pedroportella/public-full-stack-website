# Local Development

## Frontend

```bash
pnpm --dir frontend install
pnpm --dir frontend --filter @web26/web dev
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
