# Zabbix Agent Script
## Install the Zabbix Agent with ease!

[![Build Status](https://camo.githubusercontent.com/4e084bac046962268fcf7a8aaf3d4ac422d3327564f9685c9d1b57aa56b142e9/68747470733a2f2f7472617669732d63692e6f72672f6477796c2f657374612e7376673f6272616e63683d6d6173746572)](https://travis-ci.org/joemccann/dillinger)

Releasing script that installs zabbix agent without any hassle.

## Features

- Detects the operating system and any previous Zabbix agent files
- More user-friendly installation process
- Prompts for the "Zabbix Server" IP address, or accepts it as a command line argument
- Organizes log files on Windows systems

To use command line arguments, simply provide the script name and the IP address.

## Usage

Zabbix Agent Script requires a Windows, Ubuntu, or CentOS operating system, depending on which platform you're using.

To launch the script:

```sh
./zabbix_agent.sh
./zabbix_agent_5.2.ps1
./zabbix_agent_6.2.ps1
```

To set variables without prompting the user:

```sh
./zabbix_agent.sh 192.168.100.100
./zabbix_agent_5.2.ps1 192.168.100.100
./zabbix_agent_6.2.ps1 192.168.100.100
```

## License

GPL-3.0

**Made with ♥ by bygalacos**
