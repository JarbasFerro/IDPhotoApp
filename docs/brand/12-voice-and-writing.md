# Calipic — Voice and writing

**Status:** Draft  
**Date:** 2026-09-17  
**Scope:** Product voice, vocabulary, instruction patterns, error and compliance language, marketing strength, naming, and localization notes for English, Spanish and Portuguese (Brazil).  
**Derived from:** BD-008, BD-013, BD-025, BD-026, BD-027, BD-030 (plus BD-001, BD-014, BD-028, BD-031), [`01-brand-foundations.md`](01-brand-foundations.md) §13–18 and [`02-experience-constitution.md`](02-experience-constitution.md) rules 1, 2, 6, 7, 8, 9, 10 and 11.

This draft applies accepted decisions; it does not reopen them. Where it proposes something new, it says so and marks it as open.

---

## 1. The voice in one paragraph

Calipic sounds like a calm, capable person standing next to you while you take the photo. It says what to do in a few plain words, says what it did, and says honestly what it could not check. It does not joke during an official-photo task, does not talk about its own technology, and never promises what a government office will decide.

> **Calm. Concise. Direct. Honest about limits.**

---

## 2. Voice principles

### 2.1 Calm and concise (BD-025)

- One idea per sentence. Most in-product messages are one or two short sentences.
- No exclamation marks in the workflow. No urgency, no alarm, no cheerleading.
- Completion is quiet (constitution rule 11): "Your files are ready." is enough.

### 2.2 Direct, not tentative (BD-025)

- Use the imperative for instructions: **"Move a little farther away."**
- Not: "You may want to move back a little." / "Try moving back if you can."
- Soften with the *size* of the request ("a little", "slightly"), not with hedging.

### 2.3 A human "we" is permitted (BD-025)

- Use "we" when it makes Calipic accountable for something it did or could not do: "We couldn't separate the background cleanly."
- Do not use "we" for decisions that belong to someone else (the receiving office) or for marketing self-praise.
- Do not use "I". Calipic is not a character or an assistant.

### 2.4 Straight in official-photo workflows (BD-025)

- No humor, puns, emoji or playful filler in capture, Photo Check, editor, export or print.
- Friendly means short, respectful and non-judgemental — not cute (foundations §7).
- Describe the photo, not the person: "The face is dark", not "You look too dark".

### 2.5 Technology disappears (BD-013, constitution rule 6)

- Say what changed or what to do next. Do not name the mechanism.
- Technology terms appear only when the user asks how something works, or in technical/help contexts.

### 2.6 Precision must be real (constitution rule 2)

- State a number only if it is measured or sourced ("26 × 32 mm", "50 mm bar").
- Separate what was measured from what needs a human eye.
- Do not use confident wording to cover uncertain logic.

### 2.7 Every warning creates agency (constitution rule 8)

Each negative message answers: what happened, why it matters (when not obvious), what to do now. The action comes last and is concrete.

---

## 3. Vocabulary

### 3.1 Preferred

| Use | Notes |
|---|---|
| photo, portrait | "photo" by default; "portrait" when choosing a source image |
| ID photo | category term (BD-028); localized category term in es / pt-BR |
| Photo Check, Background, Position, Print Sheet, Requirements | descriptive feature names (BD-027) |
| check, check by eye | for anything a human must judge |
| we can measure / could not be checked | honest scope language |
| framed to size, crop | not "biometric crop" |
| print at Actual Size (100 %) | match the wording of the iOS print dialog in each language |
| retake, choose another photo | standard recovery actions |
| stays on your iPhone | concrete privacy statement (BD-014) |
| requirements, official guidance, source | sourced rules stay traceable |
| the office that receives it | who actually decides acceptance |
| credit | one credit = one understandable completed result (BD-029) |

### 3.2 Avoid

