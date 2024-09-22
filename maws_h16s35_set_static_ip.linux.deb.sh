#!/bin/bash
clear
export EDITOR=nano

###--------------------  START  --------------------###
##


###################################################
##												 ##
##  VARIABLES									 ##
##												 ##
###################################################


###--------------------  COLORS DECLARE  --------------------###
##
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
LBLUE=$(tput setaf 6)
RED=$(tput setaf 1)
PURPLE=$(tput setaf 5)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)


###################################################
##												 ##
##  FUNCTIONS									 ##
##												 ##
###################################################


###--------------------  SUDO/ROOT CHECK  --------------------###
##
CHECK_SUDO() {
    if [ "$(id -u)" -ne 0 ]; then 
        echo -n "Checking if user is root/sudo..."; 	sleep 5
        echo -e "\rChecking if user is root/sudo... [  ACCESS DENIED  ]"; sleep 5
	    echo
        echo "Error 126: Command cannot execute."
	    echo "This error code is used when a command is found but is not executable.  Execute as root/sudo!"
	    exit 126
    else
	    echo -n "Checking if user is root/sudo..."; 	sleep 5
	    echo -e "\rChecking if user is root/sudo... [  ACCESS GRANTED  ]"; sleep 5
        clear
    fi
}

###--------------------  VALID IP ADDRESS CHECK  --------------------###
##
VALID_IP_ADDRESS() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

###--------------------  CONFIRM_YES_NO  --------------------###
#
CONFIRM_YES_NO () {
    read -p "Please confirm you're happy to proceed? (Yy/Nn): " CONFIRM
    echo
    if [[ "$CONFIRM" == "Y" ]] || [[ "$CONFIRM" == "y" ]] || [[ "$CONFIRM" == "YES" ]] || [[ "$CONFIRM" == "yes" ]] || [[ "$CONFIRM" == "Yes" ]]; then
	    break
        clear
    elif [[ "$CONFIRM" == "N" ]] || [[ "$CONFIRM" == "n" ]] || [[ "$CONFIRM" == "NO" ]] || [[ "$CONFIRM" == "no" ]] || [[ "$CONFIRM" == "No" ]]; then
	    exit 1
    else
	    echo "Invalid choice - try again please. Enter 'Yy' or 'Nn'."
	    echo
    fi
}


###################################################
##												 ##
##  DATA ENTRY									 ##
##												 ##
###################################################


CHECK_SUDO

###--------------------  IP ADDRESS ENTRY / CHECK RECALL FUNCTION  --------------------###
##
while true;
do
read -p "Enter the static IP address to set (e.g., 192.168.1.100): " STATIC_IP
    if VALID_IP_ADDRESS $STATIC_IP; then
        break
    else
        echo "Invalid IP address format: $STATIC_IP"
    fi
done

while true;
do
read -p "Enter the default gateway (e.g., 192.168.1.1): " GATEWAY
    if VALID_IP_ADDRESS $GATEWAY; then
        break
    else
        echo "Invalid IP address format: $GATEWAY"
    fi
done

while true; do
    read -p "Enter DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4): " DNS
    IFS=',' read -ra DNS_ARRAY <<< "$DNS"
    ALL_VALID_ENTRIES=1  # Assume all IPs are valid initially

    for DNS_IP in "${DNS_ARRAY[@]}"; do
        if ! VALID_IP_ADDRESS "$DNS_IP"; then
            echo "Invalid IP address format: $DNS_IP"
            ALL_VALID_ENTRIES=0  # Set flag to false if any IP is invalid
        fi
    done

    if [ "$ALL_VALID_ENTRIES" -eq 1 ]; then
        echo "All DNS entered IP addresses are valid."
        break  # Exit the while loop since all IPs are valid
    else
        echo "Please enter valid IP addresses."
    fi
done

read -p "Enter the subnet mask in CIDR notation (e.g., 24 for 255.255.255.0): " CIDR

###--------------------  GATHERED DATA  --------------------###
##
INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)

echo
echo "Setting up static IP address:"
echo
echo "IP Address: $STATIC_IP"
echo "Subnet Mask CIDR: $CIDR"
echo "Gateway: $GATEWAY"
echo "DNS Servers: $DNS"
echo "Network Interface: $INTERFACE"
echo

CONFIRM_YES_NO


###################################################
##												 ##
##  SCRIPT RUN									 ##
##												 ##
###################################################


