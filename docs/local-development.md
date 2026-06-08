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
