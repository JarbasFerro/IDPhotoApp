# 13 — Spain foto carnet: initial profile research

**Scope confirmed:** 2026-09-15  
**Source reviewed:** 2026-09-15  
**Status:** Research draft; not a published compliance profile.

## 1. First-release format

The user selected Spain and “foto carnet”, 32 × 26 mm. Implement the portrait format with explicit axes:

- `physicalWidthMm`: 26
- `physicalHeightMm`: 32
- Width-to-height ratio: 13:16

“Foto carnet” is the user-facing format description. DNI is the initial official research reference. Publish document-specific claims only after validating that profile; other Spanish document types are not automatically covered by matching dimensions.

## 2. Authoritative reference

[Ministerio del Interior — Documentación necesaria para la tramitación de la versión física del DNI](https://www.interior.gob.es/opencms/es/servicios-al-ciudadano/tramites-y-gestiones/dni/documentacion-necesaria-para-su-tramitacion/), first-inscription and renewal sections, reviewed 2026-09-15.

Source summary:

- Recent color portrait, 32 × 26 mm, facing forward against a plain, uniform white background.
- Facial identification must remain unobstructed; eyes should be visible and open.
- Religious/medical head coverings and certain medically justified dark glasses have explicit exceptions. Preserve these in manual guidance; avoid blanket automated rejection.
- Some equipped offices can capture the photograph themselves, including direct capture even when a photo is supplied.

The source states the dimension pair. The renderer explicitly records the portrait interpretation as width 26 mm, height 32 mm to prevent axis reversal.

## 3. Requirements still unknown

The reviewed page does not establish numeric head-height/eye-line bounds, exact RGB values, export pixel dimensions, PPI, JPEG quality, or file-size limits. Leave these unset as official constraints. Any app-selected rendering defaults must be labeled as implementation choices.

Background replacement permission is not established by a requirement for a white background. Record replacement policy as `unknown`; retain the original and prioritize capture against a suitable background. Segmentation research can proceed using explicitly nonofficial fixtures while official editing policy is researched.

Photo recency and exception eligibility require human review. Face observations alone cannot certify these. Child/baby launch coverage remains unresolved under ADR-017.

## 4. Implementation acceptance targets

1. Keep width and height explicit through crop, preview, raster rendering, and PDF layout; test axis reversal and orientation metadata.
2. Preserve the source and render a 13:16 portrait crop non-destructively.
3. Reopen JPEG exports and verify output dimensions/format/orientation and metadata stripping. Choose pixel dimensions and rounding policy explicitly; do not describe an app PPI setting as an official requirement.
4. Place each PDF photo in a 26 × 32 mm rectangle. Test mm-to-PDF-point conversion and measure a physical print at 100% scaling; document printer, paper, scaling, and tolerance.
5. Keep manual checks visible alongside measurable checks. No guaranteed-acceptance claim.
6. Validate the source-to-schema interpretation before activating an official catalog entry, including exception wording and background-edit policy.

Digital export supports saving/sharing the image. This research does not establish a government online-upload workflow.

## 5. First physical test setup

- **Device:** iPhone 15 Pro Max.
- **OS:** iOS 26.6.2, user-reported.
- **Toolchain:** Xcode 27.0 (27A266a), verified 2026-09-16; see [the kickoff plan](12-implementation-kickoff.md).
- **First device run:** verify signing/pairing, photo-picker import, camera permissions/capture, portrait orientation, cancellation, and export.
- **Evidence still needed:** device benchmarks, accessible task completion, physical print measurement, additional hardware tiers, and iOS 27 runtime checks.
