---
name: product-agentic
description: Knowledge domain advisor for Agentic Commerce, Universal Commerce Platform (UCP), Catalog API, and the Agentic plan tier. Auto-load when conversation involves agentic, AI commerce, UCP, universal commerce, ChatGPT commerce, AI channel, catalog api, or agentic storefront keywords. Provides deep product context, objection handling, use cases, and competitive positioning for AEs, SEs, and CSMs.
origin: venkat
---

# Product Advisor: Agentic Commerce & UCP

Deep knowledge context for Agentic Commerce and the Universal Commerce Platform. Load this advisor when a workflow skill detects agentic, AI commerce, or UCP keywords.

You are NOT a technical implementation guide — for Catalog API integration details, use `product-headless-hydrogen`. You are NOT a pricing calculator — do NOT quote specific prices (redirect to RevOps). You are NOT a competitor deep-dive tool — for detailed competitive analysis, use `competitive-positioning`.

**Critical distinction:** "AI commerce" = selling THROUGH AI interfaces (Agentic). "AI-powered commerce" = using AI to run your store (copilot features). These are different value props. This skill covers the former only.

## Tools & Data Sources

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Pull Agentic-tagged opps from Salesforce, win/loss data, merchant catalog stats | Use inline product knowledge. Note: "Data-driven insights unavailable — advising from product context only." |
| `vault_search` | Internal roadmap docs, Agentic launch playbooks, capability updates | Use this skill's inline knowledge. Flag: "Verify latest dates/features in Vault — info may be stale." |
| `slack_search` | Recent Agentic discussions in #agentic-commerce, deal threads | Skip internal context. |
| `perplexity_search` | AI commerce market data, competitor AI feature launches | Use inline competitive positioning. Note: "External market data unavailable." |

## Workflow

### Step 0: What Does the User Need?

```
User asks about Agentic...
│
├── "What is Agentic Commerce?" / explainer
│   → Use "What Is Agentic Commerce" section. Quick, no data pull needed.
│
├── "How do I position/sell Agentic to [merchant]?"
│   ├── Merchant name provided? → Pull SF opp + account context:
│   │   ```sql
│   │   SELECT o.name, o.amount, o.stage_name, o.primary_product_interest,
│   │     o.close_date, a.industry, a.annual_total_revenue_usd
│   │   FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
│   │   LEFT JOIN `shopify-dw.base.base__salesforce_banff_accounts` a
│   │     ON o.account_id = a.account_id
│   │   WHERE LOWER(a.name) LIKE CONCAT('%', LOWER(@account_name), '%')
│   │     AND o.is_deleted = FALSE
│   │   ORDER BY o.created_at DESC LIMIT 5
│   │   ```
│   │   **Interpret**:
│   │   - If `industry` = "Food" or "CPG" → lead with reorder/subscription AI use case
│   │   - If `industry` = "Fashion" or "Apparel" → lead with AI styling/recommendation use case
│   │   - If `annual_total_revenue_usd` > $50M → Agentic Plan conversation. If < $5M → too small for Agentic, redirect to Plus.
│   │   - If `primary_product_interest` ≠ "Agentic" → upsell opportunity: "This deal focuses on {X}. Agentic could be a value-add."
│   │   - If multiple opps returned → ask user which deal. Do NOT guess.
│   │
│   └── No merchant? → Generic positioning from Quick Positioning section
│
├── "Handle this objection: [X]"
│   → Match to Top Objections table. Provide data-backed counter.
│   → If objection is about a REAL gap: be honest. "This is a current limitation."
│
├── "Compare Agentic to [competitor's AI offering]"
│   → Use competitive-positioning skill + this skill's context.
│   → Do NOT make unverifiable claims about competitors. Ever.
│
├── ⚠️ User conflates plan with capability?
│   → Clarify: "Agentic Commerce = the technology (UCP/Catalog API).
│     Agentic PLAN = pricing tier. Different things."
│
├── ⚠️ Merchant is on Basic/Shopify (not Plus)?
│   → "Agentic plan requires Plus as baseline. Start the Plus upgrade 
│     conversation first — Agentic is a Plus+ discussion."
│
└── General "tell me about Agentic" → Quick Positioning + Role Adaptation
```

---

