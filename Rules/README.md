# Rules catalog

Versioned document-profile data for Calipic, per [05 — Rules engine](../docs/05-rules-engine.md) and AGENTS.md §11. Country and document rules live here as data, never as UI code.

## Layout

```text
Rules/catalog/v1/
├── catalog.json                 # catalog version, the list of profiles, and the default profile per region
├── profiles/<profileId>.json    # one official profile per file
├── custom-size-shortcuts.json   # custom-size shortcuts and options (ADR-018)
└── strings.en.json              # English strings for profile names, checks, notes
```

**Catalog 2026.11.0:** 22 Wave A profiles. The research behind each value is in [docs/profiles](../docs/profiles/README.md).

## Profile model (schema version 1)

| Field | Meaning |
|---|---|
| `profileId` | `<jurisdiction>.<document>.<variant>`. No dimensions in the ID |
| `referenceFrameMm` | The official photo size; `null` for digital-only profiles |
| `outputs` | `print` (size, `minPpi`, `route`: `home` or `shop_only`) and `digital` (pixels, formats, file-size limits). A digital output has `composition` `profile` (the official framing) or `loose` (the receiving service crops) |
| `composition` | Official constraints: `headHeight`, `eyeLine`, `faceWidth`. Each names its landmarks (`crown`, `top_of_hair`, `chin`, `eye_line`, `bottom_edge`, `ear_base`), unit, range, capability, and sources. Unknown values are `null` |
| `framingTarget` | Where the crop solver aims. `official_midpoint` lies inside the official ranges; `app_default` is the app's own choice (head 74 %, eyes 58 % from the bottom) and **never an official claim** |
| `background` | Required appearance, allowed colours, uniformity, shadows, the replacement colour Calipic uses, and the official editing rule, recorded **for reference only** (ADR-051) |
| `checks` | Manual or advisory checks from a shared vocabulary (`eyes-open`, `no-glasses`, …), each with sources |
| `specialCases` | Age-based overrides, for example a baby's eyes or the Netherlands' head size for age 10 and under |
| `profileQuestions` | Questions the app asks for this profile only (for example `age_lte_10`) |
| `sources` | Provenance: authority, title, URL, accessed date, language, type, and how it was retrieved |

Capabilities follow doc 05 §8. No rule is `machine_hard` until a calibrated evaluator exists (AGENTS.md §9); the validator enforces this.

## Validate

```sh
python3 scripts/rules/validate_catalog.py Rules/catalog/v1
python3 -m unittest discover -s scripts/rules -p 'test_*.py'
```

The validator implements doc 05 §12. Among other things it checks:

- ranges and units;
- sources referenced and present;
- localization keys present;
- print and digital aspect ratios against the reference frame;
- pixel and file limits;
- framing targets inside the official ranges;
- that framing targets are physically possible, using the spike's head model (crown to chin = 1.8 × eye to chin, at least 4 % headroom);
- that the index matches the files.

CI runs both on every change (`.github/workflows/rules.yml`).

## In the app

The spike app bundles one generated file, `Spikes/IDPhotoSpike/App/Resources/CalipicCatalog.json`. After changing `Rules/`, rebuild it:

```sh
python3 scripts/rules/build_app_catalog.py
```

CI fails if the bundled copy is stale. The app decodes it in `DocumentProfile.swift`. `DocumentChoice.swift` turns a profile or custom size into a `RenderTarget`: trim format, composition bands and framing target, digital preset, and background colour. Names and check labels are String Catalog keys, translated into Spanish and Portuguese (Brazil).

## Changing a profile

1. Update the research document in `docs/profiles/`.
2. Edit the JSON and bump `profileVersion`: patch for wording, minor for a changed value, major for a changed meaning.
3. Bump `catalogVersion` in `catalog.json`.
4. Run the validator and tests.
5. Rebuild the app catalog (`build_app_catalog.py`), and add String Catalog entries for any new name or check key.
