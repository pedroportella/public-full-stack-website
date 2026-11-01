# Pin core to a known security release; bump deliberately after checking
# https://www.drupal.org/security
FROM drupal:11.4.11-php8.5-apache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /opt/drupal

RUN composer require --no-interaction --no-progress --update-with-dependencies \
    "drupal/core-recommended:11.4.11" \
    "drupal/core-composer-scaffold:11.4.11" \
    "drush/drush:^13.8" \
    "drupal/migrate_plus:^6.0.10" \
    "drupal/migrate_tools:^6.1.4" \
  && composer audit --no-interaction --locked \
  && rm -rf /root/.composer/cache
