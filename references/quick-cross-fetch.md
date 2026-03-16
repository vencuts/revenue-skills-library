# Quick Cross Fetch — Cross-Origin Data Access for Quick Sites
*Source: quick-cross-fetch.quick.shopify.io | Built by Qlaw*

## What It Does
Handles Google IAP auth redirects when one Quick site fetches data from another Quick site. Without it, cross-origin fetches silently fail (TypeError from 302 redirect to Google login).

## When to Use
When building a Quick site that needs to pull data from another Quick site. Examples:
- Journey map dashboard fetching skill scores from quiz site
- Dashboard aggregating data from multiple Quick site databases
- Any site-to-site data sharing

## How It Works
1. Attempts `fetch(url, { credentials: 'include', redirect: 'error' })`
2. If IAP intercepts (302), detects the TypeError
3. Opens hidden iframe to target origin → iframe completes OAuth → sets auth cookie
4. Retries original fetch with cookie → succeeds

## Usage (browser-side only)
```html
<script src="https://quick-cross-fetch.quick.shopify.io/quick_cross_fetch.js"></script>
```

```javascript
// Simple fetch
const resp = await quickCrossFetch('https://other-site.quick.shopify.io/api/data');
const data = await resp.json();

// JSON shorthand
const json = await quickCrossFetchJSON('https://other-site.quick.shopify.io/api/data');

// With options
const resp = await quickCrossFetch('https://other-site.quick.shopify.io/api', {
  retryInterval: 3000,  // ms between retries (default: 2000)
  maxRetries: 5,        // max attempts (default: 10)
  onAuthStart: (origin) => console.log('Priming auth for', origin),
  onRetry: (attempt) => console.log('Retry', attempt),
  headers: { 'Accept': 'application/json' },
});
```

## Limitation
This is a BROWSER library (uses iframes, cookies, DOM). It does NOT help with CLI/terminal Quick MCP access — that uses a different auth mechanism (Quick CLI tokens).

## For Our Skills
- Use in any Quick site we build that needs cross-site data
- Add the script tag to diana-dashboard, sales-skill-lib, quiz site if they need to talk to each other
- NOT relevant for Pi/Pide CLI access to Quick sites (that uses `quick mcp <site>` with its own auth)
