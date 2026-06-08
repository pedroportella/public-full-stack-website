#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
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
cleanup_required=1

drush php:eval "$(cat <<'PHP'
use Drupal\Core\Database\Database;

$in_scope_types = ['article', 'company', 'page', 'project'];

$source = Database::getConnection('default', 'migrate');
$expected = [];
$base_rows = $source->query("
  SELECT type, language, COUNT(*) AS count
  FROM node
  WHERE type IN ('article', 'company', 'page', 'project')
  GROUP BY type, language
")->fetchAll(\PDO::FETCH_ASSOC);

foreach ($base_rows as $row) {
  $type = $row['type'];
  $language = $row['language'];
  $expected[$type][$language] = ($expected[$type][$language] ?? 0) + (int) $row['count'];
}

$translation_rows = $source->query("
  SELECT n.type, et.language, COUNT(*) AS count
  FROM entity_translation et
  INNER JOIN node n ON n.nid = et.entity_id
  WHERE et.entity_type = 'node'
    AND et.source <> ''
    AND n.type IN ('article', 'company', 'page', 'project')
  GROUP BY n.type, et.language
")->fetchAll(\PDO::FETCH_ASSOC);

foreach ($translation_rows as $row) {
  $type = $row['type'];
  $language = $row['language'];
  $expected[$type][$language] = ($expected[$type][$language] ?? 0) + (int) $row['count'];
}

$target = [];
$target_rows = \Drupal::database()->query("
  SELECT type, langcode AS language, COUNT(*) AS count
  FROM node_field_data
  WHERE type IN ('article', 'company', 'page', 'project')
  GROUP BY type, langcode
")->fetchAll(\PDO::FETCH_ASSOC);

foreach ($target_rows as $row) {
  $target[$row['type']][$row['language']] = (int) $row['count'];
}

$missing = [];
$unexpected = [];
$mismatched = [];
$all_types = array_unique(array_merge(array_keys($expected), array_keys($target)));
sort($all_types);
foreach ($all_types as $type) {
  $languages = array_unique(array_merge(array_keys($expected[$type] ?? []), array_keys($target[$type] ?? [])));
  sort($languages);
  foreach ($languages as $language) {
    $expected_count = $expected[$type][$language] ?? NULL;
    $target_count = $target[$type][$language] ?? NULL;
    $key = "$type:$language";
    if ($expected_count === NULL) {
      $unexpected[$key] = $target_count;
    }
    elseif ($target_count === NULL) {
      $missing[$key] = $expected_count;
    }
    elseif ($expected_count !== $target_count) {
      $mismatched[$key] = ['expected' => $expected_count, 'actual' => $target_count];
    }
  }
}

$source_base_total = 0;
foreach ($base_rows as $row) {
  $source_base_total += (int) $row['count'];
}

$source_translation_total = 0;
foreach ($translation_rows as $row) {
  $source_translation_total += (int) $row['count'];
}

$target_entity_total = (int) \Drupal::entityQuery('node')
  ->condition('type', $in_scope_types, 'IN')
  ->accessCheck(FALSE)
  ->count()
  ->execute();

$target_language_total = 0;
foreach ($target_rows as $row) {
  $target_language_total += (int) $row['count'];
}

$expected_language_total = $source_base_total + $source_translation_total;
$failures = [
  'missing' => $missing,
  'unexpected' => $unexpected,
  'mismatched' => $mismatched,
];

if ($source_base_total !== 42 || $source_translation_total !== 22 || $target_entity_total !== 42 || $target_language_total !== $expected_language_total || array_filter($failures)) {
  throw new \RuntimeException(json_encode([
    'source_base_total' => $source_base_total,
    'source_translation_total' => $source_translation_total,
    'target_entity_total' => $target_entity_total,
    'target_language_total' => $target_language_total,
    'expected_language_total' => $expected_language_total,
    'failures' => $failures,
  ], JSON_PRETTY_PRINT));
}

echo "Verified 42 in-scope nodes and 64 node language rows.\n";
foreach ($expected as $type => $languages) {
  ksort($languages);
  foreach ($languages as $language => $count) {
    echo "$type:$language $count\n";
  }
}
PHP
)"

rollback
cleanup_required=0

drush migrate:status --group=web26 --format=json
