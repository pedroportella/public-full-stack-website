# Public Full Stack Website

Web26 full-stack rebuild for `pedroportella.com`.

## Workspace

This repository is the implementation home for the Drupal 11 headless CMS and Next.js frontend.

```txt
backend/
docker/
docs/
frontend/
  apps/
    web/
  packages/
    services-content/
    ui-assets/
    ui-library/
    ui-tokens/
    utils/
```

The top-level shape intentionally follows the Services Australia and LAR prototypes:

```txt
backend/
frontend/
docker/
docs/
docker-compose.yml
```

The frontend remains a pnpm workspace:

```txt
frontend/
  apps/
    web/
  packages/
    services-content/
    ui-assets/
    ui-library/
    ui-tokens/
    utils/
```

## Local Baseline

The local baseline runs the frontend from the `frontend` workspace and the Drupal CMS through Docker Compose.

```bash
cp .env.example .env.local
pnpm --dir frontend install
pnpm --dir frontend --filter @web26/web dev
docker compose --profile cms up -d
```

## Documentation

Repository documentation lives in `docs/`.
