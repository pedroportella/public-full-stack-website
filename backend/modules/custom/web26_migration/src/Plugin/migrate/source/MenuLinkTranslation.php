<?php

namespace Drupal\web26_migration\Plugin\migrate\source;

use Drupal\migrate\Plugin\migrate\source\SqlBase;

/**
 * Source plugin for legacy Drupal 7 menu link translations.
 *
 * Drupal 7 i18n stores menu item labels in Locale rows keyed by contexts such
 * as menu:item:573:title.
 *
 * @MigrateSource(
 *   id = "web26_menu_link_translation"
 * )
 */
final class MenuLinkTranslation extends SqlBase {

  /**
   * {@inheritdoc}
   */
  public function query() {
    $query = $this->select('i18n_string', 'i18n')
      ->fields('i18n', ['objectid', 'context'])
      ->fields('lt', ['language', 'translation'])
      ->fields('ml', [
        'menu_name',
        'link_title',
        'link_path',
        'weight',
        'expanded',
        'hidden',
      ])
      ->condition('i18n.textgroup', 'menu')
      ->condition('i18n.type', 'item')
      ->condition('i18n.property', 'title');

    $query->innerJoin('locales_source', 'ls', '[ls].[textgroup] = [i18n].[textgroup] AND [ls].[context] = [i18n].[context]');
    $query->innerJoin('locales_target', 'lt', '[lt].[lid] = [ls].[lid]');
    $query->innerJoin('menu_links', 'ml', '[ml].[mlid] = [i18n].[objectid]');

    if (isset($this->configuration['menu_name'])) {
      $query->condition('ml.menu_name', (array) $this->configuration['menu_name'], 'IN');
    }

    return $query;
  }

  /**
   * {@inheritdoc}
   */
  public function fields() {
    return [
      'objectid' => $this->t('Translated menu link ID.'),
      'context' => $this->t('i18n string context.'),
      'language' => $this->t('Translation language.'),
      'translation' => $this->t('Translated menu link title.'),
      'menu_name' => $this->t('Legacy menu name.'),
      'link_title' => $this->t('Default menu link title.'),
      'link_path' => $this->t('Legacy menu link path.'),
      'weight' => $this->t('Menu link weight.'),
      'expanded' => $this->t('Expanded flag.'),
      'hidden' => $this->t('Hidden flag.'),
    ];
  }

  /**
   * {@inheritdoc}
   */
  public function getIds() {
    return [
      'objectid' => [
        'type' => 'integer',
        'alias' => 'i18n',
      ],
      'language' => [
        'type' => 'string',
        'alias' => 'lt',
      ],
    ];
  }

}
