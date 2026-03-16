# Signal Library — Marketing, Payments & Integrations

---

## Payment Gateways — Global

| Domain / Pattern | Gateway |
|-----------------|---------|
| `js.stripe.com`, `stripe.com` | Stripe |
| `paypal.com`, `paypalobjects.com` | PayPal |
| `braintreegateway.com`, `braintree-api.com` | Braintree (PayPal group) |
| `adyen.com`, `checkoutshopper-live.adyen.com` | Adyen |
| `checkout.com` | Checkout.com |
| `authorize.net`, `akamaihd.net/cybersource` | Authorize.Net |
| `cybersource.com` | CyberSource (Visa) |
| `worldpay.com` | Worldpay (FIS) |
| `opayo.com` (formerly `sagepay.com`) | Opayo / Sage Pay |
| `2checkout.com` / `verifone.com` | 2Checkout / Verifone |
| `square.com`, `squareup.com` | Square |
| `mollie.com` | Mollie |
| `klarna.com` | Klarna |
| `affirm.com` | Affirm (BNPL) |
| `afterpay.com` | Afterpay / Clearpay (BNPL) |
| `zip.co`, `quadpay.com` | Zip (BNPL) |
| `splitit.com` | Splitit (BNPL) |
| `sezzle.com` | Sezzle (BNPL) |
| `pay.google.com` | Google Pay |
| `applepay` in JS | Apple Pay |
| `amazonpay.com` | Amazon Pay |
| `global-e.com` | Global-e (cross-border checkout) |
| `borderfree.com` | Borderfree / Pitney Bowes |
| `flow.io` | Flow Commerce (cross-border) |
| `fastlane.com` | PayPal Fastlane |
| `bluesnap.com` | BlueSnap |
| `nuvei.com` | Nuvei |
| `recurly.com` | Recurly (subscription billing) |
| `chargebee.com` | Chargebee (subscription billing) |
| `recharge.com` | Recharge (Shopify subscriptions) |
| `bold.co` (Bold Commerce) | Bold Subscriptions |

---

## Payment Gateways — Japan

| Domain / Pattern | Gateway |
|-----------------|---------|
| `static.mul-pay.jp` | GMO Payment Gateway (GMO-PG) |
| `cdn.atokara.jp` | GMO-PG SMS authentication |
| `veritrans.co.jp` / `tsCREDIT` | Veritrans (GMO group) |
| `sbps.jp` | SB Payment Service |
| `zeus.ne.jp` | Zeus Payment |
| `epsilon.jp` / `gmo-epsilon.jp` | GMO Epsilon |
| `komoju.com` | KOMOJU |
| `paidy.com` | Paidy (BNPL JP) |
| `checkout.rakuten.co.jp` | Rakuten Pay / Rakuten Points |
| `aupay.wallet.auone.jp` | au PAY |
| `paypay.ne.jp` | PayPay |
| `d-payment.docomo.ne.jp` | docomo carrier billing |
| `merpay.com` | Merpay (Mercari Pay) |
| `pay.line.me` | LINE Pay |
| `j-payment.co.jp` | JCB J/Secure |
| `np-atobarai.com` | NP後払い (NP Atobarai deferred) |
| `smbc-card.com` | SMBC payment |
| `aeon.co.jp` | AEON Pay |

---

## BNPL — Global

| Domain | Provider |
|--------|---------|
| `klarna.com` | Klarna |
| `afterpay.com` / `clearpay.co.uk` | Afterpay / Clearpay |
| `affirm.com` | Affirm |
| `zip.co` | Zip |
| `splitit.com` | Splitit |
| `sezzle.com` | Sezzle |
| `laybuy.com` | Laybuy |
| `scalapay.com` | Scalapay (EU) |
| `alma.eu` | Alma (EU BNPL) |
| `payright.com.au` | Payright (AU) |
| `humm.com.au` | Humm (AU) |
| `tabby.ai` | Tabby (MENA) |
| `tamara.co` | Tamara (MENA) |

---

## CRM / Customer Service

