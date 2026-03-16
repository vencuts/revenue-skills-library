---
name: merchant-analytics-queries
description: Library of 48 validated BigQuery SQL queries for Shopify merchant analytics. Covers conversion/CRO signals, purchase funnel, bounce rate, traffic/acquisition, app audit, catalog/inventory, Core Web Vitals performance, customer lifecycle, retention cohorts, device breakdown, site search, content audit, and historical trends. Use as a reference when building dashboards, running merchant research, analyzing storefront data, or when asked "what queries are available", "show me the query for [topic]", "how do I analyze [metric]". Standalone reference — works alongside account-research skill.
---

# Merchant Analytics Query Library

48 validated BigQuery queries for Shopify merchant analytics. You diagnose merchant problems by selecting the right query sequence based on symptoms, NOT by running all queries. Start from the problem, not the data.

You are NOT a dashboard builder (use `sales-manager-dashboard`). You are NOT a deal researcher (use `account-research`). You are the query reference that other skills call into, or that users query directly when they know what metric they need.

## Tools

| Tool | Purpose | If Unavailable |
|------|---------|----------------|
| `query_bq` | Execute SQL queries against Shopify BigQuery | Tell user which query to run manually in Data Portal or BigQuery console |
| `read` | Load SQL files from `queries/` directory | Provide inline SQL from this skill's knowledge |

## Workflow: Problem-Driven Query Selection

### Step 0: Identify the Merchant

Every analysis starts with shop_id. If user provides a domain:

```sql
-- queries/shop-identification-by-domain.sql
SELECT shop_id, domain, permanent_domain, country_code, shop_currency
FROM `shopify-dw.accounts_and_administration.shop_profile_current`
WHERE domain = '{DOMAIN}' OR permanent_domain LIKE '%{DOMAIN}%'
LIMIT 5
```

**If multiple results**: Ask user to confirm which shop. Do NOT guess.
**If zero results**: Try `LIKE '%{partial_name}%'` on permanent_domain. If still nothing: "Shop not found — verify the domain spelling."

### Step 1: Route by Problem

```
What is the user trying to understand?
│
├── "Why is conversion low?" / "CRO analysis" / "funnel problems"
│   → Conversion Diagnostic (queries below)
│   ├── Start: cro-signals-cr-with-benchmark-90d.sql (is it actually low vs. industry?)
│   ├── If CR < benchmark: improved-purchase-funnel-analysis.sql (where's the drop-off?)
│   ├── If mobile CR << desktop: cro-signals-devices-form-factor.sql + device-performance-breakdown.sql
│   ├── If bounce rate high: cro-signals-bounce-rate-by-page-type.sql (which pages?)
│   └── If all metrics normal: "Conversion is within benchmarks — problem may be traffic volume, not rate"
│
├── "Traffic is dropping" / "Where are visitors coming from?" / "Acquisition"
│   → Traffic Diagnostic
│   ├── Start: cro-signals-referrers.sql (source breakdown)
│   ├── If organic dropped: traffic-source-crisis-analysis.sql (when did it start?)
│   ├── If paid is dominant: marketing-channel-attribution.sql (ROI by channel)
│   └── If suspicious patterns: perf-suspicious-traffic.sql (bot detection)
│
├── "What apps do they have?" / "App audit"
│   → App Ecosystem
│   ├── Use: app-audit-canonical.sql (complete audit with billing + permissions)
│   ├── Interpret: flag redundant apps (2+ in same category), high-cost apps, unused installs
│   └── Do NOT use merchant-app-audit.sql (original) — use canonical version (corrected joins)
│
├── "Catalog health" / "Product analysis" / "Inventory"
│   → Catalog & Inventory
│   ├── Start: comprehensive-catalog-overview.sql (size, structure)
│   ├── Deep dive: catalog-architecture-analysis.sql (variants, collections, metafields)
│   ├── Inventory: current-inventory-levels.sql + inventory-value-analysis.sql
│   └── Content quality: content-audit-product-richness.sql (descriptions, images per product)
│
├── "Site is slow" / "Performance" / "Core Web Vitals"
│   → Performance Diagnostic
│   ├── Start: perf-rum-aggregation.sql (TTFB, FCP, LCP, INP, CLS by device at p50/p75/p90)
│   ├── Interpret: LCP > 2.5s = poor, INP > 200ms = poor, CLS > 0.1 = poor
│   ├── If mobile-only: cross-ref with cro-signals-devices-form-factor.sql
│   └── If theme-related: content-audit-theme-architecture.sql
│
├── "Retention" / "Customer lifecycle" / "Repeat buyers"
│   → Customer Analysis
│   ├── Start: customer-lifecycle-behavior.sql (new vs returning)
│   ├── Deep dive: retention-cohort-analysis.sql (return frequency patterns)
│   └── Interpret: returning visitor CR should be 2-3x new visitor CR. If not → loyalty/retention problem
│
├── "What queries are available?" / "Show me the library"
│   → Return the query index table (see below)
│
└── Specific metric requested (e.g., "bounce rate", "AOV")
    → Match to specific query file by name/purpose from index below
```

### Step 2: Execute and Interpret

After running a query:
1. **Compare to benchmarks** — raw numbers without context are useless. Industry medians: CR 1.5-3.5%, bounce rate 35-55%, mobile CR ~60% of desktop.
2. **Note sample size** — if < 100 sessions, data is unreliable. Flag it.
3. **Check date range** — queries default to 90 days. For trend analysis, extend to 180-365 days.
4. **Cross-reference** — never conclude from one query. E.g., low CR + high bounce → landing page problem, not checkout problem.

