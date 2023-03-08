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


if ! command -v curl &> /dev/null
then
    echo -e "🛑${F_RED} => curl is not installed. Please install it and try again.${F_DEFAULT}"
    exit 1
fi

SERVICE_NAME="keeper-gateway.service"

LATEST_LINUX_BIN="https://keepersecurity.com/pam/keeper-gateway_linux_x86_64"
LATEST_MAC_PKG="https://keepersecurity.com/pam/keeper-gateway_darwin_x86_64.pkg"
LATEST_WIN_EXE="https://keepersecurity.com/pam/keeper-gateway_windows_x86.exe"

OS="$(echo $(uname -s) | tr '[:upper:]' '[:lower:]')"
ARCH="$(echo $(uname -m) | tr '[:upper:]' '[:lower:]')"
SUPPORTED_PAIRS="linux_x86_64 linux_arm64 darwin_x86_64 darwin_arm64"


if [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
fi

echo $SUPPORTED_PAIRS | grep -w -q "${OS}_${ARCH}"

if [ $? != 0 ] ; then
	echo -e "\n${F_RED}🛑Unsupported OS \"$OS\" or architecture \"$ARCH\". Failed to install $PROG_NAME.${F_DEFAULT}"
  echo -e "${B_RED}Please report issues to sm@keepersecurity.com${F_DEFAULT}"
	exit 1
fi

# Parse parameters
while [[ $# -gt 0 ]]; do

case $1 in
    -t|--token)
    TOKEN="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    shift # past argument
    ;;
esac
done


echo -e "📦${B_BLUE} => Installing $PROG_NAME...${F_DEFAULT}"

if [ -z "$TOKEN" ]; then

  echo "    Token parameter is not set."
else
  echo "    Token parameter is set to $TOKEN"
fi



installMac(){
  cd "$HOME"

  macpkgfiledest="${HOME}/.keeper/${EXE_NAME}.pkg"

  mkdir -p "${HOME}/.keeper"

  echo -e "⛴${B_BLUE} => Downloading latest ${PROG_NAME} Installation package...${F_DEFAULT}";


  if curl -# --fail -Lo "$macpkgfiledest" "${LATEST_MAC_PKG}" ; then
      echo -e "\n📦${F_GREEN} => Package download succeeded to $macpkgfiledest${F_DEFAULT}"
  else
      echo -e "\n🛑${F_RED} => Couldn't download ${LATEST_MAC_PKG}\n\
    ⚠️  Check your internet connection.\n\
    ⚠️  Make sure 'curl' command is available.\n ${F_DEFAULT}"
      echo -e "${B_RED} => Please report issues to sm@keepersecurity.com${F_DEFAULT}"
      exit 1
  fi

  sudo installer -verbose -pkg "$macpkgfiledest" -target /

  # Cleanup
  echo -e "🚜${B_BLUE} => Cleaning up downloaded package $macpkgfiledest ${F_DEFAULT}"
  rm -rf "$macpkgfiledest"

  if [ -z "$TOKEN" ]; then
    echo "    Token parameter is not set."
    echo -e "🚀${F_GREEN} => You can use the ${F_DEFAULT}${B_BLUE}$ALIAS_NAME${F_DEFAULT}${F_GREEN} command now.${F_DEFAULT}"
  else
    echo "    Token parameter is set to $TOKEN."
    echo "    Initializing One-Time Token and creating config file (~/.keeper/gateway-config.json). Please wait..."
    $ALIAS_PATH ott-init --json "$TOKEN" > ~/.keeper/gateway-config.json

    echo "    Starting Gateway. Please wait..."
    $ALIAS_PATH start -d
  fi



  echo "";
}


installSystemctlService(){
  SERVICE_USERNAME="keeper-gateway-service"
  SERVICE_LOGS_FOLDER="/var/log/keeper-gateway"
  SERVICE_CONFIG_FOLDER="/etc/keeper-gateway"
  SERVICE_CONFIG_FILE_PATH="$SERVICE_CONFIG_FOLDER/gateway-config.json"


  # Check if systemctl is available
  if which systemctl >/dev/null; then
    echo -e "✅${F_GREEN} => systemctl exists on this system and will be used to install $SERVICE_NAME service${F_DEFAULT}"
  else
    echo -e "❗️${B_RED} => systemctl could not be found. $SERVICE_NAME will not be installed on this system${F_DEFAULT}"
    return 1
  fi


  # Check if user already exists
  if ! id -u {$SERVICE_USERNAME} &> /dev/null
  then
      echo "    Create the user '$SERVICE_USERNAME' to run the service"
      adduser --disabled-password --gecos "" "$SERVICE_USERNAME" >/dev/null 2>/dev/tty
  else
      echo "    User $SERVICE_USERNAME already exists on this system. Skipping creation."
  fi


  if [ ! -d $SERVICE_LOGS_FOLDER ]
  then
      echo -e "✅${F_GREEN} => Create directory to store Gateway logs with appropriate permissions ($SERVICE_LOGS_FOLDER)${F_DEFAULT}"
      mkdir -p $SERVICE_LOGS_FOLDER
      chmod 700 $SERVICE_LOGS_FOLDER
      chown "$SERVICE_USERNAME":"$SERVICE_USERNAME" $SERVICE_LOGS_FOLDER
  else
      echo -e "✅${F_GREEN} => Directory $SERVICE_LOGS_FOLDER already exists on this system${F_DEFAULT}"
  fi


  if [ ! -d $SERVICE_CONFIG_FOLDER ]
  then
    echo -e "✅${F_GREEN} => Create directory to store config file with appropriate permissions ($SERVICE_CONFIG_FOLDER)${F_DEFAULT}"
    mkdir -p $SERVICE_CONFIG_FOLDER
    chmod 700 $SERVICE_CONFIG_FOLDER
    chown "$SERVICE_USERNAME":"$SERVICE_USERNAME" $SERVICE_CONFIG_FOLDER
  else
      echo "    "
      echo -e "✅${F_GREEN} => Directory $SERVICE_CONFIG_FOLDER already exists on this system${F_DEFAULT}"
  fi


  if [ -f /etc/systemd/system/${SERVICE_NAME} ]
  then
      echo -e "✅${F_GREEN} => Updating service unit file at /etc/systemd/system/${SERVICE_NAME}${F_DEFAULT}"
  else
      echo -e "✅${F_GREEN} => Creating service unit file at /etc/systemd/system/${SERVICE_NAME}${F_DEFAULT}"
  fi

  tee >/etc/systemd/system/${SERVICE_NAME} << EOF
[Unit]
Description=${PROG_NAME} Service
After=network.target

[Service]
Type=simple
ExecStart=${ALIAS_PATH} start -d --service --config-file $SERVICE_CONFIG_FILE_PATH
User=$SERVICE_USERNAME
Group=$SERVICE_USERNAME
StandardOutput=file:$SERVICE_LOGS_FOLDER/service-out.log
StandardError=file:$SERVICE_LOGS_FOLDER/service_error.log
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  echo -e "✅${F_GREEN} => Reloading systemd configuration ${F_DEFAULT}"
  systemctl daemon-reload

  echo -e "✅${F_GREEN} => Enabling service to start automatically on boot ${F_DEFAULT}"
  systemctl enable "${SERVICE_NAME}"


  ONE_TIME_TOKEN_VAL=""

  if [ -z "$TOKEN" ]; then
    echo -e "✅${F_GREEN} => Token parameter is not set${F_DEFAULT}"

    read -p "   Do you want to initialize and start the service right now with a one-time token? (yes/y or no/n) " choice

    if [[ "$choice" == "yes" || "$choice" == "y" ]]; then
      read -p "   Please enter the one-time token: " ONE_TIME_TOKEN_VAL
    elif [[ "$choice" == "no" || "$choice" == "n" ]]; then
      echo "    You can initialize the service later by running the command:
      '$ALIAS_PATH ott-init --json $ONE_TIME_TOKEN_VAL > $SERVICE_CONFIG_FILE_PATH'"
      return 1
    else
      echo "    Invalid choice"
      echo "    You can initialize the service later by running the command:
      '$ALIAS_PATH ott-init --json $ONE_TIME_TOKEN_VAL > $SERVICE_CONFIG_FILE_PATH'"
      return 1
    fi

  else
    ONE_TIME_TOKEN_VAL=$TOKEN
    echo -e "✅${F_GREEN} => Provided One-Time Token parameter is set to '$ONE_TIME_TOKEN_VAL'${F_DEFAULT}"
  fi


  echo -e "✅${F_GREEN} => Initializing One-Time Token ($ONE_TIME_TOKEN_VAL) and creating config file ($SERVICE_CONFIG_FILE_PATH). Please wait...${F_DEFAULT}"
  $ALIAS_PATH ott-init --json "$ONE_TIME_TOKEN_VAL" > $SERVICE_CONFIG_FILE_PATH || {
    echo "    "
    echo -e "❗️${B_RED} => Failed to initialize One-Time Token. Please check the token value and try again ${F_DEFAULT}"
    return 1
  }

  echo -e "✅${F_GREEN} => Setting owner of the config file ($SERVICE_CONFIG_FOLDER) to $SERVICE_USERNAME${F_DEFAULT}"
  chown "$SERVICE_USERNAME":"$SERVICE_USERNAME" $SERVICE_CONFIG_FOLDER

  echo -e "✅${F_GREEN} => Starting service ${SERVICE_NAME}${F_DEFAULT}"
  systemctl start "${SERVICE_NAME}"

  if sudo systemctl is-active ${SERVICE_NAME} >/dev/null 2>&1 ; then
    echo -e "✅${F_GREEN} => ${SERVICE_NAME} is running${F_DEFAULT}"
  else
    echo "    "
    echo -e "✅${B_YELLOW} => ${SERVICE_NAME} is not running. For more details, run command \"systemctl status ${SERVICE_NAME}\"${F_DEFAULT}"
  fi

  echo ""
  echo -e "✅${B_BLUE} => ---------------------------------------------------------------${F_DEFAULT}"
  echo -e "✅${B_BLUE} => Config file location: $SERVICE_CONFIG_FILE_PATH${F_DEFAULT}"
  echo -e "✅${B_BLUE} => Logs file location  : $SERVICE_LOGS_FOLDER${F_DEFAULT}"

}

installLinux(){
  echo -e "\n🚜 ${B_BLUE} => Started to download latest ${PROG_NAME}${F_DEFAULT}"


  if curl -# --fail -Lo ${EXE_NAME} "${LATEST_LINUX_BIN}" ; then
      chmod +x ${PWD}/${EXE_NAME}
      echo -e "\n✅${F_GREEN} => $PROG_NAME is downloaded into ${B_BLUE}${PWD}/${EXE_NAME}${F_DEFAULT}"
  else
      echo -e "\n🛑${F_RED} => Couldn't download ${LATEST_LINUX_BIN}\n\
    ⚠️    Check your internet connection.\n\
    ⚠️    Make sure 'curl' command is available.\n\
    ⚠️    Make sure there is no directory named '${EXE_NAME}' in ${PWD}\n ${F_DEFAULT}"
      echo -e "${B_RED} => Please report issues to sm@keepersecurity.com${F_DEFAULT}"
      exit 1
  fi

  if sudo -n true ; then
    echo -e "✅${F_GREEN} => User can run commands as 'sudo'${F_DEFAULT}"
  else
    echo -e "⚠️${B_RED} => Please run installation script as sudo to install this ${PROG_NAME} system wide and add ${B_BLUE}$ALIAS_NAME${F_DEFAULT} alias${F_DEFAULT}"
    exit 1
  fi

  sudo mv ./$EXE_NAME ${INSTALL_PATH} || exit 1
  echo -e "✅${F_GREEN} => ${PROG_NAME} is installed into ${B_BLUE}${INSTALL_PATH}${F_DEFAULT}"

  sudo ln -sf ${INSTALL_PATH} ${ALIAS_PATH}
  echo -e "✅${F_GREEN} => Added system-wide alias ${F_DEFAULT}${B_BLUE}$ALIAS_NAME${F_DEFAULT}${F_GREEN}${F_DEFAULT}"

}

if [[ $OSTYPE = 'darwin'* ]]; then
  installMac
elif [[ $OSTYPE = 'linux'* ]]; then
  installLinux
  installSystemctlService
else
    echo -e "💔${B_RED} => ${OSTYPE} is not supported${F_DEFAULT}"
    exit 1
fi