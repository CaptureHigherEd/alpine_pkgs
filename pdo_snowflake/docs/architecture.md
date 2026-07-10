# Architecture

The canonical, detailed plan of record lives in the `auto/` planning directory
(`auto/PLAN.md`, `repo-structure.md`, `autonomy.md`, `build-pipeline.md`,
`llm-fix-loop.md`, `governance.md`). This page is the in-repo summary; promote the
full plan here once Phase 1 lands.

## One paragraph

"Renovate for aports, with an LLM build-doctor on the failure path." Self-hosted
Renovate is the autonomy engine (schedule → detect → bump → PR → automerge). A
per-package `APKBUILD` (transcribed from the proven `snowflake/` spike) is the
build. On build failure a coding agent driving a **swappable SaaS model** authors
a musl patch inside the Alpine build env, capped at ~3 attempts. Git is the state
store; signed APKs go to a **swappable backend** (GitHub Pages on a custom domain
today). Every part — model, host, engine, publish — sits behind an OSS/swappable
boundary: cloud-based, never locked-in.

## Reconciliation loop

```
schedule → RECONCILE (Renovate) → RESOLVE PAIR (bin/resolve-pair)
        → BUILD (bin/build-package: refresh-patches → abuild → check() gates)
             success → PUBLISH (bin/publish: prune → index → sign → push)
             failure → FIX LOOP (bin/fix-loop: agent+model, ≤3, in the env)
                          fixed → PR held for human review
                          stuck → label needs-human, file issue
```

Desired state (per package, in `manifest.toml`) = latest **coherent** upstream
pair, musl-patched, built + gated green, signed, published. Each scheduled run
converges desired→actual, so transient failures self-heal on the next tick.

## Phase status

- ✅ **Phase 0** — repo bootstrap / scaffold
- ✅ **Phase 1** — deterministic build + keyring-signed publish, proven on x86_64
  (build → gates → sign → publish → `apk add` from the signed repo → loads).
  Remaining: push `site/` to gh-pages@apk.<domain>; build aarch64 on an aarch64
  runner.
- ✅ **Phase 2** — drift detection + auto-bump PRs. `bin/resolve-pair` reads the
  pdo CHANGELOG to resolve the coherent `(pdo_ref, client_tag)` pair;
  `bin/reconcile` compares it to the pins and, on drift, bumps `manifest.toml` +
  `APKBUILD` and opens a PR (`.github/workflows/reconcile.yml`, nightly). The
  two-repo atomic pairing is handled by this controller, **not** a Renovate
  custom datasource (Renovate only keeps the repo's own GH-Actions fresh).
- ✅ **Phase 3** — the LLM build-doctor. `bin/classify-error` maps a build log to
  the musl taxonomy; `bin/fix-loop` iterates ≤3 times (classify → prompt a
  swappable model → apply → containerized re-verify → keep-or-escalate), with a
  pluggable patch provider (`api` | `replay` | `cmd`) so it runs without a live
  model. Wired into `build.yml` (fix on failure → rebuild → review PR) and
  `fix.yml`. Verified end-to-end on a faithful `fopen64`-on-musl fixture: success
  path fixes on attempt 1; a wrong patch escalates to needs-human after 3.
  LLM-authored patches are candidates **held for human review**, never auto-merged.
- ✅ **Phase 4** — hardening. `bin/refresh-patches` clones the pinned client and
  classifies each patch keep/retire(reverse-applies)/fuzz(needs fix-loop), wired
  into `bin/reconcile`; `bin/status [--markdown]` is the self-report (in
  `reconcile.yml`'s summary); the trust ladder's **auto-merge for `autonomy=auto`
  clean bumps** is implemented in reconcile; `bin/publish` now pushes the signed
  repo to **gh-pages** (`apk.<domain>` CNAME, gated on `PUBLISH_PUSH`);
  `bin/build-package` takes a `--platform` for **aarch64** cross-builds.
  *Deferred (env-bound):* an actual aarch64 build needs binfmt/QEMU or a native
  runner; the credentialed integration suite needs a live Snowflake account.
