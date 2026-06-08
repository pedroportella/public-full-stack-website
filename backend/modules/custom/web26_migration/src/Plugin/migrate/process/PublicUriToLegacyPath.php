<?php

declare(strict_types=1);

namespace Drupal\web26_migration\Plugin\migrate\process;

use Drupal\migrate\MigrateExecutableInterface;
use Drupal\migrate\ProcessPluginBase;
use Drupal\migrate\Row;

/**
 * Converts a Drupal public:// URI into the mounted legacy files path.
 *
 * @MigrateProcessPlugin(
 *   id = "web26_public_uri_to_legacy_path"
 * )
 */
final class PublicUriToLegacyPath extends ProcessPluginBase {

  /**
   * {@inheritdoc}
   */
  public function transform($value, MigrateExecutableInterface $migrate_executable, Row $row, $destination_property) {
    if (!is_string($value) || $value === '') {
      return $value;
    }

    $base_path = rtrim($this->configuration['base_path'] ?? '/legacy/sites/default/files', '/');
    $relative_path = preg_replace('#^public://#', '', $value);

    return $base_path . '/' . ltrim((string) $relative_path, '/');
  }

}
