#!/usr/bin/env bash
#
# Builds the app, logs into the demo Readeck server without going through the
# OAuth web sheet, seeds a few throwaway bookmarks, runs the Maestro flows in
# maestro/, and deletes everything it created again, even on failure.
#
# Usage: scripts/e2e.sh
#
# Credentials come from `asc` (App Store Connect review notes) by default.
# Override with READECK_E2E_USER / READECK_E2E_PASSWORD to skip that lookup.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAESTRO_DIR="$REPO_ROOT/maestro"

SIMULATOR_NAME="${E2E_SIMULATOR_NAME:-readeck-e2e}"
SIMULATOR_DEVICE_TYPE="iPhone 17"
SIMULATOR_RUNTIME="com.apple.CoreSimulator.SimRuntime.iOS-26-5"

DEMO_SERVER="${READECK_E2E_SERVER:-https://readeck.mnk.any64.de}"
ASC_PROFILE="${ASC_PROFILE:-readeck}"
ASC_VERSION_ID="${ASC_VERSION_ID:-c3eb783d-ecbd-4131-b33a-db15820f6ab5}"

OAUTH_REDIRECT_URI="readeck://oauth-callback"
OAUTH_SCOPE="bookmarks:read bookmarks:write profile:read"

RUN_ID="$(date +%s)-$$"
E2E_LABEL="e2e-${RUN_ID}"

WORKDIR="$(mktemp -d)"
COOKIE_JAR="$WORKDIR/cookies.txt"

ACCESS_TOKEN=""

log() { echo "==> $*"; }

# --- JAVA_HOME for Maestro: it needs a real JDK, which isn't `java` on PATH on a
# fresh machine, only installed via `brew install openjdk`.
setup_java() {
    if command -v java >/dev/null 2>&1; then
        return
    fi
    local brew_openjdk
    brew_openjdk="$(brew --prefix openjdk 2>/dev/null || true)"
    if [ -n "$brew_openjdk" ] && [ -x "$brew_openjdk/libexec/openjdk.jdk/Contents/Home/bin/java" ]; then
        export JAVA_HOME="$brew_openjdk/libexec/openjdk.jdk/Contents/Home"
        export PATH="$JAVA_HOME/bin:$PATH"
    else
        echo "error: no Java runtime found. Install one with 'brew install openjdk'." >&2
        exit 1
    fi
}

# --- The Maestro CLI installer only adds ~/.maestro/bin to interactive shells.
setup_maestro() {
    if command -v maestro >/dev/null 2>&1; then
        return
    fi
    if [ -x "$HOME/.maestro/bin/maestro" ]; then
        export PATH="$HOME/.maestro/bin:$PATH"
    else
        echo "error: maestro CLI not found, install it first." >&2
        exit 1
    fi
}

cleanup() {
    local exit_code=$?
    if [ -n "$ACCESS_TOKEN" ]; then
        log "Cleaning up test data (label: $E2E_LABEL)"
        delete_e2e_bookmarks || echo "warning: cleanup failed, check the demo server for leftover '$E2E_LABEL' bookmarks" >&2
        # Readeck's OAuth tokens never expire on their own (no expires_in), so a
        # leftover one stays valid on the demo account indefinitely. The
        # dynamically-registered client isn't a lasting concern: Readeck only
        # keeps it in a 10-minute cache, not persisted storage.
        revoke_token || echo "warning: token revoke failed, check the demo account's connected apps for a leftover 'Readeck iOS E2E' entry" >&2
    fi
    rm -rf "$WORKDIR"
    exit "$exit_code"
}
trap cleanup EXIT

json_get() {
    # json_get <json-on-stdin> <python expression using "d">
    python3 -c "import json,sys; d=json.load(sys.stdin); print($1)"
}

fetch_credentials() {
    if [ -n "${READECK_E2E_USER:-}" ] && [ -n "${READECK_E2E_PASSWORD:-}" ]; then
        DEMO_USER="$READECK_E2E_USER"
        DEMO_PASSWORD="$READECK_E2E_PASSWORD"
        return
    fi
    log "Fetching demo credentials via asc"
    local details
    details="$(asc --profile "$ASC_PROFILE" review details-for-version --version-id "$ASC_VERSION_ID")"
    DEMO_USER="$(echo "$details" | json_get "d['data']['attributes']['demoAccountName']")"
    DEMO_PASSWORD="$(echo "$details" | json_get "d['data']['attributes']['demoAccountPassword']")"
}

