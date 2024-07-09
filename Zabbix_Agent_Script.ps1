#  Version:        1.1
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  04.02.2024
#  Modify Date:    04.07.2024
#  Purpose/Change: Initial script development

param (
    [string]$agent,
    [string]$version,
    [string]$ip,
    [string]$hostname,
    [switch]$saveConfig,
    [switch]$help
)

Clear-Host

$validArguments = @("-agent", "-version", "-ip", "-hostname", "-saveConfig", "-help")
$unexpectedArguments = $args | Where-Object { $_ -notin $validArguments }
if ($unexpectedArguments.Count -gt 0) {
    Write-Host "Usage: script.ps1 -agent <1 or 2 12 or 21> -version <6.0 or 6.2 or 6.4> -ip <IP_Address> -hostname <HostName> -saveConfig <Optional & Requires Only -agent and -version>"
    Write-Host "Usage: script.ps1 -help <Detailed command explanations>"
    Write-Host "Error: Unexpected argument(s): $($unexpectedArguments -join ', ')" -ForegroundColor Red
    Write-Host "`nTerminating execution.`n" -ForegroundColor Red
    exit 1
}

# Check Required PowerShell Version
$minimumRequiredVersion = [Version]"3.0"
$psVersion = $PSVersionTable.PSVersion
if ($psVersion -lt $minimumRequiredVersion) {
    Write-Host "`nThis script requires PowerShell version $minimumRequiredVersion or later.`n" -ForegroundColor Red
    Write-Host "`nPlease upgrade PowerShell and try running the script again.`n" -ForegroundColor Red
    Write-Host "`nTerminating execution in 5 seconds...`n" -ForegroundColor Red
    Start-Sleep 5
    exit 1
}

