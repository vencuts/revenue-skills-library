# Data Quality BQ Tables Reference

Source: Molly Parapini's 5 RevOps data quality Quick sites (March 2026)
Slack: #rev-ops, 2026-03-13

## Core Tables

### UAL (Unified Account List)
- `sdp-prd-commercial.mart.unified_account_list` — THE canonical account list
  - Fields: account_id, account_name, region, country, industry, service_model, estimated_total_annual_revenue, estimated_online_annual_revenue, estimated_offline_annual_revenue, d2c_fit_score, b2b_fit_score, retail_fit_score, account_owner_email, merchant_success_manager_id, location_count_3p, company_description_3p, tags

### Salesforce Raw
- `shopify-dw.raw_salesforce_banff.account` — SF account records (for dupe detection)
- `shopify-dw.raw_salesforce_banff.contact` — SF contact records (for contact dupe detection)

## UAL Data Quality Check Tables (20 tables)
Pattern: `shopify-dw.scratch.UAL_data_quality_check_SP_null_{field_name}`

Each table contains UAL records where that specific field is null:
- UUID_values, account_id, account_name, account_owner
- b2b_fit_score, d2c_fit_score, retail_fit_score
- company_description_3p, country, estimated_offline_annual_revenue
- estimated_online_annual_revenue, estimated_total_annual_revenue
- industry, location_count_3p, merchant_success_manager_id
- region, service_model, tags

## Territory Inspector Tables (16 tables)
Pattern: `shopify-dw.scratch.TI_{check_name}`

- `TI_employees_initial_extract` — all employees with territory assignments
- `TI_employees_with_more_than_one_territory` — multi-territory reps
- `TI_segments_with_no_territories` — segments with zero territory coverage
- `TI_subregions_with_no_territories` — subregions with zero territory coverage
- `TI_summary_territory_account_relationships` — territory-to-account mapping
- `TI_summary_territory_employee_relationships` — territory-to-rep mapping
- `TI_territories_accounts_relationships_initial_extract` — raw account assignments
- `TI_territories_employees_relationships_initial_extract` — raw employee assignments
- `TI_territories_initial_extract` — all territories
- `TI_territories_with_inactive_users` — ⚠️ territories owned by inactive reps
- `TI_territories_with_inconsistent_lobs` — LOB mismatch between territory and accounts
- `TI_territories_with_inconsistent_names` — naming convention violations
- `TI_territories_with_more_than_one_user_with_the_same_roleinterritory` — duplicate role assignments
- `TI_territories_with_no_accounts` — empty territories
- `TI_territories_with_no_accounts_and_no_employees` — ghost territories
- `TI_territories_with_no_employees` — unowned territories

## Worker Attributes Table
- `shopify-dw.scratch.worker_current_null_sales_attributes_where_sales_team_not_null`
  - Workers on a sales team but missing: region, segment, subregion, sales_motion, LOB, vertical

## Quick Site URLs (for human reference)
- https://salesforceaccountdupecheck.quick.shopify.io/
- https://salesforcecontactdupecheck.quick.shopify.io/
- https://territoryinspector.quick.shopify.io/
- https://ualinspector.quick.shopify.io/
- https://workersalesattributecheck.quick.shopify.io/
