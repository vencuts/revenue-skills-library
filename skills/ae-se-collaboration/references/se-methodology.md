# SE Methodology Reference

## SE Organization

- Parent: Solution Engineering (under Sales)
- Segments: Enterprise, Large, Mid-Market, Retail, Partners
- Roles: Solutions Engineers, Solution Architects, Demo Engineering, Retail Specialists
- Leader (Enterprise): Tim Keelan

## Core Responsibilities

### 1. Technical Discovery
- Lead requirements discovery sessions with merchants
- Translate pain points into technical requirements
- Partner with Sales throughout deal cycle
- Understand current tech stack, processes, and goals

### 2. Solution Architecture
- Architect end-to-end solutions (frontend to backend)
- Map Shopify capabilities to merchant requirements
- Ensure all pieces fit together and stakeholders accept

### 3. Demos & POCs
- Custom Shopify demos for prospects
- Prove technical viability for complex needs
- Use free development stores (full Plus features)

### 4. Deal Support & Risk Assessment
- Technical qualification of deals
- Commercial Risk Assessment
- Identify risks impacting budget or timeline
- Work with development partners/agencies

### 5. Platform Expertise
- Expert on Shopify ecosystem
- Mentor client-facing teams
- Align with product/R&D on roadmaps
- Channel feedback on features and trends

## Common Solutioning Scenarios

### 1. Platform Migration / Replatforming
- **Timeline**: 3–6 months typical
- Data migration: products, customers, orders (historical)
- URL redirect mapping for SEO preservation
- Theme/storefront rebuild (Liquid or Hydrogen)
- App ecosystem mapping (replace custom with apps)
- Integration re-architecture
- Common sources: Magento, SFCC, WooCommerce, custom

### 2. International Expansion
- **Decision**: Markets (single store, multi-market) vs expansion stores (Plus)
- Markets: up to 50 markets on Plus, 3 on standard plans
- Multi-currency (130+ via Shopify Payments)
- Managed Markets: Shopify as merchant of record
- Local payment methods per market
- Multi-entity support for legal structures
- 13% conversion increase with localized language

### 3. B2B Launch
- **Requirement**: Plus for native B2B
- Company accounts → locations → catalogs → price lists
- Payment terms (Net 7/15/30/45/60/90)
- Draft orders and invoicing workflow
- ERP integration for order sync
- B2B + DTC from single store

### 4. Omnichannel / Unified Commerce
- POS deployment strategy (Lite vs Pro)
- Inventory unification across channels
- BOPIS, ship-from-store, in-store returns
- Customer recognition across channels
- Plus: 20 POS Pro locations included

### 5. Headless / Custom Storefront
- **Decision framework**: Hydrogen vs Liquid
- Hydrogen when: custom UX needed, React team available, multi-storefront
- Liquid when: speed to market, self-service editing, broader app compatibility
- Oxygen hosting: free, 100+ edge locations
- Storefront API: no rate limits
- TCO: Hydrogen higher initial investment, Liquid lower

### 6. Complex Checkout
- Functions: discount, delivery, payment, validation, fulfillment, cart transform
- UI Extensions: pre-purchase, purchase, post-purchase
- Plus required for checkout step customization
- All plans: Thank You / Order Status extensions
- checkout.liquid deprecated → Checkout Extensibility

### 7. Enterprise Integration Architecture
- ERP as source of truth (products, inventory)
- Order routing and fulfillment logic
- Customer data platform integration
- Financial reconciliation
- Middleware selection (Celigo, MuleSoft, Workato)
- Multi-location inventory management

## Technical Skills

### Required
- HTML, CSS, JavaScript
- Liquid (Shopify's template language)
- REST and GraphQL APIs
- Cloud/SaaS fundamentals
- Commerce domain knowledge

### Beneficial
- React (Hydrogen/headless)
- Node.js (app development)
- Data modeling (metafields/metaobjects)
- CI/CD workflows
- Middleware/integration platforms

### Soft Skills
- Executive-level presentation
- Technical storytelling
- Requirements gathering
- Risk assessment
- Cross-functional collaboration

## Key Knowledge Areas

1. **Commerce models**: DTC, B2B, Retail, Omnichannel, International
2. **Platform**: Admin API (GraphQL), Storefront API, Checkout Extensibility
3. **Integration**: ERP, PIM, OMS, CRM, middleware patterns
4. **Plus features**: Checkout extensibility, Functions, B2B, Markets, expansion stores
5. **Competitive**: vs SFCC, Adobe, BigCommerce, commercetools, WooCommerce
6. **Emerging**: Agentic commerce, Sidekick, AI recommendations, Shop App

## Discovery Questions Framework

### Business Understanding
- Current platform and pain points?
- GMV and growth trajectory?
- Commerce models (DTC, B2B, retail, international)?
- Number of SKUs, variants, locations?

### Technical Assessment
- Current tech stack (ERP, PIM, OMS, CRM)?
- Integration requirements and data flows?
- Custom functionality that must be preserved?
- Team's technical capabilities?

### Requirements Mapping
- What's the must-have vs nice-to-have?
- Timeline and budget constraints?
- Stakeholder alignment on approach?
- Success metrics and KPIs?
