#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
  drush migrate:rollback web26_taxonomy_term_translations || true
  drush migrate:rollback web26_taxonomy_terms || true
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

drush migrate:import web26_taxonomy_terms --update
drush migrate:import web26_taxonomy_term_translations --force
cleanup_required=1

drush php:eval "$(cat <<'PHP'
use Drupal\Core\Database\Database;

$source = Database::getConnection("default", "migrate");
$rows = $source->query("
  SELECT
    td.tid,
    tv.machine_name AS vocabulary,
    td.name AS source_name,
    lt.language,
    lt.translation AS translated_name,
    description_target.translation AS translated_description
  FROM locales_source label_source
  INNER JOIN locales_target lt ON lt.lid = label_source.lid
  INNER JOIN taxonomy_term_data td ON td.tid = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(label_source.context, ':', 2), ':', -1) AS UNSIGNED)
  INNER JOIN taxonomy_vocabulary tv ON tv.vid = td.vid
  LEFT JOIN locales_source description_source
    ON description_source.textgroup = 'taxonomy'
   AND description_source.context = CONCAT('term:', td.tid, ':description')
  LEFT JOIN locales_target description_target
    ON description_target.lid = description_source.lid
   AND description_target.language = lt.language
  WHERE label_source.textgroup = 'taxonomy'
    AND label_source.context LIKE 'term:%:name'
    AND tv.machine_name IN ('tags', 'technologies_used', 'type_of_work_done', 'country')
  ORDER BY tv.machine_name, td.tid, lt.language
")->fetchAll(\PDO::FETCH_ASSOC);

$expected_count = count($rows);
if ($expected_count !== 25) {
  throw new \RuntimeException("Expected 25 taxonomy translation source rows, found $expected_count.");
}

$term_storage = \Drupal::entityTypeManager()->getStorage("taxonomy_term");
$missing_terms = [];
$missing_translations = [];
$name_mismatches = [];
$description_mismatches = [];
$verified_by_vocabulary = [];

foreach ($rows as $row) {
  $tid = (int) $row["tid"];
  $language = $row["language"];
  $key = $tid . ":" . $language;
  $term = $term_storage->load($tid);

  if (!$term) {
    $missing_terms[] = $tid;
    continue;
  }

  if (!$term->hasTranslation($language)) {
    $missing_translations[] = $key;
    continue;
  }

  $translation = $term->getTranslation($language);
  if ($translation->label() !== $row["translated_name"]) {
    $name_mismatches[] = $key . " expected " . $row["translated_name"] . " got " . $translation->label();
  }

  $expected_description = $row["translated_description"] ?? "";
  $actual_description = $translation->get("description")->value ?? "";
  if ($actual_description !== $expected_description) {
    $description_mismatches[] = $key;
  }

  $verified_by_vocabulary[$row["vocabulary"]] = ($verified_by_vocabulary[$row["vocabulary"]] ?? 0) + 1;
}

$failures = [
  "missing_terms" => $missing_terms,
  "missing_translations" => $missing_translations,
  "name_mismatches" => $name_mismatches,
  "description_mismatches" => $description_mismatches,
];
$has_failures = array_filter($failures);
if ($has_failures) {
  throw new \RuntimeException(json_encode($failures, JSON_PRETTY_PRINT));
}

ksort($verified_by_vocabulary);
echo "Verified $expected_count taxonomy term translations.\n";
foreach ($verified_by_vocabulary as $vocabulary => $count) {
  echo "$vocabulary: $count\n";
}
PHP
)"

rollback
cleanup_required=0

drush migrate:status --group=web26 --format=json