| Avoid | Why | Instead |
|---|---|---|
| AI, AI-powered, neural, machine learning, algorithm, segmentation, model, biometric engine, generative | BD-013, rule 6 | describe the result: "We prepared the crop." |
| scan, scanning, detect, recognition, verify your identity | surveillance / Face ID cues (BD-023) | find, check, look |
| guaranteed, approved, certified, compliant, official (as a claim about the output), "will be accepted", 100 % | BD-008, rule 7 | "framed to the required size", "everything we can measure is fine" |
| valid / invalid photo, passed / failed (as a verdict on acceptance) | implies a government verdict | "Looks good", "Needs attention", "Better to retake" |
| error, operation, failed, exception, invalid input, codes | rule 8 | say what happened and what to do |
| oops, uh-oh, whoops, yay, awesome, magic, smart, instantly, effortless (in product) | BD-025, anti-traits childish / cheap | plain statement |
| prototype, spike, beta, "not included yet", "still needs testing" | internal project language leaking into product | remove, or state the current limit plainly |
| premium, pro, unlock, upgrade now, limited time | BD-012, rule 11, no conversion pressure | "credits", plain price |
| secure, military-grade, encrypted vault, shields/locks language | BD-014: privacy through concrete behavior | "Your photo stays on your iPhone." |
| perfect, flawless, beautify, enhance your look, retouch | BD-007 | "Nothing on your face is retouched." |

---

## 4. Instruction patterns

### 4.1 Live capture hints

- Imperative, two to six words, no trailing period when shown as a single overlay line.
- One hint at a time. The hint names the *one* thing to change.
- Prefer moving the easiest thing: the phone before the head, the person before the room.

Pattern: **verb + small amount + direction.**

| Good | Not |
|---|---|
| Move a little closer | You're too far from the camera |
| Hold the phone at eye level | Camera pitch out of range |
| Find more light on your face | Low luminance detected |
| Hold still | Please try not to move |

### 4.2 Preparation tips

- Noun phrases or short imperatives in a list. Parallel structure.
- Explain the reason only when it changes behavior: "About an arm's length. Too close distorts the nose."

### 4.3 Buttons and titles

- Buttons: verb or verb + object, in the platform's casing for the language ("Take Photo", "Choose Photo", "Retake", "Print", "Share PDF").
- Use system-standard labels (Cancel, Done, OK, Continue, Open Settings) exactly as iOS localizes them.
- Titles name the place or the object ("Print sheet", "Photo requirements"), not the brand.

### 4.4 Progress

- Present participle + object + ellipsis: "Checking your photo…", "Preparing your files…".
- Say what is happening in user terms. "Finding your face…" is acceptable; "Running face landmarks…" is not.

### 4.5 Accessibility wording (constitution rule 9)

- VoiceOver labels say the state in words, never only a color: "Light: needs attention", not "orange".
- When visible copy explains a color key (as the capture ring does), the same information must exist as text or a symbol for each state.
- Spell out units in spoken labels ("26 millimeters wide, 32 millimeters high").
- Control names must be speakable for Voice Control: short, unique on screen, no symbols-only labels.

---

## 5. Errors and negative states

Template:

> **What happened** (plain, photo-focused, "we" where Calipic is the actor). **What to do now** (one concrete action, two at most).

- Never end on the failure. End on the action.
- No blame. "The top of the head is cut off" — not "You cut off your head".
- No codes, no component names, no "the operation".
- If nothing can be done in-app, say where the fix lives: "Allow camera access in Settings, or choose an existing photo instead."
- If Calipic kept something safe, say so: "…so the original is kept."

Severity ladder used by Photo Check (wording, not color, carries the meaning):

| State | Plain wording family |
|---|---|
| pass | "Looks good", "Fine", specific confirmation ("Eyes level") |
| warn | "Needs attention", "A few things to check", specific fixable note |
| fail | "Better to retake" + the reason + the fix |
| manual_check | "Check by eye", "Could not be checked" + what to look for |

---

## 6. Uncertainty and compliance language (BD-008)

This is the strictest part of the voice. **Calipic never guarantees acceptance and never implies government affiliation or certification.**

### 6.1 Rules

