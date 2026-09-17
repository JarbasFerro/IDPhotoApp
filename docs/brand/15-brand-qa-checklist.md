# Calipic — Brand QA checklist

**Status:** Draft  
**Date:** 2026-09-17  
**Purpose:** A practical review checklist for screens, copy, assets, features and implementation PRs.  
**Derived from:** accepted entries in [`99-brand-decisions-log.md`](99-brand-decisions-log.md), [`02-experience-constitution.md`](02-experience-constitution.md), [`01-brand-foundations.md`](01-brand-foundations.md), [`03-color-strategy-research.md`](03-color-strategy-research.md) §5–7 and [`12-voice-and-writing.md`](12-voice-and-writing.md) (draft).

This checklist applies decisions; it does not make them. If an item seems wrong, change the decision log first, then this file.

---

## 1. How to use it

- Pick the sections that match the change: a copy-only PR needs §2, §7 and §10 (plus the wording items in §6 if accessibility labels change); a new screen needs most of §2–§8; an asset needs §2 and §9.
- Every item is answerable with **yes / no / not applicable**. A "no" is either fixed or written down with a reason in the PR.
- **Blockers** are marked **[B]**. They map to non-negotiable constraints (correctness, privacy, truthful compliance language) or to accepted decisions. A PR with an open blocker does not merge.
- When otherwise-good options conflict, use BD-034: native iOS familiarity, then beauty, then accessibility. Blockers are not traded against that order.
- Provisional items (icon, color) are in §9. Do not review against a final icon or brand color — neither exists yet.

---

## 2. Two questions first (experience test)

- [ ] Does this make the task easier, clearer, more beautiful or more complete for the user — rather than mainly making Calipic look more impressive?
- [ ] Would a first-time iPhone user understand what to do without learning Calipic's interface?

If either answer is no, stop and simplify before checking anything else.

---

## 3. Native iOS first (BD-002, BD-003, BD-004, BD-005, rule 4)

- [ ] The standard system control, navigation pattern, sheet, alert, picker or share/print path is used wherever one exists.
- [ ] Any custom control has a written reason why the native one cannot solve the problem. "It looks more branded" is not a reason. **[B]**
- [ ] Typography is system text styles with Dynamic Type. No custom font in product UI.
- [ ] Standard actions and system concepts use SF Symbols. Custom icons exist only for genuinely Calipic-specific concepts.
- [ ] Materials and Liquid Glass come from native components. No imitation glass, custom blur theme or app-wide tint shell.
- [ ] System labels (Cancel, Done, Settings, Actual Size…) match what iOS shows in each language.
- [ ] Gestures, back navigation, swipe-to-dismiss and keyboard behavior work as they do elsewhere on iPhone.

---

## 4. Photo primacy and restraint (BD-006, BD-018, rules 3 and 5)

- [ ] The portrait is the largest, most prominent element on any screen that shows it.
- [ ] Surfaces around the photo are system-neutral. No saturated brand surface, gradient or colored toolbar next to a face. **[B]**
- [ ] Guides and overlays help the photo and can be understood at a glance; none is decorative.
- [ ] Nothing frames the face as a biometric specimen: no scanning beam, recognition grid, pulsing ring, mesh or target reticle.
- [ ] Every visible element helps finish the job. Cards, dividers, badges and icons that only make the screen "look designed" are removed.
- [ ] Accent color is used selectively: a primary action, a selected state, a small guidance detail. Not as a theme.
- [ ] Negative space is kept. One obvious next action per screen (rule 1).
- [ ] Technical choices (resolution, DPI, color profile, segmentation options) are hidden unless genuinely necessary.

---

## 5. Status, color and appearance (BD-019, BD-033, rule 9, 03 §5–6)

- [ ] `pass`, `warn`, `fail` and `manual_check` use semantic/system status colors that are **independent of the brand accent**. The accent never means "pass", "selected check" and "brand" at once. **[B]**
- [ ] No state is communicated by color alone: each has a distinct symbol shape and/or text, on screen and in VoiceOver. **[B]**
- [ ] Any copy that explains a color key ("green means fine") is backed by a non-color cue for each state.
- [ ] States remain distinguishable in grayscale and under common color-vision deficiencies.
- [ ] Light and Dark Mode are both designed, both screenshotted and both reviewed. Neither is a derived afterthought.
- [ ] Every custom color has Light, Dark, Increase Contrast Light and Increase Contrast Dark values, defined as semantic assets — no hard-coded hex in views.
- [ ] Text and icon contrast is verified where a custom color is used.
- [ ] No brand color is treated as approved. Test values (BD-037) appear only in prototypes and scripts, never in shipping assets. **[B]**
- [ ] The photo's own pixels are never tinted, dimmed or color-shifted by appearance or theme.

