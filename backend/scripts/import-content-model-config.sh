#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

docker compose exec -T drupal bash -lc '
set -eu

source_dir=/var/www/config/sync
target_dir=/tmp/web26-content-config

rm -rf "$target_dir"
mkdir -p "$target_dir"

copy_pattern() {
  pattern="$1"
  for file in "$source_dir"/$pattern; do
    [ -e "$file" ] || continue
    cp "$file" "$target_dir"/
  done
}

copy_pattern "language.entity.pt-br.yml"
copy_pattern "media.type.image.yml"
copy_pattern "node.type.*.yml"
copy_pattern "taxonomy.vocabulary.*.yml"
copy_pattern "field.storage.*.yml"
copy_pattern "field.field.*.yml"
copy_pattern "language.content_settings.*.yml"
'

docker compose exec -T drupal vendor/bin/drush config:import --partial --source=/tmp/web26-content-config --yes
