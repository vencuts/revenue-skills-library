# Demo Follow-up Email Template

Reusable HTML structure for demo follow-up emails. Gmail copy-paste safe (no flexbox, no grid, single column).

## CSS Classes

| Class | Use |
|---|---|
| `.container` | Outer wrapper, max-width 680px, white background, rounded corners |
| `.header` | Dark (#1a1a2e) header, centred text |
| `.body` | Main content area, 32px/36px padding |
| `.topic` | Info block for answers/topics, left border accent |
| `.app-card` | App recommendation card, same left border style |
| `.info-box` | Neutral info block (light blue/grey) |
| `.note-box` | Yellow callout for tips/notes |
| `.footer` | Light footer with small grey text |

## HTML Skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>[Merchant] - Demo Follow-up</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; font-size: 15px; line-height: 1.6; color: #1a1a1a; background: #f5f5f5; margin: 0; padding: 20px; }
    .container { max-width: 680px; margin: 0 auto; background: #ffffff; border-radius: 8px; overflow: hidden; }
    .header { background: #1a1a2e; padding: 28px 36px; text-align: center; }
    .header h1 { color: #ffffff; margin: 0; font-size: 20px; font-weight: 600; letter-spacing: -0.3px; }
    .header p { color: rgba(255,255,255,0.7); margin: 4px 0 0; font-size: 13px; }
    .body { padding: 32px 36px; }
    h2 { font-size: 14px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.6px; color: #1a1a2e; margin: 28px 0 10px; border-bottom: 2px solid #1a1a2e; padding-bottom: 6px; }
    h2:first-of-type { margin-top: 0; }
    p { margin: 0 0 14px; color: #333; }
    ul { margin: 0 0 16px; padding-left: 20px; }
    li { margin-bottom: 8px; color: #333; }
    a { color: #1a1a2e; }
    .topic { background: #f8f8fb; border-left: 3px solid #1a1a2e; border-radius: 0 6px 6px 0; padding: 14px 16px; margin-bottom: 12px; }
    .topic strong { display: block; font-size: 14px; margin-bottom: 4px; color: #1a1a1a; }
    .topic span { font-size: 14px; color: #555; }
    .topic ul { margin: 8px 0 0; padding-left: 18px; }
    .topic li { font-size: 14px; color: #555; margin-bottom: 4px; }
    .app-card { background: #f8f8fb; border-left: 3px solid #1a1a2e; border-radius: 0 6px 6px 0; padding: 14px 16px; margin-bottom: 12px; }
    .app-card strong { display: block; font-size: 14px; color: #1a1a1a; margin-bottom: 2px; }
    .app-card a { font-size: 13px; color: #1a1a2e; }
    .app-card span { display: block; font-size: 13px; color: #666; line-height: 1.5; margin-top: 4px; }
    .info-box { background: #f0f2f8; border-radius: 6px; padding: 16px 20px; margin-bottom: 16px; }
    .info-box p { margin: 0 0 8px; }
    .info-box ul { margin: 0; }
    .info-box li { font-size: 14px; color: #444; }
    .note-box { background: #fff8e6; border: 1px solid #f5c842; border-radius: 6px; padding: 16px 20px; margin-bottom: 16px; }
    .note-box p { margin: 0 0 6px; font-size: 14px; color: #555; }
    .note-box strong { color: #7a5c00; }
    .footer { border-top: 1px solid #e8e8e8; padding: 20px 36px; font-size: 13px; color: #888; }
    @media (max-width: 580px) { .body { padding: 24px 20px; } .header { padding: 20px 20px; } } /* browser preview only — stripped by Gmail on copy-paste */
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Demo Follow-up</h1>
      <p>[Merchant] × Shopify</p>
    </div>
    <div class="body">

      <p>Hi [Name],</p>
      <p>[Intro paragraph referencing the call]</p>

      <!-- Table of contents — anchor links are visual only, in-page navigation doesn't work in Gmail -->
      <div class="info-box">
        <p><strong>In this email:</strong></p>
        <ul>
          <li><a href="#section-id">Section title</a></li>
          <!-- repeat per section -->
        </ul>
      </div>

      <!-- Per open question / topic -->
      <h2 id="section-id">Topic Title</h2>
      <p>[Context paragraph]</p>
      <div class="topic">
        <strong>Key point</strong>
        <span>Explanation</span>
      </div>
      <p><strong>Useful links:</strong></p>
      <ul>
        <li><a href="[url]">[Link title]</a> - [Brief description]</li>
      </ul>

      <!-- Apps section -->
      <h2 id="apps">Apps Worth Exploring</h2>
      <div class="app-card">
        <strong>[App Name]</strong>
        <a href="[app-store-url]">View on Shopify App Store</a>
        <span>[Why it's relevant for this merchant]</span>
      </div>
      <!-- repeat per app -->

      <div class="note-box">
        <p><strong>Tip:</strong> [Soft recommendation, e.g. about Built for Shopify badge]</p>
      </div>

      <!-- Editions section -->
      <h2 id="editions">Where Shopify Is Heading</h2>
      <p>[Brief paragraph about latest Editions release and how it connects to the merchant's interests]</p>

      <!-- Next steps -->
      <h2 id="next-steps">Next Steps</h2>
      <ul>
        <li>[Action item]</li>
      </ul>

      <p>[Sign-off]</p>
    </div>
    <div class="footer">
      This email is a follow-up to our conversation on [date].
    </div>
  </div>
</body>
</html>
```

## Logo Note

Including a logo in the header is possible via `<img>` tag with a CDN URL, but be aware:
- **Gmail copy-paste**: Remote images often don't survive copy-paste from browser to Gmail compose
- **Inline SVG**: Renders locally but Gmail strips SVG on paste
- **Recommendation**: Skip the logo for reliability, or accept it may not appear in Gmail