1. Separate three things every time they appear together:
   - what Calipic **measured** (dimensions, head size, eye line, background evenness);
   - what Calipic **could not check** and the user must check by eye (expression, glare, recency, exceptions);
   - who **decides** (the office that receives the photo).
2. Do not predict the office's decision in either direction. "Will be accepted" and "will be rejected" are both claims Calipic cannot support. Describe the photo's measurable problem instead.
3. "Official" describes a **source** or a **published size**, never Calipic's output. "Official guidance" — yes. "Official photo", "officially approved" — no.
4. Cite and date sources: "Source reviewed September 15, 2026."
5. Manual checks stay visible even when everything measured passes.
6. No seals, check-mark badges or wording that resembles a certificate ("Verified", "Compliant", "Approved").

### 6.2 Reference phrases

| Situation | Phrase |
|---|---|
| All measurable checks pass | "Everything we can measure is fine. Also check by eye: neutral expression, eyes open, no glare on glasses." |
| Scope statement | "The app formats the photo. Acceptance is decided by the office that receives it." |
| Could not measure | "Could not be checked. Make sure it is plain and light." |
| Exceptions | "The guidance includes medical and religious exceptions. Review the source for your situation." |
| Serious measurable problem | "This photo has problems we can't fix. A new one takes a minute." |
| After export | "Your files are ready. Review your photo before using it for a document." |

---

## 7. Marketing vs in-product strength (BD-026, BD-030)

| | Marketing / App Store | In product |
|---|---|---|
| Outcome language | Stronger is allowed: "Passport photos made right." | Precise: what was measured, what to check |
| Acceptance | Still **never** "guaranteed", "approved", "100 % accepted", "government-compliant" | Never predicted |
| Privacy | Headline-level promise: "Your photo stays on your iPhone for the core workflow." | Repeated at the moments it matters (permissions, import, export) |
| Commercial | "No ads. No subscription." as a **supporting** proof point, only while true (BD-030, Working) | Plain credit wording; no prompt right after success (rule 11) |
| Technology | No AI framing (BD-013) | No AI framing |
| Tone | Confident, still calm; no hype adjectives, no emoji | Calm and concise |

Marketing may compress; it may not contradict the product. Any claim that would be false inside the app is false in an advert too. Final public wording for pricing and "no ads" remains subject to implementation and App Store review (foundations §17).

---

## 8. Naming

- **Calipic** is never translated, transliterated, pluralized or given an article. No possessive branding of features ("Calipic Check" — no; BD-027).
- Consumer descriptor: **Calipic — ID Photos** (BD-028). The descriptor *is* localized; the name is not. Working localizations, to be validated against App Store search behavior: `Calipic — Fotos de carnet` (es-ES), `Calipic — Fotos para documentos` (es-419 and pt-BR). Write the descriptor exactly as BD-028 does. (Foundations §15 asks for an en dash in formal typography while every document, including BD-028, writes it with an em dash — see open point 6.)
- Inside the product, prefer "the app" or no subject at all over repeating the brand name. The brand name belongs on the Home title, About, App Store and marketing.
- Feature names are descriptive, in sentence or title case per platform convention, and are translated as ordinary words: Photo Check, Background, Position, Print Sheet, Requirements.
- Document names keep their local official form (DNI, RG, CPF, passport → pasaporte / passaporte).
- Technical identifiers (repository, bundle ID, targets) are not renamed by this document (BD-001).

---

## 9. Localization notes

General:

- Write the English source so it translates: short sentences, no idioms, no sentence built from concatenated fragments, placeholders with positions (`%1$@`).
- Translate the *instruction*, not the words. Each language gets the direct, calm imperative that a native iOS app would use.
- Use the iOS system term for system things (Settings, Photos library, AirPrint dialog options) exactly as Apple localizes them in that language.
- Numbers, decimal separators and units follow the locale ("3.5 × 5 in" → "3,5 × 5 in"). Millimeters are the primary unit for photo sizes everywhere; paper sizes follow the market.
- Plurals use automatic grammar agreement or plural variants — never "page(s)".

