# End-to-end (functional) testing

The build gate (`bin/verify-acceptance`) is a **smoke test**: the `.apk` installs,
the extension loads, the driver registers, zero glibc object code. It proves the
package *loads* — not that it *works*.

`bin/e2e` is the quality gate above that: it installs the **shipped `.apk`** in a
clean Alpine runtime image and runs the package's **real functional suite** —
connecting to the live service and moving data — across every supported
`(alpine × arch)`. For `php83-pdo_snowflake` that means running **Snowflake's own
`.phpt` suite on musl**, which upstream never tests (they validate on glibc /
RockyLinux 9 only). A musl-specific *runtime* bug passes every upstream test and
still ships broken; this catches it.

## How it runs

```
bin/e2e <package> [arch]
  ├─ read manifest [e2e]: enabled? required_env present?
  │     absent creds  -> SKIP (exit 0)   unless E2E_REQUIRED=1 -> hard fail
  ├─ find the built .apk for (package, arch) under .build/packages
  └─ docker run alpine:<ALPINE_VER>:
        trust keys/keyring, apk add the SIGNED built apk (+ runtime deps),
        exec packages/<package>/e2e/run.sh   # package-specific test logic
```

- **`ALPINE_VER`** picks the runtime image (defaults 3.24). CI runs one e2e job
  per matrix `(alpine, runner)` on `main`, after `build`, before `publish`.
- Creds come from the **`Builder` environment** secrets, forwarded by name.
- **Publish is gated on e2e** (`publish: needs: [build, e2e]`). While creds are
  absent, e2e skips (counts as pass); set the repo variable **`E2E_REQUIRED=1`**
  to make a real e2e run mandatory before any publish.

## Credentials (Builder environment secrets)

Keypair / JWT auth (non-interactive), matching upstream's `testenv.ini`:

| Secret | Notes |
|---|---|
| `SNOWFLAKE_TEST_ACCOUNT` | account locator |
| `SNOWFLAKE_TEST_USER` | test user |
| `SNOWFLAKE_TEST_DATABASE` / `_SCHEMA` / `_WAREHOUSE` / `_ROLE` | CI-scoped objects |
| `SNOWFLAKE_TEST_PRIVATE_KEY` | PEM contents of the keypair private key (never the file path) |

`e2e/run.sh` writes the key to a file, points `testenv.ini` at it, and keeps the
key material out of the ini.

## Adding e2e to another package (the framework)

`bin/e2e` is generic. For a new `packages/<pkg>/`:

1. `manifest.toml`:
   ```toml
   [e2e]
   enabled = true
   required_env = ["FOO_TOKEN", "FOO_ENDPOINT"]   # skip if any absent
   ```
2. Write `packages/<pkg>/e2e/run.sh` — runs **inside** the runtime container with
   the built apk already installed and `required_env` in the environment. Exit 0
   = pass, non-zero = fail. Reuse the upstream project's own test suite where one
   exists (as pdo_snowflake reuses Snowflake's `.phpt` tests).
3. Add the package's secrets to the `Builder` environment and map them in the
   `e2e` job's `env:` in `ci.yml`.

## Known first-run verification point

`packages/php83-pdo_snowflake/e2e/run.sh` runs a **guaranteed connectivity gate**
(a direct `PDO` connect + DDL/DML/fetch round-trip) and then upstream's full
`.phpt` suite. `run-tests.php` loading an *installed* (vs make-built) extension
may need a small `-d extension=` tweak on the first real run — the connectivity
gate already validates the core, so treat a suite-harness hiccup as a wiring fix,
not a musl regression.
