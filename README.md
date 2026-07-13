# alpine_pkgs — CaptureHigherEd custom Alpine packages

A monorepo of **custom Alpine Linux (musl) package pipelines**. Each subdirectory
is a self-contained package project that builds APKs from source, gates them, and
publishes **signed** packages to a shared apk repository. The layout is generic —
add a new directory to add a new package pipeline.

## Layout

```
alpine_pkgs/
└── <package-project>/        # one directory per package pipeline
    ├── packages/             # abuild APKBUILD(s) + manifest.toml (desired state)
    ├── bin/                  # build / verify / publish / fix-loop tooling
    ├── keys/keyring/         # PUBLIC signing keys (private keys are CI secrets)
    ├── .github/workflows/    # per-project CI (build, publish, fix, reconcile)
    └── docs/                 # architecture, runbook, adding-a-package
```

Current projects:

| Project | Package(s) | Status |
|---|---|---|
| [`pdo_snowflake/`](pdo_snowflake/README.md) | `php83-pdo_snowflake` | Phase 1 proven (x86_64); aarch64 building via hosted arm runners |

## How a package pipeline works

Each project is a self-maintaining pipeline: it builds from source under `abuild`
in an Alpine container, runs gates (unit tests, extension loads, glibc-object
audit), repairs musl build breakage with an LLM build-doctor on the failure path
(candidate patches are **held for human review, never auto-merged**), signs the
result, and publishes. Humans are in the loop only when it genuinely gets stuck.
See each project's `docs/architecture.md` for its phase plan.

## Consuming the packages

All projects publish into a **single signed apk repository**, served via AWS
CloudFront at `mmedia-stage.capturehighered.net` under the `/apk` prefix:

```sh
# trust the signing keyring
k=domains@capturehighered.com-6a521812.rsa.pub
wget -O /etc/apk/keys/$k https://mmedia-stage.capturehighered.net/apk/keyring/$k

# add the repo (adjust the Alpine version to match your image)
echo "https://mmedia-stage.capturehighered.net/apk/v3.22/main" >> /etc/apk/repositories

apk update && apk add php83-pdo_snowflake
```

`apk update` must report the repo as trusted — no `UNTRUSTED signature` warning.
The URL is a CDN endpoint, not a raw GitHub URL, so the S3 origin can move without
breaking consumers.

## Publishing (maintainers)

Publishing is signed and automated in CI, gated on passing builds. Configuration
lives in the repo's **`Builder`** GitHub Actions environment:

- **Signing:** `ABUILD_ACTIVE_KEY` (private key; public half in `keys/keyring/`).
  Active key ID `domains@capturehighered.com-6a521812`.
- **Publish target:** AWS S3 + CloudFront on the shared `mmedia-stage` bucket.
  `PUBLISH_S3_TARGET` = `s3://mmedia-stage.capturehighered.net/apk`,
  `AWS_MMEDIA_REGION` = `us-east-1`, creds `AWS_MAIN_MMEDIA_ACCESS_KEY` /
  `AWS_MAIN_MMEDIA_SECRET_ACCESS_KEY` (global secrets). `--delete` is scoped to the
  `/apk` prefix; the index and keyring are uploaded `no-cache`.
- **LLM fix-loop:** OpenAI (`OPENAI_BASE_URL` = `https://api.openai.com/v1`,
  `FIXLOOP_MODEL` = `gpt-5.6-sol`, `OPENAI_API_KEY`), bounded by
  `FIXLOOP_MAX_SPEND_USD`.

Per-project custody, key rotation, and runbooks are documented in each project's
`MAINTAINERS.md`, `keys/README.md`, and `docs/`.

## Adding a package

Copy an existing project directory as a template and follow its
`docs/adding-a-package.md`. A new project needs, at minimum, a `packages/<name>/`
with an `APKBUILD` + `manifest.toml`, and CI wired to the shared `Builder`
environment so it signs and publishes into the same apk repository.