# --- OAuth, driven by curl the same way the app's ASWebAuthenticationSession
# would: register a client, submit the login form, exchange the code. Maestro
# can't reliably drive that system sheet, and it's explicitly out of scope for
# automation (issue #160), so flows start from an already-injected session.
oauth_login() {
    log "Registering a throwaway OAuth client"
    local client_json
    client_json="$(curl -sf -X POST "$DEMO_SERVER/api/oauth/client" \
        -H "Content-Type: application/json" \
        -d "{\"client_name\":\"Readeck iOS E2E\",\"client_uri\":\"https://github.com/ilyas-hallak/readeck-ios\",\"software_id\":\"readeck-ios-e2e-${RUN_ID}\",\"software_version\":\"e2e\",\"redirect_uris\":[\"${OAUTH_REDIRECT_URI}\"],\"grant_types\":[\"authorization_code\"]}")"
    CLIENT_ID="$(echo "$client_json" | json_get "d['client_id']")"

    local verifier challenge state
    verifier="$(openssl rand -base64 48 | tr -d '=+/\n' | cut -c1-64)"
    challenge="$(printf '%s' "$verifier" | openssl dgst -sha256 -binary | openssl base64 | tr -d '=' | tr '+/' '-_' | tr -d '\n')"
    state="$(openssl rand -hex 16)"

    local encoded_client_id encoded_redirect encoded_scope
    encoded_client_id="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$CLIENT_ID")"
    encoded_redirect="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$OAUTH_REDIRECT_URI")"
    encoded_scope="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$OAUTH_SCOPE")"
    local auth_url="$DEMO_SERVER/authorize?client_id=${encoded_client_id}&redirect_uri=${encoded_redirect}&scope=${encoded_scope}&code_challenge=${challenge}&code_challenge_method=S256&state=${state}&response_type=code"

    log "Starting the authorization code flow"
    local login_url r_param
    login_url="$(curl -sf -c "$COOKIE_JAR" -D - -o /dev/null "$auth_url" | grep -i "^Location:" | sed 's/^[Ll]ocation: //' | tr -d '\r')"
    r_param="$(python3 -c "
import sys, urllib.parse
qs = urllib.parse.parse_qs(urllib.parse.urlparse(sys.argv[1]).query)
print(qs['r'][0])
" "$login_url")"

    log "Submitting demo credentials"
    local authorize_again_url
    authorize_again_url="$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" -D - -o /dev/null \
        -X POST "$DEMO_SERVER/login" \
        --data-urlencode "r=$r_param" \
        --data-urlencode "username=$DEMO_USER" \
        --data-urlencode "password=$DEMO_PASSWORD" \
        | grep -i "^Location:" | sed 's/^[Ll]ocation: //' | tr -d '\r')"

    if [ -z "$authorize_again_url" ]; then
        echo "error: login did not redirect. Check READECK_E2E_USER/READECK_E2E_PASSWORD or the asc review notes." >&2
        exit 1
    fi
    case "$authorize_again_url" in
        http*) ;;
        *) authorize_again_url="$DEMO_SERVER$authorize_again_url" ;;
    esac

    # Now authenticated (cookie jar holds the session), re-entering /authorize
    # shows a consent screen ("Allow this app to access...") for a freshly
    # registered client, same as the app's ASWebAuthenticationSession would.
    local code_redirect
    code_redirect="$(curl -s -b "$COOKIE_JAR" -D - -o /dev/null \
        -X POST "$authorize_again_url" \
        --data-urlencode "granted=1" \
        | grep -i "^Location:" | sed 's/^[Ll]ocation: //' | tr -d '\r')"

    if [ -z "$code_redirect" ]; then
        echo "error: granting consent did not redirect to the callback" >&2
        exit 1
    fi

    local code
    code="$(python3 -c "
import sys, urllib.parse
qs = urllib.parse.parse_qs(urllib.parse.urlparse(sys.argv[1]).query)
print(qs.get('code', [''])[0])
" "$code_redirect")"

    if [ -z "$code" ]; then
        echo "error: no authorization code in the redirect: $code_redirect" >&2
        exit 1
    fi

    log "Exchanging the authorization code for an access token"
    local token_json
    token_json="$(curl -sf -X POST "$DEMO_SERVER/api/oauth/token" \
        -H "Content-Type: application/json" \
        -d "{\"grant_type\":\"authorization_code\",\"client_id\":\"$CLIENT_ID\",\"code\":\"$code\",\"code_verifier\":\"$verifier\",\"redirect_uri\":\"${OAUTH_REDIRECT_URI}\"}")"

    ACCESS_TOKEN="$(echo "$token_json" | json_get "d['access_token']")"
}

