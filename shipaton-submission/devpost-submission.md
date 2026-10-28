# Dear Socrates

## One-line summary

Write what is weighing on you and receive one thoughtful letter built around a verified quotation from a great mind.

## What it does

Dear Socrates turns private reflection into a focused, source-backed experience rather than an open-ended AI chat. A user writes about the day or a worry, stars gather, and a fitting historical figure appears as a constellation. The reply contains a short personal note, a quotation, the original-language text, meaning and context, and a complete source citation. Letters remain available in an archive, every figure met lights up in a personal Star Atlas, and a privacy-safe share card excludes the user's original concern.

## Why I built it

People often want to put a worry into words without starting a conversation or sharing it with someone they know. Generic AI chat can feel endless and disposable. I wanted to create a quieter ritual: one concern, one letter, and one historically grounded idea to carry into tomorrow. The product deliberately avoids generated or unattributed quotations. AI is limited to matching and contextualizing a curated quotation database whose entries include source work, passage, year, and original text.

## How it uses RevenueCat

The iOS app initializes the RevenueCat SDK with the same anonymous Firebase user ID used by the backend. RevenueCat powers two complementary purchase paths: a consumable one-letter ticket for an occasional extra letter, and the Hoshiyomi monthly unlimited plan for people who write more often. The default offering, products, packages, and unlimited entitlement are registered in the Igen RevenueCat project. The backend checks the same entitlement and ticket history before granting access beyond the free daily letter.

## Target awards and judging evidence

### HAMM Award

The monetization matches the product's irregular usage pattern. Everyone can receive one free letter per day. Someone who needs one additional letter can buy a low-commitment consumable ticket, while frequent writers can choose an unlimited monthly plan. This combines usage-based and recurring revenue without placing the first helpful experience behind a paywall. Conversion and revenue figures will be added only after the public launch; no estimates are presented as measured results.

### Most Viral App (Noise)

The built-in share card turns each result into repeatable vertical content: a constellation, a quotation, and its source. It never includes the private concern that produced the letter. This gives users something safe and visually recognizable to share while keeping the app's core value clear. Noise campaign links, account details, reach, and download results remain pending until the app is publicly launched and promoted during Shipaton.

## Traction and measured results

The App Store version is still in Prepare for Submission as of September 1, 2026. There are no public downloads, paying users, conversion figures, retention figures, or revenue results to report yet. This section will be updated from App Store Connect and RevenueCat measurements after launch.

## Monetization strategy

- Free: one letter each day.
- Consumable: one extra letter ticket (configured at JPY 160 in Japan).
- Subscription: Hoshiyomi unlimited monthly plan (configured at JPY 480 in Japan).

The ticket fits occasional, emotionally time-sensitive use without requiring a subscription. The unlimited plan fits users who build a regular writing habit and value their growing letter archive and Star Atlas. RevenueCat keeps the App Store products, default offering, packages, and unlimited entitlement consistent across the client and backend.

## Build story and AI tools

Development began on August 5, 2026. On August 6, the project established its source-backed quotation database, Firebase backend, anonymous authentication, generated-letter contract, animated reply, archive, Star Atlas, share card, safety flow, RevenueCat integration, and English experience. Store metadata, screenshots, App Store Connect configuration, StoreKit tests, RevenueCat product configuration, and App Check hardening followed in late August.

Claude Design was used to explore and hand off the high-fidelity visual direction. Claude Code and Codex CLI supported repository-guided implementation, testing, and review. The human developer chose the product boundaries, verified the visual result, maintained the source rules for quotations, and made release and monetization decisions. OpenAI Structured Outputs are used inside the shipped product only for quotation matching and contextual prose; the quotation text itself comes from the curated database.

## Build in public timeline

No public build-in-public posts are recorded for this submission, so the project is not claiming the #BuildInPublic Award.

## Testing instructions

The public App Store URL and the judge access method are pending. Before submission, this section will include the final store URL and either a free-trial path or a promo code that unlocks all premium features. The core flow to test is: write a concern, request a letter, review the original text and citation, create a share card, and open the Star Atlas.

## Links

- Published app: Pending App Store publication
- Demo video: Pending public YouTube or Vimeo upload
- Other required category material: Pending Noise campaign URL and Noise account email for the Most Viral App category
