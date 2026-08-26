# --- Aliases ------------------------------------------------------------------
alias ls='ls --color'
alias vi='vim'
alias c='clear'
alias k='kubectl'
alias ctx='kubectx'
export PATH="$HOME/.local/bin:$PATH"

# --- Default Teleport settings ------------------------------------------------
# Start with no Teleport persona selected so your prompt stays clean.
unset TELEPORT_DEMO_USER
unset TELEPORT_HOME
unset TELEPORT_PROXY
unset TELEPORT_AUTH

# Active cluster: "cloud" (pc3ai.teleport.sh) or "selfhosted" (pc3ai.teleportdemo.com)
TELEPORT_CLUSTER="cloud"

# --- Teleport cluster selector ------------------------------------------------
_tp_proxy() {
  [ "$TELEPORT_CLUSTER" = "selfhosted" ] && echo "pc3ai.teleportdemo.com:443" || echo "pc3ai.teleport.sh:443"
}
_tp_home() {
  [ "$TELEPORT_CLUSTER" = "selfhosted" ] && echo "$HOME/.tsh-${1}-sh" || echo "$HOME/.tsh-${1}"
}

tcloud() {
  TELEPORT_CLUSTER="cloud"
  echo "Cluster: cloud (pc3ai.teleport.sh)"
  [ -n "$TELEPORT_DEMO_USER" ] && teleport_demo_user "$TELEPORT_DEMO_USER"
}
tself() {
  TELEPORT_CLUSTER="selfhosted"
  echo "Cluster: self-hosted (pc3ai.teleportdemo.com)"
  [ -n "$TELEPORT_DEMO_USER" ] && teleport_demo_user "$TELEPORT_DEMO_USER"
}

# --- Teleport identity switching ----------------------------------------------
teleport_demo_user() {
  case "$1" in
    sabo|alice|bob|connor)
      export TELEPORT_DEMO_USER="$1"
      export TELEPORT_HOME="$(_tp_home "$1")"
      export TELEPORT_PROXY="$(_tp_proxy)"
      export TELEPORT_AUTH="okta-integrator"
      ;;
    off|clear|reset|none)
      unset TELEPORT_DEMO_USER TELEPORT_HOME TELEPORT_PROXY TELEPORT_AUTH
      echo "Teleport settings cleared"
      return 0
      ;;
    *)
      echo "Usage: teleport_demo_user {sabo|alice|bob|connor|off}"
      return 1
      ;;
  esac

  echo "Teleport persona : $TELEPORT_DEMO_USER  ($TELEPORT_CLUSTER)"
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
}

tsabo()   { teleport_demo_user sabo; }
talice()  { teleport_demo_user alice; }
tbob()    { teleport_demo_user bob; }
tconnor() { teleport_demo_user connor; }
tnone()   { teleport_demo_user off; }

# --- Teleport helpers ----------------------------------------------------------
tlogin() {
  if [ -z "$TELEPORT_PROXY" ] || [ -z "$TELEPORT_AUTH" ] || [ -z "$TELEPORT_HOME" ]; then
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
  if [ -z "$TELEPORT_HOME" ]; then
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

# --- MCP demo helper -----------------------------------------------------------
# Make one MCP tool call through Teleport from the terminal (no AI client needed).
# MCP is JSON-RPC 2.0 over stdio: this sends the initialize handshake, the
# initialized notification, then the tools/call, and greps the id:2 response.
# The sleep keeps stdin open long enough for the server to reply.
#
#   mcp_call <app> <tool> [json-args]
#   mcp_call postgres-mcp list_schemas
#   mcp_call postgres-mcp execute_sql '{"sql":"DROP TABLE products"}'
mcp_call() {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: mcp_call <app> <tool> [json-args]" >&2
    echo "  e.g. mcp_call postgres-mcp list_schemas" >&2
    return 2
  fi
  local args='{}'; [ -n "$3" ] && args="$3"
  # tsh reissues a cert per connect (~4s) and closes the session on stdin EOF, so
  # hold stdin open long enough for the reply. The result prints as soon as it
  # arrives; the prompt returns after the wait. Bump MCP_CALL_WAIT if a cold call
  # comes back empty.
  { printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"demo","version":"1"}}}' \
                  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
                  "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/call\",\"params\":{\"name\":\"$2\",\"arguments\":$args}}"
    sleep "${MCP_CALL_WAIT:-10}"; } | tsh mcp connect "$1" 2>/dev/null | grep --line-buffered '"id":2'
}
