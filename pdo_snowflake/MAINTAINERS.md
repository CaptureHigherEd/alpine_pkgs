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
  `OPENAI_API_KEY` (model API key, OpenAI `sk-…` — TBD, set in Builder env).
  `GITHUB_TOKEN` is Actions-provided.
- **CI variables:** `OPENAI_BASE_URL` = `https://api.openai.com/v1` ·
  `FIXLOOP_MODEL` = `gpt-5.6-sol` (OpenAI flagship; fallback `gpt-5.6-terra`) ·
  `FIXLOOP_MAX_SPEND_USD` = `5.00` (per-package per-run ceiling).
- **Signing keyring:** public keys in `keys/keyring/`; **active key ID =
  `domains@capturehighered.com-6a521812`** (private key held in the owner's vault;
  minted via `gen-active-key.sh`, kept outside the repo). Superseded personal key
  `jmaclachlan@zemlyaozer.com-6a4edfb6` still in keyring — remove once unused (see
  keys/README rotation; safe to drop now since nothing has published yet).
- **Publish target:** AWS S3 + CloudFront at `mmedia-stage.capturehighered.net`
  under the `/apk` prefix (shared bucket owned by infra — we only write under the
  prefix; no S3/CloudFront setup on our side). Config: `PUBLISH_S3_TARGET` =
  `s3://mmedia-stage.capturehighered.net/apk` and `AWS_MMEDIA_REGION` = `us-east-1`
  (Builder env vars); `AWS_MAIN_MMEDIA_ACCESS_KEY` / `AWS_MAIN_MMEDIA_SECRET_ACCESS_KEY`
  (global secrets). CloudFront invalidation is not assumed — the index + keyring
  are uploaded `no-cache`.
- **Org owners:** _list `PDOSnowAlpine` GitHub org owners._

## Handoff — DEFERRED (stub)

A full maintainer/org-ownership transfer runbook is **intentionally not written
yet** (`docs/governance.md`). The setup choices that keep handoff cheap (org
ownership, custom-domain apk URL, keyring succession, no personal CLA) are
already in place. Write the step-by-step transfer runbook — org ownership
transfer, billing reassignment, private-key custody handover — only **if/when a
handoff becomes real.**
