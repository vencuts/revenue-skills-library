---
name: competitive-positioning
description: Competitive intelligence framework with positioning by segment tier, S.T.A.R. objection handling, battle card generation, and win/loss research. Use when handling competitive situations, dealing with objections, positioning Shopify against other platforms, asked "how do I compete against [platform]", "competitor battle card", "objection handling for [competitor]", or "win/loss analysis". Works for AEs, SEs, and sales leadership preparing competitive strategy.
---

# Competitive Positioning

Competitive intelligence framework for positioning Shopify against other commerce platforms. Combines structured research with positioning strategy and objection handling.

**Philosophy:** Lead with Shopify strengths and merchant outcomes, not competitor weaknesses.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Win/loss rates by competitor from SF, loss reasons, deal velocity comparisons | Use qualitative positioning from this skill. Note: "No data-backed win/loss rates — using qualitative intel." |
| `vault_search` | Internal battle cards, competitive playbooks, win story docs | Use inline competitor profiles from this skill. |
| `slack_search` | Recent competitive mentions in #competitive-intel, deal threads with competitor context | Skip recent intelligence. Rely on static knowledge. |
| `perplexity_search` | Current competitor pricing, features, recent announcements | Use last-known data. Flag: "Verify before using in merchant comms." |
| `gdrive_search` | Klue battle cards, competitive decks in Google Drive | Use inline knowledge. |

## Workflow

### Step 1: Identify the Competitor

- Has the user named a competitor?
  - **Yes** → Is it a known platform from the list below (SFCC, Adobe, BigCommerce, etc.)?
    - **Yes** → Proceed to Step 2 with segment classification
    - **No** → Ask: "Is {name} a commerce platform, SI/agency, or tool/plugin?" Then web search for positioning data.
  - **No** → Ask: "Which competitor or platform are you going up against?"
  - **User describes an objection without naming competitor** → Apply S.T.A.R. framework generically (see below). Ask: "Which competitor said this?"

### Step 2: Classify and Pull Data

- Classify competitor by segment tier:
  - Enterprise: SFCC, Adobe Commerce, SAP Commerce → use Enterprise positioning
  - Mid-Market: BigCommerce, commercetools, Salesforce B2C → use Mid-Market positioning
  - SMB/Platform: Wix, Squarespace, WooCommerce → use SMB positioning
  - AI/Agentic: Salesforce ACP, direct AI competitors → use Agentic competitive section

- Has BQ access? → Pull win/loss data:

### Step 3: Win/Loss Data (if BQ available)

```sql
-- Win rate and top loss reasons by competitor (last 12 months)
SELECT
  CASE WHEN o.stage_name = 'Closed Won' THEN 'Won' ELSE 'Lost' END AS outcome,
  COUNT(*) AS deals,
  ROUND(AVG(o.amount), 0) AS avg_deal_size,
  STRING_AGG(DISTINCT o.primary_result_reason, ', ' LIMIT 5) AS top_reasons
FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
WHERE LOWER(COALESCE(o.loss_reason, '')) LIKE CONCAT('%', LOWER(@competitor_name), '%')
  AND o.close_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
  AND o.stage_name IN ('Closed Won', 'Closed Lost')
GROUP BY 1
```
**Interpret**: Win rate < 40% = we're losing this matchup → address top loss reason proactively. Win rate > 60% = strong position. avg_deal_size tells you if this is mid-market or enterprise.

---

## Positioning by Segment Tier

### Enterprise (SFCC, Adobe Commerce/Magento, SAP Commerce)
- **Shopify strengths:** Speed to market, lower TCO, native checkout, unified commerce, 99.99% uptime
- **Migration triggers:** Platform re-architecture costs, slow feature velocity, complex customization debt
- **Their pain:** Magento/Adobe Commerce is expensive, developer-heavy, and slow to ship. Merchants pay enterprise costs for a platform that slows them down. Every feature requires agency involvement. Upgrades are migration projects.
- **Key message:** "Modern commerce without the legacy complexity"
- **Watch for:** Enterprise buyers who conflate complexity with capability
- **Do NOT** underestimate switching costs — acknowledge the migration investment, then quantify the 3-year TCO savings

