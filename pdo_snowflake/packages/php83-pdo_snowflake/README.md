# php83-pdo_snowflake

Alpine/musl package for Snowflake's PHP PDO driver (`pdo_snowflake`), **built
entirely from source** (driver + `libsnowflakeclient` + its full dependency tree).
Snowflake does not support Alpine/musl for any native driver — this package and
its patch set are maintained downstream.

Provenance: proven viable in the `snowflake/` spike
(`snowflake/OPTION3_REPORT.md`, verdict GO-WITH-CAVEATS): 3 patches, ~12–13 min
clean build, zero glibc object code in the final `.so`, 35/35 credential-free
unit tests.

## The one rule that will bite you: the version PAIR

`pdo_snowflake` and `libsnowflakeclient` are versioned **together**, and their
tags drift out of sync — so **never** take "latest tag" of each independently.
The correct pair is the one the pdo **CHANGELOG** declares
("Updated the `libsnowflakeclient` to vX.Y.Z"). This genuinely moves: at spike
time (2026-07-02) pdo tag `v4.0.0` paired with client `v2.8.0` while `master`
led at `v2.9.1`; upstream has since updated so `v4.0.0` also pairs with `v2.9.1`.
Reading the changelog — not assuming — is the whole point.

`bin/resolve-pair <pkg>` fetches the pdo CHANGELOG at the configured channel
(`[upstream].pdo_channel`, default `master`), takes the topmost declared client
version, verifies it is a real client tag, and prints the coherent pair as JSON.
`bin/reconcile <pkg>` compares that to `manifest.toml` `[pins]` and, on drift,
rewrites the pins + `APKBUILD` (`pkgver`, `_client_tag`, `_pdo_ref`) and opens a
bump PR. Current pin: client `v2.9.1` / pdo `50335c9`.

## What re-breaks on a bump (most → least likely)

1. **pair drift** → `bin/resolve-pair`.
2. **upstream build-script churn** (scripts mask their own failures;
   `ARROW_FROM_SOURCE` slated for removal; lib/lib64 moves) → the APKBUILD's
   `_assert_dep_artifacts` + `check()` turn silent regressions into loud failures.
3. **refreshed vendored dep reintroduces a glibc-ism** (the cmocka class) → fix
   loop; worst case is test-only, driver unaffected.
4. **new client code using glibc-only APIs** → ~0–2 small `001`-style patches per
   client release; the fix loop authors them.

## Patches

| Patch | Fixes | Auto-retires when |
|---|---|---|
| `001-sf-fopen-no-lfs64-on-musl.patch` | `fopen64` in `SF_CRTFunctionSafe.h` (musl ≥1.2.4 dropped LFS64 aliases) | client source no longer calls `fopen64` |
| `002-cmocka-musl-uintptr_t.patch` | vendored cmocka 1.1.1 `__WORDSIZE`-keyed `uintptr_t` typedef clash | vendored cmocka ≥ 1.1.2 |
| `003-build_arrow-sourced-exit-skips-tomlplusplus.patch` | `build_arrow.sh` `exit 0` when *sourced* kills toml++ build (latent upstream bug, not musl) | upstreamed |

Patches are git-diff format against the pinned `_client_tag`; `bin/refresh-patches`
applies/refreshes/retires them on a bump.

## Build & gates

`bin/build-package php83-pdo_snowflake` runs `abuild` in an Alpine environment.
`check()` gates (all must pass to publish):

1. `ctest -R unit` minus the two documented infra/creds-requiring tests
   (`acceptance/ctest-exclude.txt`).
2. `php83 -m` lists `pdo_snowflake` and `PDO::getAvailableDrivers()` contains
   `snowflake`.
3. `readelf` audit: **zero** `@GLIBC` object code beyond the two standard weak
   crt frame-info stubs.

## Outputs

- `php83-pdo_snowflake` — the runtime extension apk.
- `libsnowflakeclient-static`, `libsnowflakeclient-dev` — the static lib +
  headers, for a company base image.
