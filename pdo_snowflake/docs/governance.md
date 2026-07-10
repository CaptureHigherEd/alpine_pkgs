# governance.md — license, contribution terms, and staying handoff-ready

We are **not** writing a handoff procedure yet (deferred). We **are** making the
setup choices now that keep a future handoff a cheap ownership change rather than
a migration. This doc records those choices.

## License: Apache-2.0

- **Why:** permissive, widely trusted, and — unlike MIT — carries an **explicit
  patent grant**, which protects both users and any future maintainer. It is the
  handoff-friendly default.
- **Compatibility:** the upstreams we package (`pdo_snowflake`,
  `libsnowflakeclient`) are themselves Apache-2.0, so our patches (derivative of
  their source) and our own code (APKBUILDs, `bin/` scripts, Renovate config) all
  sit cleanly under Apache-2.0.
- **Files:** `LICENSE` (full text) + `NOTICE` (attribution) at repo root. Keep a
  short provenance note on each patch (which upstream file/version it targets).
- **The foundational rule:** *public ≠ open source.* Without `LICENSE`, the
  default is all-rights-reserved and **no one — including a successor — may
  legally fork or continue it.** The license is the transferability baseline.

## Contribution terms: inbound = outbound, never a personal CLA

- Inbound contributions are licensed **inbound = outbound** (Apache-2.0): opening
  a PR provides the contribution under the repo's license. **No commit sign-off /
  DCO is required.**
- **Do not** adopt a CLA that assigns rights to an individual. That binds rights
  to a *person* and actively **breaks transferability** — a successor wouldn't
  hold them. Keeping rights with the project/its license, not a maintainer, is
  what preserves handoff.

## Health files (make it adoptable)

At repo root, so a successor can pick it up without archaeology:

| File | Purpose |
|---|---|
| `README.md` | what it is, how to consume the apk repo, how to build |
| `LICENSE` + `NOTICE` | Apache-2.0 + attribution |
| `MAINTAINERS.md` | current owner(s); a *stub* handoff pointer (filled only if/when needed) |
| `SECURITY.md` | vuln contact + **how to verify signed apks** + signing-key info |
| `CONTRIBUTING.md` | inbound=outbound licensing, how patches are structured, the pair rule |
| `CODE_OF_CONDUCT.md` | standard adoptable baseline |

`SECURITY.md` carries extra weight here because we ship **signed binaries** —
it documents the keyring, how to verify, and where to report a compromise.

## Optimizing the setup so handoff stays *possible* (not doing it now)

Six choices that keep the option open at near-zero cost:

1. **Own everything in the org, never a personal account.** An org ownership
   change keeps every `org/repo` URL and every repo-level secret intact (repo
   transfers are lossy and can permanently retire popular repo names). This is
   the single highest-leverage transferability decision.
2. **Canonical apk URL on a custom domain we control** (`apk.<domain>` via a
   Pages CNAME). DNS is ours to repoint — it survives an ownership change *and* a
   move off GitHub entirely. See [build-pipeline.md](build-pipeline.md) §6.
3. **Keyring-based signing** (agreed) — see below and build-pipeline.md §6 — so a
   future key succession never breaks consumers.
4. **A living, in-repo inventory** (not secret *values*): what secrets exist,
   what the signing keyring contains, what DNS points where, who holds owner.
   Lives in `MAINTAINERS.md` + `keys/README.md`. The actual transfer runbook is
   deferred — a one-line stub in `MAINTAINERS.md` marks it as "write when needed."
5. **No personal CLA** (above).
6. **Standard health files** (above) so onboarding a successor is self-serve.

Explicitly **deferred** (write only if handoff becomes real): the step-by-step
org-ownership-transfer runbook, billing reassignment, and private-key custody
transfer. Tracked as a stub, not built.

## Keyring-based signing (agreed) — summary

Full mechanics in [build-pipeline.md](build-pipeline.md) §6. In short: `apk`
consumers trust a **directory** of public keys (`/etc/apk/keys/`), so we ship and
maintain a **keyring of all currently-valid public keys**. Adding a key (routine
rotation, or a successor's key) means publishing the new public key alongside the
old, signing new indexes with it, and retiring the old key only after a grace
window in which both are valid. Consumers who updated in that window never see a
break. **Private keys never touch git** — each is a CI secret; the public keyring
is committed under `keys/keyring/`.