## Output Format

### Required
- **Finding**: 2-3 sentences describing what the data shows
- **Evidence**: Specific numbers from query results with comparison to benchmarks
- **Recommendation**: What the merchant should investigate or change

### Conditional
- **Trend Analysis** (when comparing time periods): Include period-over-period change with direction
- **Device Breakdown** (when mobile/desktop diverge): Split findings by device
- **Query Reference** (when user wants to re-run): Include the exact SQL with parameters filled in

### Never Include
- Raw query output without interpretation
- Recommendations not supported by query data
- Generic advice ("improve your conversion rate") without specific diagnostic evidence

## Query Index (48 queries)

### Shop Identification
| File | Purpose |
|---|---|
| `shop-identification-by-domain.sql` | Find shop_id from domain |

### Conversion & CRO (9 queries)
| File | Purpose |
|---|---|
| `cro-signals-cr-with-benchmark-90d.sql` | CR with industry benchmarks |
| `cro-signals-purchase-funnel.sql` | Raw funnel by device/landing page |
| `cro-signals-aov-cr-benchmarking.sql` | AOV and CR benchmarking |
| `cro-signals-orders-trend.sql` | Order volume trends |
| `conversion-benchmarking-90d.sql` | Conversion benchmarking (90d) |
| `detailed-conversion-aov-benchmarking.sql` | Conversion + AOV combined |
| `improved-purchase-funnel-analysis.sql` | Enhanced funnel with drop-off |
| `purchase-funnel-analysis.sql` | Purchase funnel analysis |
| `comprehensive-metrics-diagnostic.sql` | Multi-metric diagnostic |

### Traffic & Acquisition (4 queries)
| File | Purpose |
|---|---|
| `cro-signals-referrers.sql` | Traffic source breakdown |
| `marketing-channel-attribution.sql` | Channel attribution |
| `traffic-source-crisis-analysis.sql` | Diagnose traffic drops |
| `landing-page-analysis.sql` | Landing page performance |

### Devices (5 queries)
| File | Purpose |
|---|---|
| `cro-signals-devices-form-factor.sql` | Mobile/desktop/tablet split |
| `cro-signals-devices-os.sql` | OS breakdown |
| `cro-signals-devices-browsers.sql` | Browser distribution |
| `cro-signals-devices-raw.sql` | Raw device data |
| `device-performance-breakdown.sql` | Performance by device |

### Behavior (5 queries)
| File | Purpose |
|---|---|
| `cro-signals-bounce-rate-by-page-type.sql` | Bounce by page type |
| `bounce-rate-benchmarking.sql` | Bounce vs benchmarks |
| `cro-signals-cr-over-time.sql` | CR trends |
| `session-engagement-analysis.sql` | Session depth patterns |
| `cro-signals-searches.sql` | Site search terms |

### Catalog & Inventory (6 queries)
| File | Purpose |
|---|---|
| `product-catalog-analysis.sql` | Catalog structure |
| `comprehensive-catalog-analysis.sql` | Deep catalog analysis |
| `comprehensive-catalog-overview.sql` | Catalog overview |
| `catalog-architecture-analysis.sql` | Architecture patterns |
| `current-inventory-levels.sql` | Current inventory |
| `inventory-value-analysis.sql` | Inventory value |

### Apps (4 queries)
| File | Purpose |
|---|---|
| `app-audit-canonical.sql` | ✅ Canonical app audit (use this one) |
| `merchant-app-audit.sql` | ⚠️ Original (deprecated) |
| `merchant-app-audit-corrected.sql` | Corrected joins |
| `merchant-app-audit-optimized.sql` | Optimized version |

### Performance (2 queries)
| File | Purpose |
|---|---|
| `perf-rum-aggregation.sql` | Core Web Vitals (TTFB/FCP/LCP/INP/CLS) |
| `perf-suspicious-traffic.sql` | Bot/suspicious traffic detection |

### Customer Lifecycle (2 queries) + Content (3 queries) + Trends (3 queries) + Salesloft (1 query)
Located in `queries/` — use `read queries/{filename}.sql` to load.

## Key Tables

| Table | Key Fields |
|---|---|
| `shopify-dw.accounts_and_administration.shop_profile_current` | `shop_id`, `domain`, `permanent_domain` |
| `shopify-dw.buyer_activity.storefront_sessions_summary_v3` | `shop_id`, `session_id`, `has_checkout_completed` |
| `sdp-for-analysts-platform.growth_services_prod.purchase_funnel_new` | `shop_id`, `device`, `landing_page_type` |
| `shopify-dw.intermediate.app_install_permission_state_events_v1` | `api_client_id`, `shop_id` |

## Error Handling

| Scenario | Action |
|----------|--------|
| Query returns 0 rows | Check: (1) Is shop_id correct? (2) Is date range appropriate? (3) Does table exist? Report which check failed. |
| Permission denied on table | Tell user: "Access denied to {table}. This likely requires data-portal-mcp or BigQuery console with appropriate project permissions." |
| Session count < 100 | Flag: "Low session count ({N}) — data may not be statistically reliable. Extend date range or note as directional only." |
| Multiple queries contradict each other | Report both findings: "CR benchmark says 2.1% (above median), but funnel analysis shows 45% cart abandonment — investigate checkout friction specifically." |
| User asks for a metric not in the library | Say which queries are closest. Do NOT improvise SQL — untested queries against production tables risk wrong conclusions. |
| Query file not found in queries/ directory | Provide the inline SQL from this skill's knowledge if available. Otherwise: "Query file missing — check backups or rebuild from table documentation." |