###--------------------  UPDATE SYSTEM AND INSTALL NETWORK MANAGER  --------------------###
##
echo "${GREEN}[ 1. ] UPDATE SYSTEM AND INSTALL NETWORK MANAGER${NORMAL}"
apt install -y network-manager > /dev/null 2>&1
apt install -y openvswitch-switch > /dev/null 2>&1

###--------------------  DISABLE SYSTEM NETWORKD SERVICE WAIT WHILE BOOT  --------------------###
##
echo "${GREEN}[ 2. ] DISABLE SYSTEM NETWORKD SERVICE WAIT WHILE BOOT  ]${NORMAL}"
systemctl disable systemd-networkd-wait-online.service > /dev/null 2>&1

###--------------------  EDIT GLOBALLY MANAGED DEVICES  --------------------###
##
echo "${GREEN}[ 3. ] EDIT GLOBALLY MANAGED DEVICES${NORMAL}"
CONF_FILE="/usr/lib/NetworkManager/conf.d/10-globally-managed-devices.conf"
tee $CONF_FILE > /dev/null <<EOL
[keyfile]
unmanaged-devices=*,except:type:wifi,except:type:gsm,except:type:cdma,except:type:ethernet,except:type:wireguard
EOL

###--------------------  EDIT NETWORK MANAGER  --------------------###
##
echo "${GREEN}[ 4. ] EDIT NETWORK MANAGER${NORMAL}"
NM_CONF="/etc/NetworkManager/NetworkManager.conf"
    if grep -q "\[ifupdown\]" $NM_CONF; then
      sed -i '/\[ifupdown\]/,/\[/{s/managed=false/managed=true/}' $NM_CONF
    else
      echo -e "\n[ifupdown]\nmanaged=true" | sudo tee -a $NM_CONF > /dev/null 2>&1
    fi

###--------------------  DISABLE CLOUD-INIT NETWORK CONFIGURATION  --------------------###
##
echo "${GREEN}[ 5. ] DISABLE CLOUD-INIT NETWORK CONFIGURATION${NORMAL}"
CLOUD_CFG="/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg"
tee $CLOUD_CFG > /dev/null 2>&1 <<EOL
network: {config: disabled}
EOL

###--------------------  RESTART NETWORK MANAGER  --------------------###
##
echo "${GREEN}[ 6. ] RESTART NETWORK MANAGER${NORMAL}"
systemctl restart NetworkManager > /dev/null 2>&1

###--------------------  CONFIGURE NETWORK INTERFACE USING NMCLI  --------------------###
##
echo "${GREEN}[ 7. ] CONFIGURE NETWORK INTERFACE USING NMCLI${NORMAL}"
nmcli device set $STATIC_IP managed yes > /dev/null 2>&1
ip addr add $IP_A_CIDR dev $INTERFACE > /dev/null 2>&1
nmcli device connect $INTERFACE > /dev/null 2>&1

ENS=$(nmcli dev status | grep '^ens' | awk '{ print $1 }')

nmcli con modify $ENS ipv4.addresses $STATIC_IP/$CIDR
nmcli con modify $ENS ipv4.gateway $GATEWAY
nmcli con modify $ENS ipv4.dns $DNS
nmcli con modify $ENS ipv4.method manual
sudo nmcli con up $ENS

###--------------------  REMOVE NETPLAN FILES AND CREATE A NEW  --------------------###
##
echo "${GREEN}[ 8. ] REMOVE NETPLAN FILES AND CREATE A NEW${NORMAL}"
rm -rf /etc/netplan/* > /dev/null 2>&1
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml" > /dev/null 2>&1

sudo tee $NETPLAN_FILE > /dev/null 2>&1 <<EOL
## This is the network config written by Neil Jamieson for Insentrica Lab!
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
      - $STATIC_IP/$CIDR
      nameservers:
        addresses:
$(IFS=','; for ip in $DNS; do echo "        - $ip"; done)
      routes:
      - to: default
        via: $GATEWAY
EOL

###--------------------  NETPLAN SECURE AND APPLY  --------------------###
##
echo "${GREEN}[ 9. ] NETPLAN SECURE AND APPLY${NORMAL}"
sudo chmod 600 /etc/netplan/00-installer-config.yaml
sudo netplan apply

###--------------------  EXECUTION COMPLETE  --------------------###
##
echo "${GREEN}[ 10. ] EXECUTION COMPLETE${NORMAL}"
systemctl restart NetworkManager

###--------------------  OUTPUT INFORMATION  --------------------###
##
echo
echo "The IP address has been statically set."
echo "Login with the new IP address: $STATIC_IP and configured port number for SSH."
sleep 5 #&& sudo reboot
exit 126

##
###--------------------  END  --------------------###