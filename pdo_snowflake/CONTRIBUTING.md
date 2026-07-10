# Contributing

## Licensing — no CLA

Inbound contributions are licensed **inbound = outbound** under **Apache-2.0**
(`LICENSE`): by opening a PR you agree your contribution is provided under that
license. We deliberately do **not** use a CLA that assigns rights to any
individual — rights stay with the project, which keeps a future maintainer
handoff clean (`docs/governance.md`). No commit sign-off is required.

## How patches are structured

- Musl patches live in `packages/<pkg>/patches/` as `NNN-<slug>.patch`, git-diff
  format against the pinned upstream tag, applied in numeric order.
- **Guard every change** so glibc behavior is unchanged
  (`#if defined(__linux__) && !defined(__GLIBC__)` …). Prefer the smallest diff.
  Prefer upstreaming; note upstreamability in `manifest.toml` `[patches]`.
- Give each patch a provenance note (upstream file + version it targets).

## The version-pair rule (read before bumping)

`pdo_snowflake` and `libsnowflakeclient` are versioned **together** and their tags
drift out of sync. Never bump one side to "latest tag" independently — use the
pair the pdo CHANGELOG declares. See `packages/php83-pdo_snowflake/README.md`.

## Before you push

- `bin/build-package <pkg>` builds and runs the acceptance gates; they must be
  green. A failed or skipped gate blocks publish by design.
- New packages: follow `docs/adding-a-package.md`; start at `autonomy = "notify"`.

## LLM-authored patches

Patches produced by the automated fix loop carry a provenance trailer and are
**held for human review** — they are never auto-merged. Review them like any
other contribution.
