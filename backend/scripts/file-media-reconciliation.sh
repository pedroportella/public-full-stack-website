#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
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
cleanup_required=1

drush php:eval "$(cat <<'PHP'
use Drupal\Core\Database\Database;

$source = Database::getConnection('default', 'migrate');
$source_rows = $source->query("
  SELECT fid, filename, uri, filemime, filesize, status
  FROM file_managed
  ORDER BY fid
")->fetchAll(\PDO::FETCH_ASSOC);

$source_count = count($source_rows);
$source_mime_counts = [];
$missing_source_files = [];
$file_mismatches = [];
$missing_target_files = [];
$missing_media = [];
$media_mismatches = [];

foreach ($source_rows as $row) {
  $source_mime_counts[$row['filemime']] = ($source_mime_counts[$row['filemime']] ?? 0) + 1;
  $legacy_path = '/legacy/sites/default/files/' . ltrim(preg_replace('#^public://#', '', $row['uri']), '/');
  if (!is_file($legacy_path)) {
    $missing_source_files[] = $row['fid'] . ':' . $row['uri'];
  }
}

$target_files = \Drupal::entityTypeManager()->getStorage('file')->loadMultiple();
$target_media = \Drupal::entityTypeManager()->getStorage('media')->loadByProperties(['bundle' => 'image']);

foreach ($source_rows as $row) {
  $fid = (int) $row['fid'];
  $file = $target_files[$fid] ?? NULL;
  if (!$file) {
    $missing_target_files[] = $fid;
    continue;
  }

  if ($file->getFilename() !== $row['filename'] || $file->getFileUri() !== $row['uri'] || $file->getMimeType() !== $row['filemime'] || (int) $file->getSize() !== (int) $row['filesize'] || (int) $file->isPermanent() !== (int) $row['status']) {
    $file_mismatches[] = $fid;
  }

  if (!is_file($file->getFileUri())) {
    $missing_target_files[] = $fid . ':disk';
  }
}

$media_storage = \Drupal::entityTypeManager()->getStorage('media');
$mapped_media_rows = \Drupal::database()->query("
  SELECT sourceid1, destid1
  FROM migrate_map_web26_media_images
  WHERE destid1 IS NOT NULL
  ORDER BY sourceid1
")->fetchAll(\PDO::FETCH_ASSOC);

$media_by_legacy_fid = [];
foreach ($mapped_media_rows as $map_row) {
  $legacy_fid = (int) $map_row['sourceid1'];
  $media = $media_storage->load((int) $map_row['destid1']);
  if ($media) {
    $media_by_legacy_fid[$legacy_fid] = $media;
  }
}

$extra_legacy_media = [];
foreach ($target_media as $media) {
  if ($media->hasField('field_legacy_fid') && !$media->get('field_legacy_fid')->isEmpty()) {
    $legacy_fid = (int) $media->get('field_legacy_fid')->value;
    if (!isset($media_by_legacy_fid[$legacy_fid]) || (int) $media_by_legacy_fid[$legacy_fid]->id() !== (int) $media->id()) {
      $extra_legacy_media[] = $media->id() . ':' . $legacy_fid;
    }
  }
}

foreach ($source_rows as $row) {
  $fid = (int) $row['fid'];
  $media = $media_by_legacy_fid[$fid] ?? NULL;
  if (!$media) {
    $missing_media[] = $fid;
    continue;
  }

  if ($media->bundle() !== 'image' || $media->label() !== $row['filename'] || (int) $media->get('field_media_image')->target_id !== $fid) {
    $media_mismatches[] = $fid;
  }
}

$target_mime_counts = [];
foreach ($target_files as $file) {
  $target_mime_counts[$file->getMimeType()] = ($target_mime_counts[$file->getMimeType()] ?? 0) + 1;
}
ksort($source_mime_counts);
ksort($target_mime_counts);

$failures = [
  'missing_source_files' => $missing_source_files,
  'missing_target_files' => $missing_target_files,
  'file_mismatches' => $file_mismatches,
  'missing_media' => $missing_media,
  'media_mismatches' => $media_mismatches,
  'source_mime_counts' => $source_mime_counts,
  'target_mime_counts' => $target_mime_counts,
];

if ($source_count !== 97 || count($target_files) !== 97 || count($mapped_media_rows) !== 97 || count($media_by_legacy_fid) !== 97 || $source_mime_counts !== ['image/jpeg' => 38, 'image/png' => 59] || $target_mime_counts !== $source_mime_counts || array_filter(array_slice($failures, 0, 5))) {
  throw new \RuntimeException(json_encode([
    'source_count' => $source_count,
    'target_file_count' => count($target_files),
    'mapped_media_count' => count($mapped_media_rows),
    'target_migrated_media_count' => count($media_by_legacy_fid),
    'target_total_image_media_count' => count($target_media),
    'extra_legacy_media' => $extra_legacy_media,
    'failures' => $failures,
  ], JSON_PRETTY_PRINT));
}

echo "Verified 97 managed files and 97 image media entities.\n";
if ($extra_legacy_media) {
  echo "Found pre-existing legacy-tagged media outside the migration map: " . implode(', ', $extra_legacy_media) . "\n";
}
foreach ($source_mime_counts as $mime => $count) {
  echo "$mime $count\n";
}
PHP
)"

rollback
cleanup_required=0

drush migrate:status --group=web26 --format=json
