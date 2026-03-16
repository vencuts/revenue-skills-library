# Agentic Commerce & AI Reference

## Universal Commerce Protocol (UCP)

- **Open standard** co-developed by Shopify and Google Shopping
- Enables AI agents to discover, recommend, and complete purchases programmatically
- Launched with **20+ partners**: Google, OpenAI, Perplexity, Microsoft, Meta, others
- Not proprietary to Shopify — industry-wide protocol
- Built on existing web standards (REST/GraphQL, OAuth, JSON-LD)

### End-to-End Flow
1. **Discovery**: AI queries Global Catalog API for products
2. **Recommendation**: AI presents curated options (text, images, rich cards)
3. **Selection**: Buyer chooses product in AI interface
4. **Checkout**: Checkout Kit renders embedded purchase experience
5. **Payment**: Shop Pay or Google Pay processes transaction
6. **Confirmation**: Order created in Shopify admin

### Key Principle: Checkout Stays on Shopify
- Zero PII shared with AI partners
- Payment processing entirely on Shopify infrastructure
- AI partners receive only: catalog data, availability, pricing
- Shopify handles tax, shipping, compliance
- Merchants retain full checkout customizations

## Core Components

### Global Catalog API
- Centralized product catalog for approved AI partners
- Rich metadata: descriptions, images, pricing, variants, availability
- Real-time inventory and pricing updates
- Merchant opt-in per AI partner (granular control)
- Supports international pricing and multi-currency

### Checkout Kit
- Embeddable checkout for third-party surfaces
- Renders Shopify-hosted checkout within AI interfaces
- Supports: single product, multi-item carts, subscriptions
- Shop Pay (150M+ users) + Google Pay
- Customizable via Checkout UI Extensions
- Responsive: chat interfaces, modals, full-screen, mobile

### Storefront MCP (Model Context Protocol)
- MCP server for AI tool/LLM integration
- Capabilities: product search, cart management, checkout initiation, store info
- Merchants install Storefront MCP app to enable
- Scoped permissions (merchant controls access)

### MCP UI
- Visual layer for AI commerce interactions
- Rich product cards, carousels, checkout flows in chat
- Variant selectors, quantity pickers, price display
- Progressive enhancement (falls back to text-only)

## Agentic Plan
- New Shopify plan tier for AI-native commerce
- Optimized for merchants whose primary channel is AI agents
- Enhanced API access + Global Catalog participation
- May not require traditional online storefront

## AI Partner Integrations

| Partner | Status |
|---------|--------|
| OpenAI / ChatGPT | Early Access (Sept 2025) — Allbirds, Spanx, Skims, Vuori |
| Google Shopping | Deep UCP integration + Google Pay |
| Perplexity | AI search with shopping |
| Microsoft Copilot | Shopping within Copilot |
| Meta AI | Product discovery across Instagram, WhatsApp, Messenger |

## Market Data
- **15x growth** in AI-assisted orders during 2025
- Higher conversion rates for AI-recommended products
- AOV comparable to or higher than traditional web
- Full attribution tracking in Shopify admin

## Merchant Opt-In Process
1. Enable agentic commerce in admin
2. Select AI partners (granular control)
3. Configure product visibility
4. Confirm pricing rules
5. Review Checkout Kit rendering
6. Go live — additive channel, no store changes needed
7. Can revoke access at any time

---

## Sidekick (AI Admin Assistant)

- Built into Shopify Admin, **100M+ conversations**
- Available on **all plans** (not a Plus upsell)
- Powered by LLMs with Shopify-specific fine-tuning
- Context-aware: understands store data, products, orders, settings

### Capabilities
- **Store management**: analytics, reports, insights, natural language → GraphQL queries
- **Content generation**: generate apps, themes, Flow automations, product descriptions
- **Voice and multimodal**: speak or share screenshots
- **Screen sharing**: sees what merchant sees for contextual help

### Sidekick Pulse
- Proactive AI insights (initiates, not just responds)
- Low inventory alerts, traffic anomalies, fulfillment delays
- Actionable: each insight includes recommended next step
- Learns merchant preferences to reduce noise

### Sidekick App Extensions
- Third-party apps extend Sidekick with domain-specific knowledge
- Registered via app manifest
- Example: shipping app adds tracking, rate comparison, label generation

---

## Shopify Magic

Suite of AI features embedded across the platform (all plans, no extra cost):

| Feature | Location |
|---------|----------|
| Product descriptions | Products editor |
| Email subject lines | Email editor |
| Image background removal/replacement | Media editor |
| Image generation | Media editor |
| Auto-categorization | Product organization |
| Semantic search | Admin + Storefront |
| Reply suggestions | Inbox |
| Blog post generation | Blog editor |
| Alt text generation | Media editor |

### AI Store Builder
- Create complete store from a single prompt
- Generates: theme, products, collections, policies, homepage
- Iterative refinement via follow-up prompts

### Commerce Foundation Model
- Shopify's internal ML model for commerce understanding
- Powers: categorization, attribute extraction, search ranking, recommendations
- Trained on anonymized/aggregated commerce data

---

## Strategic Missions (2026)

### P0 (Highest Priority)
1. **World-class Product Search** — Commerce Foundation Model, semantic search (35 projects)
2. **Shopify Markets** — International selling at scale (18 projects)
3. **Inventory Ledger Foundations** — Accuracy and scalability (17 projects)
4. **Agentic Storefronts** — UCP, Checkout Kit, AI partners (24 projects, 111 contributors)
5. **Money Infrastructure** — Payments, Balance, Capital (21 projects)

### P1
6. Low Latency Storefronts Everywhere
7. Accelerate Shop App DAU Growth
8. **Win Retail** — POS overhaul (51 projects, 156 contributors)
9. Shopify, Help Me Sell
10. **Best AI Recommendations** — HSTU, Shop Agent, Identity Graph (48 projects)
11. Build Shopify Ads Engine
12. 1 Checkout Engine
13. Yugabyte (database migration)

### Strategic Themes
1. **AI-Native Commerce** — Sidekick, agentic storefronts, AI recommendations
2. **Global Commerce** — Markets, multi-currency, duty/tax
3. **Unified Commerce** — One checkout engine, POS + online convergence
4. **Enterprise/Upmarket** — Checkout extensibility, B2B, scalability
5. **Consumer Experience** — Shop App, product search, recommendations
6. **Platform Performance** — Low latency, inventory accuracy, DB modernization

---

## SE Considerations

### When to Highlight Agentic Commerce
- Strong brand recognition (AI users search by brand)
- DTC brands diversifying beyond web/social
- High-AOV products (AI recommendation adds value)
- Already using Shop Pay (frictionless agentic checkout)

### Common Merchant Questions
- **"Will AI discount my products?"** — No, merchants control pricing
- **"Revenue share with AI partners?"** — Standard Shopify fees; no AI partner fees
- **"Need Hydrogen?"** — No, works with any Shopify store
- **"Is my data used for AI training?"** — Aggregated/anonymized; individual store data not shared
- **"Which plan includes AI?"** — All plans include Sidekick and Magic
