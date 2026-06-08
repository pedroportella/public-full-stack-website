import { getSiteBaseline } from "@web26/services-content";

export default function HomePage() {
  const baseline = getSiteBaseline();

  return (
    <main className="web26-page-frame" id="main-content">
      <p className="web26-eyebrow">Web26 baseline</p>
      <h1>{baseline.siteName}</h1>
      <p>{baseline.summary}</p>
    </main>
  );
}
