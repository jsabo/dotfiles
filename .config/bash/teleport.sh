# shellcheck shell=bash
# --- Default Teleport settings ------------------------------------------------
# Preserve an explicitly selected persona when starting a nested shell.

# Active cluster: "cloud" (pc3ai.teleport.sh) or "selfhosted" (pc3ai.teleportdemo.com)
export DOTFILES_TELEPORT_CLUSTER="${DOTFILES_TELEPORT_CLUSTER:-cloud}"

# --- Teleport cluster selector ------------------------------------------------
_tp_proxy() {
  [ "$DOTFILES_TELEPORT_CLUSTER" = "selfhosted" ] && echo "pc3ai.teleportdemo.com:443" || echo "pc3ai.teleport.sh:443"
}
_tp_home() {
  [ "$DOTFILES_TELEPORT_CLUSTER" = "selfhosted" ] && echo "$HOME/.tsh-${1}-sh" || echo "$HOME/.tsh-${1}"
}

tcloud() {
  DOTFILES_TELEPORT_CLUSTER="cloud"
  echo "Cluster: cloud (pc3ai.teleport.sh)"
  if [ -n "${TELEPORT_DEMO_USER:-}" ]; then teleport_demo_user "$TELEPORT_DEMO_USER"; fi
}
tself() {
  DOTFILES_TELEPORT_CLUSTER="selfhosted"
  echo "Cluster: self-hosted (pc3ai.teleportdemo.com)"
  if [ -n "${TELEPORT_DEMO_USER:-}" ]; then teleport_demo_user "$TELEPORT_DEMO_USER"; fi
}

# --- Teleport identity switching ----------------------------------------------
teleport_demo_user() {
  case "${1:-}" in
    sabo|alice|bob|connor)
      export TELEPORT_DEMO_USER="$1"
      TELEPORT_HOME="$(_tp_home "$1")"
      export TELEPORT_HOME
      TELEPORT_PROXY="$(_tp_proxy)"
      export TELEPORT_PROXY
      export TELEPORT_AUTH="okta-integrator"
      ;;
    # jonathan@sabo.io lives in the Entra ID tenant, not Okta: same per-persona
    # tsh home pattern, different SSO connector.
    jonathan)
      export TELEPORT_DEMO_USER="$1"
      TELEPORT_HOME="$(_tp_home "$1")"
      export TELEPORT_HOME
      TELEPORT_PROXY="$(_tp_proxy)"
      export TELEPORT_PROXY
      export TELEPORT_AUTH="entra-id"
      ;;
    off|clear|reset|none)
      unset TELEPORT_DEMO_USER TELEPORT_HOME TELEPORT_PROXY TELEPORT_AUTH
      echo "Teleport settings cleared"
      return 0
      ;;
    *)
      echo "Usage: teleport_demo_user {sabo|alice|bob|connor|jonathan|off}"
      return 1
      ;;
  esac

  echo "Teleport persona : $TELEPORT_DEMO_USER  ($DOTFILES_TELEPORT_CLUSTER)"
  echo "  TELEPORT_HOME  : $TELEPORT_HOME"
  echo "  TELEPORT_PROXY : $TELEPORT_PROXY"
  echo "  TELEPORT_AUTH  : $TELEPORT_AUTH"
  echo
  echo "Next step:"
  echo "  tsh login --browser=none --proxy=\"$TELEPORT_PROXY\" --auth=\"$TELEPORT_AUTH\""
  echo
  echo "Then copy/paste the URL into the matching Chrome profile:"
  echo "  sabo   -> sabo@pc3.ai"
  echo "  alice  -> alice@pc3.ai"
  echo "  bob    -> bob@pc3.ai"
  echo "  connor -> connor@pc3.ai"
  echo "  jonathan -> jonathan@sabo.io (Entra ID)"
}

tsabo()     { teleport_demo_user sabo; }
talice()    { teleport_demo_user alice; }
tbob()      { teleport_demo_user bob; }
tconnor()   { teleport_demo_user connor; }
tjonathan() { teleport_demo_user jonathan; }
tnone()     { teleport_demo_user off; }

