# Profile research index

One document per official profile (L19-013). Each profile must pass the release gate in [01 §15](../01-product-definition.md) and its browser-confirmation checklist before it ships. The research order is in [25 §3](../25-wave-a-document-types.md).

## Status

| Profile | Document | Status | Output | Background replacement | Tone | Home print |
|---|---|---|---|---|---|---|
| Spain · DNI | [13](../13-spain-foto-carnet.md) | Researched (reference profile) | Print 26 × 32 mm | Unknown → off | Unknown → off | Yes |
| US · passport | [us-passport-and-visa](us-passport-and-visa.md) | Draft, needs browser check | Print 2 × 2 in + online-renewal digital | **Disallowed** | **Disallowed** | Yes, on photo paper |
| US · visa | [us-passport-and-visa](us-passport-and-visa.md) | Draft, needs browser check | Digital 600 × 600 + print 2 × 2 in | **Disallowed** | **Disallowed** | When a post asks |
| UK · passport | [uk-passport](uk-passport.md) | Draft, needs browser check | Digital ≥ 600 × 750 (primary) + print 35 × 45 | **Disallowed** | **Disallowed** | **No**: shop print |
| Japan · passport | [japan-passport-and-my-number](japan-passport-and-my-number.md) | Draft, needs browser check | Print 35 × 45 | Unknown → off | Unknown → off | Not stated |
| Japan · My Number card | [japan-passport-and-my-number](japan-passport-and-my-number.md) | Draft, needs browser check | Print 35 × 45 + digital | Off ("edited images may not be accepted") | Off | Not stated |

Remaining approved profiles, in order: Italy passport and CIE; Spain TIE and driving licence; Netherlands passport, ID card, and driving licence; South Korea passport; Schengen visa.

## The pattern so far

**No official profile researched so far allows background replacement or tone correction.** They either forbid it outright (US, UK) or do not say (Spain, Japan), which means off under AGENTS.md §11.

For official documents, Calipic's quality therefore comes from:

1. **capture:** setup coaching, helper mode, live background and light checks (L19-001, L19-002, L19-014, L19-019);
2. **exact framing:** the solver and the landing moment;
3. **exact output:** print sheets, the print check, digital presets.

Background replacement and Document Tone remain valuable for **custom sizes** (ADR-018) and for any profile whose official source allows them.