| Signal | Platform |
|--------|---------|
| `server: sfdcedge`, `x-sfdc-*`, `siteforce:communityApp` | Salesforce (Experience / Service Cloud) |
| `zendesk.com` in scripts | Zendesk |
| `zdassets.com` | Zendesk Assets CDN |
| `freshdesk.com` | Freshdesk |
| `freshchat.com` | Freshchat |
| `kustomer.com` | Kustomer (Meta) |
| `intercom.io` / `widget.intercom.io` | Intercom |
| `chat.zopim.com` | Zendesk Chat (Zopim legacy) |
| `hubspot.com`, `js.hs-scripts.com` | HubSpot CRM |
| `re-engage.com` | Re:amaze |
| `gorgias.com` | Gorgias (Shopify-native CS) |
| `richpanel.com` | Richpanel |
| `gladly.com` | Gladly |
| `helpscout.net` | Help Scout |
| `dixa.com` | Dixa |
| `salesforceliveagent.com` | Salesforce Live Agent |
| `oracle.com/cx` patterns | Oracle CX Service |
| `servicenow.com` | ServiceNow |

---

## Chatbots & Live Chat

| Domain | Platform |
|--------|---------|
| `drift.com` | Drift |
| `crisp.chat` | Crisp |
| `tawk.to` | Tawk.to |
| `comm100.com` | Comm100 |
| `livechat.com`, `liveagent.com` | LiveChat |
| `olark.com` | Olark |
| `tidio.com` | Tidio |
| `chatra.io` | Chatra |
| `snapengage.com` | SnapEngage |
| `whoson.com` | WhoSon |
| `boldchat.com` | BoldChat (LogMeIn) |
| `liveperson.com` | LivePerson |
| `nuance.com` | Nuance (Microsoft) |
| `support-widget.userlocal.jp` | UserLocal (JP AI chatbot) |
| `zeals.co.jp` | Zeals (JP conversational commerce) |
| `chatlive.jp` | ChatLive (JP) |

---

## Analytics & Tag Management

| Pattern | Tool |
|---------|-----|
| `GTM-[A-Z0-9]+` | Google Tag Manager |
| `G-[A-Z0-9]+` | GA4 |
| `UA-[0-9-]+` | Universal Analytics (legacy) |
| `googletagmanager.com`, `googletag.js` | Google Tag Manager |
| `tags.tiqcdn.com/utag/` | Tealium iQ (profile in URL: `{account}/{profile}/{env}`) |
| `utag.js`, `utag_data` in HTML | Tealium iQ |
| `dtm.adobe.com` / `launch-ENx` | Adobe Launch / DTM |
| `assets.adobedtm.com` | Adobe Launch |
| `b.scorecardresearch.com` | Comscore |
| `hotjar.com`, `static.hotjar.com` | Hotjar |
| `clarity.ms` | Microsoft Clarity |
| `fullstory.com` | FullStory |
| `cdn.segment.com`, `segment.com` | Segment CDP |
| `cdn.amplitude.com`, `amplitude.com` | Amplitude |
| `mixpanel.com` | Mixpanel |
| `heap.io` | Heap |
| `fpjscdn.net` | FingerprintJS Pro |
| `mouseflow.com` | Mouseflow |
| `luckyorange.com` | Lucky Orange |
| `contentsquare.com`, `cquotient.com` | ContentSquare |
| `quantum-metric.com` | Quantum Metric |
| `medallia.com` | Medallia |
| `qualtrics.com` | Qualtrics |
| `glassbox.com` | Glassbox |
| `dynatrace.com` | Dynatrace RUM |
| `nr-data.net`, `newrelic.com` | New Relic (browser agent) |
| `browser.sentry-cdn.com` | Sentry (error tracking) |
| `datadog-browser-agent.com` | Datadog RUM |

---

## Adobe Stack

| Signal | Tool |
|--------|-----|
| `assets.adobedtm.com`, `launch-ENx` in scripts | Adobe Launch (tag manager) |
| `omtrdc.net`, `2o7.net`, `s_code.js`, `AppMeasurement.js` | Adobe Analytics |
| `mbox` in Tealium/JS bundles, `tt.omtrdc.net` | Adobe Target |
| `/etc.clientlibs/`, `clientlib-`, AEM path patterns | Adobe Experience Manager (AEM) |
| `scene7.com`, `s7d*.scene7.com` | Adobe Dynamic Media / Scene7 |
| `business.adobe.com` CDN | Adobe Fonts / Typekit |
| `rum.hlx.page`, `rum.hlx3.page` | Adobe Helix RUM / Edge Delivery |
| `experience.adobe.com` | Adobe Experience Platform (AEP) |
| `demdex.net` | Adobe Audience Manager |