# --- Teleport Connect, one window per persona ---------------------------------
# Connect keys its profiles by proxy host, so one tsh home can hold ONE user per
# cluster. Personas therefore need separate homes, and Connect reads its tshHome
# from app_config.json inside its data directory at startup. Two knobs make a
# second window possible: Electron's --user-data-dir moves the data directory
# AND the single-instance lock (main.ts takes the lock before reading any env,
# so the env var alone is refused as "second instance"), and CONNECT_DATA_DIR
# (web/packages/teleterm/src/mainProcess/runtimeSettings.ts) relocates home and
# session data to match. Each persona gets its own Connect window that runs at
# the same time as the others. The persona's tsh home is the same
# ~/.tsh-<persona> the t<persona> + tlogin helpers log into — Connect watches
# that directory, so log in from the terminal (right Chrome profile) and the
# window picks the session up.
#
#   tconnect            # persona from the current shell (after tsabo etc.), or main
#   tconnect bob        # explicit persona
#   tconnect main       # the stock Connect: ~/.tsh, jonathan.sabo@goteleport.com
tconnect() {
  local app="${TELEPORT_CONNECT_BIN:-/Applications/Teleport Connect.app/Contents/MacOS/Teleport Connect}"
  [ -x "$app" ] || { echo "Teleport Connect not found at $app" >&2; return 1; }
  local p="${1:-${TELEPORT_DEMO_USER:-main}}"
  case "$p" in
    main)
      ( "$app" >/dev/null 2>&1 & ) ;;
    sabo|alice|bob|connor|jonathan)
      command -v jq >/dev/null 2>&1 || { echo "tconnect requires jq" >&2; return 1; }
      local data="$HOME/.connect-$p" home config tmp
      [ "$DOTFILES_TELEPORT_CLUSTER" != selfhosted ] || data="$data-sh"
      home="$(_tp_home "$p")"
      mkdir -p "$data/userData" "$home" || return
      config="$data/userData/app_config.json"
      tmp="$(mktemp "$data/userData/.app_config.XXXXXX")" || return
      # Update only the managed home. Preserve existing application preferences.
      # shellcheck disable=SC2016
      if ! jq -s --arg home "$home" '
        if length != 1 or (.[0] | type != "object") then error("Connect config must be one object") else
          .[0] |
          .tshHome = $home |
          if has("$schema") then . else .["$schema"] = "schema_app_config.json" end |
          if has("usageReporting.enabled") then . else .["usageReporting.enabled"] = false end
        end' "${config:-/dev/null}" > "$tmp" 2>/dev/null; then
        if [ -e "$config" ]; then
          rm -f "$tmp"
          echo "Invalid Connect config; left unchanged: $config" >&2
          return 1
        fi
        jq -n --arg home "$home" '{tshHome:$home,"$schema":"schema_app_config.json","usageReporting.enabled":false}' > "$tmp" || { rm -f "$tmp"; return 1; }
      fi
      # An empty file is invalid too: jq can exit successfully without output.
      if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        echo "Empty Connect config; left unchanged: $config" >&2
        return 1
      fi
      chmod 600 "$tmp"
      mv "$tmp" "$config" || { rm -f "$tmp"; return 1; }
      echo "Teleport Connect as $p  (tsh home $home, data $data)"
      [ -f "$home/current-profile" ] || echo "  not logged in yet: run t$p then tlogin, the window will pick it up"
      ( CONNECT_DATA_DIR="$data" "$app" --user-data-dir="$data/userData" >/dev/null 2>&1 & ) ;;
    *)
      echo "Usage: tconnect {main|sabo|alice|bob|connor|jonathan}" >&2; return 1 ;;
  esac
}

# --- Teleport helpers ----------------------------------------------------------
tlogin() {
  if [ -z "${TELEPORT_PROXY:-}" ] || [ -z "${TELEPORT_AUTH:-}" ] || [ -z "${TELEPORT_HOME:-}" ]; then
    echo "Teleport environment is not set."
    echo "Run one of: tsabo, talice, tbob"
    return 1
  fi

  echo "Using Teleport persona: ${TELEPORT_DEMO_USER:-unknown}"
  echo "Using TELEPORT_HOME: $TELEPORT_HOME"
  echo "Starting SSO login via: $TELEPORT_AUTH"
  echo
  echo "Browser auto-open is disabled."
  echo "Copy/paste the login URL into the correct Chrome profile."
  tsh login --browser=none --proxy="$TELEPORT_PROXY" --auth="$TELEPORT_AUTH"
}

tstatus() {
  tsh status
}

tlogout() {
  # TELEPORT_PROXY acts like --proxy, which makes `tsh logout` demand --user.
  # Each persona has its own TELEPORT_HOME, so a full logout there is safe.
  env -u TELEPORT_PROXY tsh logout
}

twho() {
  echo "Teleport persona: ${TELEPORT_DEMO_USER:-unset}"
  echo "TELEPORT_HOME: ${TELEPORT_HOME:-unset}"
  echo "TELEPORT_PROXY: ${TELEPORT_PROXY:-unset}"
  echo "TELEPORT_AUTH: ${TELEPORT_AUTH:-unset}"
  echo
  tsh status 2>/dev/null || true
}

# Everything the current persona could request, in one shot.
#
# There is no single tsh command for this: `tsh request search --kind` accepts
# exactly one kind and has no "all" option, so this loops the kinds. Roles are a
# separate flag (--roles) from resources.
#
# Nothing here is standing access — `tsh ls` / `tsh db ls` / `tsh kube ls` show
# what the persona HOLDS. This shows what it could ask for.
treq() {
  if [ -z "${TELEPORT_HOME:-}" ]; then
    echo "Teleport environment is not set."
    echo "Run one of: tsabo, talice, tbob, tconnor"
    return 1
  fi

  # Strip the two header lines and the ---- rule from every tsh table.
  _treq_col() { awk -v c="$1" 'NR>2 && NF && $1 !~ /^-+$/ {print "   " $c}'; }

  echo "Requestable for ${TELEPORT_DEMO_USER:-unknown} (${TELEPORT_HOME})"
  echo "-- roles"
  tsh request search --roles 2>/dev/null | _treq_col 1

  # node is the odd one out: column 1 is the host UUID and column 2 is the
  # hostname. Every other kind puts the useful name in column 1.
  echo "-- node"
  tsh request search --kind node 2>/dev/null | _treq_col 2

  local k
  for k in db kube_cluster app windows_desktop; do
    echo "-- $k"
    tsh request search --kind "$k" 2>/dev/null | _treq_col 1
  done

  # Kubernetes namespaces are a sub-resource, so they need the cluster named.
  local c
  for c in $(tsh request search --kind kube_cluster 2>/dev/null |
             awk 'NR>2 && NF && $1 !~ /^-+$/ {print $1}'); do
    echo "-- namespaces in $c"
    tsh request search --kind kube_resource --kube-kind namespaces \
      --kube-cluster "$c" --all-kube-namespaces 2>/dev/null | _treq_col 1
  done

  unset -f _treq_col
}

# A real MCP handshake and bounded response wait; stderr remains visible.
mcp_call() {
  command -v python3 >/dev/null 2>&1 || { echo "mcp_call requires python3" >&2; return 1; }
  python3 "$HOME/.config/bash/mcp_call.py" "$@"
}
