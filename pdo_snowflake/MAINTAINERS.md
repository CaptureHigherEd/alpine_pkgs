# Maintainers

| Role | Who | Contact |
|---|---|---|
| Owner / lead maintainer | James MacLachlan | jmaclachlan@zemlyaozer.com |

Ownership lives in the **`PDOSnowAlpine` GitHub org**, not a personal account —
an org ownership change keeps every `org/repo` URL and repo-level secret intact.

## Custody inventory (what exists — never the secret values)

Keep this current; it is the map a successor needs. Values live in the secret
store / DNS, not here.

- **CI secrets:** `ABUILD_ACTIVE_KEY` (active signing private key — set) ·
  `OPENAI_API_KEY` (model API key, Chutes `cpk_…` — set). `GITHUB_TOKEN` is
  Actions-provided.
- **CI variables:** `OPENAI_BASE_URL` = `https://llm.chutes.ai/v1` ·
  `FIXLOOP_MODEL` = `zai-org/GLM-5.2-TEE` (model served on **Chutes**).
- **Signing keyring:** public keys in `keys/keyring/`; **active key ID =
  `jmaclachlan@zemlyaozer.com-6a4edfb6`** (private key held in the owner's vault;
  minted via `gen-active-key.sh`, kept outside the repo).
- **DNS:** `apk.<domain>` → GitHub Pages (`CNAME`). _TBD — set when gh-pages
  publishing goes live (`PUBLISH_PUSH` / `APK_DOMAIN` / `PUBLISH_ORIGIN`)._
- **Org owners:** _list `PDOSnowAlpine` GitHub org owners._

## Handoff — DEFERRED (stub)

A full maintainer/org-ownership transfer runbook is **intentionally not written
yet** (`docs/governance.md`). The setup choices that keep handoff cheap (org
ownership, custom-domain apk URL, keyring succession, no personal CLA) are
already in place. Write the step-by-step transfer runbook — org ownership
transfer, billing reassignment, private-key custody handover — only **if/when a
handoff becomes real.**
