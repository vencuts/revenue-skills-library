# Integration Patterns Reference

## Integration Architecture Types

| Pattern | When to Use | Examples |
|---------|-------------|---------|
| **Native** | Shopify's own features | Payments, Shipping, Tax, Markets |
| **App-based** | Standard integrations | Install from App Store or build custom |
| **Middleware / iPaaS** | Complex multi-system | Celigo, MuleSoft, Workato, Boomi |
| **Direct API** | Unique business logic | Custom code via GraphQL Admin API |

## Enterprise Integration Scenarios

### ERP (NetSuite, SAP, Microsoft Dynamics)

| Data Flow | Direction | Notes |
|-----------|-----------|-------|
| Products & pricing | ERP → Shopify | ERP typically source of truth |
| Inventory | ERP → Shopify | Real-time or near-real-time |
| Orders | Shopify → ERP | Including refunds, returns |
| Customers | Bidirectional | B2B accounts especially |
| Financial | Shopify → ERP | Revenue reconciliation, tax reporting |

**Key challenge**: Shopify is often not the system of record for enterprise. Design integration with clear source-of-truth per data type.

### PIM (Akeneo, Salsify, inRiver)

- PIM as product data source of truth
- Sync: PIM → Shopify (products, variants, metafields, images)
- Map PIM taxonomy to Shopify product taxonomy
- Handle complex product relationships and attributes
- Use metafields for rich product data beyond standard fields

### OMS / Fulfillment (ShipStation, ShipBob, custom WMS)

| Data Flow | Direction |
|-----------|-----------|
| Orders | Shopify → OMS/WMS |
| Fulfillment + tracking | OMS → Shopify |
| Inventory updates | WMS → Shopify |
| Returns | Bidirectional |

- Multi-location fulfillment routing
- Ship-from-store scenarios
- Use fulfillment orders API for complex routing

### CRM (Salesforce, HubSpot)

- Customer data sync: Shopify → CRM
- Order history and lifetime value
- Marketing automation triggers
- B2B account management sync
- Typically via app or middleware

### Marketing (Klaviyo, Attentive, Mailchimp)

- Customer segments and event data
- Abandoned cart flows
- Post-purchase flows
- Product recommendations
- SMS and email marketing
- Most have native Shopify apps

## Key Technology Partners

| Category | Partners |
|----------|---------|
| ERP | NetSuite, SAP, Microsoft Dynamics |
| PIM | Akeneo, Salsify |
| Search | Algolia, Searchspring |
| Loyalty | Yotpo, Smile.io, LoyaltyLion |
| Reviews | Yotpo, Judge.me, Stamped |
| Subscriptions | Recharge, Bold Subscriptions |
| Email/SMS | Klaviyo, Attentive, Omnisend |
| Returns | Loop, Returnly, AfterShip |
| Bundling | Shopify Bundles (native), Rebuy |
| Personalization | Nosto, Dynamic Yield |
| Tax | Avalara |
| Fulfillment | ShipBob, ShipStation, Flexport |

## Integration Best Practices

### Data Flow Design
- Define clear source of truth per data type
- Use webhooks for real-time event triggers (50+ topics)
- Use bulk operations for large data syncs (up to 5 concurrent)
- Queue webhook payloads for background processing (5-second timeout)

### API Strategy
- GraphQL Admin API for all new integrations
- Storefront API for buyer-facing experiences
- Bulk operations for catalog sync (no rate limits)
- Build reconciliation jobs for missed webhooks

### Middleware Selection Criteria
- Volume of data transformations needed
- Number of systems to connect
- Team's technical capability
- Budget for iPaaS licensing
- Need for pre-built connectors vs custom

## Partner Ecosystem

### Agency / SI Partners
- **Shopify Plus Partners**: certified agencies
- **Solutions Partners**: implementation, design, development
- **Technology Partners**: apps and integrations

### App Partner Economics
- Revenue share: **0% on first $1M earned** (since 2021)
- Collaborator accounts free (don't count toward staff limits)

### Development Stores
- Free for partners, unlimited number
- Full feature access (including Plus features)
- Cannot process real transactions
- Perfect for POCs and demos
