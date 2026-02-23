#!/bin/bash

# Update 20260223
# Script to automate Grafana installation on various Linux distributions.
# Version 3: Fixes variable name collision with /etc/os-release.

# --- Configuration ---
DEFAULT_GRAFANA_VERSION="12.1.0"
GRAFANA_URL="https://grafana.com/grafana/download?edition=oss"

# --- Colors for output ---
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

echo "${BLUE}--- Grafana Installer ---${RESET}"

# --- 1. Root Check ---
if [ "$EUID" -ne 0 ]; then
  echo "${RED}Error: Please run this script as root or with sudo.${RESET}"
  exit 1
fi

# --- 2. Check if Grafana is already installed ---
if command -v grafana-server &> /dev/null; then
    echo "${GREEN}Grafana is already installed on your system.${RESET}"
    
    read -p "Do you want to check for and apply updates to Grafana now? (y/N) [N]: " DO_UPGRADE
    if [[ ! "$DO_UPGRADE" =~ ^[Yy]$ ]]; then
        echo "Current service status:"
        systemctl status grafana-server
        exit 0
    fi

    echo -e "${YELLOW}WARNING: It is highly recommended to backup the Grafana database before upgrading to prevent data loss in case of a failed update.${RESET}"
    read -p "Do you want to backup the Grafana database now? (Y/n) [Y]: " DO_BACKUP
    if [[ ! "$DO_BACKUP" =~ ^[Nn]$ ]]; then
        # 1. Backup the database (Safety First)
        echo "Backing up Grafana database..."
        cp /var/lib/grafana/grafana.db /var/lib/grafana/grafana.db.bak_$(date +%Y%m%d)
        echo -e "${GREEN}Backup completed.${RESET}"
        echo ""
    else
        echo -e "${RED}Skipping database backup as requested.${RESET}"
        echo ""
    fi

    echo -e "${GREEN}Starting Grafana Update Sequence...${RESET}"

    # 2. Update Package Lists
    echo "Updating APT repositories..."
    apt-get update -y

    # 3. Upgrade Grafana
    echo "Upgrading Grafana package..."
    apt-get install --only-upgrade grafana -y

    # 4. Update all Plugins
    echo "Updating all Grafana plugins..."
    grafana-cli plugins update-all

    # 5. Reload and Restart Service
    echo "Reloading systemd and restarting Grafana..."
    systemctl daemon-reload
    systemctl restart grafana-server

    # 6. Verify Status
    echo -e "${GREEN}Update Complete! Current Status:${RESET}"
    systemctl is-active grafana-server
    
    exit 0
fi

# --- 3. Get Grafana Version from User ---
echo "Please check for the latest Grafana OSS version at: ${YELLOW}${GRAFANA_URL}${RESET}"
echo "Examples of valid versions: 12.1.0, 12.0.3, 11.1.0"
read -p "Enter Grafana version to install [default: ${DEFAULT_GRAFANA_VERSION}]: " GRAFANA_VERSION
GRAFANA_VERSION=${GRAFANA_VERSION:-${DEFAULT_GRAFANA_VERSION}}

# --- Input Validation ---
# A simple regex to check if the version format is plausible (e.g., 12.1.0 or 12.0.2+security-01)
if ! [[ "$GRAFANA_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    echo "${RED}Error: Invalid version format. Please use a format like X.Y.Z (e.g., 12.1.0).${RESET}"
    exit 1
fi

echo "${BLUE}Will attempt to install Grafana version: ${GRAFANA_VERSION}${RESET}"
echo "----------------------------------------"

# --- 4. Detect Linux Distribution ---
OS_ID=""
if [ -f /etc/os-release ]; then
    # shellcheck source=/dev/null
    # This sources the file, which defines variables like ID, VERSION_ID, etc.
    . /etc/os-release
    OS_ID=$ID
else
    echo "${RED}Error: Cannot determine the Linux distribution. Exiting.${RESET}"
    exit 1
fi

# --- 5. Installation Logic ---
install_grafana() {
    case "$OS_ID" in
        ubuntu|debian)
            echo "Detected Debian-based system (Ubuntu/Debian)."
            echo "Installing dependencies..."
            apt-get update > /dev/null
            apt-get install -y adduser libfontconfig1 musl wget
            
            DEB_FILE="grafana_${GRAFANA_VERSION}_amd64.deb"
            DOWNLOAD_URL="https://dl.grafana.com/oss/release/${DEB_FILE}"
            
            echo "Downloading Grafana: ${DOWNLOAD_URL}"
            wget -q --show-progress -O "${DEB_FILE}" "${DOWNLOAD_URL}"
            
            # --- Download Check ---
            if [ ! -f "${DEB_FILE}" ] || [ ! -s "${DEB_FILE}" ]; then
                echo "${RED}Error: Failed to download Grafana. Please check the version number and your network connection.${RESET}"
                rm -f "${DEB_FILE}"
                exit 1
            fi
            
            echo "Installing package..."
            dpkg -i "${DEB_FILE}"
            rm "${DEB_FILE}"
            ;;
            
        rhel|centos|fedora)
            echo "Detected Red Hat-based system (RHEL/CentOS/Fedora)."
            RPM_URL="https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}-1.x86_64.rpm"
            
            echo "Installing Grafana from: ${RPM_URL}"
            yum install -y "${RPM_URL}"
            # yum will exit with a non-zero status on failure, which will stop the script if 'set -e' is used.
            # We check the command's exit code explicitly.
            if [ $? -ne 0 ]; then
                echo "${RED}Error: Failed to install Grafana. Please check the version number and your network connection.${RESET}"
                exit 1
            fi
            ;;
            
        suse|opensuse*|sles)
            echo "Detected SUSE-based system (SUSE/OpenSUSE)."
            RPM_FILE="grafana-${GRAFANA_VERSION}-1.x86_64.rpm"
            DOWNLOAD_URL="https://dl.grafana.com/oss/release/${RPM_FILE}"
            
            echo "Downloading Grafana: ${DOWNLOAD_URL}"
            wget -q --show-progress -O "${RPM_FILE}" "${DOWNLOAD_URL}"

            # --- Download Check ---
            if [ ! -f "${RPM_FILE}" ] || [ ! -s "${RPM_FILE}" ]; then
                echo "${RED}Error: Failed to download Grafana. Please check the version number and your network connection.${RESET}"
                rm -f "${RPM_FILE}"
                exit 1
            fi

            echo "Installing package..."
            rpm -Uvh "${RPM_FILE}"
            rm "${RPM_FILE}"
            ;;
            
        *)
            echo "${RED}Error: Your Linux distribution ('${OS_ID}') is not supported by this script.${RESET}"
            exit 1
            ;;
    esac
}

install_grafana

# --- 6. Start and Enable Grafana Service ---
echo "----------------------------------------"
echo "${BLUE}Starting and enabling the Grafana service...${RESET}"
systemctl daemon-reload
systemctl enable grafana-server.service
systemctl start grafana-server.service

# --- 7. Final Status ---
echo ""
echo "${GREEN}Grafana installation complete! ✅${RESET}"
echo "Current service status:"
systemctl status grafana-server --no-pager
echo "----------------------------------------"
echo "You can now access Grafana at: ${YELLOW}http://<your_server_ip>:3000${RESET}"
echo "Default credentials are: ${YELLOW}admin / admin${RESET}"
echo "----------------------------------------"
echo "${BLUE}Thank you for using the Grafana Installer!${RESET}"
# --- End of Script ---
exit 0