---

## 6. Accessibility as equivalent functionality (rule 9)

- [ ] **Dynamic Type:** usable up to the largest accessibility sizes; text wraps or the layout reflows rather than truncating. Layout changes never alter photo geometry, crop or print dimensions. **[B]**
- [ ] **VoiceOver:** every control has a label, value and trait; images of the photo and the sheet have meaningful descriptions; reading order follows the task; status changes are announced.
- [ ] **VoiceOver during capture:** live guidance is spoken, not only drawn; the user can complete capture without seeing the ring.
- [ ] **Voice Control:** control names are short, unique on screen and speakable.
- [ ] **Precision gestures:** drag/pinch editing has an accessible alternative (steppers, sliders, adjustable actions).
- [ ] **Reduce Motion:** every animation has a reduced variant (cross-fade or none). No meaning depends on motion.
- [ ] **Increase Contrast / Reduce Transparency / Differentiate Without Color:** checked on the changed screens.
- [ ] Touch targets are at least 44 × 44 pt.
- [ ] Haptics confirm state; they are never the only signal.

---

## 7. Copy and trust language (BD-008, BD-013, BD-025, BD-026, BD-027, rules 2, 6, 7, 8)

See [`12-voice-and-writing.md`](12-voice-and-writing.md) for patterns and vocabulary.

- [ ] No guarantee or prediction of acceptance or rejection. None of: guaranteed, approved, certified, compliant, verified (as a badge), "will be accepted", "will be rejected". **[B]**
- [ ] Nothing implies government affiliation or certification: no seals, crests, flags-as-endorsement, certificate-style check marks. **[B]**
- [ ] "Official" describes a source or a published size, never Calipic's output.
- [ ] Measured checks, manual checks and "who decides" are kept separate. Manual checks stay visible even when everything measured passes. **[B]**
- [ ] Numbers shown are measured or sourced. No pseudo-precision, decorative measurements or confidence percentages without meaning. **[B]**
- [ ] Requirements are traceable: source named, review date shown.
- [ ] **No AI theater:** no "AI", "neural", "smart", "magic", sparkles, shimmer-as-thinking, or technology names in everyday UI. Copy says what changed or what to do. **[B]**
- [ ] Every warning or error says what happened and what to do now, and ends on the action. No codes, no "the operation", no algorithm names.
- [ ] Instructions are direct imperatives, not tentative. One instruction at a time during capture.
- [ ] Calm and concise. No humor, emoji or exclamation marks in official-photo workflows.
- [ ] Describes the photo, not the person. No judgement.
- [ ] Feature names are descriptive (Photo Check, Background, Print Sheet…). No branded sub-products.
- [ ] No internal language: prototype, spike, beta, "not included yet", "needs testing".
- [ ] "Verified" is not used as a badge or verdict; plain file checks say "checked".
- [ ] Privacy claims are concrete and true for this feature ("stays on your iPhone"). No shields, locks or exaggerated security wording.
- [ ] Marketing copy may be stronger than product copy, but contains nothing that would be false inside the app.

---

## 8. Feature and product behavior

### 8.1 Privacy and identity (BD-007, BD-014, rule 7)

- [ ] The core workflow still runs on-device. Any new network call, SDK, analytics event or upload involving a photo or face data is called out explicitly and has a product decision behind it. **[B]**
- [ ] No account is required for the core task.
- [ ] No cosmetic change to identity-bearing features in official-photo output (skin, face shape, eyes, blemishes). Light, color, crop and background only, within documented limits. **[B]**
- [ ] Edits are reversible; the original is kept and the user is told so.
- [ ] Generative assistance is never the source of truth for geometry or compliance.

### 8.2 Commercial conduct (BD-009, BD-029, BD-030, rule 11)

- [ ] **No ads.** No third-party advertising SDK, ad placement, cross-promotion interstitial or sponsored content. **[B]**
- [ ] No dark patterns: no fake urgency, pre-selected upsells, confusing dismissals, hidden prices or surprise watermark. **[B]**
- [ ] No commercial prompt, review prompt, confetti or gamification immediately after success. Completion is quiet.
- [ ] Credits map to understandable completed outcomes, not technical operations. Price and remaining credits are plain.
- [ ] "No ads. No subscription." appears only while it is true, and as a supporting point.

### 8.3 Finish the real-world job (BD-015, rule 10, rule 2)

