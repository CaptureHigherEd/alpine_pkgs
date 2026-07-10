#!/bin/sh
# pdo_snowflake e2e — runs INSIDE a clean Alpine runtime container (driven by
# bin/e2e) with the SHIPPED pdo_snowflake apk already installed. It:
#   1. proves the extension connects to Snowflake and round-trips data, then
#   2. runs upstream's full .phpt functional suite against the installed extension.
# This is exactly Snowflake's own validation — but on musl, which they don't test.
#
# Env (from bin/e2e / the Builder environment):
#   SNOWFLAKE_TEST_ACCOUNT/USER/DATABASE/SCHEMA/WAREHOUSE/ROLE, keypair/JWT auth
#   SNOWFLAKE_TEST_PRIVATE_KEY (PEM contents), PDO_REF (pinned pdo_snowflake ref)
set -eu
echo "e2e/pdo_snowflake: setup (alpine $(cat /etc/alpine-release 2>/dev/null))"
apk add --no-cache git >/dev/null      # php83* came in via the apk's deps

# 1) fetch the test suite matching the BUILT version (skip the vendored client)
git clone --filter=blob:none --no-checkout \
	https://github.com/snowflakedb/pdo_snowflake /src >/dev/null 2>&1
git -C /src sparse-checkout set --no-cone '/tests' '/run-tests.php' >/dev/null 2>&1
git -C /src checkout "$PDO_REF" >/dev/null 2>&1
cd /src

# 2) keypair/JWT auth: materialize the private key; point testenv.ini at the file
if [ -n "${SNOWFLAKE_TEST_PRIVATE_KEY:-}" ]; then
	umask 077; printf '%s' "$SNOWFLAKE_TEST_PRIVATE_KEY" > /tmp/sf_rsa.p8
	export SNOWFLAKE_TEST_PRIVATE_KEY_FILE=/tmp/sf_rsa.p8
	unset SNOWFLAKE_TEST_PRIVATE_KEY        # keep key material OUT of testenv.ini
fi
# tests reference ./libsnowflakeclient/cacert.pem and ./cacert.pem; the apk ships
# the bundle at /etc/snowflake/cacert.pem
mkdir -p libsnowflakeclient
cp /etc/snowflake/cacert.pem libsnowflakeclient/cacert.pem 2>/dev/null || true
cp /etc/snowflake/cacert.pem cacert.pem 2>/dev/null || true

# 3) testenv.ini exactly as upstream builds it (env -> ini); key file only, no material
env | grep '^SNOWFLAKE_TEST_' > testenv.ini
echo "e2e: params ->"; grep -viE 'key|password|token' testenv.ini || true

# 4) DEFINITIVE connectivity gate against the INSTALLED extension (conf.d-loaded):
#    connect + DDL + DML + fetch round-trip. This is the guaranteed pass/fail.
php83 -r '
	$p = parse_ini_file("testenv.ini");
	$host = $p["SNOWFLAKE_TEST_HOST"] ?? ($p["SNOWFLAKE_TEST_ACCOUNT"].".snowflakecomputing.com");
	$dsn = "snowflake:host=$host;port=443;account={$p["SNOWFLAKE_TEST_ACCOUNT"]};"
	     . "database={$p["SNOWFLAKE_TEST_DATABASE"]};schema={$p["SNOWFLAKE_TEST_SCHEMA"]};"
	     . "warehouse={$p["SNOWFLAKE_TEST_WAREHOUSE"]};role={$p["SNOWFLAKE_TEST_ROLE"]};"
	     . "protocol=https;authenticator=snowflake_jwt;priv_key_file={$p["SNOWFLAKE_TEST_PRIVATE_KEY_FILE"]}";
	$dbh = new PDO($dsn, $p["SNOWFLAKE_TEST_USER"], "", [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
	$t = "e2e_" . getmypid();
	$dbh->exec("create or replace temporary table $t (c1 int)");
	$dbh->exec("insert into $t values (1),(2),(3)");
	$n = (int)$dbh->query("select count(*) from $t")->fetchColumn();
	if ($n !== 3) { fwrite(STDERR, "row count $n != 3\n"); exit(1); }
	echo "E2E connectivity OK (PHP ".PHP_VERSION.", $n rows round-tripped)\n";
' || { echo "e2e: connectivity gate FAILED" >&2; exit 1; }

# 5) upstream's full functional suite (connect/binding/types/putget/auth/…).
#    NOTE: run-tests.php loading an INSTALLED (vs make-built) extension may need a
#    small tweak on first real run; the connectivity gate above already validates
#    the core, so treat a suite hiccup here as a wiring fix, not a musl bug.
export REPORT_EXIT_STATUS=1 NO_INTERACTION=true
echo "e2e: running upstream .phpt suite ($(ls tests/*.phpt 2>/dev/null | wc -l) tests)"
php83 run-tests.php -q --show-diff -d extension_dir=/usr/lib/php83/modules tests/
echo "e2e: pdo_snowflake suite PASSED"
