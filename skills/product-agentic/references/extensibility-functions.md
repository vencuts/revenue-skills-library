# Extensibility & Functions Reference

## Shopify Functions

### Runtime
- **WebAssembly (Wasm)** sandboxed execution
- Languages: **Rust** (recommended), **JavaScript/TypeScript** (via Javy/QuickJS)
- Deterministic: same input → same output, no randomness
- Runs on Shopify's edge infrastructure

### Resource Limits (base: carts ≤200 line items)

| Limit | Value |
|-------|-------|
| Wasm module size | **256 KB** |
| Instruction count | **11 million** (exceeding = RunOutOfFuel) |
| Execution time | **5ms** hard limit |
| Input size | **128 KB** |
| Output size | **20 KB** |
| Linear memory | **10 MB** |
| Stack memory | **512 KB** |
| Input query size | **3,000 bytes** (excl. comments) |
| Input query cost | Max **30** |
| Metafield value size in input | **10,000 bytes** max |
| Functions per app | **50** |
| Functions per store (concurrent) | **25** |

- For carts >200 line items: instruction count and input size scale proportionally

### Rust vs JavaScript

| Metric | JavaScript (Javy) | Rust |
|--------|-------------------|------|
| Instructions overhead | 3–7x more | Baseline |
| Execution speed | ~3x slower | Baseline |
| Best for | Prototyping, simple logic | Production, complex logic, large carts |

### Function API Types (2026)

1. **Discount Function API** (consolidated from Order/Product/Shipping in April 2025)
2. **Cart Transform API** (bundles, line item manipulation)
3. **Delivery Customization API** (rename, reorder, hide delivery options)
4. **Payment Customization API** (show/hide payment methods)
5. **Cart and Checkout Validation API** (enforce purchase rules)
6. **Fulfillment Constraints API** (control fulfillment grouping)
7. **Order Routing Location Rule API** (developer preview)
8. **Local Pickup Delivery Option Generator API** (Plus only)
9. **Pickup Point Delivery Option Generator API** (third-party pickup)

**Execution order**: Cart Transform → Discounts → Fulfillment/Routing → Delivery → Payment → Validation

### Network Access (Fetch Target)
- Early access: custom apps on Plus stores only
- Two-step: `fetch` defines HTTP request → Shopify executes → response becomes `run` input
- From API version 2025-04+

### Scripts → Functions Migration
- Scripts sunset: **June 30, 2026**
- Can coexist until sunset date
- Line Item Scripts → Discounts API / Cart Transform API
- Shipping Scripts → Delivery Customization API
- Payment Scripts → Payment Customization API

---

## Checkout UI Extensions

### Architecture (Remote DOM)
- Run in **Web Workers** (isolated from main checkout thread)
- Render Shopify-provided UI components only — no real DOM, no iframe, no script tags
- CSS cannot be overridden — merchant branding always respected
- Cross-platform: same experience on web, iOS, Android
- **64 KB** max compiled bundle (enforced since API 2025-10)
- May need Preact instead of full React to stay under limit

### Extension Targets

| Type | Placement | Rendering |
|------|-----------|-----------|
| Static | Auto-positioned relative to checkout feature | Only when feature renders |
| Block | Merchant-placed via Checkout Editor | **Always renders** (14 placements) |

### Plan Requirements
- Information/Shipping/Payment steps: **Plus only**
- Thank You / Order Status pages: **all plans**

### Network Access
- `network_access = true` in config → external HTTP calls from Web Worker
- `api_access` → direct Storefront API queries from extensions
- Alternative: pre-populate metafields via Admin API (faster, no runtime call)

### Post-Purchase Extensions
- After payment, before Thank You page
- Vaulted payment token → one-click acceptance (no CVV re-entry)

---

## Discounts

### Methods
- Discount codes (customer enters at checkout)
- Automatic discounts (applied when conditions met, max **25 active**)
- Buy X Get Y
- Free shipping

### Classes & Stacking
- 3 classes: **Product**, **Order**, **Shipping**
- Same-class discounts cannot combine — highest value wins
- Cross-class stacking: multiplicative (not additive)
- Priority: Product → Order → Shipping
- Max **5 discount codes** per order