### 9.1 English (`en`)

- **Open question (founder decision):** the catalog currently mixes British spelling ("colour", "centre", "neutralises", "judgement") with at least one American duplicate ("Recent color photo"). The leading market hypothesis is the United States (BD-032, research in progress). Recommendation: make base `en` American English and add `en-GB` later if the UK tier is pursued. Until decided, do not mix within one build.
- Contractions are fine ("couldn't", "can't") — they support the friendly register.
- Title Case for buttons per iOS English convention; sentence case for everything else.

### 9.2 Spanish (`es`)

- Informal **tú**, imperative: "Aléjate un poco." No "usted", no "por favor" padding.
- Sentence case everywhere, including buttons ("Hacer foto").
- The current catalog is Peninsular Spanish: "móvil", "carnet", "fototeca", "gafas", "cuenta atrás". That is correct for Spain. For US and Latin American Spanish these differ ("celular/teléfono", "lentes/anteojos", "cuenta regresiva", and "carnet" is not a universal category word). Recommendation: prefer wording that is region-neutral where it costs nothing — for example "iPhone" instead of "móvil" — and plan `es-419` (or `es-US`) as a separate localization rather than stretching one `es`.
- Impersonal "se" is natural for what happened ("No se pudo abrir esta foto"); use first-person plural ("No pudimos…") where the English uses an accountable "we". Keep the two consistent per message family.
- Use « » or the iOS-localized option name when quoting print-dialog options.

### 9.3 Portuguese — Brazil (`pt-BR`)

- **Gap:** the string catalog has no `pt-BR` localization at all today, although pt-BR is a launch language (BD-031).
- Address the user as **você**, with the imperative in the third-person form used by iOS in Brazil: "Afaste-se um pouco.", "Segure o iPhone na altura dos olhos.", "Tire a foto."
- Brazilian vocabulary, not European: "celular" (or "iPhone"), "tela", "foto 3x4" is the everyday category term for ID photos and is worth testing for search and headings; "foto para documento" is the neutral descriptor.
- Privacy line: "Sua foto fica no seu iPhone."
- Scope line: "O app formata a foto. Quem decide se ela é aceita é o órgão que a recebe."
- Do not reuse pt-PT translations; do not derive pt-BR mechanically from Spanish.

---

## 10. Audit of existing strings

Source: `Spikes/IDPhotoSpike/App/Resources/Localizable.xcstrings` as of 2026-09-17 (349 keys; `en` source, `es` translated, no `pt-BR`). These are **suggestions only** — this document does not change the catalog. "Stale" means the catalog itself marks the key `extractionState: stale` (no longer extracted from code), so it can probably be removed instead of rewritten; every other audited key is live.

### 10.1 On voice — keep as reference examples

| # | en | es | Why it works |
|---|---|---|---|
| 1 | "Move a little farther away" | "Aléjate un poco" | The canonical BD-025 instruction: imperative, small, no hedging. |
| 2 | "Your photos stay on your iPhone." | "Tus fotos se quedan en tu iPhone." | Privacy as a concrete fact (BD-014). No locks, no "secure". |
| 3 | "The app formats the photo. Acceptance is decided by the office that receives it." | "La app da formato a la foto. La aceptación la decide la oficina que la recibe." | Exact BD-008 scope statement: says who decides, promises nothing. |
| 4 | "Everything we can measure is fine. Also check by eye: neutral expression, eyes open, no glare on glasses." | "Todo lo que podemos medir está bien. Revisa también a ojo: expresión neutra, ojos abiertos, sin reflejos en las gafas." | Accountable "we", separates measured from manual, keeps manual checks visible on success. |
| 5 | "The face is dark. Face a window or a lamp and retake." | "La cara está oscura. Ponte frente a una ventana o una lámpara y repite la foto." | Rule 8 in two sentences: what happened, what to do. Describes the photo, not the person. |
| 6 | "Evens out exposure and removes colour tints. Nothing on your face is retouched." | "Iguala la exposición y elimina dominantes de color. No se retoca nada de tu cara." | States BD-007 as user-facing reassurance without technology words. (Spelling: see 9.1.) |
| 7 | "Print at Actual Size (100 %), not Fit to Page. Then measure the 50 mm bar before cutting." | "Imprime a tamaño real (100 %), no «Ajustar a la página». Después mide la barra de 50 mm antes de cortar." | Real precision, verifiable by the user (rule 2, rule 10). |

