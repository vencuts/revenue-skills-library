# Platform & APIs Reference

## GraphQL Admin API (Primary)

- **Endpoint**: `POST https://{store}.myshopify.com/admin/api/{version}/graphql.json`
- New public apps: GraphQL only as of April 2025
- Quarterly versioning: YYYY-MM (e.g., 2025-01, 2025-04, 2025-07, 2025-10, 2026-01)
- 12-month support per version; 9-month deprecation warning
- Fall-forward behavior: expired versions resolve to oldest supported version

### Rate Limits (Cost-Based Leaky Bucket)

| Plan | Restore Rate | Bucket Size |
|------|-------------|-------------|
| Standard (Basic, Grow) | 100 pts/sec | ~1,000 pts |
| Advanced | 200 pts/sec | ~2,000 pts |
| Plus | 1,000 pts/sec | ~10,000 pts |
| Enterprise (CCS) | 2,000 pts/sec | ~20,000 pts |

- Max single query cost: 1,000 points
- Cost: 1 point per object fetched; 10 points per mutation
- Actual vs requested cost: difference refunded
- Scope: per app, per store (apps don't compete)
- Nested connections multiply costs (e.g., 10 products × 5 variants = 50 points)

### Query Optimization
- Use smallest `first`/`last` values needed
- Max `first`/`last`: 250
- Max pagination depth: 25,000 objects
- Cursor-based pagination with opaque cursor strings
- Request only needed fields (GraphQL advantage)

## REST Admin API (Legacy)

| Plan | Bucket | Leak Rate |
|------|--------|-----------|
| Standard (Basic, Grow) | 40 requests | 2 req/sec |
| Advanced | 40 requests | 4 req/sec |
| Plus | 80 requests | 20 req/sec |

- Deprecated for new public apps (October 2024)
- Returns HTTP 429 + `Retry-After` header when throttled
- Monitoring: `X-Shopify-Shop-Api-Call-Limit` header

## Storefront API

- **No rate limits** on request count (designed for flash sales)
- Checkout creation throttled per minute (returns `200 Throttled`)
- GraphQL-only (no REST equivalent)
- Two token types: public (client-safe) and private (server-only)
- Supports: products, collections, cart, checkout, customer accounts, metafields
- `@inContext` directive for international pricing (country, language)
- Predictive search endpoint for autocomplete

## Customer Account API

| Plan | Rate Limit |
|------|-----------|
| Standard | 100 pts/sec |
| Advanced | 200 pts/sec |
| Plus | 200 pts/sec |
| Enterprise | 400 pts/sec |

- OAuth 2.0 with PKCE for secure browser auth
- Replaces legacy Multipass for most headless use cases
- Multipass still available for SSO (Plus only)

## Bulk Operations

- Up to **5 concurrent** bulk operations (increased from 1 in 2025)
- Output: JSONL format
- No rate limits or max cost limits
- Flow: `bulkOperationRunQuery` → poll `currentBulkOperation` → download JSONL
- Webhook: `BULK_OPERATIONS_FINISH` for async notification

## Webhooks

- 50+ event topics (orders, products, customers, inventory, etc.)
- **5-second timeout** — connection + response must complete
- **8 retries** over 4-hour window with exponential backoff
- After 8 failures: webhook subscription **removed**
- Delivery: HTTPS endpoint, Amazon EventBridge, Google Pub/Sub
- Payload versioned to API version at registration
- Retries deliver original payload; use `X-Shopify-Triggered-At` to detect staleness

### Mandatory Compliance Webhooks (GDPR/CPRA)
| Topic | Trigger | Deadline |
|-------|---------|----------|
| `customers/data_request` | Customer requests data | 30 days |
| `customers/redact` | Customer requests deletion | 30 days |
| `shop/redact` | 48h after app uninstalled | 30 days |

- Required for all public Shopify App Store apps
- Apps missing these are rejected from the App Store

## API Versioning

- Quarterly releases: January, April, July, October
- Breaking changes only at version boundaries
- Additive changes (new fields/types) can happen within a version
- `release-candidate`: preview next stable (testing only)
- `unstable`: bleeding-edge (development only)
- Max array input size: 250 items

## Key Numbers

| Metric | Value |
|--------|-------|
| API versions supported simultaneously | ~5 (12-month window) |
| Max variants per product (API) | 2,048 |
| Max `first`/`last` pagination | 250 |
| Max pagination depth | 25,000 objects |
| Bulk ops concurrent | 5 |
| Webhook timeout | 5 seconds |
| Webhook retries | 8 over 4 hours |
| Storefront API rate limit | No limit (burst-capable) |
