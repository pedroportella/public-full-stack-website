#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
  drush migrate:rollback web26_url_aliases --idlist=21 || true
  drush migrate:rollback web26_nodes_project --idlist=15 || true
  drush migrate:rollback web26_nodes_company --idlist=9 || true
  drush migrate:rollback web26_taxonomy_terms --idlist=28,5,29 || true
  drush migrate:rollback web26_media_images --idlist=1,4,10 || true
  drush migrate:rollback web26_files --idlist=1,4,10 || true
  drush migrate:rollback web26_users || true
}

./backend/scripts/import-content-model-config.sh
./backend/scripts/refresh-migration-config.sh

rollback

drush migrate:import web26_users
drush migrate:import web26_files --idlist=1,4,10
drush migrate:import web26_media_images --idlist=1,4,10 --force
drush migrate:import web26_taxonomy_terms --idlist=28,5,29 --update
drush migrate:import web26_nodes_company --idlist=9 --force
drush migrate:import web26_nodes_project --idlist=15 --force
drush migrate:import web26_url_aliases --idlist=21 --force

drush php:eval '
$project = \Drupal::entityTypeManager()->getStorage("node")->load(15);
$alias = \Drupal::entityTypeManager()->getStorage("path_alias")->loadByProperties(["path" => "/node/15", "alias" => "/portfolio/destination-nz"]);
if (!$project || $project->bundle() !== "project" || !$alias) {
  throw new \RuntimeException("Migration smoke test did not produce the expected project and alias.");
}
echo "Verified project 15 and alias /portfolio/destination-nz.\n";
'

rollback

drush migrate:status --group=web26 --format=json