---

## Marketing Automation & CDP

| Domain | Platform |
|--------|---------|
| `klaviyo.com` | Klaviyo |
| `mailchimp.com` | Mailchimp |
| `sfmc.`, `exacttarget.com`, `salesforceind.com` | Salesforce Marketing Cloud |
| `marketo.net`, `munchkin.js` | Marketo |
| `pardot.com` | Pardot / MCAE |
| `braze.com`, `appboy.com` | Braze |
| `customer.io` | Customer.io |
| `iterable.com` | Iterable |
| `blueshift.com` | Blueshift |
| `sendgrid.net` | SendGrid |
| `mailgun.com` | Mailgun |
| `postmarkapp.com` | Postmark |
| `drip.com` | Drip |
| `omnisend.com` | Omnisend |
| `getresponse.com` | GetResponse |
| `activecampaign.com` | ActiveCampaign |
| `sailthru.com` | Sailthru (Marigold) |
| `emarsys.com` | Emarsys (SAP) |
| `dotdigital.com` | Dotdigital |
| `acoustic.com` | Acoustic Campaign |
| `responsys.com` | Oracle Responsys |
| `eloqua.com` | Oracle Eloqua |
| `listrak.com` | Listrak |
| `attentivemobile.com` | Attentive (SMS) |
| `postscript.io` | Postscript (SMS) |
| `smsbump.com` | SMSBump (Yotpo SMS) |
| `lytics.io`, `c.lytics.io` | Lytics CDP |
| `treasure-data.com` | Treasure Data CDP |
| `actioniq.com` | ActionIQ |
| `amperity.com` | Amperity |
| `blueconic.com` | BlueConic |
| `b-dash.jp` | B→Dash (JP MA) |

---

## Personalisation & A/B Testing

| Signal | Platform |
|--------|---------|
| `optimizely.com`, `cdn.optimizely.com` | Optimizely (Web Experimentation) |
| `abtasty.com` | AB Tasty |
| `vwo.com` | VWO |
| `convert.com` | Convert.com |
| `qubit.com` | Qubit (now part of Coveo) |
| `nosto.com` | Nosto |
| `barilliance.com` | Barilliance |
| `monetate.net` | Monetate |
| `certona.com` | Certona (Kibo) |
| `bloomreach.com` (personalisation endpoint) | Bloomreach Engagement |
| `dynamic-yield.com` | Dynamic Yield |
| `tt.omtrdc.net` | Adobe Target |

---

## Loyalty & Referral

| Signal | Platform |
|--------|---------|
| `yotpo.com` | Yotpo Loyalty |
| `smile.io`, `cdn.smile.io` | Smile.io |
| `loyaltylion.com` | LoyaltyLion |
| `annex-cloud.com` | Annex Cloud |
| `antavo.com` | Antavo |
| `zinrelo.com` | Zinrelo |
| `referralcandy.com` | ReferralCandy |
| `friendbuy.com` | Friendbuy |
| `extole.com` | Extole |
| `saasquatch.com` | SaaSquatch (impact.com) |
| `talkable.com` | Talkable |

---

## Product Registration & Warranty

| Signal | Platform |
|--------|---------|
| `registria.com` | Registria |
| `registriastaging.com` | Registria (staging — flag if on prod) |
| `extend.com` | Extend (warranty) |
| `clyde.com` | Clyde (warranty) |
| `mulberry.com` | Mulberry (warranty) |
| `assurant.com` | Assurant |
| `servify.in` | Servify |

---

## Ad & Affiliate Networks

