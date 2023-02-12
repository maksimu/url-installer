#!/bin/sh

# Colors
ESC="\033["
F_DEFAULT=39
F_RED=31
F_GREEN=32
F_YELLOW=33
B_DEFAULT=49
B_RED=41
B_BLUE=44
B_LIGHT_BLUE=104


PROG_NAME=Keeper Gateway
EXE_NAME=keeper-gateway
ALIAS_NAME=kg
INSTALL_PATH=/usr/local/bin/$EXE_NAME
ALIAS_PATH=/usr/local/bin/$ALIAS_NAME
LATEST_LINUX_BIN="https://mustinov-pam-artifacts.s3.us-east-1.amazonaws.com/keeper-gateway_v0.12.0h_linux_amd64?response-content-disposition=inline&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEYaCXVzLXdlc3QtMSJGMEQCID8xU%2F2JZq6r%2F63kpYw%2BXlfipo1Hz4S5Fk8tLyrj5nC8AiBPhyc1Ns4%2F7hQ5bG3ghzAzGDIHj0tW9kV4R3QzXlp5SiqIAwjP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F8BEAAaDDM3MzY5OTA2Njc1NyIMfGW61YGTjUExc7uAKtwC9b1mOHbvExt%2Bd5TSZ3dY6YuDN5IiTdGwsHHdQaBoGp1K1Es%2F8pDgoUdD25D%2FE30%2Fh224qEsFRJVSgc%2B8uXV5%2BWfrTwKMzwPxeCnfAB7YOzZNhBUZ9J%2BLT%2Blbmx8cHHa4u4rOyu2rSojMFPYhEy7gJivq7mio1dH28aBpqg2ScKqBuslIsQCtJL7qFK3WHSGV7nKe%2BkjQS1nV1K%2FsaiP1Wg%2Fs6bYlts7f2Rk8gjxvnwb9E3SxUngWdKmNC%2B5B%2BGhxVKDxKj09Atg1ybmoDiOhLRy8f6%2BRf7oTBPMOzPklHjMH8a8nLQHlcJ7Ir0bqJMS1V68hKtn1V9KMlMHH5E6ZNzekxETUCw2caBX5bixxse%2FXsylpL7QUI%2FEnrzpcQZCKp4TSOURFJr9%2Ffh2O2FukucczIfKxOAYIPxDibKg5cH%2BQ%2B3Kb7INdrV3Qxu30sb3PwG8PyieufGHVQBNTMJ%2BAop8GOrQCic3YycFvAH5HtMpc2w9AGqwFcRI6rxI7wqIWULFRt4SI%2FUdXBuY7z1aWeWljQnq3Top62lFb513n8It13va0%2BTblR0mWVIk4R4VG90hxRP1koAx1FqrALtJ%2BPFCXZkcu9ENH2eF%2BCNUx5pf2A6TPIREcZFcIlCHj4DZvphHayqUkY7sEfId1yb5CG1X7v%2FhVJyyp5b0nJDZiWAJgtLofB8QgD%2Fx7KCxlBVBYe7LBJlx1axKHbKPC8XUP%2BmKmBX6Tjy4FBmPEGscX7rY75VMXIRZwPJ02mmdm3MDRSNPQBUtWS9e8atqKPCuwwCiEqAT%2Bm4wBLwTQYmmmmZVTWXtR6AK1WixbLCovtT23MRKAZw%2F7V4UPmvJnWn2Hmt54N6T94O2rSSjwaHIi6epAIRpZy3XwhyM%3D&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Date=20230212T062142Z&X-Amz-SignedHeaders=host&X-Amz-Expires=43200&X-Amz-Credential=ASIAVOARTHOC2J6NEV4F%2F20230212%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Signature=0ba72e4e541a7fa518abae5d3945969bf6e941c669c475ad5822113b3a94cd84"
OS=$(echo $(uname -s) | tr '[:upper:]' '[:lower:]')
ARCH=$(echo $(uname -m) | tr '[:upper:]' '[:lower:]')
SUPPORTED_PAIRS="linux_amd64 linux_arm64 darwin_amd64 darwin_arm64"

if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
fi

if [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi

echo $SUPPORTED_PAIRS | grep -w -q "${OS}_${ARCH}"

if [ $? != 0 ] ; then
	echo "\n${ESC}${F_RED}m🛑 Unsupported OS \"$OS\" or architecture \"$ARCH\". Failed to install $PROG_NAME.${ESC}${F_DEFAULT}m"
    echo "${ESC}${B_RED}mPlease report 🐛 to $REPO/issues${ESC}${F_DEFAULT}m"
	exit 1
fi


echo "\n🦈 ${ESC}${F_DEFAULT};${B_BLUE}m Started to download $PROG_NAME ${ESC}${B_DEFAULT};${F_DEFAULT}m"


if curl -# --fail -Lo $EXE_NAME "${LATEST_LINUX_BIN}" ; then
    chmod +x $PWD/$EXE_NAME
    echo "\n${ESC}${F_GREEN}m⬇️  $PROG_NAME is downloaded into $PWD/$EXE_NAME${ESC}${F_DEFAULT}m"
else
    echo "\n${ESC}${F_RED}m🛑 Couldn't download ${LATEST_LINUX_BIN}\n\
  ⚠️  Check your internet connection.\n\
  ⚠️  Make sure 'curl' command is available.\n\
  ⚠️  Make sure there is no directory named '${EXE_NAME}' in ${PWD}\n\
${ESC}${F_DEFAULT}m"
    echo "${ESC}${B_RED}mPlease report 🐛 to sm@keepersecurity.com${ESC}${F_DEFAULT}m"
    exit 1
fi

use_cmd=$EXE_NAME
printf "Do you want to install system-wide? Requires sudo 😇 (y/N)? "
old_stty_cfg=$(stty -g)
stty raw -echo ; answer=$(head -c 1) ; stty $old_stty_cfg
if echo "$answer" | grep -iq "^y" ;then
    echo "$answer"
    sudo mv ./$EXE_NAME $INSTALL_PATH || exit 1
    echo "${ESC}${F_GREEN}m$PROG_NAME is installed into $INSTALL_PATH${ESC}${F_DEFAULT}m\n"

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

echo "${ESC}${F_GREEN}m✅ You can use the ${ESC}${F_DEFAULT};${B_LIGHT_BLUE}m $use_cmd ${ESC}${B_DEFAULT};${F_GREEN}m command now.${ESC}${F_DEFAULT}m"