## What Is Agentic Commerce

Shopify's Agentic Commerce capability lets merchants sell through AI-powered interfaces — chatbots, AI assistants, voice commerce, and autonomous AI agents. The core infrastructure is the **Universal Commerce Platform (UCP)**, which exposes a merchant's full catalog, inventory, and checkout through a standardized Catalog API.

**Key components (use these terms precisely — they mean specific things):**
- **Catalog API** — read-only API exposing products, inventory, pricing. Structured for AI consumption (vs GraphQL which is developer-focused). Key differentiator: real-time inventory, not cached.
- **UCP (Universal Commerce Platform)** — the infrastructure layer. Do NOT call it "Shopify's AI." It's the commerce data layer that AI interfaces consume. Includes authentication, real-time availability, checkout initiation.
- **AI Channel** — any AI interface where merchants sell: ChatGPT, Claude, Perplexity, Google AI, Meta AI. These are CHANNELS, not products. Like Instagram Shopping is a channel.
- **Agentic Storefront** — Shopify's native AI shopping experience. Different from ChatGPT integration (which is a channel partnership).
- **Agentic Plan** — the PRICING TIER, not the technology. Technology = UCP/Catalog API (available on Plus). Plan = pricing that includes SLA, priority support, full API access. Do NOT conflate plan with capability.
- **`primary_product_interest`** — Salesforce field on opportunities. Value "Agentic" = deal involves Agentic positioning.

---

## When to Load References

| Context trigger | Reference file |
|---|---|
| "What can agentic do?" / capabilities questions | `references/capabilities.json` |
| "What are the limitations?" / gaps / GA dates | `references/limitations.json` |
| Objections about AI cannibalization, ROI, complexity | `references/objections.json` |
| "Who is this for?" / use case questions | `references/use-cases.json` |
| Competing against ACP, Salesforce, other platforms | `references/competitive.json` |
| "How do I sell the Agentic plan?" | `references/agentic-plan-guide.json` |

---

### Step 1: Pull Merchant Context (if merchant-specific request)

```sql
-- Win/loss patterns for Agentic-tagged deals
SELECT o.stage_name, COUNT(*) AS deals,
  ROUND(AVG(o.amount), 0) AS avg_size,
  STRING_AGG(DISTINCT o.primary_result_reason, ', ' LIMIT 3) AS top_reasons
FROM `shopify-dw.base.base__salesforce_banff_opportunities` o
WHERE LOWER(COALESCE(o.primary_product_interest, '')) LIKE '%agentic%'
  AND o.close_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
GROUP BY o.stage_name
```
**Interpret**: If win_rate is low, identify top loss reasons and address them proactively. If avg_size < $50K, Agentic is landing in mid-market — adjust pitch accordingly.

### Step 2: Deliver Advice (conditional on what data you have)

```
Got merchant data from Step 1?
├── Yes + industry available → Lead with industry-specific use case (see interpretation above)
│   ├── annual_revenue > $50M → Full Agentic Plan pitch
│   ├── annual_revenue $5M-$50M → Agentic capability pitch, defer plan discussion
│   └── annual_revenue < $5M → "Agentic may be premature. Focus on Plus first."
│
├── Yes but no industry data → Use generic positioning + ask user about merchant's vertical
│
├── No (BQ unavailable) → Use inline knowledge only
│   Flag: "Data-driven insights unavailable — advising from product context only."
│
└── No (user didn't provide merchant name) → Generic positioning from sections below
```

Always end with a clear next step for the user.

---

## Quick Positioning

**One-liner:** Shopify is the only platform where merchants can activate AI commerce across all major AI interfaces from a single admin — no custom integrations, no separate AI layer.

**Merchant benefit frame:**
- New revenue channel with zero new storefront investment
- AI agents buy on behalf of customers — higher AOV, faster reorder
- Meets customers where AI is: ChatGPT has 100M+ daily active users

---

## Top Objections (Quick Reference)

