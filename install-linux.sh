#!/bin/sh


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
B_BLUE="${ESC}1;34m"


PROG_NAME="Keeper Gateway"
EXE_NAME="keeper-gateway"
ALIAS_NAME="kg"
BIN_FOLDER="/usr/local/bin/"
INSTALL_PATH="${BIN_FOLDER}${EXE_NAME}"
ALIAS_PATH="/usr/local/bin/${ALIAS_NAME}"
LATEST_LINUX_BIN="https://mustinov-pam-artifacts.s3.us-east-1.amazonaws.com/keeper-gateway_v0.12.0h_linux_amd64?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEGkaCXVzLXdlc3QtMSJHMEUCIQC671yALjcs6N%2FONNXe6bZn7urX92TZns%2BPvsLgAxcDDAIgD3zVe5486zUOdnDyFVL%2FpxPLX9rvCh5Bj2YgNNcr6pEqiAMI8v%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FARAAGgwzNzM2OTkwNjY3NTciDEe59ZbQmnhiG2TMNCrcAsqUB9iN0AhWUEXRsjDOcYhGqIHfbrssrmtva5lTsLuVbhozm4%2FaGotvou3TQlNaI5Ebtt5zG94yJiGZcgI%2F1LHx23ncUjjtQyIwn%2FfJDKfkxqAN5lCRlq77f9Byc5t6TCF0Rvzm2iAbxV6w5kz%2FcAhtdjEBC1qKCe0XSixMrPYoetWpDR9V20V1dHoxJ58ui2oI0BNCYMN5m854vrjKsqVZR2oMeYJVRxLL5IHrcRrArSdhTHYF5iAxCaVKKngfVqnufATsTcBKSJaIvL7miMIYHbRs8FHYtthErpLUJtUVmMF5PDMk0t6zZS8KOaV50lkKDkIOcSPcAxjteP3ls0oBdP%2BHPepzKNK0TaLnPxZhO6TdUc0KHXfnOug7%2F%2FeqzxRsFTc6i2HQlcSHAI63XcuNFKg%2Fq5fcg7I2nBgGuoaPMDydUakLqVQD48vSbcafyMI9oLGCvz0DoPHCOTDh26mfBjqzAsvbjBDKYNR%2By7j4KOzNL%2B4fBxkYCrXca9btweb7ah%2BEN0JXZZmt9o8NtOmdAeHlWxd8%2BF5HzejGX49HGBL9c7ko%2FAswaPT2wu3wr6AHfVkok6UP58ClAyh2TR4dg3dk8OTabfJyxguEtLWvpgSI0vnKId5sQTPy60k4T%2B7OvuUILqr%2BrBCfC3OuHX4C9CY%2BtUxd6sk3aWqVewm1JDzDFeqrp2%2BU3K2LTtXco01WLyUxttKjaR9ZtsjuQTAYCFPlAPklvy7vuFCtL%2BDbwbIZEf9Xi1MYCbylZ13wYMQjXDWrLl0JOQ0umMWa%2BQRf0eR9SRYBWgLIJPwLdT9ebJTqBNpSawgIySxJutvZcL8zjWCj7igT2M4HU9rQFM02BRY4AzHKW6EMiKnCU3qukquDrV9%2Borc%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230213T170603Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIAVOARTHOCUKGEKKGO%2F20230213%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=938d93afb979bafa572d3e56c10fb111c53bb0202e481e6c935e084ae9450dff"
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
	echo -e "\n${F_RED}🛑 Unsupported OS \"$OS\" or architecture \"$ARCH\". Failed to install $PROG_NAME.${F_DEFAULT}"
    echo -e "${B_RED}Please report 🐛 to $REPO/issues${F_DEFAULT}"
	exit 1
fi


echo -e "\n🦈 ${B_BLUE}Started to download $PROG_NAME ${F_DEFAULT}"


if curl -# --fail -Lo $EXE_NAME "${LATEST_LINUX_BIN}" ; then
    chmod +x $PWD/$EXE_NAME
    echo -e "\n${F_GREEN}⬇️  $PROG_NAME is downloaded into $PWD/$EXE_NAME${F_DEFAULT}"
else
    echo -e "\n${F_RED}🛑 Couldn't download ${LATEST_LINUX_BIN}\n\
  ⚠️  Check your internet connection.\n\
  ⚠️  Make sure 'curl' command is available.\n\
  ⚠️  Make sure there is no directory named '${EXE_NAME}' in ${PWD}\n\
${F_DEFAULT}"
    echo -e "${B_RED}Please report 🐛 to sm@keepersecurity.com${F_DEFAULT}"
    exit 1
fi

use_cmd=$EXE_NAME
printf "Do you want to install system-wide into '${BIN_FOLDER}'? Requires sudo 😇 (y/N)? "
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ;then
    echo "$answer"
    sudo mv ./$EXE_NAME $INSTALL_PATH || exit 1
    echo -e "${F_GREEN}$PROG_NAME is installed into $INSTALL_PATH${F_DEFAULT}\n"

	ls $ALIAS_PATH >> /dev/null 2>&1
	if [ $? != 0 ] ; then
		printf "Do you want to add '${ALIAS_NAME}' alias for ${PROG_NAME} ? (y/N)? "
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

echo -e "${Color_Off}${F_GREEN}✅ You can use the ${Color_Off}${B_BLUE}$use_cmd${Color_Off}${F_GREEN} command now.${Color_Off}"
