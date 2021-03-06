#!/usr/bin/env bash

set -e;

ql_magenta='\033[1;35m'
ql_green='\033[1;32m'
ql_no_color='\033[0m'

ONE_TIME_TOKEN="${1}"

echo -e "🎟 => ONE TIME TOKEN=[${ql_green}${ONE_TIME_TOKEN}${ql_no_color}]"

read -p "$(echo -e "${ql_green}"👌 This script will install KSM silently on your macOS. "${ql_magenta}" Are you sure? [y/N] "${ql_no_color}")" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

if [[ $OSTYPE != 'darwin'* ]]; then
  echo '💔 Not macOS. This script only works on macOS.'
  exit 1
fi


cd "$HOME"

downloaddir=$HOME/.keeper-gateway/ksmcli.pkg

mkdir -p "$HOME/.keeper-gateway"

echo -e "⛴${ql_green} => Downloading KSM CLI Installation package...${ql_no_color}";

curl -H 'Cache-Control: no-cache' \
 "https://github.com/Keeper-Security/secrets-manager/releases/download/ksm-cli-1.0.14/keeper-secrets-manager-cli-macos-1.0.14.pkg?$(date +%s)" \
 --output "$downloaddir" \
 -L \
 --silent


echo -e "📦${ql_green} => KSM CLI download succeeded to $downloaddir.${ql_no_color}";

sudo installer -verbose -pkg "$downloaddir" -target /


# Cleanup
echo -e "🚜${ql_green} => Cleaning up temp files...${ql_no_color}"
rm -rf "$HOME/.keeper-gateway"

echo -e "🚀${ql_green} => KSM was installed successfully.${ql_no_color}";
echo "";
