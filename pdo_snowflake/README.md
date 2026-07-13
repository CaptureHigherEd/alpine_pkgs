# PDOSnowAlpine — self-maintaining Alpine/musl packages

Automatically builds Alpine Linux (musl) APKs from source as upstream releases
land, repairs musl build breakage with an LLM on the failure path, and publishes
**signed** packages — humans in the loop only when it genuinely gets stuck.

First package: **`php83-pdo_snowflake`** — Snowflake's PHP PDO driver, built
entirely from source on musl (Snowflake does not support Alpine). Proven viable
in the `snowflake/` spike; see `packages/php83-pdo_snowflake/README.md`.

> **Status: Phase 1 proven (x86_64).** `bin/build-package` → `bin/verify-acceptance`
> → `bin/publish` run end to end: the package builds from source under `abuild` in
> an Alpine container, passes all gates (35/35 unit tests, extension loads, zero
> glibc object code), is signed, published to a signed `site/` APK repo, and
> `apk add php83-pdo_snowflake` from that repo installs and loads on a clean image.
> Detection/auto-bump (Renovate) and the LLM fix loop are still skeletons — see
> `docs/architecture.md` for the phase plan and `auto/` for full detail. aarch64
> (proven in the spike) still needs an aarch64 runner to build here.

## Consuming the apk repo (once published — Phase 1)

```sh
# trust our signing keyring
for k in domains@capturehighered.com-6a521812.rsa.pub; do
    wget -O /etc/apk/keys/$k https://mmedia-stage.capturehighered.net/apk/keyring/$k
done
# add the repo
echo "https://mmedia-stage.capturehighered.net/apk/v3.22/main" >> /etc/apk/repositories
apk update && apk add php83-pdo_snowflake
```

Verify signatures per `SECURITY.md`. The repo is served via CloudFront at
`mmedia-stage.capturehighered.net` under the `/apk` prefix — a CDN URL, not a raw
GitHub URL, so the S3 origin can move without breaking consumers.

## Building locally

```sh
bin/build-package php83-pdo_snowflake      # runs abuild in an Alpine env + gates
```

Requires an Alpine/musl build environment (native, container, or
`alpine-chroot-install`). ~12–13 min clean on 10 cores.

## Repo map

| Path | What |
|---|---|
| `packages/<name>/` | one dir per package: `APKBUILD`, `manifest.toml`, `patches/`, gates |
| `bin/` | the glue: resolve-pair, reconcile, build-package, verify-acceptance, classify-error, fix-loop, refresh-patches, publish, e2e, status |
| `llm/` | build-doctor: agent config, swappable model adapter, the musl-fix prompt |
| `keys/keyring/` | public signing keys (private keys are CI secrets only) |
| `.github/workflows/` | reconcile / build / fix / publish |
| `docs/` | architecture, governance, runbook, adding-a-package |

## License & contributing

Apache-2.0 (`LICENSE`). Contributions under the DCO (`CONTRIBUTING.md`) —
sign off your commits (`git commit -s`). See `docs/governance.md`.
