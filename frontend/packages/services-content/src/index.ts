export interface SiteBaseline {
  siteName: string;
  defaultLocale: "en";
  supportedLocales: readonly ["en", "pt-br"];
  summary: string;
}

export function getSiteBaseline(): SiteBaseline {
  return {
    siteName: "Pedro Portella",
    defaultLocale: "en",
    supportedLocales: ["en", "pt-br"],
    summary:
      "Drupal 11 headless and Next.js workspace baseline for the Web26 rebuild."
  };
}
