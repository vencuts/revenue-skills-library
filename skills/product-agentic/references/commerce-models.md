# Commerce Models Reference

## B2B on Shopify

### Plan Requirement: Plus Only ($2,300+/mo)
Non-Plus merchants use third-party apps (BSS, SparkLayer).

### Company Accounts
- Company → Company Locations (shipping/billing addresses)
- Up to **50 customers** per Company Location
- Up to **25 catalogs** per Company Location
- Catalogs define per-location pricing, volume pricing, quantity rules
- B2B Markets: group company locations by region for bulk catalog assignment

### Payment Terms
- Due immediately (default)
- Net terms: Net 7, 15, 30, 45, 60, 90 (from order placement)
- Due on fulfillment (supports per-fulfillment payment for multi-shipment)
- Fixed date (draft orders only)
- Deposit option: any term can require upfront % deposit
- Up to 5 automated payment reminders, up to 30 days after due date
- Vaulted credit cards for deferred payment

### B2B APIs
- Company, CompanyLocation, CompanyContact GraphQL objects
- Catalog API, Payment Terms API, DraftOrder API
- Max 25 payment customization functions per store
- B2B GMV grew **96% in 2025** YoY
- Named Leader in 2024 Forrester Wave for B2B Commerce

---

## Shopify Markets (International)

### Currency & Pricing
- **130+ currencies** via Shopify Payments (only gateway supporting multi-currency)
- Per-market price adjustments (percentage or fixed)
- Currency rounding rules per market
- Currency conversion fee: 1.5% (US), up to 2.0% (international)
- Multi-entity support: map markets to legal entities, per-entity Shopify Payments

### Plan Availability
| Plan | Markets |
|------|---------|
| Basic | Up to 3 |
| Grow | Up to 3 |
| Advanced | Up to 3 + Markets included |
| Plus | Up to 50 + Managed Markets |

### Managed Markets (formerly Markets Pro)
- Shopify acts as merchant of record for international sales
- Handles duties, taxes, compliance on behalf of merchant

### Routing Options
- **Subfolder**: `example.com/en-ca` (default, simplest)
- **Subdomain**: `ca.example.com`
- **ccTLD**: `example.ca`
- Apps/themes must use `routes` Liquid object (not hardcoded URLs)

### Expansion Stores (Plus Only)
- Up to **10 stores** (1 main + 9 expansion) at no additional cost
- Dev/staging stores don't count toward limit
- Must be extensions of main brand (same name, same goods)
- Don't confuse with Markets — Markets = international from one store

### Key Stat
- 13% conversion increase with localized language (Shopify data)

---

## POS (Retail)

### POS Lite (Free with all plans)
- Basic product/inventory, payment processing, customer management
- Limited multi-location, no staff roles, no advanced inventory

### POS Pro
- **$89/mo per location** (monthly) / $79/mo (annual)
- Advanced inventory, BOPIS, staff roles/permissions, customizable checkout, exchanges
- Plus: first **20 POS Pro locations included**
- Plus with Shopify Payments + 1 retail tx/mo: POS Pro may be **waived on all locations**
- Mix-and-match: some locations Lite, some Pro

### Hardware
| Device | Price |
|--------|-------|
| Tap & Chip Reader | $49 |
| POS Terminal | $349 |
| Terminal Countertop Kit | $459 |
| Tablet Stand | $149 |

### Tap to Pay
- Free: iPhone XS+ (iOS 15.5+) or compatible Android
- Contactless credit/debit, Apple Pay, Google Pay, digital wallets

### Capabilities
- Real-time inventory sync (online + in-store)
- Buy Online, Pick Up In-Store (BOPIS)
- Ship-from-store
- Shop Pay in-store
- Offline mode
- Extensible via POS UI Extensions

---

## Hydrogen (Headless)

### Framework
- React-based, built on **React Router 7** (formerly Remix)
- Shopify-specific primitives: cart, customer accounts, product data, analytics
- File-based routing (`app/routes/`)
- Open-source: `@shopify/hydrogen`
- CLI: `npm create @shopify/hydrogen@latest`

### Oxygen Hosting
- **100+ data center locations** worldwide
- Runs on **workerd** runtime (Cloudflare Workers-based), not Node.js
- **Free** on all paid Shopify plans (not Starter/dev stores)
- Auto-deploy from GitHub, PR previews, custom domains
- Worker bundle: 10 MB compressed max
- No persistent filesystem (stateless edge compute)

### Performance
- Edge-cached: sub-100ms TTFB globally
- Streaming SSR: FCP typically under 1 second
- Lighthouse 90+ achievable

### When to Go Headless
**Use Hydrogen when**: custom/app-like UX needed, multi-storefront, strong React team, performance-critical
**Stay with Liquid when**: merchant needs self-service editor, budget/timeline constrained, standard e-commerce flows, broader app compatibility

### Key Tradeoffs
| Factor | Liquid | Hydrogen |
|--------|--------|----------|
| Time to launch | Days–weeks | Weeks–months |
| Theme editor | Full | Not available |
| App compatibility | Broad | API-only apps |
| Developer skillset | Liquid/HTML/CSS | React/TypeScript |
| Checkout | Shopify Checkout | Same Shopify Checkout |

### Caching
- CacheNone() / CacheShort() (1s SWR) / CacheLong() (1h SWR) / CacheCustom()
- Subrequest caching for Storefront API calls

### Customer Auth (Headless)
- Customer Account API with OAuth 2.0 PKCE
- Multipass SSO for Plus merchants

### Content Management
- Metaobjects as headless CMS within Shopify
- Or integrate external CMS (Contentful, Sanity)

### Third-Party Headless
- `@shopify/hydrogen-react`: framework-agnostic React components (works with Next.js, etc.)
- Includes: `<Money>`, `<Image>`, `<CartProvider>`, `<ShopPayButton>`
- No server-side utilities or Oxygen integration

### Commerce Components by Shopify (CCS)
- Composable, modular access to Shopify's stack
- Target: $500M+ GMV retailers
- Cherry-pick: Checkout, Shop Pay, Cart, etc.
