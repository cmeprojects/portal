# Proposals (cmeprojects)

SQL that is written and tested but **not applied**, because it changes a
permission or a deliberate design rule and needs the owner's decision first.
Nothing here is in the migrations or the fresh install. If approved, it
becomes the next numbered live update (with its migration and tests).

| File | What it would change | Why it's waiting |
|---|---|---|
| odometer-uploads-follow-setting.sql (+ undo) | The "drivers upload odometer photos" storage policy also requires the Odometer photo setting not to be Off | Owner approved preparing it (16 Nov 2026); implementation needs separate approval (plan QA-008) |
| odometer-default-off.sql | New copies start with the Odometer photo setting Off (migration only) | Same (plan QA-008 action A2) |

(managers-act-on-unmanaged-registers was approved on 15 Nov 2026 and became live update 83.)