### Mid-Market (BigCommerce, commercetools, Salesforce B2C)
- **Shopify strengths:** App ecosystem (10K+ apps), Markets for global, Plus features, BFCM scale proof
- **Migration triggers:** Hitting growth limits, need for global expansion, app ecosystem gaps
- **Their pain:** BigCommerce is solid but merchants hit walls around customization, a shallower app ecosystem, and costs that climb as they try to unlock advanced functionality. Features exist but are gated behind higher tiers.
- **Key message:** "Scale with the ecosystem, not despite it"
- **Watch for:** "Headless" positioning from composable players — reframe as "you can pick your own tools" without the jargon

### Open-Source (WooCommerce, Magento/Adobe Open Source)
- **Shopify strengths:** Managed infrastructure, feature velocity, true cost of "free"
- **Migration triggers:** Security burden, maintenance costs, performance issues, plugin conflicts
- **Their pain:** WooCommerce requires WordPress + constant plugin management. Open source means merchants own the hosting, security patches, and integration maintenance. They have a developer dependency they didn't sign up for. "Free" means paying a dev $5K/month to keep the lights on.
- **Key message:** "Commerce that just works — so you can focus on growth"
- **Watch for:** Merchants emotionally attached to "owning their code" — reframe as "you own the store, we handle the plumbing"

### Retail POS (Lightspeed, Square)
- **Shopify strengths:** Unified online + in-store on one platform, single inventory, Shopify POS is native not bolted on
- **Migration triggers:** Online growth hitting walls, inventory sync nightmares, needing real ecommerce (not a checkout page bolted onto POS)
- **Lightspeed pain:** Retail POS first — online store is bolted on and limited. Merchants find online disconnected from in-store. Inventory sync between online and physical locations is a constant headache. Not built for brands that want to grow online.
- **Square pain:** Started as a payment tool. Ecommerce features are basic, customization is shallow, integrations are limited. Does not scale for brands with real online ambitions. The story is always about outgrowing the tool.
- **Key message:** "Sell everywhere from one place — not two systems duct-taped together"
- **Watch for:** Merchants who think "we're a retail business, not an ecommerce business" — show them the D2C revenue they're leaving on the table

### Adjacent (Wix, Squarespace, Webflow)
- **Shopify strengths:** Scale without re-platforming, professional features, B2B capabilities
- **Migration triggers:** Outgrew website builder, need B2B, hitting transaction limits
- **Their pain:** Website builders that added ecommerce as an afterthought. Fine for a landing page with a buy button, but merchants hit walls fast: limited product variants, no B2B, no subscription support, painful checkout customization.
- **Key message:** "Built for commerce, not adapted for it"
- **Watch for:** "But my website builder does ecommerce too" — the answer is "and my car has a radio, but I wouldn't call it a stereo"

---

## S.T.A.R. Objection Handling Framework

**Situation → Truth → Advantage → Reference**

### Live Objection Response Mode

