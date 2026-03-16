# Plans & Pricing Reference

## Plan Tiers

| Plan | Monthly | Annual | Target |
|------|---------|--------|--------|
| Starter | $5 | N/A | Social selling, link-in-bio |
| Basic | $39 | $29 | New businesses, low volume |
| Grow (formerly "Shopify") | $105 | $79 | Growing businesses |
| Advanced | $399 | $299 | Scaling, multi-market |
| Plus | From $2,300 | Custom | Enterprise, high-GMV |

## Plus Pricing Formula

- **Base**: $2,300/mo for merchants under $800K/mo GMV
- **Variable**: 0.25% of monthly GMV above $800K threshold
- **Contract**: typically 1-year or 3-year commitments

### Calculation Examples
| Monthly GMV | Calculation | Monthly Cost |
|-------------|------------|-------------|
| $500K | Base only | $2,300 |
| $1M | $2,300 + 0.25% × $200K | $2,800 |
| $2M | $2,300 + 0.25% × $1.2M | $5,300 |
| $3M | $2,300 + 0.25% × $2.2M | $7,800 |
| $5M | $2,300 + 0.25% × $4.2M | $12,800 |
| $10M | $2,300 + 0.25% × $9.2M | $25,300 |

## Credit Card Rates (US Domestic Online)

| Plan | Online | In-Person |
|------|--------|-----------|
| Starter | 5% + 30¢ | N/A |
| Basic | 2.9% + 30¢ | 2.6% + 10¢ |
| Grow | 2.7% + 30¢ | 2.5% + 10¢ |
| Advanced | 2.5% + 30¢ | 2.4% + 10¢ |
| Plus | 2.15% + 30¢ | 2.4% (negotiable) |

- International/AMEX: typically +1% surcharge
- Currency conversion fee: 1.5% (US), up to 2.0% (international)

## Third-Party Transaction Fees

| Plan | Fee |
|------|-----|
| Basic | 2.0% |
| Grow | 1.0% |
| Advanced | 0.6% |
| Plus | 0.2% |

**Waived entirely when using Shopify Payments** — key selling point.

## Feature Gates by Plan

| Feature | Basic | Grow | Advanced | Plus |
|---------|-------|------|----------|------|
| Staff accounts | 2 | 5 | 15 | Unlimited |
| Inventory locations | 10 | 10 | 10 | 200 |
| Markets | 3 | 3 | 3 + Markets | 50 + Managed |
| B2B (native) | No | No | No | Yes |
| Checkout extensibility (full) | No | No | No | Yes |
| Expansion stores | No | No | No | 9 included |
| Organization admin | No | No | No | Yes |
| LaunchPad | No | No | No | Yes |
| POS Pro included locations | 0 | 0 | 0 | 20 |
| Flow | Yes | Yes | Yes | Yes |
| Flow HTTP action | No | Yes | Yes | Yes |
| Functions (all types) | Some | Some | Some | All |

## API Rate Limits by Plan

| Plan | GraphQL Admin | REST Admin | Storefront |
|------|--------------|-----------|------------|
| Basic/Grow | 100 pts/sec | 2 req/sec | No limit |
| Advanced | 200 pts/sec | 4 req/sec | No limit |
| Plus | 1,000 pts/sec | 20 req/sec | No limit |

## Shopify Payments

- Powered by Stripe under the hood
- Available in **39 countries** (as of March 2026)
- Using Shopify Payments eliminates 3P transaction fees
- PCI DSS Level 1 compliant
- Fraud analysis on every order (AVS, CVV, IP, velocity)
- Shopify Protect: free fraud protection on eligible Shop Pay orders

## Development Stores

- **Free** for Shopify Partners — unlimited number
- Full feature access including Plus features
- Cannot process real transactions
- Transfer to merchant triggers plan selection

## Common Upgrade Triggers

| Trigger | Recommended |
|---------|------------|
| Need >2 staff accounts | Grow+ |
| High tx volume (fee savings) | Advanced or Plus |
| B2B / wholesale | Plus |
| Multiple stores | Plus |
| Advanced checkout customization | Plus |
| 50+ international markets | Plus |
| Organization admin | Plus |
