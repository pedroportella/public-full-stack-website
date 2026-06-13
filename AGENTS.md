# Web26 Public Full Stack Website Agent Guide

You are working in the Web26 public full-stack website repository for `pedroportella.com`.

## Codex Instruction Model

- Treat this `AGENTS.md` file as the source of truth for durable repository guidance.
- Keep ordinary engineering conventions, verification expectations and handoff rules here.
- Keep private research, delivery planning and implementation diary notes in `../ai-notes-website/`; do not copy private planning history into public repo docs.
- Do not move project guidance to `.codex/AGENTS.md`. Codex reads `$CODEX_HOME/AGENTS.md` as global guidance and repo-root or nested `AGENTS.md` files as project guidance; a checked-in `.codex/AGENTS.md` only applies when Codex is deliberately launched with `CODEX_HOME` pointed at that directory.
- Reserve `.codex/config.toml`, Codex rules, hooks or plugins for Codex settings, command approvals, lifecycle enforcement or reusable workflows. Do not use them for ordinary prose guidance unless the repo needs that capability.
- Add nested `AGENTS.md` files only when a subtree needs stable rules that differ from this root guidance.
- Keep `.cursorrules` as a legacy compatibility pointer only. Do not duplicate the full instruction set there.

## Project Intent

- This repository is a portfolio-quality full-stack rebuild for `pedroportella.com`.
- Optimise for a Principal Full-Stack Software Engineer review: clear architecture, credible implementation boundaries, repeatable local setup, focused validation and honest documentation.
- Present the work as a personal public website, portfolio and technical implementation, not as a client system or production service for another organisation.
- Do not imply private client approval, production hosting maturity, analytics coverage, security accreditation, production CMS governance or completed migration scope unless it is implemented and documented.
- Keep public-facing copy concise, credible and portfolio-ready.
- Internal delivery labels, planning shorthand and private notes belong outside the public repo. Do not add them to README, docs, `AGENTS.md`, `.cursorrules` or UI copy.

## Repo Shape

- The git repo root is `public-full-stack-website/`.
- `frontend/` owns the Next.js app and shared frontend packages.
- `frontend/apps/web` is the public website app.
- `frontend/apps/web/src/app` owns App Router routes, layouts and route handlers.
- `frontend/apps/web/src/features` owns app-specific feature slices such as contact flows.
- `frontend/packages/services-content` owns content access, DTOs and content service boundaries.
- `frontend/packages/ui-library` owns shared React components and the theme stylesheet entrypoint.
- `frontend/packages/ui-tokens` owns shared design tokens and CSS variables.
- `frontend/packages/ui-assets` owns reusable visual assets.
- `frontend/packages/utils` owns pure shared helpers.
- `backend/` owns the Drupal 11 headless CMS baseline, exported config, custom modules, migration definitions and backend scripts.
- `backend/config/sync` owns exported Drupal configuration.
- `backend/modules/custom/web26_migration` owns Drupal migration definitions and custom process plugins.
- `docker/` and `docker-compose.yml` own local runtime support.
- `docs/` owns public handover and technical documentation.
- `../ai-notes-website/` is private planning context, not app source and not public documentation.

## Runtime And Tooling

- Use Node.js 22-compatible tooling, pnpm and TypeScript for frontend work.
- The frontend workspace is rooted at `frontend/`; run frontend package scripts with `pnpm --dir frontend ...`.
- The public app currently uses Next.js 15, React 19 and TypeScript 5.8.
- The local CMS baseline uses Drupal 11 and MariaDB through Docker Compose.
- Keep root scripts and documented commands as orchestration commands over package-specific details.
- Do not commit `node_modules`, `.next`, `dist`, coverage, Playwright reports, local logs, generated databases, Drupal generated public/private files, Docker volumes, local env files or generated secrets.
- Keep changes small, reviewable and easy to commit.
- Check `git status` before editing and never overwrite user changes.

## Runtime Config

- Backend and CMS-origin configuration belongs server-side or in documented local runtime files.
- Public `NEXT_PUBLIC_*` values may contain only safe browser configuration.
- Do not expose CMS credentials, database URLs, private file paths, admin endpoints, tokens, webhook secrets or deployment credentials to browser code.
- Add local-only keys to `.env.example` only when they are safe examples and document new runtime requirements.
- Treat generated Drupal config, local database state and imported files as runtime artefacts unless explicitly exported into the repo-owned config boundary.

## Frontend Rules

- Use Next.js App Router with React and TypeScript.
- Keep route files thin. Move reusable behaviour into feature modules, services, UI packages or utilities.
- Use `frontend/packages/services-content` for content access, content DTOs, mock/static data boundaries and service helpers.
- Do not scatter ad hoc `fetch` wrappers through pages or components. Add a typed service boundary or route handler when backend communication grows.
- Keep browser code free of private backend origins and secret configuration.
- Preserve semantic HTML: one clear `h1` per routed page, useful landmarks, labels for controls, visible focus, readable contrast and no text overflow at supported viewport widths.
- Preserve form state on recoverable errors and prevent duplicate submissions where practical.
- Keep bilingual or localized route behaviour intentional. If Portuguese and English surfaces differ, document the expected canonical route, redirects and copy ownership.
- Avoid marketing-page bloat. The site should feel polished, direct and inspectable as a portfolio implementation.
- Prefer package imports over relative cross-boundary imports when consuming shared packages.

## Design System And Styling