### Limits
| Limit | Value |
|-------|-------|
| Active automatic discounts | 25 |
| Discount codes per order | 5 |
| Bulk-generated codes per discount | 20 million |

### Volume Pricing (Plus / B2B)
- Quantity-based price tiers on variants
- Example: 1-9 = $20, 10-49 = $18, 50+ = $15

---

## Metafields & Metaobjects

### Metafield Limits
| Limit | Value |
|-------|-------|
| Definitions per resource per app | 256 |
| Definitions per resource (merchant) | 256 |
| Standard definitions | Don't count toward limits |
| Pinned definitions per resource | 20 |
| Most value types | 65,000 characters |
| JSON value (current) | ~2MB |
| JSON value (2026-04, new apps) | 128KB → 16KB |
| List items | 128 (256 for metaobject refs) |
| Smart collection definitions | 128 |

### Metaobject Limits
| Limit | Value |
|-------|-------|
| Definitions per app | 128 |
| Definitions per merchant (non-Plus) | 128 |
| Definitions per merchant (Plus) | 256 |
| Entries per definition | 1,000,000 |

### Capabilities
- Accessible in: Liquid, APIs, Flow, Checkout Extensions
- Standard definitions universal across Shopify, supported by apps/themes
- Metaobjects serve as headless CMS (queryable via Storefront API)

---

## Shopify Flow

### Availability
- Basic, Grow, Advanced, Plus (free app)
- Not on Starter plan
- HTTP Request action: **Grow+ only** (not Basic)
- Custom partner app tasks: **Plus only**

### Limits
| Limit | Value |
|-------|-------|
| Workflows per store | 1,000 |
| Wait steps per workflow | 40 |
| Max cumulative wait | 90 days |
| Execution timeout per section | 36 hours |
| Scheduled trigger min frequency | 10 minutes |
| Manual run max items | 50 |
| For Each max items | 1,000 |
| For Each nesting | 2 levels |
| For Each actions per iteration | 1 |
| Get Data max items | 100 |
| HTTP timeout | 30 seconds |
| Tag limit in conditions | 250 |

---

## Liquid / Themes (Online Store 2.0)

| Limit | Value |
|-------|-------|
| For loop max iterations | 50 |
| Paginate page size | 1–250 |
| Max reachable item | 25,000th |
| Sections per JSON template | 25 |
| Blocks per section | 50 |
| JSON templates per theme | 1,000 |

- Cannot make API calls from Liquid
- `gift_card` and `robots.txt` must be Liquid (not JSON)
- Sections Everywhere: sections on any page via JSON templates
- Section presets required for theme editor discoverability

---

## Apps

### Distribution Types
| Type | App Store | Multi-Store | Review |
|------|-----------|-------------|--------|
| Custom | No | No (single store/org) | No |
| Public (Listed) | Yes | Yes | Yes |
| Unlisted | Yes (limited) | Yes (direct link) | Yes |

### Built for Shopify (BFS)
- Quality certification: performance, design, integration standards
- Badge + priority review + **49% average increase in installs** (14 days)
- All new public apps: GraphQL Admin API only (April 2025)

### Plus Certified App Program (PCAP)
- Requires: BFS, security assessment, 4.0+ rating (20+ reviews), latest 2 API versions
- Provides: partnership manager, solutions architect access, certified directory listing

### App Proxies
- 1 proxy route per app
- `Content-Type: application/liquid` → renders with store data in theme context

### Theme App Extensions
- App blocks (in sections) + App embed blocks (site-wide)
- Survive theme updates (no code injection)

---

## Security & Compliance (Key Facts)

- PCI DSS Level 1 (v4.0.1 mandatory March 2025)
- SOC 1/2/3 Type II, ISO 27001
- Free SSL (Let's Encrypt, auto-renewed, TLS 1.2+)
- DDoS protection automatic
- 2FA mandatory for all staff
- Bug bounty on HackerOne ($500–$50,000+, >$4M paid out)
- Shopify Protect: free fraud protection on Shop Pay orders
- Web pixel sandbox: isolated iframe + Web Worker (PCI DSS v4 compliant)
- checkout.liquid deprecation: Plus stores by Aug 2025, non-Plus by Aug 2026
