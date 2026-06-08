<?php

namespace Drupal\web26_migration\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SqlBase;

/**
 * Source plugin for legacy Drupal 7 page entity translations.
 *
 * @MigrateSource(
 *   id = "web26_page_entity_translation"
 * )
 */
final class PageEntityTranslation extends SqlBase {

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
    $query->condition('n.type', 'page');

    $query->leftJoin('field_data_title_field', 'tf', "[tf].[entity_type] = 'node' AND [tf].[entity_id] = [et].[entity_id] AND [tf].[language] = [et].[language] AND [tf].[deleted] = 0");
    $query->addField('tf', 'title_field_value', 'translated_title');

    $query->leftJoin('field_data_body', 'body', "[body].[entity_type] = 'node' AND [body].[entity_id] = [et].[entity_id] AND [body].[language] = [et].[language] AND [body].[deleted] = 0");
    $query->addField('body', 'body_value', 'body_value');
    $query->addField('body', 'body_summary', 'body_summary');
    $query->addField('body', 'body_format', 'body_format');

    $query->leftJoin('field_data_field_subtitle', 'subtitle', "[subtitle].[entity_type] = 'node' AND [subtitle].[entity_id] = [et].[entity_id] AND [subtitle].[language] = [et].[language] AND [subtitle].[deleted] = 0");
    $query->addField('subtitle', 'field_subtitle_value', 'field_subtitle_value');

    $query->leftJoin('field_data_field_image', 'image', "[image].[entity_type] = 'node' AND [image].[entity_id] = [et].[entity_id] AND [image].[language] = [et].[language] AND [image].[deleted] = 0");
    $query->addField('image', 'field_image_fid', 'field_image_fid');

    return $query;
  }

  /**
   * {@inheritdoc}
   */
  public function fields() {
    return [
      'entity_id' => $this->t('Translated page node ID.'),
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
      'body_value' => $this->t('Translated body value.'),
      'body_summary' => $this->t('Translated body summary.'),
      'body_format' => $this->t('Translated body text format.'),
      'field_subtitle_value' => $this->t('Translated subtitle field value.'),
      'field_image_fid' => $this->t('Translated image file ID.'),
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