- Keep design tokens in `frontend/packages/ui-tokens`.
- Keep shared app-facing components in `frontend/packages/ui-library`.
- Keep theme integration in `frontend/packages/ui-library/src/theme/styles.css` and app globals focused on app-level base rules.
- Do not scatter colours, shadows, radii, spacing or focus styles through route pages when a token, theme rule or shared component is more appropriate.
- Keep style layering clear:
  1. `frontend/packages/ui-tokens`
  2. `frontend/packages/ui-library`
  3. app global styles
  4. route or feature layout styles
  5. component-specific styles
- Use cards for repeated items, modals or genuinely framed tools, not as a default wrapper for every page section.
- Keep visual assets real and purposeful. Do not add decorative assets that obscure the public website content or make the implementation harder to review.

## Backend And Drupal Rules

- Treat Drupal as the headless CMS baseline for the website, not as disposable mock infrastructure.
- Keep Drupal exported config under `backend/config/sync`.
- Keep custom Drupal modules under `backend/modules/custom`.
- Keep migration definitions and process plugins inside `backend/modules/custom/web26_migration`.
- Preserve legacy IDs used for reconciliation.
- Treat migration imports as repeatable and rollback-friendly.
- Use backend scripts for repeatable Drupal operations:
  - `backend/scripts/import-content-model-config.sh`
  - `backend/scripts/refresh-migration-config.sh`
  - `backend/scripts/migration-smoke-test.sh`
  - reconciliation scripts for aliases, files/media, node counts and taxonomy translations
- Do not commit generated database volumes, imported file directories, private files or local CMS state.
- Document Drupal runtime changes in public docs when they affect setup, migration, verification or handoff.

## Content And Migration Rules

- Preserve source-content identity and legacy IDs where migrations rely on them.
- Keep migration definitions, content model config and reconciliation scripts aligned.
- When changing migration behaviour, update the relevant smoke test or reconciliation path.
- Do not claim complete migration coverage unless the matching reconciliation script or documented verification supports it.
- Keep content modelling decisions documented in reviewer-friendly language.
- Public docs should explain what is implemented, what is simulated, what is local-only and what remains production-next.

## Security, Privacy And Configuration

- Keep secrets server-side only.
- Do not commit `.env` files except safe examples.
- Do not add private personal data, credentials, API tokens, database dumps with sensitive data, production backups or private keys to the repo.
- Validate public form input on the server side or route-handler boundary before using it.
- Keep user-safe error messages; do not expose stack traces, raw exception messages, secrets or infrastructure details in public responses.
- For contact flows, keep delivery, persistence, consent and privacy boundaries explicit in docs and code comments where useful.
- Add rate limits, request size limits and spam controls when public write surfaces become real.

## Testing And Quality Gates

- Add focused tests when behaviour changes or when a bug fix could regress.
- Use the nearest available command for validation:
  - `pnpm --dir frontend lint`
  - `pnpm --dir frontend typecheck`
  - `pnpm --dir frontend build`
  - `docker compose --profile cms up -d`
  - `backend/scripts/migration-smoke-test.sh`
- Validate YAML, PHP, TypeScript and CSS changes with the smallest command that proves the touched behaviour.
- When changing routed UI, check relevant desktop and mobile viewport behaviour before finishing where practical.
- When changing backend migration behaviour, run or document the closest migration smoke/reconciliation check.
- If a command cannot be run locally, say so clearly in the final handoff.

## Docs And Public Handoff

- Keep docs technical and reviewer-friendly, not marketing copy.
- README should answer what this is, how to run it, how to verify it and where deeper docs live.
- Use `docs/` for architecture, local development, migration runtime, contact flow, testing and deployment notes.
- Do not publish internal planning notes, private delivery shorthand or implementation diary content in public docs.
- Update docs alongside code when setup, runtime, migration, contact handling or public behaviour changes.
- Keep screenshots and examples intentional; refresh them only after runtime mode, content and theme are stable.

## Implementation Style

- Prefer small vertical slices that prove real behaviour end to end.
- Reuse existing packages, components, services and helpers before creating new abstractions.
- Add abstractions only when repeated behaviour has stabilized or the boundary is architecturally meaningful.
- Keep shared constants, mappings, validation logic and response shapes single-source where practical.
- Keep comments short and useful. Avoid narrating obvious code.
- Do not rewrite unrelated files or planning notes while implementing a scoped change.
- Before finishing a change, scan for endpoint leaks, generated artefacts, accidental secrets, misleading production claims and public docs containing internal planning labels.

## Commit Message Handoff

- Every implementation wrap-up should include a suggested git commit message.
- Use `type(scope): past-tense summary`.
- Keep the message concise, conventional and scoped to the actual changes made.
- Start the summary with a past-tense verb such as `added`, `documented`, `implemented`, `improved` or `resolved`.
- Allowed types are `feat`, `fix`, `refactor`, `chore`, `perf`, `ci`, `ops`, `build`, `docs`, `style`, `revert` and `test`.
- Use lowercase scopes with hyphens where needed.
- Prefer `frontend`, `backend`, `docs`, `migration`, `contact`, `repo` or a package/app-specific scope that matches the actual change boundary.
- Do not include private planning labels in commit messages.
- Format suggested commit messages in final user wrap-ups as copyable code blocks containing only the commit subject. Do not include `git commit -m`, shell commands, quotes or extra prose inside the code block.

## Step Handoff

- After completing a meaningful implementation chunk, update private planning notes only when the task belongs to that delivery context.
- Public docs should receive professional system documentation only, not private implementation diary notes.
- Final user wrap-ups should mention the important files changed, verification run, known caveats and suggested commit message.
