# Runbook — when the pipeline escalates

The system does everything it safely can, then stops **loudly and usefully**. A
package reaches you as a PR labeled `needs-human` (and an issue) when the LLM fix
loop exhausted its ≤3 attempts, or a gate failed in a way it won't auto-touch.

## What you get

- The PR with the attempted patch(es) and the failing build-log tail.
- The `fix-loop` diagnosis: error class, file, why it didn't converge.
- `manifest.toml` `[status] last_result = "needs-human"`.

## Triage

1. **Reproduce:** `bin/build-package <package>` on a self-hosted runner (or
   locally in an Alpine env). Same environment the loop used.
2. **Classify** using the taxonomy in `llm/prompts/musl-fix.md`. Is it a new
   musl-ism (author/accept a guarded `001`-style patch), upstream script churn
   (adjust the APKBUILD `_assert_dep_artifacts` list), or a genuine pair
   mismatch (fix `bin/resolve-pair` / the pins)?
3. **Fix or accept:** amend the agent's patch or write your own; push to the PR.
4. **Re-run gates.** Green → merge → publish. Update the package README's
   "what re-breaks" table if this was a new failure mode.

## Never

- Never publish with a failed or **skipped** gate — that's what dropped it to
  `needs-human` in the first place.
- Never merge an LLM-authored patch without reading it (default disposition is
  human review; it carries a provenance trailer for context).

## Deferred

The step-by-step maintainer/org-ownership handoff runbook is intentionally not
written yet (auto/governance.md). This file is the operational runbook; the
transfer runbook is a stub in `MAINTAINERS.md`, to be written if handoff becomes
real.
