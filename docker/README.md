# Docker

Docker support for the Web26 local full-stack baseline.

The root `docker-compose.yml` owns the local Drupal 11 and MariaDB services. This folder is reserved for service-specific Docker files and configuration, following the Services Australia and LAR repository shape.

Current baseline:

```bash
docker compose --profile cms up -d
```

Future expected contents:

- PHP/Drupal runtime overrides;
- web server configuration if Drupal moves behind nginx/apache custom config;
- database bootstrap scripts;
- migration-runner service definitions if needed.
