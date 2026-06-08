#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")/../.."

drush() {
  docker compose exec -T drupal vendor/bin/drush "$@"
}

rollback() {
  drush migrate:rollback web26_menu_link_translations || true
  drush migrate:rollback web26_menu_links || true
  drush migrate:rollback web26_url_aliases --idlist=1,3,4,5,6,7,8,9,10,11,13,17,21,43,55,56,154,158,182,190,191,193,195,196,198,200,206 || true
  drush migrate:rollback web26_nodes_project_translations --idlist=11:pt-br || true
  drush migrate:rollback web26_nodes_project --idlist=11,15 || true
  drush migrate:rollback web26_nodes_article_translations --idlist=18:pt-br || true
  drush migrate:rollback web26_nodes_article --idlist=18 || true
  drush migrate:rollback web26_nodes_page_translations || true
  drush migrate:rollback web26_nodes_page || true
  drush migrate:rollback web26_nodes_company_translations --idlist=7:pt-br || true
  drush migrate:rollback web26_nodes_company --idlist=7,9 || true
  drush migrate:rollback web26_taxonomy_term_translations --idlist=1:pt-br,5:pt-br,29:pt-br || true
  drush migrate:rollback web26_taxonomy_terms --idlist=1,4,5,8,10,11,12,15,16,17,18,19,28,29,35,37 || true
  drush migrate:rollback web26_media_images --idlist=1,2,4,6,10,13,21,22,58,59,88 || true
  drush migrate:rollback web26_files --idlist=1,2,4,6,10,13,21,22,58,59,88 || true
  drush migrate:rollback web26_users || true
}

./backend/scripts/import-content-model-config.sh
./backend/scripts/refresh-migration-config.sh

rollback

drush migrate:import web26_users
drush migrate:import web26_files --idlist=1,2,4,6,10,13,21,22,58,59,88
drush migrate:import web26_media_images --idlist=1,2,4,6,10,13,21,22,58,59,88 --force
drush migrate:import web26_taxonomy_terms --idlist=1,4,5,8,10,11,12,15,16,17,18,19,28,29,35,37 --update
drush migrate:import web26_taxonomy_term_translations --idlist=1:pt-br,5:pt-br,29:pt-br --force
drush migrate:import web26_nodes_company --idlist=7,9 --force
drush migrate:import web26_nodes_company_translations --idlist=7:pt-br --force
drush migrate:import web26_nodes_page --force
drush migrate:import web26_nodes_page_translations --force
drush migrate:import web26_nodes_article --idlist=18 --force
drush migrate:import web26_nodes_article_translations --idlist=18:pt-br --force
drush migrate:import web26_nodes_project --idlist=11,15 --force
drush migrate:import web26_nodes_project_translations --idlist=11:pt-br --force
drush migrate:import web26_url_aliases --idlist=1,3,4,5,6,7,8,9,10,11,13,17,21,43,55,56,154,158,182,190,191,193,195,196,198,200,206 --force
drush migrate:import web26_menu_links --update --force
drush migrate:import web26_menu_link_translations --force

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

$node7 = $node_storage->load(7);
if (!$node7 || !$node7->hasTranslation("pt-br")) {
  throw new \RuntimeException("Missing company 7 translation.");
}
$node7_pt = $node7->getTranslation("pt-br");
if ($node7_pt->get("field_media_images")->count() !== 1 || $node7_pt->get("field_company_website")->uri !== "https://www.olympic.co.nz") {
  throw new \RuntimeException("Company 7 translation did not map media and link fields.");
}

$article18 = $node_storage->load(18);
if (!$article18 || !$article18->hasTranslation("pt-br")) {
  throw new \RuntimeException("Missing article 18 translation.");
}
$article18_pt = $article18->getTranslation("pt-br");
if ($article18_pt->label() !== "Bem-vindo ao nosso website" || $article18_pt->get("field_tags")->count() !== 5 || $article18_pt->get("field_media_images")->count() !== 1) {
  throw new \RuntimeException("Article 18 translation did not map title, tags and media.");
}

