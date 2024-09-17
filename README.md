<div align="center">
    <a href="https://github.com/Valikahn/set_static_ip" target="_blank">
        <img alt="lamp" src="https://github.com/Valikahn/set_static_ip/blob/master/img/static_ip_address_logo.jpg">
    </a>
</div>

## Script Description
This script is designed to set a static IP address on a Linux system that uses NetworkManager for managing network interfaces.<br />
Program designed, developed, and tested while at university studying Computer Science for module "Managing a Web Server (maws_h16s35)"<br />

Program Version: 24.9.17.83<br />
File Name: maws_h16s35-v24.9.17.83.linux.deb.sh<br />
Author:  Neil Jamieson (Valikahn)<br />

* [Tested Operating Systems](#tested-operating-systems)
* [Features and Components](#features-and-components)
* [Install Commands](#install-commands)
* [Copyright](#copyright)
* [Bugs & Issues](#bugs--issues)
* [Licence](#licence)

## Tested Operating Systems
* Ubuntu 24.04.x (Noble Numbat)

## Features and Components
Setup and Initialisation
* Clears the terminal (clear) and sets the default text editor to nano.
* Defines several color variables to format output messages (e.g., bold text, colored text).

***Root Privileges Check***
* The function CHECK_SUDO ensures the script is being executed with root privileges. If not, it exits with an error code (126).

***IP Address Validation***
* The VALID_IP_ADDRESS function checks whether a given string is a valid IPv4 address.

***Confirmation Prompt***
* CONFIRM_YES_NO asks the user for confirmation before proceeding, ensuring that they explicitly agree to continue.

***User Input Collection***
The script asks for several network settings:
* Static IP address (STATIC_IP)
* Default gateway (GATEWAY)
* DNS servers (entered as a comma-separated list)
* Subnet mask in CIDR notation (e.g., 24 for 255.255.255.0)
* Each input is validated to ensure correct IP format.

***Display Settings for Confirmation***
* The gathered data (IP address, subnet mask, gateway, DNS servers, and network interface) is displayed to the user for review and confirmation.

***System Configuration Steps***
The script proceeds with several system configuration tasks:
* Update System and Install NetworkManager: Installs network-manager if it is not already installed.
* Disable Systemd-Networkd-Wait Service: Disables the service that waits for network connectivity during boot.
* Edit Globally Managed Devices: Modifies the NetworkManager configuration to manage specific device types like Wi-Fi and Ethernet.
* Edit NetworkManager Configuration: Ensures that NetworkManager is set to manage interfaces previously managed by ifupdown.
* Disable Cloud-Init Network Configuration: Disables any cloud-init network configuration to avoid conflicts.

***Configure Network Interface***
* Uses nmcli and ip commands to assign the static IP and connect the specified network interface.

Netplan Configuration***
* Removes existing Netplan files, creates a new configuration (/etc/netplan/00-installer-config.yaml), and writes the static network settings to it (IP address, DNS, gateway, etc.).
* Ensures the Netplan configuration is secure by setting appropriate permissions and applying it.

***Completion and Reboot***
* Displays a message confirming that the static IP has been set.
* Finally, the script reboots the system to apply the changes.

This script essentially automates the process of setting up a static IP address and configuring the necessary network settings in a Linux environment that uses NetworkManager.

## Install Commands
Install Git and clone the "set_static_ip" package
```
sudo apt-get -y install wget git
git clone https://github.com/Valikahn/set_static_ip.git
```

## Execute Script
Change directory -->  Make shell file executable -->  sudo run the script<br />
Thats it - there is only one interaction required (y/n)
```
cd set_static_ip
chmod +x maws_h16s35_set_static_ip.linux.deb.sh
sudo ./maws_h16s35_set_static_ip.linux.deb.sh
```

## Bugs & Issues
Please let me know if there is any bugs or issues with this script.
* Issues:  <a href="https://github.com/Valikahn/set_static_ip/issues">Via GitHub</a>

## Licence
Licensed under the GPLv3 License.
This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.<br /><br />
GPLv3 Licence:  https://www.gnu.org/licenses/gpl-3.0.en.html 

## References
Linux (Ubuntu 24.04.x) - https://ubuntu.com/download/server<br />
Apache - https://httpd.apache.org/<br />
MySQL - https://www.mysql.com/<br />
phpMyAdmin - https://www.phpmyadmin.net/<br />
Webmin - https://webmin.com/download/<br />
VSFTPD - https://wiki.archlinux.org/title/Very_Secure_FTP_Daemon<br />
OpenSSL - https://openssl-library.org/source/gitrepo/ and https://ubuntu.com/server/docs/openssl<br />
