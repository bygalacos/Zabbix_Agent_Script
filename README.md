# Zabbix Agent Script
## Install the Zabbix Agent with ease!

[![Build Status](https://camo.githubusercontent.com/4e084bac046962268fcf7a8aaf3d4ac422d3327564f9685c9d1b57aa56b142e9/68747470733a2f2f7472617669732d63692e6f72672f6477796c2f657374612e7376673f6272616e63683d6d6173746572)](https://travis-ci.org/joemccann/dillinger)

Releasing script that installs zabbix agent without any hassle.

## Features

- Checks if PowerShell version is higher or equal to 3.0 **(Windows Only)**
- Supports Self-Elevation **(Windows Only)**
- Detects the operating system and any previous Zabbix agent files
- More user-friendly installation process
- Added SSL & TLS support for better handling while downloading
- Supports both x64 and x86 system architectures **(Windows Only)**
- Prompts for the "Zabbix Server" IP address, or accepts it as a command line argument
- The hostname can be automatically assigned or specified as a command line argument **(Windows Only)**
- Organizes log files **(Windows Only)**
- Supports update w/o changing config file **(Windows Only)**
- Now support both Agent & Agent2

To use command line arguments, simply provide the script name and the IP address.

## Usage

Please note that **Zabbix Agent Script** requires a Windows, Ubuntu or CentOS operating system, depending on which platform you're using.

```sh
First grant executable permissions using chmod +x zabbix_agent_6.2.sh
```

To launch the script:

```sh
./zabbix_agent_6.0.sh
./zabbix_agent_6.0.ps1
```

To set variables without prompting the user:

```sh
./zabbix_agent_6.0.sh 192.168.100.100
./zabbix_agent_6.0.ps1 -ip 192.168.100.100
./zabbix_agent_6.0.ps1 -ip 192.168.100.100 -hostname hostname
```

Guide for Zabbix_Agent_Script.ps1:

```sh
./Zabbix_Agent_Script.ps1
./Zabbix_Agent_Script.ps1 -agent <1 or 2> -version <6.0 or 6.2 or 6.4> -ip <IP_Address> -hostname <HostName>"
```

Note: If you encounter any errors while launching the script, try right-clicking and selecting "Run with Powershell".

## License

This software is licensed under GPL-3.0

**Made with ♥ by bygalacos**