# Grant Administrator Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $scriptPath = $MyInvocation.MyCommand.Definition
    $argumentString = ""

    # Loop through each parameter and reconstruct the argument string
    foreach ($param in $MyInvocation.MyCommand.Parameters.Keys) {
        if ($PSBoundParameters[$param]) {
            $argumentString += " -$param `"$($PSBoundParameters[$param])`""
        }
    }

    # Relaunch the script as an administrator with the arguments
    Start-Process PowerShell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $argumentString" -Verb RunAs; exit
}
else {
    Write-Host "`nAdministrator Privileges granted, continuing...`n" -ForegroundColor Green
}

function help {
    Clear-Host
    Write-Host "`nUsage: script.ps1 -agent <1 or 2 12 or 21> -version <6.0 or 6.2 or 6.4> -ip <IP_Address> -hostname <HostName> -saveConfig <Optional & Requires -agent and -version>`n" -ForegroundColor Yellow
    Write-Host "`nArguments -agent and -version are mandatory. If -saveConfig is not used, -ip is also mandatory, while -hostname is optional. When -saveConfig is used, only -agent and -version are required, assuming an active configuration file exists.`n" -ForegroundColor Yellow
    Write-Host "`nExample: <script.ps1 -agent 1 -version 6.4 -ip 192.168.1.2> -hostname is optional here since it script can use computer name.`n"
    Write-Host "`nExample: <script.ps1 -agent 12 -version 6.4 -ip 192.168.1.2> -hostname is optional here since it script can use computer name.`n"
    Write-Host "`nExample: <script.ps1 -agent 12 -version 6.4 -saveConfig> -saveConfig is optional here since it can store variables during agent update/upgrade, overriding the need for -ip and -hostname arguments`n"
    exit 0
}

function checkAgent {
    $zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agentd.exe"'
    $zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent"'

    if ($zabbixProcess) {
        $pathZabbixExe = $zabbixProcess.Path
        $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
        if ($saveConfig) {
            if (Test-Path -Path "C:\zabbix_agent\conf\zabbix_agentd.conf") {
                # Save configuration details if configuration file exists
                Write-Host "`n[Zabbix Agent] -saveConfig parameter provided. Saving currently running agent configuration.`n"
                $oldconf = "C:\zabbix_agent\conf\zabbix_agentd.conf"
                Start-Sleep -Seconds 1
                $oldconfServer = (Select-String -Path $oldconf -Pattern "^Server=(.+)" -CaseSensitive).Matches.Groups[1].Value.Trim()
                Start-Sleep -Seconds 1
                $oldconfServerActive = (Select-String -Path $oldconf -Pattern "^ServerActive=(.+)" -CaseSensitive).Matches.Groups[1].Value.Trim()
                Start-Sleep -Seconds 1
                $oldconfHostname = (Select-String -Path $oldconf -Pattern "^Hostname=(.+)" -CaseSensitive).Matches.Groups[1].Value.Trim()
                Start-Sleep -Seconds 1
                # Check missing configuration details
                if ((-not $oldconfServer) -or (-not $oldconfServerActive) -or (-not $oldconfHostname)) {
                    Write-Host "`n[Zabbix Agent 2] Unable to find parameter(s) in the configuration file. Saving failed. Try running without -saveConfig parameter.`n" -ForegroundColor Red
                    Write-Host "`nTerminating execution in 5 seconds.`n"
                    Start-Sleep -Seconds 5
                    exit 1
                }
                if (Test-Path -Path "$env:TEMP\oldconf.txt") {
                    Remove-Item -Path "$env:TEMP\oldconf.txt" -Force
                    Start-Sleep -Seconds 1
                }
                # Save old configuration values to a file
                @"
$oldconfServer
$oldconfServerActive
$oldconfHostname
"@ | Set-Content -Path "$env:TEMP\oldconf.txt" -Force
                Write-Host "`n[Zabbix Agent] Configuration saved successfully. Server: $oldconfServer & ServerActive: $oldconfServerActive & Hostname: $oldconfHostname`n" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            else {
                Write-Host "`n[Zabbix Agent] Unable to find currently running agent configuration file. Saving failed. Try running without -saveConfig parameter.`n" -ForegroundColor Red
                Write-Host "`nTerminating execution in 5 seconds.`n"
                Start-Sleep -Seconds 5
                exit 1
            }
        }
        Write-Host "`n[Zabbix Agent] Already running, uninstalling...`n"
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --stop
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --uninstall
        Start-Sleep -Seconds 3
        Remove-Item $pathZabbixFolder -Force -Recurse
        if (Test-Path -Path "C:\zabbix_agentd.log") {
            $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
            Rename-Item -Path "C:\zabbix_agentd.log" -NewName "C:\zabbix_agentd_$logdate.log"
            Write-Host "`n[Zabbix Agent] Log renamed successfully.`n"
        }
        Write-Host "`n[Zabbix Agent] Removed successfully.`n" -ForegroundColor Green
    }
    elseif ($zabbixService) {
        $null = $zabbixService.Delete()
        Write-Host "`n[Zabbix Agent] Service stopped and uninstalled successfully.`n" -ForegroundColor Green
    }
    else {
        Write-Host "`n[Zabbix Agent] Unable to find running agent or service, continuing...`n"
    }
}

function checkAgent2 {
    $zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agent2.exe"'
    $zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent 2"'

    if ($zabbixProcess) {
        $pathZabbixExe = $zabbixProcess.Path
        $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
        if ($saveConfig) {
            if (Test-Path -Path "C:\zabbix_agent2\conf\zabbix_agent2.conf") {
                # Save configuration details if configuration file exists
                Write-Host "`n[Zabbix Agent 2] -saveConfig parameter provided. Saving currently running agent configuration.`n"
                $oldconf = "C:\zabbix_agent2\conf\zabbix_agent2.conf"
                Start-Sleep -Seconds 1
                $oldconfServer = (Select-String -Path $oldconf -Pattern "^Server=(.+)" -CaseSensitive).Matches.Groups[1].Value.Trim()
                Start-Sleep -Seconds 1
                $oldconfServerActive = (Select-String -Path $oldconf -Pattern "^ServerActive=(.+)" -CaseSensitive).Matches.Groups[1].Value.Trim()
                Start-Sleep -Seconds 1
                $oldconfHostname = (Select-String -Path $oldconf -Pattern "^Hostname=(.+)" -CaseSensitive).Matches.Groups[1].Value.Trim()
                Start-Sleep -Seconds 1
                # Check missing configuration details
                if ((-not $oldconfServer) -or (-not $oldconfServerActive) -or (-not $oldconfHostname)) {
                    Write-Host "`n[Zabbix Agent 2] Unable to find parameter(s) in the configuration file. Saving failed. Try running without -saveConfig parameter.`n" -ForegroundColor Red
                    Write-Host "`nTerminating execution in 5 seconds.`n"
                    Start-Sleep -Seconds 5
                    exit 1
                }
                if (Test-Path -Path "$env:TEMP\oldconf.txt") {
                    Remove-Item -Path "$env:TEMP\oldconf.txt" -Force
                    Start-Sleep -Seconds 1
                }
                # Save old configuration values to a file
                @"
$oldconfServer
$oldconfServerActive
$oldconfHostname
"@ | Set-Content -Path "$env:TEMP\oldconf.txt" -Force
                Write-Host "`n[Zabbix Agent 2] Configuration saved successfully. Server: $oldconfServer & ServerActive: $oldconfServerActive & Hostname: $oldconfHostname`n" -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            else {
                Write-Host "`n[Zabbix Agent 2] Unable to find currently running agent configuration file. Saving failed. Try running without -saveConfig parameter.`n" -ForegroundColor Red
                Write-Host "`nTerminating execution in 5 seconds.`n"
                Start-Sleep -Seconds 5
                exit 1
            }
        }
        Write-Host "`n[Zabbix Agent 2] Already running, uninstalling...`n"
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --stop
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --uninstall
        Start-Sleep -Seconds 3
        Remove-Item $pathZabbixFolder -Force -Recurse
        if (Test-Path -Path "C:\zabbix_agent2.log") {
            $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
            Rename-Item -Path "C:\zabbix_agent2.log" -NewName "C:\zabbix_agent2_$logdate.log"
            Write-Host "`n[Zabbix Agent 2] Log renamed successfully.`n"
        }
        Write-Host "`n[Zabbix Agent 2] Removed successfully.`n" -ForegroundColor Green
    }
    elseif ($zabbixService) {
        $null = $zabbixService.Delete()
        Write-Host "`n[Zabbix Agent 2] Service stopped and uninstalled successfully.`n" -ForegroundColor Green
    
        $registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Zabbix Agent 2"
        if (Test-Path $registryKeyPath) {
            Remove-Item -Path $registryKeyPath -Force
            Write-Host "`n[Zabbix Agent 2] Registry key removed successfully.`n" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`n[Zabbix Agent 2] Unable to find running agent or service, continuing...`n"
    }
}

function downloadAgent {
    # Download & Install Zabbix Agent Files
    Start-Sleep -Seconds 3
    Write-Host "`n[Zabbix Agent] Initializing installation...`n"
    if (Test-Path -Path "C:\zabbix_agent") {
        Remove-Item "C:\zabbix_agent" -Force -Recurse
    }
    if (Test-Path -Path C:\zabbix_agentd.log) {
        Remove-Item "C:\zabbix_agentd.log" -Force
    }
    Start-Sleep -Seconds 1
    $protocols = 'Ssl3,Tls,Tls11,Tls12,Tls13' -split ',' | Where-Object { [System.Enum]::IsDefined([System.Net.SecurityProtocolType], $_) }
    [System.Net.ServicePointManager]::SecurityProtocol = $protocols -join ','
    Write-Host "`n[Zabbix Agent] Available security protocols: $([System.Net.ServicePointManager]::SecurityProtocol)`n"

    # Check if the version parameter is provided, otherwise, ask the user for input
    if (!($version)) {
        Write-Host "`n`n"
        $version = Read-Host '[Zabbix Agent] Select version, valid options are: 6.0 6.2 6.4'
    }

    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ($version -eq "6.0") {
        if ($architecture -eq "AMD64") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.29/zabbix_agent-6.0.29-windows-amd64.zip"
        }
        elseif ($architecture -eq "x86") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.29/zabbix_agent-6.0.29-windows-i386.zip"
        }
        else {
            Write-Host "`n[Zabbix Agent] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
    }
    elseif ($version -eq "6.2") {
        if ($architecture -eq "AMD64") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent-6.2.9-windows-amd64.zip"
        }
        elseif ($architecture -eq "x86") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent-6.2.9-windows-i386.zip"
        }
        else {
            Write-Host "`n[Zabbix Agent] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
    }
    elseif ($version -eq "6.4") {
        if ($architecture -eq "AMD64") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.16/zabbix_agent-6.4.16-windows-amd64.zip"
        }
        elseif ($architecture -eq "x86") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.16/zabbix_agent-6.4.16-windows-i386.zip"
        }
        else {
            Write-Host "`n[Zabbix Agent] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
    }
    else {
        Write-Host "`n[Zabbix Agent] Unsupported Version. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }

    Write-Host "`n[Zabbix Agent] Detected System Architecture: $architecture`n"
    Write-Host "`n[Zabbix Agent] Version: $version`n"

    $extractPath = "C:\zabbix_agent"
    if (Test-Path -Path "C:\zabbix_agentd.log") {
        Remove-Item "C:\zabbix_agentd.log" -Force
    }
    Invoke-WebRequest -Uri $agentUrl -OutFile "$env:TEMP\zabbix_agent.zip"
    Start-Sleep -Seconds 3
    if (!(Test-Path -Path "$env:TEMP\zabbix_agent.zip")) {
        Write-Host "`n[Zabbix Agent] Download failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
        Expand-Archive -Path "$env:TEMP\zabbix_agent.zip" -DestinationPath "$extractPath"
    }
    else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$env:TEMP\zabbix_agent.zip", "$extractPath")
    }
    Remove-Item "$env:TEMP\zabbix_agent.zip" -Force
    if (!(Test-Path -Path $extractPath)) {
        Write-Host "`n[Zabbix Agent] Installation failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
    Write-Host "`n[Zabbix Agent] Files copied successfully.`n" -ForegroundColor Green
}

