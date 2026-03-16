---
name: outbound-cadence
description: Generate cold outbound email cadences for SDRs and AEs targeting specific personas, platforms, and industries. Use when asked to "write a cadence", "cold email sequence", "outbound emails for [company]", "SDR outreach plan", "email drip for [persona]", "write prospecting emails", or when preparing outbound campaigns. Works for SDRs, BDRs, AEs doing outbound, and sales managers coaching outreach.
---

# Outbound Cadence Generator

Generate data-informed cold email cadences tailored by persona, platform, industry, and business model. Produces copy-paste-ready email sequences — NOT generic templates.

**Source**: Patterns extracted from sdr-pov-generator.quick.shopify.io (Mike Canaan, Manager Commercial Sales) + internal competitive intel.

## Required Tools

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` / `agent-data` | Pull account context from UAL, SF opps, activity history | Generate without data personalization. Flag: "No account data — using industry/platform positioning only." |
| `perplexity_search` / `web_search` | Recent company news, funding, launches for personalization | Skip company-specific hooks. Use industry-level angles. |
| `slack_search` | Check #competitive-intel for recent competitor mentions | Use static platform knowledge from this skill. |

## Workflow

### Step 0: Gather Context

**What do you know?**
- Has persona? (Head of Ecomm / CTO / CEO / Finance / Marketing) → If not, default to "Head of Ecommerce" for commerce-focused, "CTO" for tech-focused
- Has current platform? → If not, ask. If truly unknown, use "unknown platform" angles
- Has industry? → If not, check UAL or ask
- Has business model? (D2C / Retail / B2B / Mixed) → If not, check SF opp or ask
- Has company-specific context? (news, funding, expansion, hiring) → Optional but dramatically improves quality

**If user provides a company name**: Run a quick UAL check to get platform, industry, and any existing opp context before generating.

### Step 1: Select Positioning Angles

Map the combination of persona + platform + business model to angles:

**By Persona (what they care about):**
- **Head of Ecommerce**: site performance, conversion rate, owning the roadmap, not waiting on dev
- **CTO**: dev velocity, integration maintenance burden, not being on-call for platform fires, total system complexity
- **CEO/Founder**: growth speed, time to market, not getting slowed by tech debt, competitive positioning
- **Finance (CFO/VP Finance)**: total cost of ownership, unpredictable fees, ROI timeline, hidden agency costs
- **Marketing (CMO/VP Marketing)**: campaign speed, personalization without dev, speed to launch, not waiting on tickets

**By Business Model (shapes the entire cadence):**
- **D2C**: conversion, repeat purchase, marketing automation, subscription revenue
- **Retail**: inventory sync, unified online+offline, POS reliability, staff training
- **B2B**: bulk ordering, account management, net terms, custom catalogs, draft orders
- **Mixed (D2C+Retail, D2C+B2B, ALL)**: managing multiple channels without breaking anything, single source of truth

### Step 2: Generate 7-Step Cadence

Produce 7 emails following this progression:

| Email | Day | Tone | Purpose |
|-------|-----|------|---------|
| 1 | Day 1 | Direct | Lead with strongest POV angle. Establish relevance. |
| 2 | Day 3 | Curious | Ask a genuine question about their business/platform. |
| 3 | Day 7 | Pattern interrupt | Break the expected cold email format. Short, punchy, unexpected. |
| 4 | Day 10 | Bold | Make a specific claim or challenge an assumption. |
| 5 | Day 14 | Empathetic | Acknowledge their situation. Show you understand the real problem. |
| 6 | Day 17 | Last-try angle | New angle entirely. Something you haven't tried yet. |
| 7 | Day 21 | Breakup | Honest, no-pressure goodbye. Sometimes this one gets the reply. |

### Rules (do NOT violate)

**Format:**
- Each email: 3-5 lines max. Read like a text message, not a newsletter.
- Subject lines: under 5 words, lowercase feel, curiosity-driving. Like something a friend sent.
  - Good: "your checkout is leaking", "quick ? about WooCommerce", "saw something interesting", "honest question"
  - Bad: "Shopify Migration Opportunity", "Following Up On Our Discussion", "Unlock Your Growth Potential"
- Never start two subject lines the same way.

**CTAs — vary across the 7 emails:**
- Do NOT use the same CTA twice. Mix: 15-min call, one specific question, "is this even a priority?", yes/no reply, quick demo offer, "who should I talk to?"

**Banned words (do NOT use in any email):**
"leverage", "synergy", "solution", "pain points", "touch base", "circle back", "hope this finds you", "just following up", "wanted to reach out", "I know you're busy", "headless", "composable", "omnichannel", "tech stack", "scalable", "robust", "seamless", "streamline", "optimize", "ecosystem"

**Language:**
- Write in plain English. If you can't say it in normal words, don't say it.
- Instead of "headless commerce" → "building your own storefront"
- Instead of "composable architecture" → "picking the tools you actually want"
- Instead of "omnichannel" → "selling everywhere"
- Instead of "scalable infrastructure" → "doesn't break when you grow"

### Step 3: Platform-Specific Pain Points

Use these ONLY for the relevant platform. Do NOT include pain points for platforms the prospect isn't on.

**Lightspeed**: Retail POS first. Online store is bolted on and limited. Inventory sync between online and physical locations is a constant headache. Not built for growing online.

**Square**: Started as a payment tool. Ecommerce is basic, customization shallow, doesn't scale for real online ambitions. The angle: outgrowing the tool.

**WooCommerce**: WordPress-based, constant plugin management. Merchants own the hosting, security patches, broken integrations. Developer dependency they didn't sign up for.

**Magento/Adobe Commerce**: Expensive, slow to deploy, requires heavy dev resources. Built for enterprise but mid-market merchants pay enterprise prices for problems they don't need.

**BigCommerce**: Solid features but merchants hit walls around customization, app ecosystem depth, and costs to unlock advanced functionality.

**Unknown/Custom**: Focus on general operational pain — slow dev cycles, limited flexibility, vendor lock-in, integration maintenance burden.

## Output Format

```
📧 7-STEP COLD EMAIL CADENCE
Target: {persona} at {company/industry} ({business_model}) — currently on {platform}

