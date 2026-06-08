<?php

namespace Drupal\web26_migration\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SqlBase;
use Drupal\migrate\Row;

/**
 * Source plugin for legacy Drupal 7 taxonomy term translations.
 *
 * Drupal 7 stores these term labels and descriptions in the Locale module
 * tables, keyed by taxonomy contexts such as term:5:name.
 *
 * @MigrateSource(
 *   id = "web26_taxonomy_term_translation"
 * )
 */
final class TaxonomyTermTranslation extends SqlBase {

  /**
   * {@inheritdoc}
   */
  public function query() {
    $query = $this->select('locales_source', 'ls')
      ->fields('ls', ['context'])
      ->fields('lt', ['language', 'translation'])
      ->fields('td', ['tid', 'vid'])
      ->fields('tv', ['machine_name'])
      ->condition('ls.textgroup', 'taxonomy')
      ->condition('ls.context', 'term:%:name', 'LIKE');

    $query->innerJoin('locales_target', 'lt', '[lt].[lid] = [ls].[lid]');
    $query->innerJoin('taxonomy_term_data', 'td', "[td].[tid] = CAST(SUBSTRING_INDEX(SUBSTRING_INDEX([ls].[context], ':', 2), ':', -1) AS UNSIGNED)");
    $query->innerJoin('taxonomy_vocabulary', 'tv', '[tv].[vid] = [td].[vid]');

    if (isset($this->configuration['vocabulary'])) {
      $query->condition('tv.machine_name', (array) $this->configuration['vocabulary'], 'IN');
    }

    return $query;
  }

  /**
   * {@inheritdoc}
   */
  public function prepareRow(Row $row) {
    $tid = (int) $row->getSourceProperty('tid');
    $language = $row->getSourceProperty('language');

    $row->setSourceProperty('translated_name', $row->getSourceProperty('translation'));
    $row->setSourceProperty('translated_description', $this->translatedProperty($tid, $language, 'description'));

    return parent::prepareRow($row);
  }

  /**
   * Returns a translated taxonomy locale property.
   */
  private function translatedProperty(int $tid, string $language, string $property): ?string {
    $query = $this->select('locales_source', 'ls')
      ->fields('lt', ['translation'])
      ->condition('ls.textgroup', 'taxonomy')
      ->condition('ls.context', "term:$tid:$property")
      ->condition('lt.language', $language)
      ->range(0, 1);

    $query->innerJoin('locales_target', 'lt', '[lt].[lid] = [ls].[lid]');

    $value = $query->execute()->fetchField();

    return $value === FALSE ? NULL : $value;
  }

  /**
   * {@inheritdoc}
   */
  public function fields() {
    return [
      'tid' => $this->t('Translated taxonomy term ID.'),
      'vid' => $this->t('Legacy vocabulary ID.'),
      'machine_name' => $this->t('Vocabulary machine name.'),
      'language' => $this->t('Translation language.'),
      'translated_name' => $this->t('Translated taxonomy term name.'),
      'translated_description' => $this->t('Translated taxonomy term description.'),
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getIds() {
    return [
      'tid' => [
        'type' => 'integer',
        'alias' => 'td',
      ],
      'language' => [
        'type' => 'string',
        'alias' => 'lt',
      ],
    ];
  }

}
