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

# --- Teleport identity switching ----------------------------------------------
teleport_demo_user() {
  case "$1" in
    sabo)
      export TELEPORT_DEMO_USER="sabo"
      export TELEPORT_HOME="$HOME/.tsh-sabo"
      export TELEPORT_PROXY="pc3ai.teleport.sh:443"
      export TELEPORT_AUTH="okta-integrator"
      ;;
    alice)
      export TELEPORT_DEMO_USER="alice"
      export TELEPORT_HOME="$HOME/.tsh-alice"
      export TELEPORT_PROXY="pc3ai.teleport.sh:443"
      export TELEPORT_AUTH="okta-integrator"
      ;;
    bob)
      export TELEPORT_DEMO_USER="bob"
      export TELEPORT_HOME="$HOME/.tsh-bob"
      export TELEPORT_PROXY="pc3ai.teleport.sh:443"
      export TELEPORT_AUTH="okta-integrator"
      ;;
    off|clear|reset|none)
      unset TELEPORT_DEMO_USER
      unset TELEPORT_HOME
      unset TELEPORT_PROXY
      unset TELEPORT_AUTH
      echo "Teleport settings cleared"
      return 0
      ;;
    *)
      echo "Usage: teleport_demo_user {sabo|alice|bob|off}"
      return 1
      ;;
  esac

  echo "Teleport persona: $TELEPORT_DEMO_USER"
  echo "  TELEPORT_HOME=$TELEPORT_HOME"
  echo "  TELEPORT_PROXY=$TELEPORT_PROXY"
  echo "  TELEPORT_AUTH=$TELEPORT_AUTH"
  echo
  echo "Next step:"
  echo "  tsh login --browser=none --proxy=\"$TELEPORT_PROXY\" --auth=\"$TELEPORT_AUTH\""
  echo
  echo "Then copy/paste the URL into the matching Chrome profile:"
  echo "  sabo  -> sabo@pc3.ai"
  echo "  alice -> alice@pc3.ai"
  echo "  bob   -> bob@pc3.ai"
}

tsabo()  { teleport_demo_user sabo; }
talice() { teleport_demo_user alice; }
tbob()   { teleport_demo_user bob; }
tnone()  { teleport_demo_user off; }

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
  tsh logout
}

twho() {
  echo "Teleport persona: ${TELEPORT_DEMO_USER:-unset}"
  echo "TELEPORT_HOME: ${TELEPORT_HOME:-unset}"
  echo "TELEPORT_PROXY: ${TELEPORT_PROXY:-unset}"
  echo "TELEPORT_AUTH: ${TELEPORT_AUTH:-unset}"
  echo
  tsh status 2>/dev/null || true
}
