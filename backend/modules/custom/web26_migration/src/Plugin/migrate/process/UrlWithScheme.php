<?php

declare(strict_types=1);

namespace Drupal\web26_migration\Plugin\migrate\process;

use Drupal\migrate\MigrateExecutableInterface;
use Drupal\migrate\ProcessPluginBase;
use Drupal\migrate\Row;

/**
 * Adds a default scheme to legacy URLs that were stored without one.
 *
 * @MigrateProcessPlugin(
 *   id = "web26_url_with_scheme"
 * )
 */
final class UrlWithScheme extends ProcessPluginBase {

  /**
   * {@inheritdoc}
   */
  public function transform($value, MigrateExecutableInterface $migrate_executable, Row $row, $destination_property) {
    if (!is_string($value) || trim($value) === '') {
      return $value;
    }

    $url = trim($value);
    if (preg_match('/^[a-z][a-z0-9+.-]*:/i', $url) === 1) {
      return $url;
    }

    $scheme = $this->configuration['scheme'] ?? 'https';

    return $scheme . '://' . ltrim($url, '/');
  }

}
