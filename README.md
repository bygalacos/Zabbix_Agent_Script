# Zabbix Agent Script
## Install the Zabbix Agent with ease!

[![Build Status](https://camo.githubusercontent.com/4e084bac046962268fcf7a8aaf3d4ac422d3327564f9685c9d1b57aa56b142e9/68747470733a2f2f7472617669732d63692e6f72672f6477796c2f657374612e7376673f6272616e63683d6d6173746572)](https://travis-ci.org/joemccann/dillinger)

Releasing script that installs zabbix agent without any hassle.

## Features

- Checks PowerShell version 3.0 or higher **(Windows Only)**
- Supports Self-Elevation **(Windows Only)**
- Detects OS and previous Zabbix agent files
- User-friendly installation process
- Added SSL & TLS support for secure downloads
- Supports x64 and x86 architectures **(Windows Only)**
- Prompts or accepts "Zabbix Server" IP address as a command line argument
- Automatic or specified hostname via command line **(Windows Only)**
- Organizes log files **(Windows Only)**
- Update & upgrade without changing config file **(Windows Only)**
- Supports both Agent & Agent2
- Remote Script Execution support **(Windows Only)**

To use command line arguments, simply provide the script name and the IP address.

## Usage

Please note that **Zabbix Agent Script** requires a Windows, Ubuntu or CentOS operating system, depending on which platform you're using.

```sh
First grant executable permissions using chmod +x zabbix_agent_6.2.sh
```

To launch the script:

```sh
./zabbix_agent_6.0.sh
```

To set variables without prompting the user:

```sh
./zabbix_agent_6.0.sh 192.168.100.100
```

Guide for Zabbix_Agent_Script.ps1:

```sh
./Zabbix_Agent_Script.ps1
./Zabbix_Agent_Script.ps1 -agent <1 or 2 12 or 21> -version <6.0 or 6.2 or 6.4> -ip <IP_Address> -hostname <HostName> -saveConfig <Optional & Requires Only -agent and -version>"
Arguments -agent and -version are mandatory. If -saveConfig is not used, -ip is also mandatory, while -hostname is optional. When -saveConfig is used, only -agent and -version are required, assuming an active configuration file exists.
```

Note: If you encounter any errors while launching the script, try right-clicking and selecting "Run with Powershell".

## License

This software is licensed under GPL-3.0

**Made with ♥ by bygalacos**
