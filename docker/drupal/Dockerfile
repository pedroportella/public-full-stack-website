FROM drupal:11-apache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /opt/drupal

RUN composer require --no-interaction --no-progress \
    drush/drush \
    drupal/migrate_plus \
    drupal/migrate_tools \
  && rm -rf /root/.composer/cache