# Self-revocation (RFC 7009-style): authenticate with the token being revoked
# and name that same token in the body. Readeck checks the two match.
revoke_token() {
    curl -sf -X POST "$DEMO_SERVER/api/oauth/revoke" \
        -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"token\":\"$ACCESS_TOKEN\"}" >/dev/null
}

api() {
    # api <method> <path> [json-body]
    local method="$1" path="$2" body="${3:-}"
    if [ -n "$body" ]; then
        curl -sf -X "$method" "$DEMO_SERVER$path" \
            -H "Authorization: Bearer $ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$body"
    else
        curl -sf -X "$method" "$DEMO_SERVER$path" \
            -H "Authorization: Bearer $ACCESS_TOKEN"
    fi
}

seed_bookmark() {
    # seed_bookmark <title> -> sets REPLY_ID to the new bookmark's id
    local title="$1"
    api POST "/api/bookmarks" \
        "{\"url\":\"https://example.com\",\"title\":\"$title\",\"labels\":[\"$E2E_LABEL\"]}" >/dev/null

    # Creation is async (202), so poll until the bookmark shows up labelled.
    local attempt
    for attempt in $(seq 1 10); do
        REPLY_ID="$(api GET "/api/bookmarks?labels=%22${E2E_LABEL}%22" | python3 -c "
import json, sys
for b in json.load(sys.stdin):
    if b['title'] == sys.argv[1]:
        print(b['id'])
        break
" "$title" 2>/dev/null || true)"
        if [ -n "$REPLY_ID" ]; then
            return
        fi
        sleep 2
    done

    echo "error: bookmark '$title' never showed up after creation" >&2
    exit 1
}

delete_e2e_bookmarks() {
    local ids
    ids="$(api GET "/api/bookmarks?labels=%22${E2E_LABEL}%22" | python3 -c "
import json, sys
for b in json.load(sys.stdin):
    print(b['id'])
")"
    while IFS= read -r id; do
        [ -n "$id" ] || continue
        api DELETE "/api/bookmarks/$id" >/dev/null || true
    done <<<"$ids"
}

ensure_simulator() {
    SIMULATOR_UDID="$(xcrun simctl list devices -j \
        | python3 -c "
import json, sys
devices = json.load(sys.stdin)['devices']
for runtime_devices in devices.values():
    for d in runtime_devices:
        if d['name'] == sys.argv[1]:
            print(d['udid'])
            sys.exit()
" "$SIMULATOR_NAME")"

    if [ -z "$SIMULATOR_UDID" ]; then
        log "Creating simulator $SIMULATOR_NAME"
        SIMULATOR_UDID="$(xcrun simctl create "$SIMULATOR_NAME" "$SIMULATOR_DEVICE_TYPE" "$SIMULATOR_RUNTIME")"
    fi
}

build_and_install() {
    log "Building the app"
    # Ad-hoc signed, not just CODE_SIGNING_ALLOWED=NO: the keychain writes in
    # E2ETestSupport need a real entitlement, see the profile's note on -34018.
    xcodebuild build -project "$REPO_ROOT/readeck.xcodeproj" -scheme readeck \
        -destination "id=$SIMULATOR_UDID" \
        -derivedDataPath "$REPO_ROOT/build/DerivedData" \
        CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES -quiet

    local app_path
    app_path="$(find "$REPO_ROOT/build/DerivedData/Build/Products" -maxdepth 2 -name "readeck.app" -path "*iphonesimulator*" | head -1)"
    if [ -z "$app_path" ]; then
        echo "error: couldn't find the built readeck.app" >&2
        exit 1
    fi

    xcrun simctl boot "$SIMULATOR_UDID" 2>/dev/null || true
    xcrun simctl install "$SIMULATOR_UDID" "$app_path"
}

run_maestro() {
    log "Running Maestro flows"
    maestro --device "$SIMULATOR_UDID" test "$MAESTRO_DIR" \
        -e E2E_ENDPOINT="$DEMO_SERVER" \
        -e E2E_ACCESS_TOKEN="$ACCESS_TOKEN" \
        -e E2E_CLIENT_ID="$CLIENT_ID" \
        -e E2E_LABEL="$E2E_LABEL" \
        -e E2E_BOOKMARK_A_ID="$BOOKMARK_A_ID" \
        -e E2E_BOOKMARK_B_ID="$BOOKMARK_B_ID"
}

setup_java
setup_maestro
fetch_credentials
oauth_login

log "Seeding test bookmarks (label: $E2E_LABEL)"
seed_bookmark "Readeck E2E A"
BOOKMARK_A_ID="$REPLY_ID"
seed_bookmark "Readeck E2E B"
BOOKMARK_B_ID="$REPLY_ID"

ensure_simulator
build_and_install
run_maestro

log "All flows passed"