| Signal | Platform |
|--------|---------|
| `doubleclick.net`, `googleadservices.com` | Google Ads / DV360 |
| `facebook.net`, `connect.facebook.net` | Meta Pixel / Conversions API |
| `sc-static.net` | Snapchat Pixel |
| `ads.tiktok.com`, `analytics.tiktok.com` | TikTok Pixel |
| `pinterest.com/ct.html` | Pinterest Tag |
| `static.ads-twitter.com` | Twitter / X Ads |
| `linkedin.com/li.lms-analytics` | LinkedIn Insight Tag |
| `bat.bing.com` | Microsoft Advertising (Bing Ads) |
| `criteo.net`, `static.criteo.net` | Criteo |
| `rtmark.net` | RTB House |
| `adnxs.com` | Xandr / AppNexus |
| `taboola.com` | Taboola |
| `outbrain.com` | Outbrain |
| `tradedoubler.com` | Tradedoubler (affiliate) |
| `awin.com`, `awin1.com` | AWIN (affiliate) |
| `shareasale.com` | ShareASale (affiliate) |
| `impact.com` | impact.com (affiliate/partnerships) |
| `pepperjam.com` | Pepperjam (Partnerize) |
| `rakuten.com/li/` | Rakuten Advertising |

---

## Logistics / Carriers — Global

| Domain | Carrier |
|--------|--------|
| `fedex.com` | FedEx |
| `ups.com` | UPS |
| `dhl.com` | DHL |
| `usps.com` | USPS |
| `royalmail.com` | Royal Mail (UK) |
| `parcelforce.com` | Parcelforce (UK) |
| `dpd.co.uk` / `dpd.de` | DPD |
| `hermes.de` / `myhermes.co.uk` | Hermes / Evri |
| `gls-group.eu` | GLS |
| `tnt.com` | TNT (FedEx) |
| `postnord.com` | PostNord (Scandinavia) |
| `bpost.be` | bpost (Belgium) |
| `poste.it` | Poste Italiane |
| `laposte.fr` | La Poste (France) |
| `correos.es` | Correos (Spain) |
| `deutschepost.de` | Deutsche Post |
| `auspost.com.au` | Australia Post |
| `nzpost.co.nz` | NZ Post |
| `singpost.com` | SingPost |

---

## Logistics / Carriers — Japan

| Domain | Carrier |
|--------|--------|
| `kuronekoyamato.co.jp` / `yamato.co.jp` | Yamato Transport (ヤマト運輸) |
| `e-service.sagawa-exp.co.jp` | Sagawa Express (佐川急便) |
| `trackings.post.japanpost.jp` | Japan Post (日本郵便) |
| `sfc.jp` | SFC (Seino Freight) |
| `nipponexpress.com` | Nippon Express |

---

## SPF Record Patterns

| SPF include | Platform |
|-------------|---------|
| `pphosted.com` | Proofpoint |
| `sendgrid.net` | SendGrid |
| `amazonses.com` | Amazon SES |
| `mktomail.com` | Marketo |
| `exacttarget.com` / `sfmc.` | Salesforce Marketing Cloud |
| `spf.mandrillapp.com` | Mandrill (Mailchimp transactional) |
| `mailgun.org` | Mailgun |
| `postmarkapp.com` | Postmark |
| `klaviyo.com` | Klaviyo |
| `mailersend.com` | MailerSend |
| `braze.com` | Braze |
| `iterable.com` | Iterable |
| `customer.io` | Customer.io |
| `sailthru.com` | Sailthru |
| `emarsys.com` | Emarsys (SAP) |
| `dotdigital.com` | Dotdigital |
| `hubspot.com` | HubSpot |
| `google.com` (include:_spf.google.com) | Google Workspace |
| `outlook.com` / `protection.outlook.com` | Microsoft 365 |
| `mpme.jp` / `bma.mpme.jp` | Japanese email delivery |

---

## MX Record Patterns

| MX domain | Platform |
|-----------|---------|
| `*.google.com` / `aspmx.l.google.com` | Google Workspace |
| `*.outlook.com` / `*.mail.protection.outlook.com` | Microsoft 365 |
| `*.pphosted.com` | Proofpoint |
| `*.mimecast.com` | Mimecast |
| `*.barracudanetworks.com` | Barracuda |
| `*.messagelabs.com` | Symantec / Broadcom |
| `*.zendesk.com` | Zendesk inbound email |
| `*.freshdesk.com` | Freshdesk inbound email |

---

*Scope: Marketing, payments & integration signals | Part 2 of 2*
