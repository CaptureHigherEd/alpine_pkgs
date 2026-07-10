# keys/ — apk signing keyring

`apk` clients trust a **directory** of public keys (`/etc/apk/keys/`), which is
what makes graceful key rotation and maintainer succession possible without ever
breaking consumers (auto/governance.md, build-pipeline.md §6).

## Layout

- `keyring/` — **all currently-valid PUBLIC keys**, committed. Published to
  `site/keyring/`; consumers install every key here into `/etc/apk/keys/`.
- **Private keys are NEVER in git.** Each lives only as a CI secret. One is the
  ACTIVE signer (`ABUILD_ACTIVE_KEY`); others may exist during a rotation window.

## Rotation / succession (no consumer breakage)

1. Generate a new keypair (`abuild-keygen -a -i`). Add the **public** key to
   `keyring/` and publish it.
2. Consumers pick it up on their next `apk update` — now they trust it, but it
   isn't signing yet.
3. Switch `ABUILD_ACTIVE_KEY` to the new **private** key; new indexes are signed
   with it. Consumers already trust it → nothing breaks.
4. After a grace window (both keys valid), retire the old public key from
   `keyring/`.

This dual-trust window is exactly what turns an eventual maintainer handoff into
a non-event: a successor's key is added and trusted *before* it starts signing.

## Custody inventory (values live in the secret store, not here)

Record — in `MAINTAINERS.md` — *which* key IDs exist, who holds each private key,
and which is ACTIVE. Never the key material itself.
