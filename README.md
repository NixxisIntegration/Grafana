# Grafana Automated Installer

This repository contains a Bash script to automate the installation of [Grafana OSS](https://grafana.com/grafana/download?edition=oss) on various Linux distributions. The script is designed to be user-friendly, robust, and suitable for both beginners and experienced system administrators.

## Features
- **Automatic detection** of your Linux distribution (Debian/Ubuntu, RHEL/CentOS/Fedora, SUSE/OpenSUSE)
- **Version selection**: Choose which Grafana version to install
- **Dependency installation**
- **Service management**: Starts and enables the Grafana service after installation
- **Colorful, clear output** for easy tracking
- **Input validation** and error handling

## Supported Distributions
- Ubuntu
- Debian
- RHEL
- CentOS
- Fedora
- SUSE
- openSUSE
- SLES

## Usage

### 1. Download the Script
Clone this repository or download the `GrafanaSetup.sh` file to your Linux server.

```
chmod +x GrafanaSetup.sh
```

### 2. Run the Script as Root
You **must** run the script as root or with `sudo`:

```
sudo ./GrafanaSetup.sh
```

### 3. Follow the Prompts
- The script will prompt you to enter the Grafana version you wish to install (default is 12.1.0).
- It will automatically detect your Linux distribution and proceed with the appropriate installation steps.

## Example Output
```
--- Grafana Installer ---
Please check for the latest Grafana OSS version at: https://grafana.com/grafana/download?edition=oss
Examples of valid versions: 12.1.0, 12.0.3, 11.1.0
Enter Grafana version to install [default: 12.1.0]:
Will attempt to install Grafana version: 12.1.0
----------------------------------------
Detected Debian-based system (Ubuntu/Debian).
Installing dependencies...
Downloading Grafana: https://dl.grafana.com/oss/release/grafana_12.1.0_amd64.deb
Installing package...
----------------------------------------
Starting and enabling the Grafana service...
Grafana installation complete! ✅
Current service status:
... (service status output) ...
You can now access Grafana at: http://<your_server_ip>:3000
Default credentials are: admin / admin
Thank you for using the Grafana Installer!
```

## Notes
- The script checks if Grafana is already installed and will exit if it is detected.
- Only tested on x86_64 systems.
- For the latest versions, always check the [official Grafana downloads page](https://grafana.com/grafana/download?edition=oss).

## Troubleshooting
- Ensure you have a working internet connection.
- Run the script as root or with `sudo`.
- If you encounter issues, check the output for error messages and verify your Linux distribution is supported.

## License
MIT License

---

**Thank you for using the Grafana Automated Installer!**
