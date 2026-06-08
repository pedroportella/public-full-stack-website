#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

docker compose exec -T drupal vendor/bin/drush pm:enable migrate migrate_drupal migrate_plus migrate_tools web26_migration --yes
docker compose exec -T drupal vendor/bin/drush config:import --partial --source=/var/www/html/modules/custom/web26_migration/config/install --yes
docker compose exec -T drupal vendor/bin/drush cache:rebuild
