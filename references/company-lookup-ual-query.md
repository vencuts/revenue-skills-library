# Company Lookup / Dupe Checker — UAL Query Reference

Source: https://company-lookup.quick.shopify.io/
Extracted: 2026-03-12

## What It Does
Searches the Unified Account List (UAL) and Salesforce Website records to find existing account matches.
Used for: dupe checking before opp creation, territory/ownership lookup, account identification.

## Tables

| Table | What | Use For |
|-------|------|---------|
| `sdp-prd-commercial.mart.unified_account_list` | **Master account dedup table** — combines SF, 3P, 1P data | Account ownership, territory, existing account check |
| `shopify-dw.raw_salesforce_banff.account` | SF accounts (raw) | Account name, territory, owner |
| `shopify-dw.raw_salesforce_banff.user` | SF users (raw) | Owner name lookup |
| `shopify-dw.raw_salesforce_banff.website__c` | SF website records | Domain → Account mapping, Shop ID lookup |

## UAL Key Fields (unified_account_list)

| Field | What |
|-------|------|
| `account_name` / `account_name_sf` / `account_name_3p` / `account_name_1p` | Company name from 4 sources |
| `account_owner` / `sales_rep` / `d2c_sales_rep` | Owner from 3 sources |
| `domain` / `domain_sf` / `domain_3p` / `domain_1p` | Website domain from 4 sources |
| `territory_name` | Sales territory |
| `account_id` | SF Account ID |

## Matching Logic

### Search Parameters
- `@search_name` — company name (lowercased)
- `@search_domain` — full domain (e.g., `example.com`)
- `@search_root` — root domain (e.g., `example` from `shop.example.com`)
- `@search_shop_id` — Shopify shop ID

### Fuzzy Scoring (domain)
| Score | Match Type |
|-------|-----------|
| 100 | Exact domain match |
| 85 | Root domain match (different subdomain) |
| 80 | Subdomain of search domain |

### Fuzzy Scoring (name)
| Score | Match Type |
|-------|-----------|
| 100 | Exact name match |
| 85 | Starts with search name |
| 70 | Contains search name |

### Domain Normalization
```sql
LOWER(REGEXP_REPLACE(IFNULL(domain, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3'))
```
Strips protocol, www, path, port — leaves just the normalized domain.

### Dedup Logic
1. UNION UAL + SF results (only rows with score > 0)
2. Dedupe by (company_name, owner) — prefer UAL over SF, then highest score
3. Return top 75

## Skills This Powers

| Skill | How to Use |
|-------|-----------|
| `prospect-researcher` | **Pre-check**: Before running external research, check UAL to see if account already exists and who owns it |
| `opp-compliance-checker` | **Territory validation**: Verify the opp's account is in the right territory for the rep |
| `account-research` | **Account identification**: Given a domain or shop ID, resolve to SF account + owner + territory |
| `meeting-prep` | **Context enrichment**: Look up account ownership and territory before calls |
| `deal-followup` | **Account context**: Confirm account details when writing follow-up emails |
| `opp-hygiene` | **Dupe detection**: Flag potential duplicate opps for the same account |
| `qualification-trainer` | **Realistic scenarios**: Use real account data to create training scenarios |

## Full SQL Query

