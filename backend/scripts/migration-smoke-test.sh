#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
  drush migrate:rollback web26_menu_links || true
  drush migrate:rollback web26_url_aliases --idlist=1,3,4,5,6,7,8,9,10,11,21,55,56,190,191,195,196,206 || true
  drush migrate:rollback web26_nodes_project --idlist=15 || true
  drush migrate:rollback web26_nodes_page_translations || true
  drush migrate:rollback web26_nodes_page || true
  drush migrate:rollback web26_nodes_company --idlist=9 || true
  drush migrate:rollback web26_taxonomy_terms --idlist=28,5,29 || true
  drush migrate:rollback web26_media_images --idlist=1,4,10,58,59 || true
  drush migrate:rollback web26_files --idlist=1,4,10,58,59 || true
  drush migrate:rollback web26_users || true
}

./backend/scripts/import-content-model-config.sh
./backend/scripts/refresh-migration-config.sh

rollback

drush migrate:import web26_users
drush migrate:import web26_files --idlist=1,4,10,58,59
drush migrate:import web26_media_images --idlist=1,4,10,58,59 --force
drush migrate:import web26_taxonomy_terms --idlist=28,5,29 --update
drush migrate:import web26_nodes_company --idlist=9 --force
drush migrate:import web26_nodes_page --force
drush migrate:import web26_nodes_page_translations --force
drush migrate:import web26_nodes_project --idlist=15 --force
drush migrate:import web26_url_aliases --idlist=1,3,4,5,6,7,8,9,10,11,21,55,56,190,191,195,196,206 --force
drush migrate:import web26_menu_links --update --force

drush php:eval '
$project = \Drupal::entityTypeManager()->getStorage("node")->load(15);
$alias = \Drupal::entityTypeManager()->getStorage("path_alias")->loadByProperties(["path" => "/node/15", "alias" => "/portfolio/destination-nz"]);
if (!$project || $project->bundle() !== "project" || !$alias) {
  throw new \RuntimeException("Migration smoke test did not produce the expected project and alias.");
}
echo "Verified project 15 and alias /portfolio/destination-nz.\n";

$node_storage = \Drupal::entityTypeManager()->getStorage("node");
$translations = [
  1 => "Bem-vindo à pedroportella.com",
  2 => "Sobre",
  20 => "Empresas",
  26 => "Pedro O.  J. Portella",
  27 => "Tecnologias utilizadas",
];
foreach ($translations as $nid => $expected_title) {
  $node = $node_storage->load($nid);
  if (!$node || !$node->hasTranslation("pt-br")) {
    throw new \RuntimeException("Missing pt-br translation for page node $nid.");
  }
  $translation = $node->getTranslation("pt-br");
  if ($translation->label() !== $expected_title) {
    throw new \RuntimeException("Unexpected pt-br title for page node $nid.");
  }
}
$node28 = $node_storage->load(28);
if (!$node28 || $node28->language()->getId() !== "pt-br") {
  throw new \RuntimeException("Portuguese-only page node 28 was not imported as pt-br.");
}
$node26 = $node_storage->load(26);
if ($node26->get("field_media_images")->count() !== 1 || $node26->getTranslation("pt-br")->get("field_media_images")->count() !== 1) {
  throw new \RuntimeException("Page node 26 did not keep one image per language.");
}
echo "Verified page translations and translated media.\n";

$alias_storage = \Drupal::entityTypeManager()->getStorage("path_alias");
$required_aliases = [
  "/home|en",
  "/inicio|pt-br",
  "/companies|en",
  "/empresas|pt-br",
  "/about-us/pedro-o-j-portella|en",
  "/sobre/pedro-o-j-portella|pt-br",
  "/proposta-de-convenio-mutua-rs|pt-br",
];
$seen_aliases = [];
foreach ($alias_storage->loadMultiple() as $path_alias) {
  $key = $path_alias->getAlias() . "|" . $path_alias->language()->getId();
  if (in_array($key, $required_aliases, TRUE)) {
    $seen_aliases[$key] = TRUE;
  }
}
foreach ($required_aliases as $key) {
  if (!isset($seen_aliases[$key])) {
    throw new \RuntimeException("Missing expected page alias $key.");
  }
}
echo "Verified bilingual page aliases.\n";

$expected = [
  "Home" => ["internal:/node/1", -50],
  "About Us" => ["internal:/node/2", -49],
  "Portfolio" => ["internal:/node/3", -48],
  "Services" => ["internal:/node/4", -47],
  "Contact Us" => ["internal:/node/5", -46],
];
$links = \Drupal::entityTypeManager()->getStorage("menu_link_content")->loadByProperties(["menu_name" => "main"]);
foreach ($links as $link) {
  $title = $link->label();
  if (isset($expected[$title])) {
    [$uri, $weight] = $expected[$title];
    if ($link->get("link")->uri !== $uri || (int) $link->getWeight() !== $weight || !$link->isEnabled()) {
      throw new \RuntimeException("Menu link $title did not match the expected URI, weight and enabled state.");
    }
    unset($expected[$title]);
  }
}
if ($expected) {
  throw new \RuntimeException("Migration smoke test did not produce all expected main menu links.");
}
echo "Verified main menu page links.\n";
'

rollback

drush migrate:status --group=web26 --format=json
