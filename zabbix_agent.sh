#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  18.12.2023
#  Purpose/Change: Initial script development

# Check if system is running Ubuntu
if [ "$(lsb_release -si)" != "Ubuntu" ]; then
    # Check if system is running CentOS
    if [ "$(cat /etc/*release | grep '^ID=' | cut -f2 -d\=)" != "centos" ]; then
        # Exit script if system is not running Ubuntu or CentOS
        echo "This script only works on Ubuntu or CentOS systems. Exiting."
        exit 1
    fi
fi

# Check if running as root
if [[ $(id -u) -ne 0 ]]
then
  echo "Please run this script as root"
  exit 1
fi

# Remove Previous Files
if [ "$(lsb_release -si)" == "Ubuntu" ]; then
  # Remove Zabbix agent and configuration file
  apt-get purge -y zabbix-agent
elif [ "$(cat /etc/*release | grep '^ID=' | cut -f2 -d\=)" == "centos" ]; then
  # Remove Zabbix agent and configuration file
  #yum erase -y -c zabbix-agent
  #rm -f /etc/zabbix/zabbix_agentd.conf
  echo "This feature is under construction"
fi

# Update Package Repository & Install Zabbix Agent
if [ "$(lsb_release -si)" == "Ubuntu" ]; then
  apt-get update
  apt-get install -y zabbix-agent
elif [ "$(cat /etc/*release | grep '^ID=' | cut -f2 -d\=)" == "centos" ]; then
  yum update
  yum install -y zabbix-agent
fi

# Get IP Address of Zabbix Server
if [ -z "$1" ]; then
  read -p "Enter the IP address of the Zabbix server: " zabbixIP
else
  zabbixIP=$1
fi
hostname=$(hostname)

# Replace Server, ServerActive and Hostname in zabbix agent configuration file
sed -i "s/Server=127.0.0.1/Server=$zabbixIP/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/ServerActive=$zabbixIP/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/Hostname=Zabbix server/Hostname=$hostname/g" /etc/zabbix/zabbix_agentd.conf

# Restart Zabbix Agent
if [ "$(lsb_release -si)" == "Ubuntu" ]; then
  service zabbix-agent restart
elif [ "$(cat /etc/*release | grep '^ID=' | cut -f2 -d\=)" == "centos" ]; then
  systemctl restart zabbix-agent
fi
