---
name: techstack-fingerprint
description: "Reverse-engineer a merchant's tech stack from public signals before a discovery meeting. Triggered by '/techstack-fingerprint [URL]', 'fingerprint [merchant] site', 'what tech does [merchant] use'."
---

# Tech Stack Fingerprint Skill

Produces a structured report with confirmed integrations, architecture diagram, and migration complexity ratings using only public HTTP, JS, and DNS signals.

**Agent prefix:** `[Tech Stack Fingerprint]`

**Output:** `merchants/[Name]/techstack-fingerprint-[store-slug]-[YYYY-MM-DD].md`
*(`store-slug` = hostname dots-to-hyphens, e.g. `store-sony-com-sg`)*

---

## Local Rules

Read `.claude/skills/techstack-fingerprint/local-rules.md` before starting. Apply all settings — language mode, auto_docx. Local rules override defaults. If the file doesn't exist, create it with `mode: en` and ask the SE for their preferred language before proceeding.

---

## Input

Accepts: `/techstack-fingerprint https://shop.example.jp/`, bare domain, or merchant name (resolve URL from briefing doc). If no URL found, ask: `[Tech Stack Fingerprint] No URL provided — please enter the store URL:`

---

## Execution Playbook

First, read all files in `.claude/skills/techstack-fingerprint/references/` — they are required for signal matching in all phases.

Run all phases in parallel.

### Phase 1 — HTTP Headers

```bash
curl -sI "https://[URL]/"
```

Key signals:

| Header | What it reveals |
|--------|----------------|
| `server:` | App server — `openresty`, `Apache`, `cloudflare`, `sfdcedge` |
| `x-powered-by:` | Runtime — `PHP`, `ASP.NET`, `Next.js` |
| `set-cookie:` names | `JSESSIONID` (Java), `PHPSESSID` (PHP), `AWSALB` (AWS ALB), `CookieConsentPolicy` (Salesforce) |
| `via:` / `x-cache:` | CDN — CloudFront, Fastly, Akamai |
| `cf-ray` | Cloudflare |
| `x-sfdc-*` | Salesforce |

Also probe: `member.`, `api.`, `faq.`, `help.`, `cdn.`, `static.`, `blog.`, `shop.`, `store.`, `www.`

### Phase 2 — HTML Shell Analysis

```bash
curl -sL "https://[URL]/"
```

Extract: external `src=` script URLs (CDN domains = third-party services), `<meta name="generator">`, inline `<script>` init patterns, named JS files (`_next/` = Next.js, `wp-content/` = WordPress, `chunk-vendors` = Vue/Webpack).

### Phase 3 — JS Bundle Deep Scan

```bash
export LANG=C; curl -s "[bundle URL]" | grep -oE 'https?://[a-zA-Z0-9._/-]+' | sort | uniq
export LANG=C; curl -s "[bundle URL]" | grep -oE '"GTM-[A-Z0-9]+"'
export LANG=C; curl -s "[bundle URL]" | grep -oE '"G-[A-Z0-9]+"'
```

### Phase 4 — DNS / SPF

```bash
dig [domain] TXT +short
dig [domain] MX +short
```

Match SPF `include:` entries against `references/signal-library.md` → email platform identification.

**Match all domains and patterns found against `references/signal-library.md`** for payment gateways, CRM, analytics, marketing automation, and infrastructure signals.

---

## Output Format

Apply language mode from `local-rules.md`:

| Element | `en` | `en+[lang]` |
|---------|------|-------------|
| Section headings | English | `## English / [Native]` |
| "What it means" | English | Add `> 🌐 [translation]` blockquote (use merchant's country flag) |
| Tables & diagrams | English always | English always |

```markdown
# Tech Stack Fingerprint — [Merchant Name]
**URL analysed:** [URL]
**Date:** [YYYY-MM-DD]
**Methodology:** Public signal reconnaissance — HTTP headers, JS bundle analysis, DNS/SPF, subdomain probing. No authenticated access.

---

## TL;DR

[3–5 bullets: most impactful confirmed systems + top migration complexity items]

---

## Confirmed Integrations

### [System Name] ✅ CONFIRMED
**Category:** [Payment / CRM / Analytics / etc.]
**Evidence:** [exact header, script URL, or bundle pattern]
**What it means:** [plain-language explanation]
**Shopify migration path:** [existing app / custom app / API bridge / N/A]

> 🌐 [Translation]   ← en+[lang] mode only

---

## Infrastructure Fingerprint

| Layer | Signal | Inference |
|-------|--------|-----------|

---

## Subdomain Ecosystem

| Subdomain | Purpose | Tech Signals |
|-----------|---------|-------------|

---

## Estimated Architecture Diagram

[ASCII — confirmed boxes solid, inferred marked (TBD)]

---

## Migration Complexity Summary

| Integration | Complexity | Shopify Path |
|------------|-----------|-------------|
| | 🔴 High / 🟡 Medium / 🟢 Low | |

---

## Discovery Questions Unlocked

[Per confirmed system: what this removes or refines from the discovery question list]

---

## Unknown — Still Needs Discovery

[Layers with no signal: ERP, OMS, POS, loyalty, etc.]

---

*Generated: [date] | Method: public signal reconnaissance | [INTERNAL-ONLY]*
```

---

## Post-Report Actions

1. **Save MD** to `merchants/[Name]/techstack-fingerprint-[store-slug]-[YYYY-MM-DD].md`
2. **DOCX:** If `auto_docx: true` in local-rules.md, run `pandoc [file].md -o [file].docx --from=markdown+emoji --to=docx`
3. **If TA exists** (`technical-assessment.md`): offer to insert findings before `## Current Tech Stack Summary`, update confirmed rows, refresh Discovery Gaps
4. **If no TA exists:** append `Run /technical-assessment to generate a full TA using these findings.`
5. **Always:** Flag any staging/dev infrastructure exposed in production as `⚠️ InfoSec note`

---

## Guardrails

- No authenticated requests — public URLs only, never attempt login or brute-force paths
- No destructive probing — no fuzzing, port scanning, or exploit attempts
- Label every finding: ✅ CONFIRMED (direct evidence) or 🔍 INFERRED (logical deduction)
- InfoSec hygiene: flag exposed staging paths but do not probe further

---

**Version:** v1.3