When the user pastes a prospect's actual reply or objection text:
1. **Identify** the core objection in one sentence — be specific, not generic ("They think Shopify POS can't handle their 12-location inventory" not "pricing concern")
2. **Classify** against known objections below — if no match, reason from first principles
3. **Draft a response** that: acknowledges the concern directly (don't dodge), flips the objection into a reason to talk (not argue), ends with one low-friction CTA
4. **Keep it short** — 3-5 sentences. Read like a text message, not a sales pitch.
5. **Never use:** "leverage", "synergy", "solution", "pain points", "touch base", "circle back", "hope this finds you", "seamless", "streamline", "ecosystem"

### Common Objections

**"Shopify is too rigid / not customizable enough"**
- **S:** You need specific customization for your business
- **T:** Shopify's architecture is highly extensible — theme architecture, checkout extensions, Functions, Liquid, Hydrogen for headless
- **A:** Customization without the maintenance burden. Extensions survive upgrades.
- **R:** [Cite a merchant who customized extensively without custom dev burden]

**"Shopify is not enterprise-ready"**
- **S:** You need enterprise-grade features and reliability
- **T:** Shopify Plus powers billions in GMV with 99.99% uptime including BFCM
- **A:** Plus, Hydrogen, Commerce Components, dedicated support, guaranteed SLAs
- **R:** [Cite enterprise merchant's BFCM performance or scale numbers]

**"B2B on Shopify is too basic"**
- **S:** You need sophisticated B2B capabilities
- **T:** B2B on Shopify launched 2022, iterating rapidly — company accounts, custom catalogs, quantity rules, payment terms, draft orders
- **A:** Unified D2C + B2B on one platform. No separate B2B system.
- **R:** [Cite B2B merchant managing X company accounts]

**"Limited for global / international"**
- **S:** You sell in multiple countries and currencies
- **T:** Shopify Markets is purpose-built for global commerce — 150+ currencies, localized checkout, duty/tax, Markets Pro
- **A:** One admin, many markets. No separate storefronts per country.
- **R:** [Cite global merchant selling in X markets from one Shopify store]

**"Hidden costs / pricing not transparent"**
- **S:** You're concerned about total cost of ownership
- **T:** Transparent subscription + transaction fees. No licensing fees, no surprise charges.
- **A:** Predictable costs. Compare 3-year TCO vs [competitor] licensing + hosting + maintenance + agency.
- **R:** [Cite TCO analysis showing X% savings]

**"We need headless / composable"**
- **S:** You want flexibility to decouple frontend from backend
- **T:** Shopify supports headless via Hydrogen + Storefront API, AND traditional Liquid themes
- **A:** Choice without commitment. Start with Liquid, go headless for specific experiences, keep both.
- **R:** [Cite merchant using hybrid approach]

---

## Battle Card Generation

When asked to generate a battle card for a specific competitor:

### Research Protocol (parallel)

1. **Vault** — Search for win/loss analyses, competitive mentions `[INTERNAL-ONLY]`
2. **Slack** — Search #competitive channels and deal discussions
3. **Klue** (via Drive) — Search for existing battle card docs
4. **Web** — Public competitor pricing, features, reviews, G2/TrustRadius comparisons

### Battle Card Format

```markdown
## ⚔️ Battle Card: Shopify vs [Competitor]

**Last Updated:** [Date]
**Tier:** [Enterprise / Mid-Market / Open-Source / Adjacent]

### Quick Positioning
[One-liner: why Shopify wins against this competitor]

### Their Strengths (Acknowledge)
- [Genuine strength — don't dismiss]
- [Strength]

### Their Weaknesses (Probe)
- [Weakness + discovery question to surface it]
- [Weakness + question]

### Our Advantages (Lead With)
- [Advantage + evidence/proof point]
- [Advantage + evidence]

### Key Objections & S.T.A.R. Responses
| Objection | S.T.A.R. Response |
|---|---|
| "[Objection]" | S: [Situation] T: [Truth] A: [Advantage] R: [Reference] |

### Discovery Questions to Ask
- [Question that surfaces their platform pain]
- [Question that highlights our advantage]

### Migration Triggers
- [Events that make merchants switch FROM this competitor]

### Win Stories
- [Merchant who switched from competitor → result] [INTERNAL-ONLY]

### Landmines to Plant
- [Question for merchant to ask competitor that exposes weakness]
```

---

## Win/Loss Research

When analyzing wins or losses against a specific competitor:

1. Search Vault for win/loss reports
2. Search Salesforce for closed opps where competitor was mentioned
3. If `agent-data` available, query:

```sql
SELECT o.name, o.amount_usd, o.close_date, o.primary_result_reason,
       u.name as owner_name
FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
JOIN `shopify-dw.base.base__salesforce_banff_users` u ON o.owner_id = u.user_id
WHERE o.stage_name IN ('Closed Won', 'Closed Lost')
  AND o.close_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
  AND (LOWER(o.competitor__c) LIKE '%[competitor]%'
       OR LOWER(o.primary_result_reason) LIKE '%[competitor]%')
ORDER BY o.close_date DESC
LIMIT 20
```

### Output Format

```markdown
## Win/Loss vs [Competitor] — Last 6 Months

**Record:** [W wins] / [L losses] ([win rate]%)
**Avg Deal Size:** Won $[X] | Lost $[Y]

### Why We Won
- [Pattern from won deals]

### Why We Lost
- [Pattern from lost deals]

### Top Loss Reasons
| Reason | Count | Example |
|---|---|---|
| [Reason] | [N] | [Brief] |

### Coaching Implications
[What reps should do differently based on the data]
```

---

## Agentic Commerce Competitive (UCP vs ACP)

When merchant evaluates Shopify's Agentic / UCP against Salesforce Agentforce Commerce:

**Battle Card: UCP vs ACP (Agentforce Commerce Platform)**

| Dimension | Shopify UCP | Salesforce ACP |
|---|---|---|
| **Native catalog** | Yes — live, real-time from Shopify admin | Synced from Salesforce Commerce Cloud |
| **Checkout** | Shopify checkout (highest-converting) | Redirects to existing checkout |
| **AI integrations** | Production partnerships (ChatGPT, Claude, Perplexity) | Einstein AI, limited third-party |
| **Merchant install base** | 5M+ merchants, global | Enterprise-only, smaller base |
| **Setup complexity** | Low — Catalog API + Agentic plan | High — Salesforce stack required |
| **Pricing model** | Agentic plan tier | Enterprise licensing |

**Positioning:** "Salesforce Agentforce is a CRM layer over AI. Shopify UCP is the commerce layer — real catalog, real checkout, real inventory, real time. Merchants need the store to work in AI, not just the CRM to know about the AI conversation."

**Reference:** For deeper product context, load `~/.claude/skills/product-agentic/SKILL.md`.

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Vault unavailable | Note: "Internal win/loss data unavailable." Proceed with inline knowledge + public research. Flag: "Verify before merchant-facing use." |
| Unknown competitor | Ask: "Is this a commerce platform, SI/agency, or tool/plugin?" Category determines positioning approach. |
| Win/loss data shows Shopify losing consistently | Report honestly. "Win rate vs {competitor}: {X}%. Top loss reason: {reason}." Help address the weakness, don't hide it. |
| Battle card requested for ally (Shopify partner, not competitor) | Flag: "This appears to be a Shopify partner. Partner positioning is collaborative, not competitive. Check with Partner team." |
| User wants to share battle card externally | STOP: "Battle cards are internal only. I can craft merchant-facing positioning, but raw competitive intel stays internal." |
| Competitor recently launched major feature | Flag: "My data may be stale on {competitor}. Verify current features at their website before making claims to merchants." |
| Two competitors in same deal | Position against BOTH. "Against {A}: lead with X. Against {B}: lead with Y." Note where Shopify uniquely wins vs. both. |
| Merchant locked into competitor (multi-year contract) | Adjust: "Long-term contract = nurture play. Focus on relationship + being ready at renewal. Don't waste active selling cycles." |

---


## Platform Reference Data
Load these files for current Shopify platform data before responding:
- `references/competitive-positioning.md` — Market positioning vs SFCC, Adobe, BigCommerce, commercetools with TCO data and stats

## Knowledge Enrichment Directive

When conversation involves specific products or verticals, reference the appropriate domain advisor skill from `~/.claude/skills/product-*` or `~/.claude/skills/vertical-*`. Use `~/.claude/skills/skill-routing-index.json` to identify which domain applies.
