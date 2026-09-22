#!/bin/sh
set -eu

export HOME="${HOME:-/data}"
export CYBERBOSS_STATE_DIR="${CYBERBOSS_STATE_DIR:-$HOME/.cyberboss}"
export CYBERBOSS_WORKSPACE_ROOT="${CYBERBOSS_WORKSPACE_ROOT:-$HOME/workspace}"

mkdir -p \
  "$CYBERBOSS_STATE_DIR" \
  "$CYBERBOSS_STATE_DIR/logs" \
  "$CYBERBOSS_WORKSPACE_ROOT" \
  "$HOME/.codex"

mode="${CYBERBOSS_BOOT_MODE:-run}"

case "$mode" in
  codex-login)
    echo "[cyberboss] Starting Codex device login. Open the URL from these logs and enter the displayed code."
    exec codex login --device-auth
    ;;
  weixin-login|wechat-login|login)
    echo "[cyberboss] Starting WeChat QR login. Save the QR/link from these logs and scan it in WeChat."
    exec npm run login
    ;;
  doctor)
    exec npm run doctor
    ;;
  run)
    if [ ! -d "$CYBERBOSS_STATE_DIR/accounts" ] || ! find "$CYBERBOSS_STATE_DIR/accounts" -maxdepth 1 -name '*.json' -print -quit 2>/dev/null | grep -q .; then
      echo "[cyberboss] No saved WeChat account was found in $CYBERBOSS_STATE_DIR/accounts."
      echo "[cyberboss] Set CYBERBOSS_BOOT_MODE=weixin-login, redeploy, scan the QR, then set it back to run."
      exit 1
    fi
    if [ -z "${CYBERBOSS_ALLOWED_USER_IDS:-}" ]; then
      echo "[cyberboss] CYBERBOSS_ALLOWED_USER_IDS is empty; refusing to expose a personal agent without an allowlist."
      echo "[cyberboss] Copy the userId printed by the WeChat login step into that variable, then redeploy."
      exit 1
    fi
    echo "[cyberboss] Starting the shared Codex runtime and WeChat bridge."
    exec npm run shared:start
    ;;
  *)
    echo "[cyberboss] Unknown CYBERBOSS_BOOT_MODE=$mode"
    echo "[cyberboss] Supported values: codex-login, weixin-login, doctor, run"
    exit 2
    ;;
esac

