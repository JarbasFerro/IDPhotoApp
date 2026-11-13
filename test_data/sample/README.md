# Sample portrait

An AI-generated image of a person who does not exist (founder decision, 2026-11-13; `docs/05-decisions.md` D-9). It is the public test photo: simulator UI tests use it as the first photo when `test_data/local/portrait.jpg` is absent. `portrait.json` holds its eye, chin and crown positions (normalized, top-left origin), measured with Vision, because Vision cannot run on the simulator.

The Home sample (`SamplePortrait`, `SampleSelfie` in the asset catalog) is the same person.