```sql
WITH
  -- Source 1: Unified Account List
  ual_base AS (
    SELECT
      COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) AS company_name,
      COALESCE(account_owner, sales_rep, d2c_sales_rep) AS owner,
      territory_name,
      COALESCE(domain, domain_sf, domain_3p, domain_1p) AS best_domain,
      account_id AS sf_account_id,
      LOWER(REGEXP_REPLACE(IFNULL(domain,    ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd,
      LOWER(REGEXP_REPLACE(IFNULL(domain_sf, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd_sf,
      LOWER(REGEXP_REPLACE(IFNULL(domain_3p, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd_3p,
      LOWER(REGEXP_REPLACE(IFNULL(domain_1p, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd_1p,
      LOWER(IFNULL(account_name,    '')) AS ln,
      LOWER(IFNULL(account_name_sf, '')) AS ln_sf,
      LOWER(IFNULL(account_name_3p, '')) AS ln_3p,
      LOWER(IFNULL(account_name_1p, '')) AS ln_1p,
      'UAL' AS data_source
    FROM `sdp-prd-commercial.mart.unified_account_list`
    WHERE COALESCE(account_name, account_name_sf, account_name_3p, account_name_1p) IS NOT NULL
  ),

  ual_scored AS (
    SELECT
      company_name, owner, territory_name, best_domain, data_source, sf_account_id,
      LOWER(REGEXP_REPLACE(IFNULL(best_domain, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd_dedup,
      CASE
        WHEN @search_domain != '' AND (nd = @search_domain OR nd_sf = @search_domain OR nd_3p = @search_domain OR nd_1p = @search_domain) THEN 100
        WHEN @search_root != '' AND @search_root != @search_domain AND (nd = @search_root OR nd_sf = @search_root OR nd_3p = @search_root OR nd_1p = @search_root) THEN 85
        WHEN @search_domain != '' AND (ENDS_WITH(nd, CONCAT('.', @search_domain)) OR ENDS_WITH(nd_sf, CONCAT('.', @search_domain)) OR ENDS_WITH(nd_3p, CONCAT('.', @search_domain)) OR ENDS_WITH(nd_1p, CONCAT('.', @search_domain))) THEN 80
        ELSE 0
      END AS domain_score,
      CASE
        WHEN @search_name != '' AND (ln = @search_name OR ln_sf = @search_name OR ln_3p = @search_name OR ln_1p = @search_name) THEN 100
        WHEN @search_name != '' AND (STARTS_WITH(ln, @search_name) OR STARTS_WITH(ln_sf, @search_name) OR STARTS_WITH(ln_3p, @search_name) OR STARTS_WITH(ln_1p, @search_name)) THEN 85
        WHEN @search_name != '' AND (CONTAINS_SUBSTR(ln, @search_name) OR CONTAINS_SUBSTR(ln_sf, @search_name) OR CONTAINS_SUBSTR(ln_3p, @search_name) OR CONTAINS_SUBSTR(ln_1p, @search_name)) THEN 70
        ELSE 0
      END AS name_score,
      0 AS shop_id_score
    FROM ual_base
  ),

  -- Source 2: Salesforce website__c
  sf_accounts_dedup AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY Id ORDER BY _sdc_extracted_at DESC) AS rn
    FROM `shopify-dw.raw_salesforce_banff.account`
    WHERE IsDeleted = FALSE
  ),

  sf_users_dedup AS (
    SELECT Id, Name, ROW_NUMBER() OVER (PARTITION BY Id ORDER BY _sdc_extracted_at DESC) AS rn
    FROM `shopify-dw.raw_salesforce_banff.user`
  ),

  sf_base AS (
    SELECT
      a.Name AS company_name, u.Name AS owner, a.Territory_Name__c AS territory_name,
      w.Domain__c AS best_domain, a.Id AS sf_account_id, CAST(w.Shop_Id__c AS STRING) AS shop_id,
      LOWER(REGEXP_REPLACE(IFNULL(w.Domain__c, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd,
      LOWER(IFNULL(a.Name, '')) AS ln,
      'SF Website' AS data_source
    FROM `shopify-dw.raw_salesforce_banff.website__c` AS w
    INNER JOIN sf_accounts_dedup AS a ON w.Account__c = a.Id AND a.rn = 1
    LEFT JOIN sf_users_dedup AS u ON a.OwnerId = u.Id AND u.rn = 1
    WHERE w.IsDeleted IS FALSE AND w._sdc_batched_at >= '2020-01-01' AND a.Name IS NOT NULL
  ),

  sf_scored AS (
    SELECT
      company_name, owner, territory_name, best_domain, data_source, sf_account_id,
      LOWER(REGEXP_REPLACE(IFNULL(best_domain, ''), r'^(https?://)?(www\.)?([^/?#:]+).*', r'\3')) AS nd_dedup,
      CASE
        WHEN @search_domain != '' AND nd = @search_domain THEN 100
        WHEN @search_root != '' AND @search_root != @search_domain AND nd = @search_root THEN 85
        WHEN @search_domain != '' AND ENDS_WITH(nd, CONCAT('.', @search_domain)) THEN 80
        ELSE 0
      END AS domain_score,
      CASE
        WHEN @search_name != '' AND ln = @search_name THEN 100
        WHEN @search_name != '' AND STARTS_WITH(ln, @search_name) THEN 85
        WHEN @search_name != '' AND CONTAINS_SUBSTR(ln, @search_name) THEN 70
        ELSE 0
      END AS name_score,
      CASE
        WHEN @search_shop_id != '' AND shop_id = @search_shop_id THEN 100
        ELSE 0
      END AS shop_id_score
    FROM sf_base
  ),

  combined AS (
    SELECT * FROM ual_scored WHERE domain_score > 0 OR name_score > 0
    UNION ALL
    SELECT * FROM sf_scored WHERE domain_score > 0 OR name_score > 0 OR shop_id_score > 0
  ),

  deduped AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY LOWER(company_name), LOWER(COALESCE(owner, ''))
        ORDER BY
          CASE data_source WHEN 'UAL' THEN 1 ELSE 2 END,
          GREATEST(domain_score, name_score) DESC
      ) AS rn
    FROM combined
  )

SELECT company_name, owner, territory_name, best_domain, data_source, sf_account_id
FROM deduped WHERE rn = 1
ORDER BY GREATEST(domain_score, name_score, shop_id_score) DESC, company_name
LIMIT 75
```
