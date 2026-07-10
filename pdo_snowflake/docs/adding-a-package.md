# Adding a package

The layout is designed so a new package is a new directory and nothing else:
Renovate config and the reusable `build.yml` matrix pick it up by globbing
`packages/*/manifest.toml`.

## Steps

1. `mkdir -p packages/<name>/{patches,acceptance}`.
2. Write `packages/<name>/APKBUILD` (start from `newapkbuild` or an existing
   package; build from source on musl).
3. Write `packages/<name>/manifest.toml` — `[upstream]` (repos + channel +
   `pair_source`), `[pins]`, `[publish].retain`, `[patches]`, `[status]`,
   `autonomy = "notify"` at first (earn trust up the ladder).
4. Add any musl patches to `patches/` in `NNN-*.patch` git-diff order; list them
   in `[patches]` with `retire_if` hints where they can self-obsolete.
5. Put gate config (e.g. `ctest-exclude.txt`) in `acceptance/`.
6. Write `packages/<name>/README.md` — especially any version-pairing rule and a
   "what re-breaks" table.
7. Build locally: `bin/build-package <name>`; iterate until `check()` is green.
8. Commit; Renovate will start tracking the upstream on the next reconcile.

## Autonomy ladder (start low)

`notify` → `propose` → `auto`. New packages start at `notify` (build+gate, open
an issue). Graduate only after a soak. LLM-authored patches never automerge until
Phase 4 graduation regardless of level. See auto/autonomy.md §3.