$project11 = $node_storage->load(11);
if (!$project11 || !$project11->hasTranslation("pt-br")) {
  throw new \RuntimeException("Missing project 11 translation.");
}
$project11_pt = $project11->getTranslation("pt-br");
if ($project11_pt->get("field_media_images")->count() !== 3 || (int) $project11_pt->get("field_company")->target_id !== 9 || $project11_pt->get("field_technologies_used")->count() !== 2 || $project11_pt->get("field_type_of_work_done")->count() !== 4 || $project11_pt->get("field_country")->count() !== 1) {
  throw new \RuntimeException("Project 11 translation did not map media, company and taxonomy references.");
}
echo "Verified company, article and project translations.\n";

$term_storage = \Drupal::entityTypeManager()->getStorage("taxonomy_term");
$translated_terms = [
  1 => ["Drupal 7", "Drupal é um framework modular"],
  5 => ["Entrevista com cliente", "conhecer o cliente"],
  29 => ["Nova Zelândia", "Nova Zelândia"],
];
foreach ($translated_terms as $tid => [$expected_name, $expected_description_fragment]) {
  $term = $term_storage->load($tid);
  if (!$term || !$term->hasTranslation("pt-br")) {
    throw new \RuntimeException("Missing pt-br translation for taxonomy term $tid.");
  }
  $translation = $term->getTranslation("pt-br");
  if ($translation->label() !== $expected_name || !str_contains($translation->getDescription(), $expected_description_fragment)) {
    throw new \RuntimeException("Taxonomy term $tid translation did not map name and description.");
  }
}

$required_taxonomy_aliases = [
  "/technologies-used/drupal-7|und",
  "/type-work-done/client-interview|und",
  "/country/new-zealand|und",
];
$seen_taxonomy_aliases = [];
foreach ($alias_storage->loadMultiple() as $path_alias) {
  $key = $path_alias->getAlias() . "|" . $path_alias->language()->getId();
  if (in_array($key, $required_taxonomy_aliases, TRUE)) {
    $seen_taxonomy_aliases[$key] = TRUE;
  }
}
foreach ($required_taxonomy_aliases as $key) {
  if (!isset($seen_taxonomy_aliases[$key])) {
    throw new \RuntimeException("Missing expected taxonomy alias $key.");
  }
}
echo "Verified taxonomy term translations and shared taxonomy aliases.\n";

$expected = [
  "Home" => ["internal:/node/1", -50, "Início"],
  "About Us" => ["internal:/node/2", -49, "Sobre"],
  "Portfolio" => ["internal:/node/3", -48, "Portfolio"],
  "Services" => ["internal:/node/4", -47, "Serviços"],
  "Contact Us" => ["internal:/node/5", -46, "Contato"],
];
$links = \Drupal::entityTypeManager()->getStorage("menu_link_content")->loadByProperties(["menu_name" => "main"]);
foreach ($links as $link) {
  $title = $link->label();
  if (isset($expected[$title])) {
    [$uri, $weight, $translated_title] = $expected[$title];
    if ($link->get("link")->uri !== $uri || (int) $link->getWeight() !== $weight || !$link->isEnabled()) {
      throw new \RuntimeException("Menu link $title did not match the expected URI, weight and enabled state.");
    }
    if (!$link->hasTranslation("pt-br") || $link->getTranslation("pt-br")->label() !== $translated_title) {
      throw new \RuntimeException("Menu link $title did not import the expected pt-br title.");
    }
    unset($expected[$title]);
  }
}
if ($expected) {
  throw new \RuntimeException("Migration smoke test did not produce all expected main menu links.");
}
echo "Verified main menu page links and translations.\n";
'

rollback

drush migrate:status --group=web26 --format=json
