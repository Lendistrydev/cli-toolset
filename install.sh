#!/bin/bash

# Colors for output
red='\033[0;31m'
green='\033[0;32m'
white='\033[1;37m'
NC='\033[0m'

# Function to get the operating system (linux, mac, windows)
get_os() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
    Linux*) machine=Linux ;;
    Darwin*) machine=Mac ;;
    CYGWIN*) machine=Cygwin ;;
    MINGW*) machine=MinGw ;;
    *) machine="UNKNOWN:${unameOut}" ;;
    esac
    echo "${machine}"
}

# Function to install aws ssm plugin
function install_plugin() {
    echo -e "${green}Installing AWS SSM Plugin${NC}"
    sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent
}

# Function to install brew package
function install_brew_package() {
    echo -ne "${green}- Installing $1... ${NC}"
    brew_output=$(brew install $1 2>&1)

    if [[ $brew_output == *"already installed"* ]]; then
        echo -e "${NC}🤙 already installed...${NC}"
    else
        echo -e "${green}✅ ${NC}"
    fi
}

function install_pipx_package() {
    echo -ne "${green}- Installing $1... ${NC}"
    brew_output=$(pipx install $1 2>&1)

    if [[ $brew_output == *"already seems to be installed"* ]]; then
        echo -e "${NC}🤙 already installed...${NC}"
    else
        echo -e "${green}✅ ${NC}"
    fi
}

function install_ssm_plugin {
    # Sudo warning
    echo
    echo -e "  ${red}This script will install the AWS SSM Session Manager Plugin. This requires sudo access.${NC}"
    read -p "  Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
        unzip sessionmanager-bundle.zip
        sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
        rm -rf sessionmanager-bundle.zip sessionmanager-bundle
    else
        echo -e "  ${red}OK! As you wish...${NC}"
    fi
}

function abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

echo "**************************************************************************************************"
echo 'ooooo       ooooooooooo oooo   oooo ooooooooo  ooooo  oooooooo8 ooooooooooo oooooooooo ooooo  oooo'
echo '888         888    88   8888o  88   888    88o 888  888        88  888  88  888    888  888  88   '
echo '888         888ooo8     88 888o88   888    888 888   888oooooo     888      888oooo88     888     '
echo '888      o  888    oo   88   8888   888    888 888          888    888      888  88o      888     '
echo 'o888ooooo88 o888ooo8888 o88o    88  o888ooo88  o888o o88oooo888    o888o    o888o  88o8   o888o   '
echo "**************************************************************************************************"
echo "Lendistry's toolset installer v1.0"
echo

echo -e "${white}Getting ready:${NC}"
echo -ne "${NC}- Operating System: ${NC}"
# Only support Mac
if [ "$(get_os)" != "Mac" ]; then
    abort "This script only supports Mac OS"
fi
echo -e "${green}✅ ($(get_os))${NC}"

echo -ne "${NC}- Checking if bash is available: ${NC}"
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
else
    echo -e "${green}✅ Version ${BASH_VERSION}${NC}"
fi

# Check if brew is installed
echo -ne "${NC}- Searching for brew: ${NC}"
if ! command -v brew &>/dev/null; then
    echo "${red}Brew could not be found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${green}✅ Already installed${NC}"    
fi

echo
echo -e "${white}Installing packages:${NC}"

# Check if aws ssm plugin is installed
echo -ne "${green}- Install AWS SSM Session Manager Plugin: ${NC}"
if ! command -v session-manager-plugin &>/dev/null; then
    install_ssm_plugin
else
    echo -e "${NC}🤙 already installed...${NC}"
fi

# Install brew packages
install_brew_package "awscli"
install_brew_package "python3"
install_brew_package "pipx"

# Install pipx packages
echo -ne "${green}- Setting pipx bin path... ${NC}"
pipx_output=$(pipx ensurepath 2>&1)

if [[ $pipx_output == *"All pipx binary directories have been added to PATH"* ]]; then
    echo -e "${NC}🤙 path already in path...${NC}"
else
    echo -e "${green}✅ ${NC}"
fi

install_pipx_package "aws-ssm-tools"

echo
echo -e "${green}We are done! 🏆${NC}"
echo -e "Check https://lendistry.atlassian.net/wiki/spaces/SLE/pages/1348010013/Runbooks for more information."
