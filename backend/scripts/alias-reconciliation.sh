#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
  drush migrate:rollback web26_url_aliases || true
  drush migrate:rollback web26_nodes_project_translations || true
  drush migrate:rollback web26_nodes_project || true
  drush migrate:rollback web26_nodes_article_translations || true
  drush migrate:rollback web26_nodes_article || true
  drush migrate:rollback web26_nodes_page_translations || true
  drush migrate:rollback web26_nodes_page || true
  drush migrate:rollback web26_nodes_company_translations || true
  drush migrate:rollback web26_nodes_company || true
  drush migrate:rollback web26_taxonomy_term_translations || true
  drush migrate:rollback web26_taxonomy_terms || true
  drush migrate:rollback web26_media_images || true
  drush migrate:rollback web26_files || true
  drush migrate:rollback web26_users || true
}

cleanup_required=0
cleanup() {
  if [ "$cleanup_required" -eq 1 ]; then
    rollback
  fi
}
trap cleanup EXIT

./backend/scripts/import-content-model-config.sh
./backend/scripts/refresh-migration-config.sh

rollback

drush migrate:import web26_users
drush migrate:import web26_files
drush migrate:import web26_media_images --force
drush migrate:import web26_taxonomy_terms --update
drush migrate:import web26_taxonomy_term_translations --force
drush migrate:import web26_nodes_company --force
drush migrate:import web26_nodes_company_translations --force
drush migrate:import web26_nodes_page --force
drush migrate:import web26_nodes_page_translations --force
drush migrate:import web26_nodes_article --force
drush migrate:import web26_nodes_article_translations --force
drush migrate:import web26_nodes_project --force
drush migrate:import web26_nodes_project_translations --force
drush migrate:import web26_url_aliases --force
cleanup_required=1

drush php:eval "$(cat <<'PHP'
use Drupal\Core\Database\Database;

$source = Database::getConnection('default', 'migrate');
$source_rows = $source->query("
  SELECT pid, source, alias, language
  FROM url_alias
  ORDER BY pid
")->fetchAll(\PDO::FETCH_ASSOC);

$expected_count = count($source_rows);
$source_by_language = [];
$source_by_type = [];
$source_by_type_language = [];
foreach ($source_rows as $row) {
  $language = $row['language'];
  $type = strtok($row['source'], '/');
  $source_by_language[$language] = ($source_by_language[$language] ?? 0) + 1;
  $source_by_type[$type] = ($source_by_type[$type] ?? 0) + 1;
  $source_by_type_language[$type][$language] = ($source_by_type_language[$type][$language] ?? 0) + 1;
}

$map_rows = \Drupal::database()->query("
  SELECT sourceid1, destid1
  FROM migrate_map_web26_url_aliases
  WHERE destid1 IS NOT NULL
  ORDER BY sourceid1
")->fetchAll(\PDO::FETCH_ASSOC);

$source_by_pid = [];
foreach ($source_rows as $row) {
  $source_by_pid[(int) $row['pid']] = $row;
}

$alias_storage = \Drupal::entityTypeManager()->getStorage('path_alias');
$missing_map_source = [];
$missing_target_alias = [];
$alias_mismatches = [];
$target_by_language = [];
$target_by_type = [];
$target_by_type_language = [];

foreach ($map_rows as $map_row) {
  $pid = (int) $map_row['sourceid1'];
  $source_row = $source_by_pid[$pid] ?? NULL;
  if (!$source_row) {
    $missing_map_source[] = $pid;
    continue;
  }

  $alias_entity = $alias_storage->load((int) $map_row['destid1']);
  if (!$alias_entity) {
    $missing_target_alias[] = $pid;
    continue;
  }

  $expected_path = '/' . ltrim($source_row['source'], '/');
  $expected_alias = '/' . ltrim($source_row['alias'], '/');
  $expected_language = $source_row['language'];

  if ($alias_entity->getPath() !== $expected_path || $alias_entity->getAlias() !== $expected_alias || $alias_entity->language()->getId() !== $expected_language) {
    $alias_mismatches[] = [
      'pid' => $pid,
      'expected' => [$expected_path, $expected_alias, $expected_language],
      'actual' => [$alias_entity->getPath(), $alias_entity->getAlias(), $alias_entity->language()->getId()],
    ];
  }

  $type = strtok($source_row['source'], '/');
  $target_by_language[$expected_language] = ($target_by_language[$expected_language] ?? 0) + 1;
  $target_by_type[$type] = ($target_by_type[$type] ?? 0) + 1;
  $target_by_type_language[$type][$expected_language] = ($target_by_type_language[$type][$expected_language] ?? 0) + 1;
}

ksort($source_by_language);
ksort($target_by_language);
ksort($source_by_type);
ksort($target_by_type);

$failures = [
  'missing_map_source' => $missing_map_source,
  'missing_target_alias' => $missing_target_alias,
  'alias_mismatches' => $alias_mismatches,
];

if ($expected_count !== 124 || count($map_rows) !== 124 || $source_by_language !== ['en' => 42, 'pt-br' => 24, 'und' => 58] || $source_by_type !== ['node' => 66, 'taxonomy' => 55, 'user' => 3] || $target_by_language !== $source_by_language || $target_by_type !== $source_by_type || array_filter($failures)) {
  throw new \RuntimeException(json_encode([
    'source_count' => $expected_count,
    'mapped_alias_count' => count($map_rows),
    'source_by_language' => $source_by_language,
    'target_by_language' => $target_by_language,
    'source_by_type' => $source_by_type,
    'target_by_type' => $target_by_type,
    'failures' => $failures,
  ], JSON_PRETTY_PRINT));
}

echo "Verified 124 URL aliases.\n";
foreach ($source_by_type as $type => $count) {
  echo "$type $count\n";
}
foreach ($source_by_language as $language => $count) {
  echo "$language $count\n";
}
PHP
)"

rollback
cleanup_required=0

drush migrate:status --group=web26 --format=json
