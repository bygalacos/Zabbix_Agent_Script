#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  18.12.2023
#  Purpose/Change: Initial script development

# Check the operating system
#

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
  wget https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-1+ubuntu$(lsb_release -rs)_all.deb
  dpkg -i zabbix-release_* && rm -rf zabbix-release_*
  apt-get update
  apt-get install -y zabbix-agent
elif [ "$(cat /etc/*release | grep '^ID=' | cut -f2 -d\=)" == "centos" ]; then
  rpm -Uvh https://repo.zabbix.com/zabbix/6.2/rhel/$(rpm -E %{rhel})/x86_64/zabbix-release-6.2-3.el$(rpm -E %{rhel}).noarch.rpm
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
  systemctl restart zabbix-agent
  systemctl enable zabbix-agent
elif [ "$(cat /etc/*release | grep '^ID=' | cut -f2 -d\=)" == "centos" ]; then
  systemctl restart zabbix-agent
  systemctl enable zabbix-agent
fi