- [ ] Export dimensions and print geometry come from deterministic calculation and are covered by tests. **[B]**
- [ ] Printing is a first-class path from this feature, not a buried export option.
- [ ] Save, share and print use native iOS paths.
- [ ] The user can verify physical size (check bar, "Actual Size" guidance).
- [ ] There is a clear completion state, and remaining manual checks are understandable.

---

## 9. Brand assets, icon and color (BD-020, BD-021, BD-022, BD-023, BD-024, BD-036, BD-037)

- [ ] `calipic-icon-draft-v0.*` is treated as a **draft stand-in only**. It is not shipped as the app icon, not used in marketing, and not described as "the Calipic logo". **[B]**
- [ ] Work on the icon refines form and finishing (shadows, depth, texture are expected) inside the frozen territory. It does not open a new broad symbol exploration.
- [ ] Frame geometry rules from the handoff hold: uniform stroke, identical round endpoints, exact top/bottom mirror symmetry, small top / bottom / left gaps, clearly larger right opening.
- [ ] Reading order holds: portrait frame, then person, then `C`. The icon says "ID photo" before anyone notices the letter.
- [ ] It does not resemble Face ID, facial recognition, Contacts, a camera aperture, an AI/sparkle mark or an agency seal. No registration marks, no calipers.
- [ ] It survives realistic sizes (App Store result, Home Screen, Spotlight, Settings), monochrome, reversed-out and grayscale. "Works at 1024 px" is not a pass.
- [ ] Any color shown on an asset is labelled as a test value. No asset implies an approved brand color.
- [ ] Evidence renders follow the re-run rule in [`prototypes/README.md`](prototypes/README.md) — regenerable by a script under `scripts/brand/` that takes the icon SVG as its argument (path planned; delivered with the prototype PRs). Findings made on flat v0 are marked provisional.
- [ ] Marketing imagery uses real human photography, treats people with dignity and shows varied skin tones. No stock-style "biometric" overlays.
- [ ] The name is written **Calipic**; descriptor written exactly as in BD-028: "Calipic — ID Photos".

---

## 10. Localization (BD-031)

- [ ] Every new user-facing string exists in the string catalog with **en, es and pt-BR**. Missing pt-BR is tracked, not ignored. (As of 2026-09-17 the catalog has no pt-BR at all — see 12 §9.3.)
- [ ] "Calipic" is not translated. Feature names are translated as ordinary descriptive words.
- [ ] No concatenated sentence fragments; placeholders are positional; plurals use grammar agreement or plural variants, never "(s)".
- [ ] Decimal separators, units and paper sizes follow the locale.
- [ ] Spanish uses informal "tú"; Brazilian Portuguese uses "você" and Brazilian vocabulary. Neither is machine-derived from the other.
- [ ] Layout holds with text about 30–40 % longer than English, combined with large Dynamic Type.
- [ ] Translations keep the compliance meaning exactly. en, es and pt-BR must not disagree about what was checked or promised. **[B]**
- [ ] Accessibility labels are localized too.

---

## 11. Implementation PR checklist

Short form for PR descriptions. Copy, tick, and link evidence.

```markdown
### Brand QA
- [ ] Native control/pattern used; any custom control justified
- [ ] Photo remains the primary content; chrome is neutral
- [ ] Status colors independent of accent; no color-only state
- [ ] Light + Dark screenshots attached
- [ ] Dynamic Type (largest), VoiceOver, Reduce Motion, Increase Contrast checked
- [ ] Copy follows 12-voice-and-writing: no acceptance guarantee/prediction, no AI wording, warnings end on an action
- [ ] No new network/SDK use of photo or face data; no ads; no dark patterns
- [ ] Export/print geometry unchanged or covered by tests
- [ ] Strings added for en / es / pt-BR (or gap noted)
- [ ] No provisional asset or test color shipped as final
- [ ] Decision log updated if a brand decision changed
```

Evidence to attach for UI changes: Light and Dark screenshots of each changed screen; one screenshot at the largest accessibility text size; a note of what was tested with VoiceOver.

---

## 12. When a check fails

1. Fix the design or copy. This is the normal outcome.
2. If the checklist item itself seems wrong, propose a change to the underlying `BD-xxx` entry or constitutional rule, following the amendment policy in `02-experience-constitution.md` and the change discipline in `99-brand-decisions-log.md`.
3. Never resolve a conflict silently in a mockup, a PR or a marketing asset.

When this draft is accepted, record the acceptance in the decision log and remove "Draft" from the status line.
