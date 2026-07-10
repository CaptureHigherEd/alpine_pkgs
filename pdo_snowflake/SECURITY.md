# Security Policy

## Reporting a vulnerability

Report privately via GitHub Security Advisories (Security → Report a
vulnerability) on this repository, or email the maintainer listed in
`MAINTAINERS.md`. Please do not open a public issue for undisclosed
vulnerabilities. We aim to acknowledge within a few days.

Report especially: a compromised or leaked **signing key**, a malicious or
unexpected package in the repo, or a supply-chain concern in a build.

## Verifying signed packages

We ship **signed** APKs. `apk` verifies the repository index against the public
keys in `/etc/apk/keys/`. Install our keyring first:

```sh
wget -O /etc/apk/keys/<keyid>.rsa.pub https://apk.<domain>/keyring/<keyid>.rsa.pub
```

The published keyring at `https://apk.<domain>/keyring/` contains **all
currently-valid** public keys. During a key rotation, more than one key is valid;
install all of them so a rotation never breaks your updates (see
`keys/README.md`).

- **Private signing keys** exist only as CI secrets — never in this repository.
- If you cannot verify a downloaded index against a key in the published keyring,
  treat it as a compromise and report it.

## Signing-key rotation & maintainer succession

Rotation is designed to be non-breaking: a new public key is published and
trusted by consumers *before* it begins signing; the old key is retired only
after a grace window. Full mechanics: `keys/README.md`, `docs/governance.md`.

## Scope note

These packages build software Snowflake does not support on Alpine/musl.
Correctness of the driver under production load is the maintainers'
responsibility, not upstream's — see the package README caveats.
