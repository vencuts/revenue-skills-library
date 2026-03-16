---
name: product-headless-hydrogen
description: Knowledge domain advisor for headless commerce, Hydrogen, Oxygen, Remix, Storefront API, and custom frontend builds. Auto-load when conversation involves headless, hydrogen, custom storefront, remix, oxygen, storefront api, liquid migration, or custom frontend keywords. Provides architecture context, migration paths, objections, and SE-level technical positioning for AEs, SEs, and CSMs.
origin: venkat
---

# Product Advisor: Headless Commerce & Hydrogen

Deep knowledge context for headless commerce, Hydrogen framework, and custom storefront builds on Shopify. Load this advisor when a workflow skill detects headless or Hydrogen keywords.

---

## What Is Headless / Hydrogen

**Headless commerce** = decoupled frontend from Shopify's backend. Merchants build their own storefront experience using Shopify as the commerce engine (cart, checkout, product data, fulfillment).

**Hydrogen** = Shopify's official React-based framework for building headless storefronts. Built on Remix. Hosted on **Oxygen** (Shopify's global edge hosting, included with Plus/Commerce Components).

**When to use headless vs Liquid themes:**
- Headless: complex content experiences, performance-critical, custom UI requirements, PWA, multi-brand
- Liquid: standard storefronts, faster time-to-market, lower dev overhead

---

## When to Load References

| Context trigger | Reference file |
|---|---|
| "How does Hydrogen work?" / architecture | `references/architecture.json` |
| "We need to migrate from [platform] to headless" | `references/migration-paths.json` |
| Objections: complexity, cost, team readiness | `references/objections.json` |
| "Who is using headless on Shopify?" / use cases | `references/use-cases.json` |

---

## Quick Positioning

**One-liner:** Hydrogen gives enterprise brands full frontend control without giving up Shopify's checkout, ecosystem, and scale — no infrastructure team required.

**Key differentiators vs composable competitors:**
- Checkout stays on Shopify (highest-converting checkout in the world)
- Oxygen hosting is included with Plus/Commerce Components — no AWS bill
- Hydrogen handles Remix complexity, data fetching, caching out of the box
- Can run hybrid: Liquid for most pages, Hydrogen for specific experiences (landing pages, PLPs)

---

## Top Objections (Quick Reference)

| Objection | Headline response |
|---|---|
| "Hydrogen is too complex for our team" | Hydrogen abstracts Remix complexity. Shopify manages the CDN, edge caching, and deploys. Most Plus agencies are already Hydrogen-certified. |
| "We'd rather use Next.js / our own framework" | Storefront API works with any frontend. But Hydrogen + Oxygen = optimized stack with better Shopify integration out of the box. |
| "Headless is expensive" | Oxygen is included with Plus — no separate hosting bill. Hydrogen devs are faster to ship vs custom Next.js builds. |
| "We're worried about checkout customization" | Checkout extensibility via Checkout Extensions (no fork). All Plus features apply. Custom checkout = Commerce Components conversation. |
| "Migration is too risky" | Phased approach: Liquid live → Hydrogen on new routes → gradual migration. No big-bang cutover required. |
| "We're on commercetools / contentful headless" | Shopify can replace the commerce layer while keeping existing CMS. Hydrogen + third-party CMS = supported pattern. |

---

## SE Engagement Note

Headless conversations require SE involvement at $3M+ GMV or any time a proof-of-concept is requested. Technical win criteria: SE must confirm Catalog API fit, Checkout Extensions coverage for custom requirements, Oxygen hosting viability, and dev team readiness.

---

## Role Adaptation

See `~/.claude/skills/role-context.md` for full role framing.

**AE:** Lead with business outcomes — speed to market, cost of Oxygen vs AWS, checkout conversion advantage, hybrid approach (no big-bang).
**SE:** Lead with architecture — Remix data fetching, Storefront API query patterns, Oxygen edge deployment, Checkout Extensions vs fork.
**CSM:** Lead with developer adoption — is the team shipping, performance metrics post-launch, monitoring on Oxygen.

---


## Platform Reference Data
Load these files for current Shopify platform data before responding:
- `references/commerce-models.md` — B2B, Markets, POS, Hydrogen/headless, Oxygen hosting details

## Knowledge Enrichment Directive

When conversation involves specific products or verticals, reference the appropriate domain advisor skill from `~/.claude/skills/product-*` or `~/.claude/skills/vertical-*`.
