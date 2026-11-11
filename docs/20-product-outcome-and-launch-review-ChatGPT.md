# 20 — Product outcome review and proposed launch contract

**Reviewed:** 2026-11-11
**Status:** Proposal for documentation and delivery changes; not an accepted ADR or evidence of release readiness.
**Objective:** Make Calipic the preferred iPhone app for taking excellent document photos at home and producing usable physical copies, through ease, trustworthy assistance, satisfying results, and visual quality.

## 1. Review conclusion

The repository has substantial capability and a strong privacy/correctness foundation. The next investment should make the complete home-photo-to-physical-copy journey dependable and easy to understand. Additional camera effects alone will not establish product leadership.

The brand constitution already states the right ambition: finish the real-world job and make satisfaction the outcome. Product requirements, release gates, and the backlog need to operationalize that ambition consistently. “#1” is an aspiration, not a claim established by this review. Define the category, territory, and comparison method before using any leadership claim publicly.

Review method: documentation review plus source inspection of the spike's workflow, output, print, and presentation surfaces. No app build, physical-camera assessment, printer test, competitive benchmark, or current official-rule verification was performed. Existing “implemented” statements describe prototype capability, not production acceptance.

## 2. Findings and concrete documentation changes

| Priority | Repository evidence | Risk | Proposed change |
|---|---|---|---|
| P0 | [README](../README.md) describes the first import/crop spike; [delivery plan §16](06-delivery-plan.md#16-immediate-next-development-step) still says create the spike; [spike README](../Spikes/IDPhotoSpike/README.md) lists much more functionality | Work can restart completed prototyping or mistake it for validated production | Replace stale next actions with the evidence-closing sequence in §8. Track implementation and validation separately. |
| P0 | [Brand constitution rules 10–11](brand/02-experience-constitution.md) demand real-world completion; [ShareView](../Spikes/IDPhotoSpike/App/Features/ShareView.swift) prepares files and displays brief print advice; [PrintController](../Spikes/IDPhotoSpike/App/Features/PrintController.swift) logs the completion callback | A correct PDF can still produce unusable physical photos; the user lacks an explicit recovery journey | Specify print preparation, mismatch recovery, measuring, cutting, and optional user-confirmed outcome (§5). File readiness and printer submission must not imply physical success. |
| P0 | ADR-015 is Deferred while BD-029 accepts credits as product direction | A launch-critical purchase experience and accounting policy can be overlooked | Reconcile the records without reopening the accepted direction; decide charge unit, retry/reprint policy, offline entitlement behavior, and purchase states before implementation. |
| P0 | ADR-016 selects Spain; BD-032 lists US priority as research in progress | Market positioning, profile coverage, screenshots, and test recruitment can diverge | Preserve Spain as the current accepted delivery scope. Separately decide commercial launch territories and profile coverage; research cannot silently supersede an ADR. |
| P1 | [Doc 16](16-screen-experience-spec.md) details the spike; §15 leaves future screens for amendment | No single inventory covers the complete launch product | Adopt the function/screen register in §4 and add production-only contracts before coding them. |
| P1 | [Doc 15](15-experience-plan.md) preserves older ring/flow proposals; doc 16's top flow omits the still review required by ADR-045; docs 18–19 contain superseded research | An implementer can build from obsolete prose | One active screen contract, with ADR-043–046 precedence and explicitly historical research. Include Retake / Use Photo in every current journey. |
| P1 | [Product metrics](01-product-definition.md#12-success-metrics) cover exports and geometry; doc 15 claims under 60 seconds without evidence | Optimizing clicks or effects can hide poor capture or print outcomes | Add observed task completion, print usability, confidence comprehension, satisfaction, and appearance evaluation (§7). Treat timings as hypotheses until measured. |
| P1 | [Brand foundations §10](brand/01-brand-foundations.md#10-design-decision-hierarchy) lists beauty above accessibility, while AGENTS and the constitution require equivalent functionality | Ambiguous prioritization during polish | Clarify that accessibility is a mandatory acceptance constraint; compare aesthetics only among accessible, correct alternatives. |
| P1 | [Spike data lifetime](../Spikes/IDPhotoSpike/README.md#data-lifetime) is temporary; experience plans mention continuing sessions | Users may expect durable photo history or later reprints | State that current resume is within the active session. Decide durable drafts separately; no silent permanent face-photo storage. |

## 3. Product promise and scope

Proposed promise: **“Take a document photo you feel good about, with guidance at every step, and print correctly sized copies at home.”** Follow it with clear limits: supported document profiles, on-device processing, by-eye checks, and no acceptance guarantee.

Prioritize outcomes in this order: usable and truthful result; easy capture and printing; equivalent accessibility; perceived photo quality and confidence; visual polish and meaningful delight. Privacy, identity preservation, and deterministic geometry remain constraints throughout.

### Recommended launch boundary

- Deliver one complete, sourced Spain DNI flow first, as ADR-016 requires. A multi-country catalog is an expansion, unless a new decision changes launch scope.
- Keep both digital and print outputs. Digital output does not imply that a receiving authority accepts online submissions.
- Preserve multi-person sheets already prototyped, with clear per-person checks and counts. Supporting several adults does not establish baby/child compliance.
- Maintain English, Spanish, and Brazilian Portuguese (BD-031). Localized language is not evidence of that country's profile coverage.
- Keep reversible crop/straightening, policy-permitted background replacement and tone adjustment, original comparison, and actionable retake guidance.
- Retain the accepted credit direction (BD-029); commercial mechanics remain a launch decision. Do not invent a subscription or make payments determine compliance.
- Defer broad country expansion, optional generative explanations, new decorative effects, and extra integrations until the core outcome passes. Any removal of an existing MVP requirement, such as the profile picker or App Intent gate, needs an explicit scope amendment.
- Decide baby/child support, custom official-photo sizes, persistent drafts, and manual mask refinement explicitly. If an allowed background cannot be produced safely, keeping the original or retaking must remain available; expansion of refinement cannot be assumed complete.

## 4. Complete function and screen register

This is a launch coverage map, not a claim that all rows exist. **Prototype** means source or existing evidence describes the capability; device/release validation remains open. **Planned** means production work; **Decision** means scope or behavior must be settled. Standard sheets and inline states are surfaces, not automatically new navigation screens.

| ID / function | Surface, primary action, and destination | Required behavior and recovery | Baseline |
|---|---|---|---|
| F01 Start / resume | Home → Take Photo or Choose Photo; active session → Your Sheet | Clear supported profile, privacy, version; loading/error/session-limit reason; no implied durable history | Prototype |
| F02 Choose document | Home profile card → Requirements; catalog search only if multiple profiles ship | Country/document/version/source/date; unavailable profile cannot masquerade as a supported one; changing profile re-evaluates edits and output | Fixed profile prototype; catalog planned/scope decision |
| F03 Prepare environment | Before your photo → chosen acquisition | Short advice on light, background, lens height and distance; optional full requirements; switch source/cancel retains add/replace context | Prototype; usability validation open |
| F04 Guided capture | Camera → shutter; Help → optional auto capture | Front/rear camera; one stable actionable cue; meaningful readiness; permission recovery, interruptions and import fallback; accessible cues and manual shutter | Prototype |
| F05 Inspect captured still | Camera review → Use Photo or Retake | Show actual still, preserve expression inspection, no premature approval; Retake stays in camera | ADR-045 / prototype |
| F06 Import | System PhotosPicker → analysis | Orientation/format/large-file handling; cancel retains previous result; unavailable iCloud asset gets honest download/retry guidance | Prototype |
| F07 Prepare photo | Inline analysis → Photo Check | Automatic framing and permitted processing; cancellable/revision-bound; source retained; no-face/multiple-face/unavailable analysis stays explicit | Prototype; calibration open |
| F08 Understand result | Photo Check → Continue → output choice | Four requirement states; plain summary and by-eye checks; fix/retake/requirements links; no false acceptance; technical export failures cannot proceed as success | Prototype; blocking-state specification open |
| F09 Correct / compare | Adjust sheet → Done → Check | Crop/zoom/straighten/auto/reset; Original/White and tone only when allowed; visible comparison action plus gesture; non-gesture controls; warn on inadequate source detail; recheck changed edits | Prototype |
| F10 Refine difficult edges | Conditional correction/help within Adjust | Preserve hair, ears, glasses, coverings; accessible alternative; iOS fallback; original/retake if unsafe | Decision; quality evidence open |
| F11 Choose output | Choose result → Digital Photo or Your Sheet | Use selected person; Back preserves work; no forced print setup for digital | Prototype |
| F12 Save digital photo | Digital Photo → native share/save | Reopened/verified file, format and dimensions; retry failure; share cancellation is neutral; file lifetime covers destination activity | Prototype; destination validation open |
| F13 Compose copies | Your Sheet → Continue | True-proportion preview; people, copies, paper, orientation, cut guides and pages; advanced controls disclosed; zero/overflow/invalid sizes explain recovery | Prototype |
| F14 Add / replace / remove person | Sheet or Check → acquisition / confirmation where needed | Per-person source, edits and count; no cross-person stale updates; replacement cancel retains previous photo; removing last person gives useful empty state | Prototype |
| F15 Prepare physical printing | Print result → Print; alternative Share PDF / page JPEG | Match loaded paper; distinguish copies per person from repeated whole sheets; no inferred printer discovery; mismatch/unavailable route | Basic prototype; guided support proposed |
| F16 Measure / cut / recover | Print result → Check printed size / Printing help | §5; optional confirmation, useful failed-print recovery, reprint current verified output without reacquiring photo | Proposed |
| F17 Complete / repeat | Result → Done or Make another | Separate files ready, handoff, and optional physical confirmation; do not claim a print from a callback; explain session lifetime | Partial prototype; proposed clarification |
| F18 Help / privacy / support | Context help; durable Help/About entry | Supported scope, manual checks, print troubleshooting, data deletion/lifetime, support/privacy links; no automatic portrait attachment | Camera help prototype; wider help planned |
| F19 Preferences / identity | App Icon; appropriate system settings links | Current choice, failure recovery, accessible labels; no configuration needed for main task | App Icon prototype |
| F20 Credits / purchases | Visible price/credit information → native StoreKit purchase | Free allowance, cost before commitment, cancelled/pending/failed purchase, retry, reconciliation and offline behavior; no loss/double charge on export failure | Direction accepted; mechanics/screens unimplemented |
| F21 System entry points | Approved App Intent / deep link → supported profile/acquisition | Same permission/preflight/source lifecycle; unavailable/deleted profile recovery; no face indexing | Planned; launch scope confirmation |
| F22 Background / restart / deletion | All surfaces, contextual progress or recovery | Cancel or safely resume work per declared retention; protected storage cleanup; no stale results, unintended exports, or hidden permanent drafts | Prototype foundations; production validation open |

For each row, expand doc 16 with: purpose, entry/exit, exact controls and catalog keys, default values, loading/empty/error/permission/interruption/cancellation states, Back/Done semantics, retained data, accessibility focus/announcements, source file, requirement IDs, and acceptance evidence. Extend [screen states](ui/screen-states.md) rather than maintaining a second competing state matrix here.

## 5. Customer journey, including the physical outcome

1. **Discover and decide.** Store listing states supported document(s), home-print capability, privacy and price/free allowance accurately. The customer can determine suitability before investing effort. No broad “passport compliant” claim from a shared size.
2. **Prepare.** Home makes the supported task obvious. Preflight provides a short practical setup, with guidance for self-capture and another person taking the photo. Show fuller help only when needed.
3. **Capture confidently.** Camera gives one achievable correction at a time. Optional auto capture is explicit; the manual shutter remains available. Actual still review lets the user decide whether they like the expression before processing.
4. **See an honest improvement.** Analysis produces a framed result and permitted correction. Compare is reversible and accessible. If the input is unsuitable, explain the smallest useful retake change; never disguise identity-changing repair as quality improvement.
5. **Understand readiness.** Photo Check explains measured results and unresolved manual checks. Continue reaches the accepted output choice. A serious source problem remains visible even when the user can export a technically valid file.
6. **Produce output.** Digital users share a verified file. Print users choose real paper and copy counts, see exactly what fits, and add other people without restarting the session.
7. **Print at home.** Before system printing, confirm the intended paper and explain the controls relevant to the actual route. Do not promise an Actual Size switch exists in every print dialog. If the printer/driver cannot preserve sizing, offer the PDF route with instructions for a compatible viewer and loaded paper. Do not silently scale a page to fit.
8. **Check and cut.** Offer “Check printed size” and “Printing help” from the print result. Ask the user to measure the calibration bar when enabled and a photo's width/height, then cut at the trim marks, not the bleed edge. Explain photo-paper suitability from the selected profile; unspecified requirements remain manual checks. The app cannot verify ink, paper, colour, or physical dimensions remotely.
9. **Recover without starting over.** Wrong size → inspect paper/scaling/borderless behavior, then reprint one test sheet; poor colour/detail → inspect source and printer settings; printer unavailable → retain result while active and share PDF. Do not compensate with guessed dimension changes. Retrying output must follow the agreed credit policy.
10. **Finish with confidence.** “Your files are ready” describes file generation. A printer handoff is a separate state. An optional user report that a print looks right is feedback, not certification. Done returns Home; support and a new task remain easy to find without an immediate rating/paywall interruption.

First-time, returning-in-session, import-only, multi-person, denied-permission, offline-with-local-input, VoiceOver and failed-print paths must all reach a useful outcome. After app restart, do not promise recovery beyond the chosen storage policy. Persistent drafts need an explicit privacy/retention ADR and deletion UI.

## 6. Satisfaction and aesthetic contract

Keep ADR-045/046: actual-still review, restrained bloom and one haptic, no custom verification theatre. Research documents 18–19 are not instructions to add effects beyond those decisions.

| Moment | User benefit and truthful trigger | Reduced-motion / accessible equivalent | Reject when |
|---|---|---|---|
| “It helped me take a better photo” | A stable useful camera cue leads to a visibly improved source; readiness means measured live checks only | Same concise spoken instruction and explicit shutter | Guidance oscillates, obscures expression, or makes an incorrect confident claim |
| “It prepared that for me” | Analysis completes and the actual solved framing/allowed correction is revealed; comparison explains what changed | Immediate prepared image, labeled Compare control and concise status | Artificial delay, face alteration, mask damage, or success before processing |
| “All our copies fit” | Real sheet rearranges after paper/count changes; exact page/copy summary stays visible | Static new layout plus accessible count/page summary | Motion hides overflow, shrinks physical photo sizes, or wastes paper silently |
| “I finished it myself” | Verified output and understandable print checking/cutting complete the job | Plain result and next action; no haptic dependence | A share dismissal is treated as successful printing or a commercial prompt interrupts relief |

Aesthetic acceptance: portrait/paper is visually primary; one dominant action per state; system typography and controls; approved restrained teal; legible skin/hair edges; intentional Light/Dark appearance; consistent spacing and transitions; understandable failure states. Judge using realistic consented portraits privately as well as synthetic fixtures. An attractive synthetic screenshot alone does not establish photographic quality.

Do not redesign the accepted brand or add effects just to create a “wow”. Validate whether people notice usefulness, feel in control, and like the result. Accessibility, contrast and reduced-motion behavior are release constraints, not optional aesthetic compromises.

## 7. Evidence and success measures

Use observed task studies and opt-in interviews first; no analytics SDK is required. Store aggregate counts/timings and de-identified findings, not photos, facial geometry, personal identifiers or sensitive paths. Agree retention/consent before collecting study artifacts. Any production telemetry follows doc 08 and its decision process.

| Outcome | Measure and definition | Proposed gate / interpretation |
|---|---|---|
| Ease | Unassisted verified-output completions / all attempted tasks, split by capture/import and digital/print | First formative round: at least 8/10 representative first-time participants complete the core task unaided. Directional evidence, not a population claim; fix all blocking observations and repeat affected tasks. |
| Physical success | Correctly sized and usable cut copies / attempted home-print tasks, including abandoned/failed attempts | Test at least two physical printers as already required; record paper/route/settings and measured dimensions. Zero unexplained out-of-tolerance output in the release matrix. Set numerical tolerance from the engineering/profile evidence before testing, never after seeing results. |
| Effort | Retakes, manual adjustments, paper sheets wasted, help requests, and abandonment reasons per task | Compare against the current spike baseline; fewer steps cannot compensate for poorer output. |
| Speed | Time from task start to verified file; separately setup, capture-to-still, processing, print and cutting | Record median and slow cases; under-60-second export is a hypothesis, not a promise or whole-print budget. Establish device budgets from measurements. |
| Satisfaction | Post-task ease and satisfaction ratings (1–5), plus “What felt especially helpful or frustrating?” | Proposed formative target: at least 8/10 rate ease and satisfaction 4 or 5; report counts and objections, not just an average. |
| Trust | Participant explains what Ready means and what still needs checking | Any observed belief in guaranteed acceptance triggers copy/flow revision and retest before release. |
| Visual quality | Structured review of portrait integrity, mask edges, colour, layout and visual hierarchy | No unresolved identity-changing artifacts or critical legibility defects; include varied skin tones, hair, glasses and head coverings. Calibrated checks stay separate from subjective preference. |
| Accessibility | Observed task completion with VoiceOver/Voice Control, largest text, reduced motion and contrast settings | Equivalent critical tasks; automatic audits alone are insufficient. Recruit relevant users and report separately from the general usability sample. |
| Leadership | Future benchmark of the same task, profiles and print routes against alternatives | Define market and sample first. Ranking/downloads and user preference are different measures; this review establishes neither. |

Each evidence record needs build/commit, OS/device or printer, profile version, scenario, expected/observed outcome, defect links, reviewer, and retest status. Physical and personal-photo evidence stays outside the public repository; commit only safe summaries and synthetic artifacts.

## 8. Ordered work from today to launch

These proposed work packages refine M1–M8, not a second milestone numbering system. Owner labels are accountable roles to assign, not claims that staff already exist. No launch date until the blocking evidence is available.

| Package / milestone | Work and owner | Depends on | Exit evidence |
|---|---|---|---|
| L01 — Scope and document reconciliation / M0–M1 | Product: resolve jurisdiction versus commercial-market plan, children/custom-size scope, credit mechanics, retention and launch integrations; reconcile docs using §9 | This review | Accepted decisions; one complete launch feature register; no contradictory active flows |
| L02 — Complete feasibility evidence / M1 | iOS + QA: measure camera/analysis/segmentation/48 MP memory/cancellation on older/current supported phones; real share lifetime; two-printer measurements; accessibility task tests | Current spike; profile research can run alongside | Updated spike reports with measured results and explicit remaining limitations; approved platform/fallback decisions; no unproven feasibility blocker |
| L03 — Production foundation and sourced profile / M2 + M4 | iOS + rules reviewer: deliberately promote reviewed components, establish domain boundaries, versioned provenance/policy, tests/CI, privacy/localization and source lifecycle | L01 and relevant L02 gates | Clean build/test evidence; audited profile; no hard-coded official UI claims; production dependency map |
| L04 — Complete acquisition-to-result / M3 + M5 | iOS + UX: F01–F12, replacement/recovery, accessible controls, calibrated checks and reliable permitted processing | L03 | Camera/import/retake/manual-check scenarios pass; actual still review; no stale overwrite; representative source-quality assessment |
| L05 — Complete home printing / M6 | iOS + QA + UX: F13–F17, actionable mismatch/error guidance, measurement/cutting support, truthful print result and repeat output | L03 and L04 output contract; prototype testing starts in L02 | Independent users obtain measured usable copies; PDF/JPEG verification and printer matrix pass; digital path remains direct |
| L06 — Commercial and support readiness / M5–M7 | Product + iOS: F18–F21 as scoped, StoreKit/free allowance/credits, price copy, cancellation/pending/offline/reconciliation, localized help/support | L01 policy and L03 foundation; can run alongside L04–L05 | Purchase failure/retry cannot double-debit or lose paid output; entitlement behavior documented; support does not require portraits; launch language review |
| L07 — Experience acceptance / M5–M7 | UX + QA: run §7 studies; improve defaults, copy, portrait presentation, meaningful transitions and recovery | Complete L04–L06 journey | Task evidence and closed blockers; visual/state matrix; no misleading readiness or physical-success claims |
| L08 — Release candidate / M7 | QA + iOS + rules reviewer: reliability, interruptions, offline paths, thermal/performance, privacy cleanup/metadata, accessibility, profile freshness, minimum/current OS | L02–L07 | Device and print gates pass; no P0 or correctness/privacy/data-loss/accessibility P1; exact build/profile evidence; TestFlight feedback resolved |
| L09 — Store release / M8 | Product + release owner: final screenshots/copy, territories, prices, privacy/support disclosures, review configuration, supported release toolchain, archive and review | L08 | Store claims match tested scope; approved release; hotfix/support ownership and withdrawal criteria ready |
| L10 — Launch follow-through / M8 completion | Product + QA: triage output failures/support, rule drift, purchase issues and user-reported outcomes; prioritize fixes before profile expansion | L09 | Early launch review with aggregate evidence and assigned fixes; severe wrong-size/privacy/charge failures trigger release action, not marketing expansion |

Immediate implementation order after review: reconcile decisions and create traceable work items; close physical evidence gaps with the existing spike; establish the production profile/foundation; complete the home-print recovery journey; then finish commercial/support and run end-to-end acceptance. Visual refinement occurs within each slice, not as a final cosmetic pass.

## 9. Exact documentation migration plan

Avoid maintaining another permanent parallel specification. After decisions are accepted, distribute this proposal into the existing authorities and leave this file as the dated review record.

| Document | Amendment |
|---|---|
| README | Lead with the home capture-and-print promise; accurate M1 capability/evidence status; current next step; link this proposal while under review. |
| 01 Product | Adopt promise, outcome definitions, launch boundary, complete customer journey and study metrics; distinguish aspiration from measured claims. |
| 02 Requirements | Give accepted F01–F22 additions stable FR identifiers, priority, defaults and pass/fail criteria; especially physical completion, recovery, credits and retention. Link existing requirements instead of duplicating them. |
| 03 Architecture | Add typed print-handoff/outcome states and error propagation; credit transaction policy and idempotency design if monetized; explicit draft/session lifecycle. Keep photo processing independent from purchasing. |
| 04 UX + 16 Screens | Doc 04 owns journey/principles; doc 16 owns every surface and exact action/state/copy contract. Include captured-still review and conditional launch screens from §4. |
| 05 Rules + 13 Spain | Complete source/review/version and alteration policy validation; distinguish physical specification, engineering export defaults and official digital channels. No new official rule is asserted by this proposal. |
| 06 Delivery | Replace obsolete create-spike instruction; map L01–L10 into M1–M8 with dependencies, owners and exit artifacts. Bring physical printing evidence forward, while preserving production gates. |
| 07 Testing | Add task studies, satisfaction rubric, physical-print recovery tests, subjective photographic review and credit failure scenarios; retain deterministic/calibration/accessibility testing. |
| 08 Privacy | Clarify session/history/reprint lifecycle and study-artifact policy; review any proposed diagnostics or purchase storage; preserve offline core processing. |
| 09 Backlog | Map each accepted F row to existing epic IDs plus genuinely missing tickets. Add owner, status, dependencies, acceptance and evidence link. Separate implemented prototype from accepted production. |
| 10 Decisions | Reconcile ADR-015 with BD-029; explicitly resolve market, child/custom-size, persistence, integration and paid-output mechanics. Do not mark a proposal accepted by editing prose. |
| 11 Excellence | Tie signature experiences and native integrations to observed task value; make physical outcome and accessible equivalents release gates. |
| 12–14, 17 | Retain useful spike research and immediate implementation detail; date stale baseline statements and point current work to the active backlog. |
| 15, 18, 19 | Historical/research labels at the top and at superseded implementation recipes; link current ADRs and screen contracts. No new choreography from abandoned proposals. |
| UI evidence/states + brand docs | Include all accepted launch surfaces and appearance/accessibility combinations; clarify accessibility as mandatory in brand hierarchy; preserve accepted identity rather than restarting branding. |

Documentation done means every launch function has one canonical behavior description, exact screen states, linked requirements/backlog items and an evidence gate. “Implemented,” “validated on device,” “validated in real printing,” and “release accepted” must be separate fields. Unresolved decisions have an owner and blocking milestone; none can disappear behind a green completion label.
