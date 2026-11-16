# Proposals (cmeprojects)

SQL that is written and tested but **not applied**, because it changes a
permission or a deliberate design rule and needs the owner's decision first.
Nothing here is in the migrations or the fresh install. If approved, it
becomes the next numbered live update (with its migration and tests).

| File | What it would change | Why it's waiting |
|---|---|---|
| update-91/ (migration, update-91.sql, undo-91.sql, check) | The "drivers upload odometer photos" storage policy also requires the Odometer photo setting not to be Off | **Awaiting the owner's review of the files** before update 91 is applied (QA-008 B). The earlier draft files odometer-uploads-follow-setting(-undo).sql are superseded by this folder and kept for history |
| odometer-default-off.sql | New copies start with the Odometer photo setting Off (migration only) | **Done (16 Nov 2026)**: became migration 20270204000001_odometer_default_off.sql |

(managers-act-on-unmanaged-registers was approved on 15 Nov 2026 and became live update 83.)
