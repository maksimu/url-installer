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

installMac(){
  cd "$HOME"

  echo -e "Check if ${PROG_NAME} process is already running"

  if pgrep "gateway" >/dev/null 2>&1 ; then
      echo "${PROG_NAME} is currently running. Please stop it and try again."
      exit 1
  else
      echo "${PROG_NAME} is not running. Proceeding with installation."
  fi

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

  installer -verbose -pkg "$macpkgfiledest" -target /

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

}


installLinuxService(){
  SERVICE_USERNAME="keeper-gateway-service"
  SERVICE_LOGS_FOLDER="/var/log/keeper-gateway"
  SERVICE_CONFIG_FOLDER="/etc/keeper-gateway"
  SERVICE_CONFIG_FILE_PATH="$SERVICE_CONFIG_FOLDER/gateway-config.json"


  # Check if systemctl is available
  if which systemctl >/dev/null; then
    echo -e "✅${F_GREEN} => systemctl exists on this system and will be used to install ${B_BLUE}$SERVICE_NAME${F_GREEN} service${F_DEFAULT}"
  else
    echo -e "❗️${B_RED} => systemctl could not be found. ${B_BLUE}$SERVICE_NAME${B_RED} will not be installed on this system${F_DEFAULT}"
    return 1
  fi


  # Check if user already exists
  if ! id -u {$SERVICE_USERNAME} &> /dev/null
  then
      echo "Create the user $SERVICE_USERNAME to run the service"
      sudo adduser --disabled-password --gecos "" "$SERVICE_USERNAME" >/dev/null 2>/dev/tty
  else
      echo "✅${F_GREEN} => User ${B_BLUE}$SERVICE_USERNAME${F_GREEN} already exists on this system. Skipping creation${F_DEFAULT}"
  fi


  if [ ! -d $SERVICE_LOGS_FOLDER ]
  then
      echo -e "⚙️${F_GREEN} => Create directory to store Gateway logs with appropriate permissions ($SERVICE_LOGS_FOLDER)${F_DEFAULT}"
      sudo mkdir -p $SERVICE_LOGS_FOLDER
      sudo chmod 700 $SERVICE_LOGS_FOLDER
      sudo chown "$SERVICE_USERNAME":"$SERVICE_USERNAME" $SERVICE_LOGS_FOLDER
  else
      echo -e "✅${F_GREEN} => Directory ${B_BLUE}$SERVICE_LOGS_FOLDER${F_GREEN} already exists on this system${F_DEFAULT}"
  fi


  if [ ! -d $SERVICE_CONFIG_FOLDER ]
  then
    echo -e "⚙️${F_GREEN} => Create directory to store config file with appropriate permissions ($SERVICE_CONFIG_FOLDER)${F_DEFAULT}"
    sudo mkdir -p $SERVICE_CONFIG_FOLDER
    sudo chmod 700 $SERVICE_CONFIG_FOLDER
    sudo chown "$SERVICE_USERNAME":"$SERVICE_USERNAME" $SERVICE_CONFIG_FOLDER
  else
      echo "    "
      echo -e "✅${F_GREEN} => Directory ${B_BLUE}$SERVICE_CONFIG_FOLDER${F_GREEN} already exists on this system${F_DEFAULT}"
  fi


  if [ -f /etc/systemd/system/${SERVICE_NAME} ]
  then
      echo -e "⚙️${F_GREEN} => Updating service unit file at ${B_BLUE}/etc/systemd/system/${SERVICE_NAME}${F_DEFAULT}"
  else
      echo -e "⚙️${F_GREEN} => Creating service unit file at ${B_BLUE}/etc/systemd/system/${SERVICE_NAME}${F_DEFAULT}"
  fi

  sudo tee >/etc/systemd/system/${SERVICE_NAME} << EOF
[Unit]
Description=${PROG_NAME} Service
After=network.target

[Service]
Type=simple
ExecStart=${ALIAS_PATH} start -d --service --config-file $SERVICE_CONFIG_FILE_PATH
User=$SERVICE_USERNAME
Group=$SERVICE_USERNAME
#StandardOutput=file:$SERVICE_LOGS_FOLDER/service-out.log
StandardOutput=null
#StandardError=file:$SERVICE_LOGS_FOLDER/service_error.log
StandardError=null
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  echo -e "✅${F_GREEN} => Reloading systemd configuration ${F_DEFAULT}"
  sudo systemctl daemon-reload

  echo -e "✅${F_GREEN} => Enabling service to start automatically on boot ${F_DEFAULT}"
  sudo systemctl enable "${SERVICE_NAME}"


  # CHECK IF THE CONFIG FILE EXISTS
  if [ -f $SERVICE_CONFIG_FILE_PATH ]
  then
    echo -e "✅${F_GREEN} => Config file already exists at ${B_BLUE}$SERVICE_CONFIG_FILE_PATH${F_DEFAULT}"

    read -p "Do you want re-initialize the Gateway? (yes/y or no/n) " choice2
    if [[ "$choice2" == "no" || "$choice2" == "n" ]]; then
        echo "    Skipping re-initialization of the Gateway."
        echo "    Restart the gateway service by running the command: systemctl start "${SERVICE_NAME}""
        return 1
    fi
  fi

  ONE_TIME_TOKEN_VAL=""

  if [ -z "$TOKEN" ]; then
    echo -e "=> Token parameter is not set."

    read -p "Do you want to initialize and start the service right now with a one-time token? (yes/y or no/n) " choice3

    if [[ "$choice3" == "yes" || "$choice3" == "y" ]]; then
      read -p "Please enter the one-time token: " ONE_TIME_TOKEN_VAL
    elif [[ "$choice3" == "no" || "$choice3" == "n" ]]; then
      echo "The service can be initialized later by running the command: '$ALIAS_PATH ott-init --json [ONE-TIME-TOKEN] > $SERVICE_CONFIG_FILE_PATH'"
      return 1
    else
      echo "=> Invalid input"
      echo "=> The service can be initialized later by running the command: '$ALIAS_PATH ott-init --json $ONE_TIME_TOKEN_VAL > $SERVICE_CONFIG_FILE_PATH'"
      return 1
    fi

  else
    ONE_TIME_TOKEN_VAL=$TOKEN
    echo -e "✅${F_GREEN} => Provided One-Time Token parameter is set to ${B_BLUE}$ONE_TIME_TOKEN_VAL${F_DEFAULT}"
  fi


  echo -e "✅${F_GREEN} => Initializing One-Time Token ${B_BLUE}$ONE_TIME_TOKEN_VAL${F_GREEN} and creating config file ${B_BLUE}$SERVICE_CONFIG_FILE_PATH${F_GREEN}. Please wait...${F_DEFAULT}"
  sudo $ALIAS_PATH ott-init --json "$ONE_TIME_TOKEN_VAL" > $SERVICE_CONFIG_FILE_PATH || {
    echo "    "
    echo -e "❗️${B_RED} => Failed to initialize One-Time Token. Please check the token value and try again ${F_DEFAULT}"
    return 1
  }

  echo -e "✅${F_GREEN} => Setting owner of the config file ${B_BLUE}$SERVICE_CONFIG_FOLDER${F_GREEN} to ${B_BLUE}$SERVICE_USERNAME${F_DEFAULT}"
  sudo chown "$SERVICE_USERNAME":"$SERVICE_USERNAME" $SERVICE_CONFIG_FOLDER

  echo -e "✅${F_GREEN} => Starting service ${B_BLUE}${SERVICE_NAME}${F_DEFAULT}"
  sudo systemctl restart "${SERVICE_NAME}"

  if sudo systemctl is-active ${SERVICE_NAME} >/dev/null 2>&1 ; then
    echo -e "✅${F_GREEN} => ${B_BLUE}${SERVICE_NAME}${F_GREEN} is running${F_DEFAULT}"
  else
    echo "    "
    echo -e "✅${B_YELLOW} => ${B_BLUE}${SERVICE_NAME}${B_YELLOW} is not running. For more details, run command \"systemctl status ${SERVICE_NAME}\"${F_DEFAULT}"
  fi

  echo ""
  echo -e "✅${F_BLUE} => ---: Files :----------------------------------------------------------${F_DEFAULT}"
  echo -e "✅${F_BLUE} => Config file          : ${B_BLUE}$SERVICE_CONFIG_FILE_PATH${F_DEFAULT}"
  echo -e "✅${F_BLUE} => Logs files           : ${B_BLUE}$SERVICE_LOGS_FOLDER${F_DEFAULT}"
  echo -e "✅${F_BLUE} => ---: Commands :----------------------------------------------------------${F_DEFAULT}"
  echo -e "✅${F_BLUE} => View Service Status  : ${B_BLUE}systemctl status ${SERVICE_NAME}${F_DEFAULT}"
  echo -e "✅${F_BLUE} => Restart Service      : ${B_BLUE}systemctl restart ${SERVICE_NAME}${F_DEFAULT}"
  echo -e "✅${F_BLUE} => Stop Service         : ${B_BLUE}systemctl stop ${SERVICE_NAME}${F_DEFAULT}"
}

