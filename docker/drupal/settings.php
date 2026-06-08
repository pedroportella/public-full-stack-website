<?php

$databases['default']['default'] = [
  'database' => getenv('DRUPAL_DB_NAME') ?: 'web26',
  'username' => getenv('DRUPAL_DB_USER') ?: 'web26',
  'password' => getenv('DRUPAL_DB_PASSWORD') ?: 'web26',
  'prefix' => '',
  'host' => getenv('DRUPAL_DB_HOST') ?: 'database',
  'port' => getenv('DRUPAL_DB_PORT') ?: '3306',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'driver' => 'mysql',
];

$databases['migrate']['default'] = [
  'database' => getenv('DRUPAL_MIGRATE_DB_NAME') ?: 'pedroportella_d7',
  'username' => getenv('DRUPAL_MIGRATE_DB_USER') ?: 'root',
  'password' => getenv('DRUPAL_MIGRATE_DB_PASSWORD') ?: '',
  'prefix' => '',
  'host' => getenv('DRUPAL_MIGRATE_DB_HOST') ?: 'legacy_database',
  'port' => getenv('DRUPAL_MIGRATE_DB_PORT') ?: '3306',
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'driver' => 'mysql',
];

$settings['config_sync_directory'] = '/var/www/config/sync';
$settings['file_private_path'] = '/var/www/private-files';
$settings['hash_salt'] = getenv('DRUPAL_HASH_SALT') ?: 'web26-local-development';
$settings['trusted_host_patterns'] = [
  '^localhost$',
  '^127\\.0\\.0\\.1$',
];

$config['system.logging']['error_level'] = 'verbose';
