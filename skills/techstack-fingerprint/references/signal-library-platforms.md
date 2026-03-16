# Signal Library — Platforms & Infrastructure

---

## Commerce Platforms

| Signal | Platform |
|--------|---------|
| `server: sfdcedge`, `x-sfdc-*`, `CookieConsentPolicy` cookie | Salesforce Commerce Cloud (SFCC / Demandware) |
| `x-sap-pad:`, `*.ondemand.com` in CSP frame-ancestors | SAP Commerce Cloud (Hybris) on SAP BTP |
| `x-hybris-*` headers | SAP Commerce Cloud (Hybris) — self-hosted |
| `wp-content/`, `wp-includes/`, `?wc-ajax=` | WooCommerce (WordPress) |
| `Magento_Ui`, `mage/`, `X-Magento-*`, `form_key` cookie | Adobe Commerce / Magento |
| `_next/`, `__NEXT_DATA__` in HTML | Next.js (may be headless Shopify or other) |
| `myshopify.com` in scripts, `Shopify.theme`, `cdn.shopify.com` | Shopify |
| `bigcommerce.com` in scripts, `bc-sf-filter` | BigCommerce |
| `commercetools.com`, `mc.commercetools.com` | commercetools |
| `elastic.co/guide/en/app-search` | Elastic / EPCC |
| `spreecommerce.org` | Spree Commerce (Ruby) |
| `snipcart.com` | Snipcart (headless cart) |
| `fastspring.com` | FastSpring |
| `wixstores.com`, `wix.com` in scripts | Wix eCommerce |
| `squarespace.com` in scripts | Squarespace |
| `prestashop.com`, `PrestaShop` meta generator | PrestaShop |
| `opencart.com`, `catalog/view/` in paths | OpenCart |
| `osCommerce` meta generator | osCommerce |
| `server: Resin`, `vtexcommerce`, `VTEX_SEGMENT` cookie | VTEX |
| `nopCommerce` meta generator | nopCommerce (.NET) |

---

## CMS / DXP

| Signal | Platform |
|--------|---------|
| `wp-content/`, `<meta name="generator" content="WordPress` | WordPress |
| `/etc.clientlibs/`, `<cq:` tags, `gwx` or `aem` in JS paths | Adobe Experience Manager (AEM) |
| `contentful.com` in scripts or API calls | Contentful |
| `cdn.sanity.io` | Sanity |
| `storyblok.com` | Storyblok |
| `prismic.io` | Prismic |
| `drupal.org` generator, `Drupal.settings` in JS | Drupal |
| `sitecore.net`, `Sitecore.` in JS | Sitecore |
| `bloomreach.com`, `brXM` | Bloomreach Content (CMS) |
| `kentico.com`, `KenticoCloud` | Kentico / Xperience |
| `umbraco.com` generator | Umbraco |
| `squiz.net` | Squiz Matrix |
| `episerver.com`, `Episerver` | Optimizely (Episerver) CMS |
| `sitefinity.com` | Sitefinity |
| `acquia.com` in CDN URLs | Acquia (Drupal cloud) |
| `rum.hlx.page` | Adobe Helix / Edge Delivery Services (AEM migration signal) |
| `scene7.com` | Adobe Dynamic Media / Scene7 (DAM + image CDN) |

---

## Search & Discovery

| Signal | Platform |
|--------|---------|
| `algolia.net`, `algoliaapis.com`, `algolia` in JS | Algolia |
| `constructor.io` | Constructor.io |
| `searchspring.net` | SearchSpring |
| `hawksearch.com` | Hawksearch |
| `klevu.com` | Klevu |
| `findify.io` | Findify |
| `bloomreach.com/api` (search endpoint) | Bloomreach Search |
| `coveo.com`, `coveoua.js` | Coveo |
| `elasticsearch` in bundle strings | Elasticsearch / OpenSearch |
| `typesense.org` | Typesense |
| `yotpo.com` | Yotpo (reviews + search) |
| `powerreviews.com` | PowerReviews |
| `bazaarvoice.com` | Bazaarvoice |
| `trustpilot.com` | Trustpilot |
| `reviews.io` | REVIEWS.io |
| `stamped.io` | Stamped |
| `okendo.io` | Okendo |
| `loox.io` | Loox |
| `judgeme.com` | Judge.me |

---

## ERP

| Signal | Platform |
|--------|---------|
| `x-sap-pad:`, `*.ondemand.com` in CSP | SAP (BTP-hosted) |
| `sap-client=` cookie | SAP (direct) |
| `netsuite.com`, `NetSuite` in scripts | Oracle NetSuite |
| `oracleerp` in bundle strings | Oracle ERP Cloud |
| `microsoftdynamics.com`, `crm.dynamics.com` | Microsoft Dynamics |
| `odoo.com` | Odoo |
| `epicor.com` | Epicor |
| `infor.com` | Infor CloudSuite |
| `sage.com` | Sage |
| `acumatica.com` | Acumatica |
| `fishbowl` in JS | Fishbowl |
| `brightpearl.com` | Brightpearl (retail OMS/ERP) |

---

## OMS / WMS / Fulfillment