### 10.2 Suggested rewrites

| # | Current en / es | Issue | Suggested en / es |
|---|---|---|---|
| 8 | "This photo is unlikely to be accepted. A new one takes a minute." / "Es poco probable que acepten esta foto. Hacer otra lleva un minuto." | Predicts the office's decision. BD-008 cuts both ways: Calipic cannot forecast rejection any more than acceptance. The second sentence is excellent — keep it. | "This photo has problems we can't fix. A new one takes a minute." / "Esta foto tiene problemas que no podemos corregir. Hacer otra lleva un minuto." |
| 9 | "Something went wrong while preparing the files." / "Algo falló al preparar los archivos." | Vague; ends on the failure; no action (rule 8). | "We couldn't prepare the files. Try again." / "No pudimos preparar los archivos. Inténtalo de nuevo." |
| 10 | "The operation could not be completed. Try again or choose another photo." / "No se pudo completar la operación. Inténtalo de nuevo o elige otra foto." (generic fallback) | "The operation" is system language. | "We couldn't finish preparing this photo. Try again or choose another photo." / "No pudimos terminar de preparar esta foto. Inténtalo de nuevo o elige otra." |
| 11 | "The background could not be separated in this photo, so the original is kept." / "No se pudo separar el fondo en esta foto, así que se conserva el original." | Correct and honest, but passive. Foundations §14 gives this exact case as the model for "we". | "We couldn't separate the background cleanly, so we kept the original." / "No pudimos separar bien el fondo, así que conservamos el original." |
| 12 | "This image is too large for this prototype. Choose a photo under 80 megapixels and 150 MB." / "Esta imagen es demasiado grande. Elige una foto de menos de 80 megapíxeles y 150 MB." | "Prototype" is internal language. The Spanish already drops it — align English with Spanish. | "This image is too large. Choose a photo under 80 megapixels and 150 MB." / (es unchanged) |
| 13 | "Check your face, lighting, and background. This prototype formats your photo; it does not check official acceptance." (stale) and "What this prototype does" (stale) | Same "prototype" leak; superseded by "What the app does" and row 3. | Remove if unused. Otherwise: "Check your face, lighting, and background. The app formats your photo; it does not decide acceptance." / "Revisa la cara, la luz y el fondo. La app da formato a la foto; no decide la aceptación." |
| 14 | "Print at Actual Size / 100%. Disable Fit to Page and measure a copy before use. Physical print accuracy still needs testing." / (es omits the last sentence) (stale) | Development note exposed to users, and en / es disagree in meaning. Row 7 already says this correctly. | Remove if unused; otherwise reuse row 7. |
| 15 | "Crop and export only. Your original background is preserved. Face analysis and background correction are not included yet." / "Solo encuadre y exportación. Se conserva el fondo original." (stale) | Roadmap and technology wording ("face analysis"); en / es disagree. | Remove if unused. |
| 16 | "Foto carnet sheet" (en source, used as the print-job name) / "Hoja de fotos de carnet" | Mixed-language English; the job name is visible in the print queue. | "ID photo sheet" (or "Calipic — ID photo sheet") / (es unchanged) |
| 17 | "Foto carnet" → en "ID Photo" / es "Foto carnet" (app title) | Pre-brand working title. BD-001: the consumer name is Calipic, never translated. Not an automatic rename — do it with the app-rename decision. | "Calipic" in every language, with the localized descriptor where a subtitle exists. |
| 18 | "Manual review needed" / "Necesita revisión manual" (stale) | Bureaucratic next to the app's own, better phrase "check by eye" / "needs your judgement". | Remove if unused; if the state returns, "Check this by eye" / "Revísalo a ojo" |
| 19 | "Top of head estimated from face proportions" / "Parte superior de la cabeza estimada por las proporciones de la cara" | Technical diagnosis without an action (rules 6 and 8). The uncertainty is worth keeping; the mechanism is not. | "The top of the head is estimated. Check the space above it by eye." / "La parte superior de la cabeza es una estimación. Revisa a ojo el espacio sobre ella." |
| 20 | "Framed to the official size; the head fills %lld%% of the photo." / "Encuadrada al tamaño oficial; la cabeza ocupa el %lld%% de la foto." — and its sibling "The head cannot be framed to the official size. Retake a little farther away." / "No se puede encuadrar la cabeza al tamaño oficial. Repite la foto un poco más lejos." | Borderline, not wrong: the size *is* officially sourced. But "official" next to the output can read as an approval (6.1 rule 3). | "Framed to the required size; the head fills %lld%% of the photo." / "Encuadrada al tamaño requerido; la cabeza ocupa el %lld%% de la foto." Sibling: "The head cannot be framed to the required size. Retake a little farther away." / "No se puede encuadrar la cabeza al tamaño requerido. Repite la foto un poco más lejos." Change both or neither. |
| 21 | "Hold the phone at eye level" / "Sujeta el móvil a la altura de los ojos" (and other "móvil" strings) | On voice in both languages. Localization only: "móvil" is Spain-specific (9.2). | en unchanged / "Sujeta el iPhone a la altura de los ojos" |
| 22 | "Recent color photo, facing forward" **and** "Recent colour photo, facing forward" (both keys exist; the American one is stale) | Duplicate keys with different spelling; symptom of the undecided English variant (9.1). | Keep one after the en-US / en-GB decision. |
| 23 | "%@ · %lld copies · %lld page(s)" / "… %lld copias · %lld página(s)" | "page(s)" is a machine plural. Inflected variants of these keys already exist in the catalog. | Both "(s)" keys are stale; remove them. The `^[%lld page](inflect: true)` variants are the model for future counts. |
| 24 | "The exported file could not be verified. Please try again." / "No se pudo verificar el archivo exportado. Inténtalo de nuevo." | "Please" is padding the rest of the catalog avoids; "verified" is certificate-adjacent wording (6.1 rule 6) even though here it only means a file check. | "We couldn't check the exported file. Try again." / "No pudimos comprobar el archivo exportado. Inténtalo de nuevo." |