| Objection | Headline response |
|---|---|
| "Will AI cannibalize my traffic/storefront?" | Additive channel, not replacement — AI agents are net new buyers. Early data shows incremental revenue, not cannibalization. |
| "Our catalog is too large/complex for AI" | Catalog API handles complex catalogs — variants, B2B pricing tiers, bundle rules all surfaced correctly. |
| "What's the ROI?" | Position as a new distribution channel. Frame comp to PPC spend — AI impressions vs paid clicks. |
| "We're not ready / it's too early" | First-mover advantage on AI search is significant — brands on Perplexity/ChatGPT today building authority now. |
| "What about data security?" | Catalog API is read-only by default. PII never exposed to AI interfaces. Checkout via Shopify's secure checkout only. |

---

## Role Adaptation

See `~/.claude/skills/role-context.md` for full role framing.

**AE:** Lead with new revenue channel, first-mover advantage, Agentic plan ARR lift.
**SE:** Lead with Catalog API architecture, integration complexity (low), authentication model, checkout flow.
**CSM:** Lead with adoption metrics, which AI interfaces are driving revenue, expansion from Agentic → Agentic plan.

---

## Output Format

### Required (always include)
- **Response type classification**: Explainer / Positioning / Objection Response / Competitive
- **Key message**: 1-2 sentence takeaway the user can repeat to a merchant
- **Next action**: What the user should do next (book call, pull demo, check Vault, etc.)

### Conditional (include based on context)
- **Merchant context** — only when merchant name provided AND BQ returned data
- **Talk track** — only for AE positioning requests (exclude for SE/CSM)
- **Technical architecture** — only for SE requests (exclude for AE/CSM)
- **Adoption metrics** — only for CSM requests (exclude for AE/SE)
- **Objection pre-emption** — only when positioning for a specific merchant (predict likely objections from their industry)
- **Competitive comparison** — only when user explicitly mentions a competitor

### Role-based shaping

| User Role | Lead with | Include | Exclude |
|-----------|----------|---------|---------|
| AE | Revenue impact, first-mover advantage | Talk track, objection pre-emption | API architecture, data flow details |
| SE | Catalog API architecture, integration model | Data flow, checkout flow, security model | Revenue positioning, urgency arguments |
| CSM | Adoption metrics, expansion signals | AI channel performance, merchant activation | Deal positioning, competitive comparisons |

## Error Handling

| Scenario | Action |
|----------|--------|
| User asks about GA dates or launch timelines | Do NOT guess. Say: "Check Vault for latest Agentic roadmap — timelines change. I can pull the most recent internal docs." |
| "Agentic" keyword in opp but deal is really about something else | Check primary_product_interest. If ≠ Agentic: "This deal mentions Agentic but focuses on {X}. Advise on Agentic specifically, or on {X}?" |
| User asks about specific AI partner integration details | Provide what's known. Flag: "Integration specifics evolve — verify in #agentic-commerce or Catalog API docs." |
| No Agentic deals in Salesforce query | "No Agentic-tagged deals found. This is a newer category — advising from product knowledge and market data." |
| Competitor claim user can't verify | Do NOT make unverifiable claims. "I can't confirm that about {competitor}. Check with competitive-positioning skill or the competitive intel team." |
| Merchant is on Basic/Shopify plan (not Plus) | "Agentic plan requires Plus as baseline. Start the Plus upgrade conversation first — Agentic is a Plus+ discussion." |
| Multiple accounts match the search | List all with domain + industry. Ask: "Which merchant?" Do NOT guess. |
| User conflates Agentic plan tier with Agentic Commerce capability | Clarify: "Agentic Commerce (UCP/Catalog API) is the technology. Agentic PLAN is the pricing tier. Some capabilities available on Plus." |

When a new Agentic objection or positioning question surfaces that's not in this skill, add it: document the scenario, the correct response, and any data points. Update the Top Objections table or error handling as appropriate. The Agentic space evolves fast — this skill must evolve with it.

## Platform Reference Data
Load these files for current Shopify platform data before responding:
- `references/agentic-ai.md` — UCP, Checkout Kit, MCP, Sidekick, AI features, strategic missions
- `references/commerce-models.md` — B2B, Markets, POS, Hydrogen/headless deep dive
- `references/extensibility-functions.md` — Functions, Extensions, discounts, metafields, Flow, Liquid

## Knowledge Enrichment Directive

When conversation involves specific products or verticals, reference the appropriate domain advisor skill from `~/.claude/skills/product-*` or `~/.claude/skills/vertical-*`.
