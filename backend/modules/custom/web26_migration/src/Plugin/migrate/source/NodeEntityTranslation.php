<?php

namespace Drupal\web26_migration\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SqlBase;
use Drupal\migrate\Row;

/**
 * Source plugin for legacy Drupal 7 node entity translations.
 *
 * @MigrateSource(
 *   id = "web26_node_entity_translation"
 * )
 */
final class NodeEntityTranslation extends SqlBase {

  /**
   * {@inheritdoc}
   */
  public function query() {
    $query = $this->select('entity_translation', 'et')
      ->fields('et', [
        'entity_id',
        'language',
        'source',
        'uid',
        'status',
        'translate',
        'created',
        'changed',
      ])
      ->fields('n', [
        'title',
        'type',
      ])
      ->condition('et.entity_type', 'node')
      ->condition('et.source', '', '<>');

    $query->innerJoin('node', 'n', '[n].[nid] = [et].[entity_id]');

    if (isset($this->configuration['node_type'])) {
      $query->condition('n.type', (array) $this->configuration['node_type'], 'IN');
    }

    return $query;
  }

  /**
   * {@inheritdoc}
   */
  public function prepareRow(Row $row) {
    $nid = (int) $row->getSourceProperty('entity_id');
    $language = $row->getSourceProperty('language');

    $row->setSourceProperty('translated_title', $this->singleFieldValue('field_data_title_field', 'title_field_value', $nid, $language));
    $row->setSourceProperty('body', $this->bodyValue($nid, $language));
    $row->setSourceProperty('field_image', $this->multiFieldValues('field_data_field_image', 'field_image_fid', 'fid', $nid, $language));
    $row->setSourceProperty('field_company', $this->multiFieldValues('field_data_field_company', 'field_company_nid', 'nid', $nid, $language));
    $row->setSourceProperty('field_technologies_used', $this->multiFieldValues('field_data_field_technologies_used', 'field_technologies_used_tid', 'tid', $nid, $language));
    $row->setSourceProperty('field_type_of_work_done', $this->multiFieldValues('field_data_field_type_of_work_done', 'field_type_of_work_done_tid', 'tid', $nid, $language));
    $row->setSourceProperty('field_country', $this->multiFieldValues('field_data_field_country', 'field_country_tid', 'tid', $nid, $language));
    $row->setSourceProperty('field_tags', $this->multiFieldValues('field_data_field_tags', 'field_tags_tid', 'tid', $nid, $language));

    $row->setSourceProperty('field_subtitle', $this->singleFieldValue('field_data_field_subtitle', 'field_subtitle_value', $nid, $language));
    $row->setSourceProperty('field_project_date', $this->singleFieldValue('field_data_field_project_date', 'field_project_date_value', $nid, $language));
    $row->setSourceProperty('field_company_website', $this->linkValue('field_data_field_company_website', 'field_company_website', $nid, $language));
    $row->setSourceProperty('field_project_link', $this->linkValue('field_data_field_project_link', 'field_project_link', $nid, $language));

    return parent::prepareRow($row);
  }

  /**
   * Returns a single translated field value.
   */
  private function singleFieldValue(string $table, string $column, int $nid, string $language): ?string {
    if (!$this->getDatabase()->schema()->tableExists($table)) {
      return NULL;
    }

    $value = $this->select($table, 'f')
      ->fields('f', [$column])
      ->condition('f.entity_type', 'node')
      ->condition('f.entity_id', $nid)
      ->condition('f.language', $language)
      ->condition('f.deleted', 0)
      ->range(0, 1)
      ->execute()
      ->fetchField();

    return $value === FALSE ? NULL : $value;
  }

  /**
   * Returns translated body field data.
   */
  private function bodyValue(int $nid, string $language): array {
    if (!$this->getDatabase()->schema()->tableExists('field_data_body')) {
      return [];
    }

    $record = $this->select('field_data_body', 'b')
      ->fields('b', ['body_value', 'body_summary', 'body_format'])
      ->condition('b.entity_type', 'node')
      ->condition('b.entity_id', $nid)
      ->condition('b.language', $language)
      ->condition('b.deleted', 0)
      ->range(0, 1)
      ->execute()
      ->fetchAssoc();

    if (!$record) {
      return [];
    }

    return [
      'value' => $record['body_value'],
      'summary' => $record['body_summary'],
      'format' => $record['body_format'],
    ];
  }

  /**
   * Returns translated multi-value reference rows.
   */
  private function multiFieldValues(string $table, string $source_column, string $target_key, int $nid, string $language): array {
    if (!$this->getDatabase()->schema()->tableExists($table)) {
      return [];
    }

    $query = $this->select($table, 'f')
      ->fields('f', [$source_column])
      ->condition('f.entity_type', 'node')
      ->condition('f.entity_id', $nid)
      ->condition('f.language', $language)
      ->condition('f.deleted', 0)
      ->orderBy('f.delta');

    $values = [];
    foreach ($query->execute() as $record) {
      if ($record[$source_column] !== NULL) {
        $values[] = [$target_key => $record[$source_column]];
      }
    }

    return $values;
  }

  /**
   * Returns translated link field data in the Drupal 7 field shape.
   */
  private function linkValue(string $table, string $field_name, int $nid, string $language): array {
    if (!$this->getDatabase()->schema()->tableExists($table)) {
      return [];
    }

    $record = $this->select($table, 'l')
      ->fields('l', [
        "{$field_name}_url",
        "{$field_name}_title",
        "{$field_name}_attributes",
      ])
      ->condition('l.entity_type', 'node')
      ->condition('l.entity_id', $nid)
      ->condition('l.language', $language)
      ->condition('l.deleted', 0)
      ->range(0, 1)
      ->execute()
      ->fetchAssoc();

    if (!$record) {
      return [];
    }

    return [[
      'url' => $record["{$field_name}_url"],
      'title' => $record["{$field_name}_title"],
      'attributes' => $record["{$field_name}_attributes"],
    ]];
  }

  /**
   * {@inheritdoc}
   */
  public function fields() {
    return [
      'entity_id' => $this->t('Translated node ID.'),
      'language' => $this->t('Translation language.'),
      'source' => $this->t('Source language.'),
      'uid' => $this->t('Translation author user ID.'),
      'status' => $this->t('Translation status.'),
      'translate' => $this->t('Translation outdated flag.'),
      'created' => $this->t('Translation created timestamp.'),
      'changed' => $this->t('Translation changed timestamp.'),
      'title' => $this->t('Base node title fallback.'),
      'type' => $this->t('Node type.'),
      'translated_title' => $this->t('Translated title field value.'),
      'body' => $this->t('Translated body field values.'),
      'field_image' => $this->t('Translated image file IDs.'),
      'field_subtitle' => $this->t('Translated subtitle value.'),
      'field_company_website' => $this->t('Translated company website link.'),
      'field_project_link' => $this->t('Translated project link.'),
      'field_project_date' => $this->t('Translated project date.'),
      'field_company' => $this->t('Translated company references.'),
      'field_technologies_used' => $this->t('Translated technology term references.'),
      'field_type_of_work_done' => $this->t('Translated type-of-work term references.'),
      'field_country' => $this->t('Translated country term references.'),
      'field_tags' => $this->t('Translated tag term references.'),
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getIds() {
    return [
      'entity_id' => [
        'type' => 'integer',
        'alias' => 'et',
      ],
      'language' => [
        'type' => 'string',
        'alias' => 'et',
      ],
    ];
  }

}