| Signal | Platform |
|--------|---------|
| `fluentcommerce.com` | Fluent Commerce |
| `deposco.com` | Deposco |
| `manhattan` in JS bundles | Manhattan Associates |
| `nulogy.com` | Nulogy |
| `shipbob.com` | ShipBob |
| `shipstation.com` | ShipStation |
| `easypost.com` | EasyPost |
| `shippo.com` | Shippo |
| `aftership.com` | AfterShip |
| `narvar.com` | Narvar (post-purchase) |
| `returnly.com` | Returnly |
| `loop-returns.com` | Loop Returns |
| `returnscenter.com` | Returns Center (re:do) |
| `whiplash.com` | Whiplash |
| `deliverr.com` | Deliverr (Shopify Logistics) |
| `ware2go.com` | Ware2Go (UPS) |
| `radial.com` | Radial |
| `hunterscloud.jp` | Hunters Cloud (JP fulfillment) |
| `ship.ecat.jp` | ecat (JP delivery management) |

---

## PIM

| Signal | Platform |
|--------|---------|
| `akeneo.com` | Akeneo |
| `salsify.com` | Salsify |
| `inriver.com` | inRiver |
| `syndigo.com` | Syndigo |
| `stibo.com` | Stibo STEP |
| `riversand.com` | Riversand (Informatica) |
| `contentserv.com` | Contentserv |
| `plytix.com` | Plytix |

---

## DAM / Media

| Signal | Platform |
|--------|---------|
| `scene7.com` | Adobe Dynamic Media / Scene7 |
| `cloudinary.com` | Cloudinary |
| `imgix.com` | imgix |
| `twicpics.com` | TwicPics |
| `imagekit.io` | ImageKit |
| `bynder.com` | Bynder |
| `widen.net` | Widen (Acquia DAM) |
| `amplience.com` | Amplience |
| `canto.com` | Canto |
| `brandfolder.com` | Brandfolder |

---

## Infrastructure / CDN

| Signal | Inference |
|--------|----------|
| `cf-ray` header | Cloudflare |
| `__cf_bm` cookie | Cloudflare Bot Management |
| `fastly.net` in headers / scripts | Fastly CDN |
| `akamaihd.net`, `akamai-request-bc` header | Akamai CDN |
| `_abck`, `bm_sz` cookies | Akamai Bot Manager |
| `x-amz-cf-*`, `cloudfront.net` | AWS CloudFront |
| `x-amz-request-id`, `x-amz-server-side-encryption` | Amazon S3 |
| `AWSALB` cookie | AWS ALB |
| `x-served-by: cache-` (Varnish format) | Fastly / Varnish |
| `x-cache: Hit from cloudfront` | AWS CloudFront |
| `server: openresty` | OpenResty (Nginx + Lua) |
| `server: sfdcedge` | Salesforce edge |
| `server: Apache` | Apache httpd |
| `x-powered-by: PHP` | PHP runtime |
| `x-powered-by: ASP.NET` | .NET / IIS |
| `JSESSIONID` cookie | Java app server (Tomcat / Spring) |
| `PHPSESSID` cookie | PHP session |
| `x-sap-pad:` header | SAP BTP |
| `x-vercel-id` header | Vercel |
| `fly-request-id` | Fly.io |
| `x-netlify-*` | Netlify |
| `x-github-request-id` | GitHub Pages |
| `x-goog-*` headers | Google Cloud CDN / GCS |
| `via: 1.1 google` | Google Cloud Load Balancer |

---

## Headless / Storefront Framework Signals

| Signal | Framework / Infra |
|--------|-----------------|
| `__NEXT_DATA__` in HTML | Next.js |
| `_next/` in script paths | Next.js |
| `__NUXT__` in HTML | Nuxt.js |
| `chunk-vendors`, `app.js` (Vue Webpack) | Vue.js + Webpack |
| `gatsby-chunk-mapping` | Gatsby |
| `___gatsby` in HTML | Gatsby |
| `remix-server`, `__remixContext` | Remix |
| `window.hydrogen` | Shopify Hydrogen |
| `<astro-island>` | Astro |
| `angular.min.js`, `ng-app` | AngularJS / Angular |
| `react.production.min.js` | React |
| `svelte` in bundle | Svelte / SvelteKit |

---

## Identity / SSO / Auth

| Signal | Platform |
|--------|---------|
| `okta.com`, `okta.js` | Okta |
| `auth0.com` | Auth0 (Okta) |
| `login.microsoftonline.com` | Azure AD / Entra |
| `accounts.google.com` | Google OAuth |
| `cognito-idp.` | AWS Cognito |
| `ping.com`, `pingone.com` | PingIdentity |
| `forgerock.com` | ForgeRock (now Ping) |
| `onelogin.com` | OneLogin |
| `stytch.com` | Stytch |
| `clerk.com` | Clerk.dev |

---

## Consent Management / Privacy

| Signal | Platform |
|--------|---------|
| `CookieConsentPolicy` cookie | OneTrust / Salesforce consent |
| `cdn.cookielaw.org`, `optanon` in JS | OneTrust |
| `cookiebot.com` | Cookiebot |
| `trustarc.com` | TrustArc |
| `evidon.com` | Evidon (now Crownpeak) |
| `consentmanager.net` | Consentmanager |
| `usercentrics.eu` | Usercentrics |
| `quantcast.com` (consent) | Quantcast Choice |
| `iubenda.com` | iubenda |
| `osano.com` | Osano |
| `didomi.io` | Didomi |

---

*Scope: Platform & infrastructure signals | Part 1 of 2*
