#!/bin/bash


# Reset
Color_Off='\033[0m'       # Text Reset

# Colors
ESC="\033["


F_DEFAULT="${ESC}0;37m"   # Default white color
F_RED="${ESC}0;31m"
F_GREEN="${ESC}0;32m"
F_BLUE="${ESC}0;34m"

# BOLD
B_DEFAULT="${ESC}1;37m"   # Default BOLD white color
B_RED="${ESC}1;31m"
B_YELLOW="${ESC}1;33m"
B_BLUE="${ESC}1;34m"


PROG_NAME="Keeper Gateway"
EXE_NAME="keeper-gateway"
ALIAS_NAME="gateway"
BIN_FOLDER="/usr/local/bin/"
INSTALL_PATH="${BIN_FOLDER}${EXE_NAME}"
ALIAS_PATH="/usr/local/bin/${ALIAS_NAME}"

LATEST_LINUX_BIN="https://keepersecurity.com/pam/keeper-gateway_v0.13.0a_linux_amd64"
LATEST_MAC_PKG="https://keepersecurity.com/pam/keeper-gateway_v0.13.0a_darwin_amd64.pkg"

OS="$(echo $(uname -s) | tr '[:upper:]' '[:lower:]')"
ARCH="$(echo $(uname -m) | tr '[:upper:]' '[:lower:]')"
SUPPORTED_PAIRS="linux_amd64 linux_arm64 darwin_amd64 darwin_arm64"

if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

if [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi

echo $SUPPORTED_PAIRS | grep -w -q "${OS}_${ARCH}"

if [ $? != 0 ] ; then
	echo "\n${F_RED}🛑 Unsupported OS \"$OS\" or architecture \"$ARCH\". Failed to install $PROG_NAME.${F_DEFAULT}"
    echo "${B_RED}Please report 🐛 to $REPO/issues${F_DEFAULT}"
	exit 1
fi

installMac(){
  cd "$HOME"

  downloaddir="${HOME}/.keeper/${EXE_NAME}.pkg"

  mkdir -p "${HOME}/.keeper"

  echo -e "⛴${B_BLUE} => Downloading ${PROG_NAME} Installation package...${F_DEFAULT}";

  curl -H 'Cache-Control: no-cache' \
   "${LATEST_MAC_PKG}?$(date +%s)" \
   --output "$downloaddir" \
   -L \
   --silent

  echo -e "📦${B_BLUE} => ${PROG_NAME} download succeeded to $downloaddir.${F_DEFAULT}";

  sudo installer -verbose -pkg "$downloaddir" -target /

  # Cleanup
  echo -e "🚜${B_BLUE} => Cleaning up temp files...${F_DEFAULT}"
  rm -rf "$HOME/.keeper"

  echo -e "🚀${B_BLUE} => ${PROG_NAME} was installed successfully.${F_DEFAULT}";
  echo "";


}


installLinux(){
  echo -e "\n🦈 ${B_BLUE}Started to download $PROG_NAME ${F_DEFAULT}"


  if curl -# --fail -Lo $EXE_NAME "${LATEST_LINUX_BIN}" ; then
      chmod +x $PWD/$EXE_NAME
      echo -e "\n⬇️ ${F_GREEN}$PROG_NAME is downloaded into $PWD/$EXE_NAME${F_DEFAULT}"
  else
      echo -e "\n${F_RED}🛑 Couldn't download ${LATEST_LINUX_BIN}\n\
    ⚠️  Check your internet connection.\n\
    ⚠️  Make sure 'curl' command is available.\n\
    ⚠️  Make sure there is no directory named '${EXE_NAME}' in ${PWD}\n ${F_DEFAULT}"
      echo -e "${B_RED}Please report 🐛 to sm@keepersecurity.com${F_DEFAULT}"
      exit 1
  fi

  use_cmd=$EXE_NAME
  echo -e "Do you want to install system-wide into '${BIN_FOLDER}'? ${B_YELLOW}Requires sudo 😇 (y/N)${F_DEFAULT}? "
  old_stty_cfg=$(stty -g)
  stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  if echo "$answer" | grep -iq "^y" ;then
      echo "$answer"
      sudo mv ./$EXE_NAME $INSTALL_PATH || exit 1
      echo -e "${F_GREEN}$PROG_NAME is installed into $INSTALL_PATH${F_DEFAULT}\n"

  	ls $ALIAS_PATH >> /dev/null 2>&1
  	if [ $? != 0 ] ; then
  		echo -e "Do you want to add ${B_BLUE}'${ALIAS_NAME}'${F_DEFAULT} alias for ${PROG_NAME} ? (y/N)? "
  		old_stty_cfg=$(stty -g)
  		stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
  		if echo "$answer" | grep -iq "^y" ; then
  			echo "$answer"
  			sudo ln -s $INSTALL_PATH $ALIAS_PATH

  			use_cmd=$ALIAS_NAME
  		else
  			echo "$answer"
  		fi
  	else
  		use_cmd=$ALIAS_NAME
  	fi
  else
  	echo "$answer"
  	use_cmd="./$EXE_NAME"
  fi

  echo -e "${F_GREEN}✅ You can use the ${F_DEFAULT}${B_BLUE}$use_cmd${F_DEFAULT}${F_GREEN} command now.${F_DEFAULT}"

}

if [[ $OSTYPE = 'darwin'* ]]; then
  installMac
elif [[ $OSTYPE = 'linux'* ]]; then
  installLinux
else
    echo '💔 Not supported OS.'
    exit 1
fi
