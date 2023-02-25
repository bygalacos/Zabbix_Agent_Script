#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  22.12.2022
#  Purpose/Change: Initial script development

# Check if running as root
if [[ $(id -u) -ne 0 ]]; then
  echo "Please run this script as root"
  exit 1
fi

# Check if running on CentOS
if [[ $(grep -Ei 'centos|red hat' /etc/*release) ]]; then
  clear
  setenforce 0 && sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
  
  # Remove Previous Files
  yum erase -y zabbix-agent
  if [ -f /etc/zabbix/zabbix_agentd.conf.rpmsave ]; then
    rm -rf /etc/zabbix/zabbix_agentd.conf.rpmsave
  fi

  # Update Package Repository & Install Zabbix Agent
  yum install -y ca-certificates
  rpm -Uvh https://repo.zabbix.com/zabbix/6.2/rhel/$(rpm -E %{rhel})/x86_64/zabbix-release-6.2-3.el$(rpm -E %{rhel}).noarch.rpm
  yum install -y zabbix-agent
  clear

  # Get IP Address of Zabbix Server
  if [ -z "$1" ]; then
    read -p "Enter the IP address of the Zabbix server: " zabbixIP
  else
    zabbixIP=$1
  fi
  hostname=$(hostname)

  # Replace Server, ServerActive and Hostname in Zabbix Agent configuration file
  sed -i "s/Server=127.0.0.1/Server=$zabbixIP/g" /etc/zabbix/zabbix_agentd.conf
  sed -i "s/ServerActive=127.0.0.1/ServerActive=$zabbixIP/g" /etc/zabbix/zabbix_agentd.conf
  sed -i "s/Hostname=Zabbix server/Hostname=$hostname/g" /etc/zabbix/zabbix_agentd.conf

  # Restart Zabbix Agent
  systemctl restart zabbix-agent && systemctl enable zabbix-agent
  clear
  systemctl status zabbix-agent
  exit 0
fi

# Check if running on Ubuntu
if [[ $(grep -Ei 'ubuntu' /etc/*release) ]]; then
  clear
  
  # Remove Previous Files
  apt-get purge -y zabbix-agent

  # Update Package Repository & Install Zabbix Agent
  apt-get update
  apt-get install -y ca-certificates
  wget https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-4+ubuntu$(lsb_release -rs)_all.deb
  dpkg -i zabbix-release_* && rm -rf zabbix-release_*
  apt-get update
  apt-get install -y zabbix-agent
  clear

  # Get IP Address of Zabbix Server
  if [ -z "$1" ]; then
    read -p "Enter the IP address of the Zabbix server: " zabbixIP
  else
    zabbixIP=$1
  fi
  hostname=$(hostname)

  # Replace Server, ServerActive and Hostname in Zabbix Agent configuration file
  sed -i "s/Server=127.0.0.1/Server=$zabbixIP/g" /etc/zabbix/zabbix_agentd.conf
  sed -i "s/ServerActive=127.0.0.1/ServerActive=$zabbixIP/g" /etc/zabbix/zabbix_agentd.conf
  sed -i "s/Hostname=Zabbix server/Hostname=$hostname/g" /etc/zabbix/zabbix_agentd.conf

  # Restart Zabbix Agent
  systemctl restart zabbix-agent && systemctl enable zabbix-agent
  clear
  systemctl status zabbix-agent
  exit 0
fi

  echo "Unsupported operating system"
  exit 1