---

Email 1 — Day 1 (Direct)
Subject: {subject}
{body}

Email 2 — Day 3 (Curious)
Subject: {subject}
{body}

[... through Email 7]

---

💡 PERSONALIZATION NOTES
- Best angle for this prospect: {which POV to lead with and why}
- If they reply with objection: use competitive-positioning skill → S.T.A.R. framework
- Cadence timing: adjust Day gaps if prospect is in active eval (compress to 2-day gaps)
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No platform identified | Use "unknown platform" angles — focus on general operational pain |
| Persona unclear | Default to Head of Ecommerce. Note: "Assumed ecomm buyer — adjust if targeting CTO/Finance" |
| No company context provided | Generate industry-level cadence. Flag: "Add company-specific context for 3x better personalization" |
| User asks for fewer than 7 emails | Generate the requested count, maintaining the tone progression arc |
| User asks for a single email | Redirect: "For single emails, use `sales-writer`. This skill generates sequences." |
| Prospect is already on Shopify | Do NOT generate migration cadence. Ask: "They're already on Shopify — are you upselling Plus, B2B, or POS?" |
| Competitor not in our platform list | Reason from first principles. Research via web search. Note: "Platform not in standard database — angles based on research." |
| User wants to include pricing | Do NOT include specific pricing. Say: "Pricing should come from deal desk. Focus on value, not cost in cold outreach." |

## Scope & Boundaries

- **Do NOT** include Shopify pricing or discount offers in cold emails — that comes from deal desk
- **Do NOT** make claims about competitor outages or security issues unless publicly documented
- **Do NOT** generate cadences for existing Shopify merchants without clarifying the upsell angle first
- **This skill is NOT for warm follow-ups** — use `deal-followup` for post-meeting emails
- **This skill is NOT for objection handling** — use `competitive-positioning` when a prospect replies with pushback