installLinux(){
  echo -e "\n🚜 ${B_BLUE} => Started to download latest ${PROG_NAME}${F_DEFAULT}"


  if curl -# --fail -Lo ${EXE_NAME} "${LATEST_LINUX_BIN}" ; then
      sudo chmod +x ${PWD}/${EXE_NAME}
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
  echo -e "${F_GREEN} => ${PROG_NAME} is installed into ${B_BLUE}${INSTALL_PATH}${F_DEFAULT}"

  sudo ln -sf ${INSTALL_PATH} ${ALIAS_PATH}
  echo -e "✅${F_GREEN} => Added system-wide alias ${F_DEFAULT}${B_BLUE}$ALIAS_NAME${F_DEFAULT}${F_GREEN}${F_DEFAULT}"

}


# Request sudo permissions and cache credentials
sudo -v

# Check if sudo authentication was successful
if [ $? -ne 0 ]; then
    echo "This script requires sudo privileges to run. Sudo authentication failed. Aborting script."
    exit 1
fi

# Check if sudo access is available
if ! sudo -v; then
  echo "Error: you must have sudo access to run this script." >&2
  exit 1
fi


if [[ $OSTYPE = 'darwin'* ]]; then
  installMac
elif [[ $OSTYPE = 'linux'* ]]; then
  installLinux
  installLinuxService
  echo -e "${PROG_NAME} is installed and service configured successfully"
else
    echo -e "💔${B_RED} => ${OSTYPE} is not supported${F_DEFAULT}"
    exit 1
fi