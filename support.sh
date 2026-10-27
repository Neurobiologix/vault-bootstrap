#!/bin/bash
# Open or close the door for a support session on a Mac (consent per session).
#   bash <(curl -fsSL https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.sh) on
#   bash <(curl -fsSL https://raw.githubusercontent.com/Neurobiologix/vault-bootstrap/main/support.sh) off
# "on" turns Remote Login on (asks for your Mac password) so William can connect over Tailscale with his key;
# "off" turns it off again. Nothing else changes. Same as System Settings -> General -> Sharing -> Remote Login.
case "$1" in
  on)  sudo systemsetup -setremotelogin on  && echo "Remote Login ON: William can connect for this session. Run with 'off' when done." ;;
  off) sudo systemsetup -setremotelogin off && echo "Remote Login OFF." ;;
  status) sudo systemsetup -getremotelogin ;;
  *) echo "usage: support.sh on|off|status"; exit 1 ;;
esac