### 10.3 Patterns seen across the catalog

- The catalog is already largely on voice: direct imperatives, no AI vocabulary, no humor, no guarantee language, visible manual checks. The problems are edges — generic error fallbacks, leftover prototype wording, and one prediction of rejection.
- "We" is used once ("Everything we can measure…") and works. Extending it to the handful of "could not be…" failures where Calipic is the actor would make the voice more consistent. It should not replace neutral descriptions of the photo ("The face is dark").
- Capture-ring help text explains a color key (grey / orange / green). The words are fine; [`15-brand-qa-checklist.md`](15-brand-qa-checklist.md) covers the requirement that the same states are never color-only on screen or in VoiceOver.
- `pt-BR` is entirely missing and should be written natively from this document, not converted from `es`.

---

## 11. Open points

1. American vs British English for base `en` (9.1) — founder decision.
2. One `es` vs `es-ES` + `es-419` (9.2) — depends on BD-032 market sequencing.
3. Localized descriptors for "Calipic — ID Photos" (8) — needs App Store search validation.
4. Credit and purchase wording — waits for the StoreKit product decisions referenced in BD-029.
5. Final public "No ads. No subscription." wording — BD-030 is still Working.
6. Dash in "Calipic — ID Photos": foundations §15 says en dash; the written form everywhere is an em dash. Pick one when the wordmark/lockup is specified.

When this draft is accepted, record the acceptance in [`99-brand-decisions-log.md`](99-brand-decisions-log.md) and remove "Draft" from the status line.