function downloadAgent2 {
    # Download & Install Zabbix Agent 2 Files
    Start-Sleep -Seconds 3
    Write-Host "`n[Zabbix Agent 2] Initializing installation...`n"
    if (Test-Path -Path "C:\zabbix_agent2") {
        Remove-Item "C:\zabbix_agent2" -Force -Recurse
    }
    if (Test-Path -Path "C:\zabbix_agent2.log") {
        Remove-Item "C:\zabbix_agent2.log" -Force
    }
    Start-Sleep -Seconds 1
    $protocols = 'Ssl3,Tls,Tls11,Tls12,Tls13' -split ',' | Where-Object { [System.Enum]::IsDefined([System.Net.SecurityProtocolType], $_) }
    [System.Net.ServicePointManager]::SecurityProtocol = $protocols -join ','
    Write-Host "`n[Zabbix Agent 2] Available security protocols: $([System.Net.ServicePointManager]::SecurityProtocol)`n"

    # Check if the version parameter is provided, otherwise, ask the user for input
    if (!($version)) {
        Write-Host "`n`n"
        $version = Read-Host '[Zabbix Agent 2] Select version, valid options are: 6.0 6.2 6.4'
    }

    $architecture = $env:PROCESSOR_ARCHITECTURE
    if ($version -eq "6.0") {
        if ($architecture -eq "AMD64") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.29/zabbix_agent2-6.0.29-windows-amd64-static.zip"
            $pluginUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.29/zabbix_agent2_plugins-6.0.29-windows-amd64.zip"
        }
        elseif ($architecture -eq "x86") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.29/zabbix_agent2-6.0.29-windows-i386-static.zip"
        }
        else {
            Write-Host "`n[Zabbix Agent 2] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
    }
    elseif ($version -eq "6.2") {
        if ($architecture -eq "AMD64") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent2-6.2.9-windows-amd64-static.zip"
            # N/A for version 6.2 $pluginUrl = ""
        }
        elseif ($architecture -eq "x86") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent2-6.2.9-windows-i386-static.zip"
        }
        else {
            Write-Host "`n[Zabbix Agent 2] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
    }
    elseif ($version -eq "6.4") {
        if ($architecture -eq "AMD64") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.16/zabbix_agent2-6.4.16-windows-amd64-static.zip"
            $pluginUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.16/zabbix_agent2_plugins-6.4.16-windows-amd64.zip"
        }
        elseif ($architecture -eq "x86") {
            $agentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.16/zabbix_agent2-6.4.16-windows-i386-static.zip"
        }
        else {
            Write-Host "`n[Zabbix Agent 2] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
    }
    else {
        Write-Host "`n[Zabbix Agent 2] Unsupported Version. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }

    Write-Host "`n[Zabbix Agent 2] Detected System Architecture: $architecture`n"
    Write-Host "`n[Zabbix Agent 2] Version: $version`n"

    $extractPath = "C:\zabbix_agent2"
    if (Test-Path -Path "C:\zabbix_agent2.log") {
        Remove-Item "C:\zabbix_agent2.log" -Force
    }
    Invoke-WebRequest -Uri $agentUrl -OutFile "$env:TEMP\zabbix_agent2.zip"
    Start-Sleep -Seconds 3
    if (!(Test-Path -Path "$env:TEMP\zabbix_agent2.zip")) {
        Write-Host "`n[Zabbix Agent 2] Download failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
    if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
        Expand-Archive -Path "$env:TEMP\zabbix_agent2.zip" -DestinationPath "$extractPath"
    }
    else {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory("$env:TEMP\zabbix_agent2.zip", "$extractPath")
    }
    Remove-Item "$env:TEMP\zabbix_agent2.zip" -Force
    if (!(Test-Path -Path $extractPath)) {
        Write-Host "`n[Zabbix Agent 2] Installation failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
    # Download plugins if $pluginUrl is not null
    if ($pluginUrl) {
        if (Test-Path -Path "C:\zabbix_agent2_plugin") {
            Remove-Item "C:\zabbix_agent2_plugin" -Force -Recurse
        }
        $pluginPath = "C:\zabbix_agent2_plugin"
        Invoke-WebRequest -Uri $pluginUrl -OutFile "$env:TEMP\zabbix_agent2_plugin.zip"
        Start-Sleep -Seconds 3
        if (!(Test-Path -Path "$env:TEMP\zabbix_agent2_plugin.zip")) {
            Write-Host "`n[Zabbix Agent 2] Download plugins failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
            Start-Sleep 5
            exit 1
        }
        if (Get-Command Expand-Archive -ErrorAction SilentlyContinue) {
            Expand-Archive -Path "$env:TEMP\zabbix_agent2_plugin.zip" -DestinationPath "$pluginPath"
        }
        else {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory("$env:TEMP\zabbix_agent2_plugin.zip", "$pluginPath")
        }
        Remove-Item "$env:TEMP\zabbix_agent2_plugin.zip" -Force
        Move-Item -Path "C:\zabbix_agent2_plugin\zabbix_agent2_plugins-*\plugins\*" -Destination "C:\zabbix_agent2\bin\"
        Move-Item -Path "C:\zabbix_agent2_plugin\zabbix_agent2_plugins-*\conf\*" -Destination "C:\zabbix_agent2\conf\zabbix_agent2.d\plugins.d\"
        Remove-Item -Path $pluginPath -Force -Recurse
        # Add Post-Installation check for plugins
    }
    Write-Host "`n[Zabbix Agent 2] Files installed successfully.`n" -ForegroundColor Green
}

function setRunAgent {
    # Set Variables
    $confFile = "C:\zabbix_agent\conf\zabbix_agentd.conf"

    if (Test-Path -Path "$env:TEMP\oldconf.txt") {
        $oldconfValues = Get-Content -Path "$env:TEMP\oldconf.txt"
        $oldconfServer = $oldconfValues[0]
        $oldconfServerActive = $oldconfValues[1]
        $oldconfHostname = $oldconfValues[2]
        Remove-Item -Path "$env:TEMP\oldconf.txt" -Force

        Write-Host "`n[Zabbix Agent] Using saved agent configuration file. Server: $oldconfServer & ServerActive: $oldconfServerActive & Hostname: $oldconfHostname`n" -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        # Update configuration file with saved values
        # Change Value (LF)
        (Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$oldconfServer" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$oldconfServerActive" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "Hostname=Windows host", "Hostname=$oldconfHostname" | Set-Content $confFile
    }
    else {
        # Check if the IP and hostname parameters are provided, otherwise, ask the user for input
        if (!($ip)) {
            $ip = Read-Host '[Zabbix Agent] Enter the IP address for agent to connect'
        }
        if (!($hostname)) {
            $hostname = hostname.exe
        }

        Write-Host "`n[Zabbix Agent] Current configuration: IP Address: $ip & Hostname: $hostname`n" -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        # Update configuration file with user-provided values
        # Change Value (LF)
        (Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$ip" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$ip" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "Hostname=Windows host", "Hostname=$hostname" | Set-Content $confFile
    }
    # Install & Run
    Start-Sleep -Seconds 1
    & C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --install
    Start-Sleep -Seconds 1
    & C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --start
    Start-Sleep -Seconds 1
    $zabbixTime = (Get-Date (Get-Process zabbix_agentd).StartTime)
    Write-Host "`n[Zabbix Agent] Started at -> $zabbixTime`n" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

function setRunAgent2 {
    # Set Variables
    $confFile = "C:\zabbix_agent2\conf\zabbix_agent2.conf"

    $mongodbPluginExe = "C:\zabbix_agent2\bin\zabbix-agent2-plugin-mongodb.exe"
    $mongodbPluginConf = "C:\zabbix_agent2\conf\zabbix_agent2.d\plugins.d\mongodb.conf"

    $mssqlPluginExe = "C:\zabbix_agent2\bin\zabbix-agent2-plugin-mssql.exe"
    $mssqlPluginConf = "C:\zabbix_agent2\conf\zabbix_agent2.d\plugins.d\mssql.conf"

    $postgresqlPluginExe = "C:\zabbix_agent2\bin\zabbix-agent2-plugin-postgresql.exe"
    $postgresqlPluginConf ="C:\zabbix_agent2\conf\zabbix_agent2.d\plugins.d\postgresql.conf"

    if (Test-Path -Path "$env:TEMP\oldconf.txt") {
        $oldconfValues = Get-Content -Path "$env:TEMP\oldconf.txt"
        $oldconfServer = $oldconfValues[0]
        $oldconfServerActive = $oldconfValues[1]
        $oldconfHostname = $oldconfValues[2]
        Remove-Item -Path "$env:TEMP\oldconf.txt" -Force

        Write-Host "`n[Zabbix Agent 2] Using saved agent configuration file. Server: $oldconfServer & ServerActive: $oldconfServerActive & Hostname: $oldconfHostname`n" -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        # Update configuration file with saved values
        # Change Value (LF)
        (Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$oldconfServer" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$oldconfServerActive" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "Hostname=Windows host", "Hostname=$oldconfHostname" | Set-Content $confFile

        if ((Test-Path -Path $mongodbPluginExe) -and (Test-Path -Path $mongodbPluginConf) -and (Test-Path -Path $mssqlPluginExe) -and (Test-Path -Path $mssqlPluginConf) -and (Test-Path -Path $postgresqlPluginExe) -and (Test-Path -Path $postgresqlPluginConf)) {
            (Get-Content $mongodbPluginConf) -join "`n" -replace "# Plugins.MongoDB.System.Path=", "Plugins.MongoDB.System.Path=$mongodbPluginExe" | Set-Content $mongodbPluginConf
            (Get-Content $mssqlPluginConf) -join "`n" -replace "# Plugins.MSSQL.System.Path=", "Plugins.MSSQL.System.Path=$mssqlPluginExe" | Set-Content $mssqlPluginConf
            (Get-Content $postgresqlPluginConf) -join "`n" -replace "# Plugins.PostgreSQL.System.Path=", "Plugins.PostgreSQL.System.Path=$postgresqlPluginExe" | Set-Content $postgresqlPluginConf
            Write-Host "`n[Zabbix Agent 2] Plugins configured.`n" -ForegroundColor Yellow
        }
    }
    else {
        # Check if the IP and hostname parameters are provided, otherwise, ask the user for input
        if (!($ip)) {
            $ip = Read-Host '[Zabbix Agent 2] Enter the IP address for agent to connect'
        }
        if (!($hostname)) {
            $hostname = hostname.exe
        }

        Write-Host "`n[Zabbix Agent 2] Current configuration: IP Address: $ip & Hostname: $hostname`n" -ForegroundColor Yellow
        Start-Sleep -Seconds 3

        # Update configuration file with user-provided values
        # Change Value (LF)
        (Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$ip" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$ip" | Set-Content $confFile
        (Get-Content $confFile) -join "`n" -replace "Hostname=Windows host", "Hostname=$hostname" | Set-Content $confFile

        if ((Test-Path -Path $mongodbPluginExe) -and (Test-Path -Path $mongodbPluginConf) -and (Test-Path -Path $mssqlPluginExe) -and (Test-Path -Path $mssqlPluginConf) -and (Test-Path -Path $postgresqlPluginExe) -and (Test-Path -Path $postgresqlPluginConf)) {
            (Get-Content $mongodbPluginConf) -join "`n" -replace "# Plugins.MongoDB.System.Path=", "Plugins.MongoDB.System.Path=$mongodbPluginExe" | Set-Content $mongodbPluginConf
            (Get-Content $mssqlPluginConf) -join "`n" -replace "# Plugins.MSSQL.System.Path=", "Plugins.MSSQL.System.Path=$mssqlPluginExe" | Set-Content $mssqlPluginConf
            (Get-Content $postgresqlPluginConf) -join "`n" -replace "# Plugins.PostgreSQL.System.Path=", "Plugins.PostgreSQL.System.Path=$postgresqlPluginExe" | Set-Content $postgresqlPluginConf
            Write-Host "`n[Zabbix Agent 2] Plugins configured.`n" -ForegroundColor Yellow
        }
    }
    # Install & Run
    Start-Sleep -Seconds 1
    & C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --install
    Start-Sleep -Seconds 1
    & C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --start
    Start-Sleep -Seconds 1
    $zabbixTime = (Get-Date (Get-Process zabbix_agent2).StartTime)
    Write-Host "`n[Zabbix Agent 2] Started at -> $zabbixTime`n" -ForegroundColor Green
    Start-Sleep -Seconds 1
}

function hotUpdate {
    $zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agentd.exe"'
    $zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent"'

    if ($zabbixProcess) {
        $pathZabbixExe = $zabbixProcess.Path
        $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
        Write-Host "`n[Zabbix Agent] Already running, uninstalling...`n"
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --stop
        Start-Sleep -Seconds 1
        if (Test-Path -Path "$pathZabbixFolder\conf\zabbix_agentd.conf") {
            Copy-Item -Path "$pathZabbixFolder\conf\zabbix_agentd.conf" -Destination "$env:TEMP"
            Write-Host "`n[Zabbix Agent] Config saved.`n"
        }
        else {
            Write-Host "`n[Zabbix Agent] Unable to find running agent or service. Reverting changes & Terminating execution in 5 seconds.`n" -ForegroundColor Red
            & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --start
            Start-Sleep -Seconds 5
            exit 1
        }
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --uninstall
        Start-Sleep -Seconds 3
        Remove-Item $pathZabbixFolder -Force -Recurse
        if (Test-Path -Path "C:\zabbix_agentd.log") {
            $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
            Rename-Item -Path "C:\zabbix_agentd.log" -NewName "C:\zabbix_agentd_$logdate.log"
            Write-Host "`n[Zabbix Agent] Log renamed successfully.`n"
        }
        Write-Host "`n[Zabbix Agent] Removed successfully.`n" -ForegroundColor Green
    }
    elseif ($zabbixService) {
        $null = $zabbixService.Delete()
        Write-Host "`n[Zabbix Agent] Service stopped and uninstalled successfully.`n" -ForegroundColor Green
    }
    else {
        Write-Host "`n[Zabbix Agent] Unable to find running agent or service. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit 1
    }

    downloadAgent

    if (Test-Path -Path "$env:TEMP\zabbix_agentd.conf") {
        Remove-Item "C:\zabbix_agent\conf\zabbix_agentd.conf" -Force
        Move-Item -Path "$env:TEMP\zabbix_agentd.conf" -Destination "C:\zabbix_agent\conf\zabbix_agentd.conf"
        Write-Host "`n[Zabbix Agent] Config restored.`n"
    }
    else {
        Write-Host "`n[Zabbix Agent] Unable to find agent configuration file. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit 1
    }

    Start-Sleep -Seconds 1
    & C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --install
    Start-Sleep -Seconds 1
    & C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --start
    Start-Sleep -Seconds 1
    $zabbixTime = (Get-Date (Get-Process zabbix_agentd).StartTime)
    Write-Host "`n[Zabbix Agent] Started at -> $zabbixTime`n" -ForegroundColor Green
    Start-Sleep -Seconds 1

    scriptCleanup
}

function hotUpdate2 {
    $zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agent2.exe"'
    $zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent 2"'

    if ($zabbixProcess) {
        $pathZabbixExe = $zabbixProcess.Path
        $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
        Write-Host "`n[Zabbix Agent 2] Already running, uninstalling...`n"
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --stop
        Start-Sleep -Seconds 1
        if (Test-Path -Path "$pathZabbixFolder\conf\zabbix_agent2.conf") {
            Copy-Item -Path "$pathZabbixFolder\conf\zabbix_agent2.conf" -Destination "$env:TEMP"
            Write-Host "`n[Zabbix Agent 2] Config saved.`n"
        }
        else {
            Write-Host "`n[Zabbix Agent 2] Unable to find running agent or service. Reverting changes & Terminating execution in 5 seconds.`n" -ForegroundColor Red
            & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --start
            Start-Sleep -Seconds 5
            exit 1
        }
        Start-Sleep -Seconds 1
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --uninstall
        Start-Sleep -Seconds 3
        Remove-Item $pathZabbixFolder -Force -Recurse
        if (Test-Path -Path "C:\zabbix_agent2.log") {
            $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
            Rename-Item -Path "C:\zabbix_agent2.log" -NewName "C:\zabbix_agent2_$logdate.log"
            Write-Host "`n[Zabbix Agent 2] Log renamed successfully.`n"
        }
        Write-Host "`n[Zabbix Agent 2] Removed successfully.`n" -ForegroundColor Green
    }
    elseif ($zabbixService) {
        $null = $zabbixService.Delete()
        Write-Host "`n[Zabbix Agent 2] Service stopped and uninstalled successfully.`n" -ForegroundColor Green
    
        $registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Zabbix Agent 2"
        if (Test-Path $registryKeyPath) {
            Remove-Item -Path $registryKeyPath -Force
            Write-Host "`n[Zabbix Agent 2] Registry key removed successfully.`n" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`n[Zabbix Agent 2] Unable to find running agent or service. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit 1
    }

    downloadAgent2

    if (Test-Path -Path "$env:TEMP\zabbix_agent2.conf") {
        Remove-Item "C:\zabbix_agent2\conf\zabbix_agent2.conf" -Force
        Move-Item -Path "$env:TEMP\zabbix_agent2.conf" -Destination "C:\zabbix_agent2\conf\zabbix_agent2.conf"
        Write-Host "`n[Zabbix Agent] Config restored.`n"
    }
    else {
        Write-Host "`n[Zabbix Agent 2] Unable to find agent configuration file. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit 1
    }

    Start-Sleep -Seconds 1
    & C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --install
    Start-Sleep -Seconds 1
    & C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --start
    Start-Sleep -Seconds 1
    $zabbixTime = (Get-Date (Get-Process zabbix_agent2).StartTime)
    Write-Host "`n[Zabbix Agent 2] Started at -> $zabbixTime`n" -ForegroundColor Green
    Start-Sleep -Seconds 1

    scriptCleanup
}

function scriptCleanup {
    Write-Host "`n[Zabbix Agent] Installation script leftovers removing...`n"
    Start-Sleep -Seconds 3
    Remove-Item $PSCommandPath -Force
    Write-Host "`n[Zabbix Agent] Installation script leftovers removed successfully.`n" -ForegroundColor Green
    Write-Host "`nMade with ♥ by bygalacos`n" -ForegroundColor Yellow
    Write-Host "`nhttps://github.com/bygalacos`n" -ForegroundColor Yellow
    Start-Sleep 3
    Write-Host "`n!!!WARNING!!!`n" -ForegroundColor Red
    Write-Host "`nThis session will self destruct in 5 seconds...`n" -ForegroundColor Red
    Start-Sleep 5
}

function zabbixAgent {
    checkAgent

    downloadAgent

    setRunAgent

    scriptCleanup
}

function zabbixAgent2 {
    checkAgent2

    downloadAgent2

    setRunAgent2

    scriptCleanup
}

function zabbixAgent12 {
    checkAgent

    downloadAgent2

    setRunAgent2

    scriptCleanup
}

function zabbixAgent21 {
    checkAgent2

    downloadAgent

    setRunAgent

    scriptCleanup  
}

function scriptMenu {
    Clear-Host
    Write-Host "Welcome to [Zabbix Agent] installation script, Made with ♥ by bygalacos`n" -ForegroundColor Yellow
    Write-Host "1) Install [Zabbix Agent]`n"
    Write-Host "2) Install [Zabbix Agent 2]`n"
    Write-Host "3) Update [Zabbix Agent 1] to [Zabbix Agent 2]`n"
    Write-Host "4) Update [Zabbix Agent 2] to [Zabbix Agent 1]`n"
    Write-Host "5) Hot-Update [Zabbix Agent]`n"
    Write-Host "6) Hot-Update [Zabbix Agent 2]`n"
    Write-Host "9) Help - Usage Manual`n"
    Write-Host "`nType [exit] to terminate [Zabbix Agent] installation script"

    $operationSelection = Read-Host "`nPlease Select Your Operation"
    if ($operationSelection -eq 1) {
        zabbixAgent
    }
    elseif ($operationSelection -eq 2) {
        zabbixAgent2
    }
    elseif ($operationSelection -eq 3) {
        zabbixAgent12
    }
    elseif ($operationSelection -eq 4) {
        zabbixAgent21
    }
    elseif ($operationSelection -eq 5) {
        hotUpdate
    }
    elseif ($operationSelection -eq 6) {
        hotUpdate2
    }
    elseif ($operationSelection -eq 9) {
        help
    }
    elseif ($operationSelection -eq "exit") {
        exit 0
    }
    else {
		$invalidSelections++
		if ($invalidSelections -eq 3) {
			Write-Host "[Zabbix Agent] installation script exceeded maximum allowed failed attempts. Terminating script in 5 seconds." -ForegroundColor Red
			Start-Sleep 5
			exit 1
		}
        Write-Host "`n[Zabbix Agent] installation script failed due to invalid selection. Redirecting to main menu in 3 seconds.`n" -ForegroundColor Red
        Start-Sleep 3
        scriptMenu
    }
}

#CLI Launcher

if ($help) {
    help
}

if ($agent -eq 1) {
    zabbixAgent
}
elseif ($agent -eq 2) {
    zabbixAgent2
}
elseif ($agent -eq 12) {
    zabbixAgent12
}
elseif ($agent -eq 21) {
    zabbixAgent21
}
else {
    scriptMenu
}