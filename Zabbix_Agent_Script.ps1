#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  04.02.2024
#  Purpose/Change: Initial script development

param (
    [string]$agent,
    [string]$version,
    [string]$ip,
    [string]$hostname
)

clear

$validArguments = @("-agent", "-version", "-ip", "-hostname")
$unexpectedArguments = $args | Where-Object { $_ -notin $validArguments }
if ($unexpectedArguments.Count -gt 0) {
    Write-Host "Usage: script.ps1 -agent <1 or 2> -version <6.0 or 6.2 or 6.4> -ip <IP_Address> -hostname <HostName>"
    Write-Host "Error: Unexpected argument(s): $($unexpectedArguments -join ', ')" -ForegroundColor Red
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

function checkAgent {
$zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agentd.exe"'
$zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent"'

if ($zabbixProcess) {
    $pathZabbixExe = $zabbixProcess.Path
    $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
    Write-Host "`n[Zabbix Agent] already running, uninstalling...`n"
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --stop
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --uninstall
    Start-Sleep -Seconds 3
    Remove-Item $pathZabbixFolder -Force -Recurse
    if (Test-Path -Path C:\zabbix_agentd.log) {
        $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
        Rename-Item -Path "C:\zabbix_agentd.log" -NewName "C:\zabbix_agentd_$logdate.log"
        Write-Host "`n[Zabbix Agent] Log renamed successfully`n"
    }
    Write-Host "`n[Zabbix Agent] removed successfully`n" -ForegroundColor Green
}
elseif ($zabbixService) {
    $null = $zabbixService.Delete()
    Write-Host "`n[Zabbix Agent] service stopped and uninstalled successfully`n" -ForegroundColor Green
}
else {
    Write-Host "`nUnable to find running [Zabbix Agent] or installed as a service, continuing...`n"
}
}

function checkAgent2 {
$zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agent2.exe"'
$zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent 2"'

if ($zabbixProcess) {
    $pathZabbixExe = $zabbixProcess.Path
    $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
    Write-Host "`n[Zabbix Agent 2] already running, uninstalling...`n"
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --stop
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --uninstall
    Start-Sleep -Seconds 3
    Remove-Item $pathZabbixFolder -Force -Recurse
    if (Test-Path -Path C:\zabbix_agent2.log) {
        $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
        Rename-Item -Path "C:\zabbix_agent2.log" -NewName "C:\zabbix_agent2_$logdate.log"
        Write-Host "`n[Zabbix Agent 2] Log renamed successfully`n"
    }
    Write-Host "`n[Zabbix Agent 2] removed successfully`n" -ForegroundColor Green
}
elseif ($zabbixService) {
    $null = $zabbixService.Delete()
    Write-Host "`n[Zabbix Agent 2] service stopped and uninstalled successfully`n" -ForegroundColor Green
    
        $registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Zabbix Agent 2"
        if (Test-Path $registryKeyPath) {
            Remove-Item -Path $registryKeyPath -Force
            Write-Host "`n[Zabbix Agent 2] Registry key removed successfully`n" -ForegroundColor Green
    }
}
else {
    Write-Host "`nUnable to find running [Zabbix Agent 2] or installed as a service, continuing...`n"
}
}

function downloadAgent {
# Download & Install Zabbix Agent Files
Start-Sleep -Seconds 3
Write-Host "`n[Zabbix Agent] initializing installation`n"
if (Test-Path -Path C:\zabbix_agent) {
    Remove-Item C:\zabbix_agent -Force -Recurse
}
if (Test-Path -Path C:\zabbix_agentd.log) {
    Remove-Item C:\zabbix_agentd.log -Force
}
Start-Sleep -Seconds 1
$protocols = 'Ssl3,Tls,Tls11,Tls12,Tls13' -split ',' | Where-Object { [System.Enum]::IsDefined([System.Net.SecurityProtocolType], $_) }
[System.Net.ServicePointManager]::SecurityProtocol = $protocols -join ','
Write-Host "`n[Zabbix Agent] Available security protocols: $([System.Net.ServicePointManager]::SecurityProtocol)`n"

# Check if the version parameter is provided, otherwise, ask the user for input
if (!($version)) {
    Write-Host "`n`n"
    $version = Read-Host 'Select [Zabbix Agent] version, valid options are: 6.0 6.2 6.4'
}

$architecture = $env:PROCESSOR_ARCHITECTURE
if ($version -eq "6.0") {
    if ($architecture -eq "AMD64") {
        $zipUrl = " https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.26/zabbix_agent-6.0.26-windows-amd64.zip"
    } elseif ($architecture -eq "x86") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.26/zabbix_agent-6.0.26-windows-i386.zip"
    } else {
        Write-Host "`n[Zabbix Agent] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
}
elseif ($version -eq "6.2") {
    if ($architecture -eq "AMD64") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent-6.2.9-windows-amd64.zip"
    } elseif ($architecture -eq "x86") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent-6.2.9-windows-i386.zip"
    } else {
        Write-Host "`n[Zabbix Agent] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
}
elseif ($version -eq "6.4") {
    if ($architecture -eq "AMD64") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.11/zabbix_agent-6.4.11-windows-amd64.zip"
    } elseif ($architecture -eq "x86") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.11/zabbix_agent-6.4.11-windows-i386.zip"
    } else {
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
if (Test-Path -Path C:\zabbix_agentd.log) {
    Remove-Item C:\zabbix_agentd.log -Force
}
Invoke-WebRequest -Uri $zipUrl -OutFile "$env:TEMP\zabbix_agent.zip"
Start-Sleep -Seconds 3
if (!(Test-Path -Path $env:TEMP\zabbix_agent.zip)) {
    Write-Host "`n[Zabbix Agent] download failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
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
if (!(Test-Path -Path C:\zabbix_agent)) {
    Write-Host "`n[Zabbix Agent] installation failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep 5
    exit 1
}
Write-Host "`n[Zabbix Agent] files installed successfully`n" -ForegroundColor Green
}

function downloadAgent2 {
# Download & Install Zabbix Agent 2 Files
Start-Sleep -Seconds 3
Write-Host "`n[Zabbix Agent 2] initializing installation`n"
if (Test-Path -Path C:\zabbix_agent2) {
    Remove-Item C:\zabbix_agent2 -Force -Recurse
}
if (Test-Path -Path C:\zabbix_agent2.log) {
    Remove-Item C:\zabbix_agent2.log -Force
}
Start-Sleep -Seconds 1
$protocols = 'Ssl3,Tls,Tls11,Tls12,Tls13' -split ',' | Where-Object { [System.Enum]::IsDefined([System.Net.SecurityProtocolType], $_) }
[System.Net.ServicePointManager]::SecurityProtocol = $protocols -join ','
Write-Host "`n[Zabbix Agent 2] Available security protocols: $([System.Net.ServicePointManager]::SecurityProtocol)`n"

# Check if the version parameter is provided, otherwise, ask the user for input
if (!($version)) {
    Write-Host "`n`n"
    $version = Read-Host 'Select [Zabbix Agent 2] version, valid options are: 6.0 6.2 6.4'
}

$architecture = $env:PROCESSOR_ARCHITECTURE
if ($version -eq "6.0") {
    if ($architecture -eq "AMD64") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.26/zabbix_agent2-6.0.26-windows-amd64-static.zip"
    } elseif ($architecture -eq "x86") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.26/zabbix_agent2-6.0.26-windows-i386-static.zip"
    } else {
        Write-Host "`n[Zabbix Agent 2] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
}
elseif ($version -eq "6.2") {
    if ($architecture -eq "AMD64") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent2-6.2.9-windows-amd64-static.zip"
    } elseif ($architecture -eq "x86") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent2-6.2.9-windows-i386-static.zip"
    } else {
        Write-Host "`n[Zabbix Agent 2] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
}
elseif ($version -eq "6.4") {
    if ($architecture -eq "AMD64") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.11/zabbix_agent2-6.4.11-windows-amd64-static.zip"
    } elseif ($architecture -eq "x86") {
        $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.11/zabbix_agent2-6.4.11-windows-i386-static.zip"
    } else {
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
if (Test-Path -Path C:\zabbix_agent2.log) {
    Remove-Item C:\zabbix_agent2.log -Force
}
Invoke-WebRequest -Uri $zipUrl -OutFile "$env:TEMP\zabbix_agent2.zip"
Start-Sleep -Seconds 3
if (!(Test-Path -Path $env:TEMP\zabbix_agent2.zip)) {
    Write-Host "`n[Zabbix Agent 2] download failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
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
if (!(Test-Path -Path C:\zabbix_agent2)) {
    Write-Host "`n[Zabbix Agent 2] installation failed. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep 5
    exit 1
}
Write-Host "`n[Zabbix Agent 2] files installed successfully`n" -ForegroundColor Green
}

function setRunAgent{
# Set Variables
$confFile = "C:\zabbix_agent\conf\zabbix_agentd.conf"

# Check if the IP and hostname parameters are provided, otherwise, ask the user for input
if (!($ip)) {
    $ip = Read-Host 'Enter the IP address of the Zabbix server'
}
if (!($hostname)) {
    $hostname = hostname.exe
}

Write-Host "`n[Zabbix Agent] Current configuration: IP Address: $ip & Hostname: $hostname`n" -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Change Value (LF)
(Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$ip" | Set-Content $confFile
(Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$ip" | Set-Content $confFile
(Get-Content $confFile) -join "`n" -replace "Hostname=Windows host", "Hostname=$hostname" | Set-Content $confFile

# Install & Run
Start-Sleep -Seconds 1
& C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --install
Start-Sleep -Seconds 1
& C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --start
Start-Sleep -Seconds 1
$zabbixTime = (Get-Date (Get-Process zabbix_agentd).StartTime)
Write-Host "`n[Zabbix Agent] started at -> $zabbixTime`n" -ForegroundColor Green
Start-Sleep -Seconds 1
}

function setRunAgent2{
# Set Variables
$confFile = "C:\zabbix_agent2\conf\zabbix_agent2.conf"

# Check if the IP and hostname parameters are provided, otherwise, ask the user for input
if (!($ip)) {
    $ip = Read-Host 'Enter the IP address of the Zabbix server'
}
if (!($hostname)) {
    $hostname = hostname.exe
}

Write-Host "`n[Zabbix Agent 2] Current configuration: IP Address: $ip & Hostname: $hostname`n" -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Change Value (LF)
(Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$ip" | Set-Content $confFile
(Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$ip" | Set-Content $confFile
(Get-Content $confFile) -join "`n" -replace "Hostname=Windows host", "Hostname=$hostname" | Set-Content $confFile

# Install & Run
Start-Sleep -Seconds 1
& C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --install
Start-Sleep -Seconds 1
& C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --start
Start-Sleep -Seconds 1
$zabbixTime = (Get-Date (Get-Process zabbix_agent2).StartTime)
Write-Host "`n[Zabbix Agent 2] started at -> $zabbixTime`n" -ForegroundColor Green
Start-Sleep -Seconds 1
}

function ZabbixAgent {
checkAgent

downloadAgent

setRunAgent

scriptCleanup
}

function ZabbixAgent2 {
checkAgent2

downloadAgent2

setRunAgent2

scriptCleanup
}

function hotUpdate {
$zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agentd.exe"'
$zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent"'

if ($zabbixProcess) {
    $pathZabbixExe = $zabbixProcess.Path
    $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
    Write-Host "`n[Zabbix Agent] already running, uninstalling...`n"
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --stop
    Start-Sleep -Seconds 1
    if (Test-Path -Path "$pathZabbixFolder\conf\zabbix_agentd.conf") {
        Copy-Item -Path "$pathZabbixFolder\conf\zabbix_agentd.conf" -Destination "$env:TEMP"
        Write-Host "`n[Zabbix Agent] config saved`n"
    }
    else {
        Write-Host "`nUnable to find running [Zabbix Agent] or installed as a service. Reverting changes & Terminating execution in 5 seconds.`n" -ForegroundColor Red
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --start
        Start-Sleep -Seconds 5
        exit 1
    }
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agentd.conf --uninstall
    Start-Sleep -Seconds 3
    Remove-Item $pathZabbixFolder -Force -Recurse
    if (Test-Path -Path C:\zabbix_agentd.log) {
        $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
        Rename-Item -Path "C:\zabbix_agentd.log" -NewName "C:\zabbix_agentd_$logdate.log"
        Write-Host "`n[Zabbix Agent] Log renamed successfully`n"
    }
    Write-Host "`n[Zabbix Agent] removed successfully`n" -ForegroundColor Green
}
elseif ($zabbixService) {
    $null = $zabbixService.Delete()
    Write-Host "`n[Zabbix Agent] service stopped and uninstalled successfully`n" -ForegroundColor Green
}
else {
    Write-Host "`nUnable to find running [Zabbix Agent] or installed as a service. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

downloadAgent

if (Test-Path -Path "$env:TEMP\zabbix_agentd.conf") {
    Remove-Item "C:\zabbix_agent\conf\zabbix_agentd.conf" -Force
    Move-Item -Path "$env:TEMP\zabbix_agentd.conf" -Destination "C:\zabbix_agent\conf\zabbix_agentd.conf"
    Write-Host "`n[Zabbix Agent] config restored`n"
}
else {
    Write-Host "`nUnable to find [Zabbix Agent] config file. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

# Install & Run
Start-Sleep -Seconds 1
& C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --install
Start-Sleep -Seconds 1
& C:\zabbix_agent\bin\zabbix_agentd.exe --config C:\zabbix_agent\conf\zabbix_agentd.conf --start
Start-Sleep -Seconds 1
$zabbixTime = (Get-Date (Get-Process zabbix_agentd).StartTime)
Write-Host "`n[Zabbix Agent] started at -> $zabbixTime`n" -ForegroundColor Green
Start-Sleep -Seconds 1

scriptCleanup
}

function hotUpdate2 {
$zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agent2.exe"'
$zabbixService = Get-WmiObject -Class Win32_Service -Filter 'Name="Zabbix Agent 2"'

if ($zabbixProcess) {
    $pathZabbixExe = $zabbixProcess.Path
    $pathZabbixFolder = Split-Path -Path $pathZabbixExe | Split-Path
    Write-Host "`n[Zabbix Agent 2] already running, uninstalling...`n"
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --stop
    Start-Sleep -Seconds 1
    if (Test-Path -Path "$pathZabbixFolder\conf\zabbix_agent2.conf") {
        Copy-Item -Path "$pathZabbixFolder\conf\zabbix_agent2.conf" -Destination "$env:TEMP"
        Write-Host "`n[Zabbix Agent 2] config saved`n"
    }
    else {
        Write-Host "`nUnable to find running [Zabbix Agent 2] or installed as a service. Reverting changes & Terminating execution in 5 seconds.`n" -ForegroundColor Red
        & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --start
        Start-Sleep -Seconds 5
        exit 1
    }
    Start-Sleep -Seconds 1
    & $pathZabbixExe --config $pathZabbixFolder\conf\zabbix_agent2.conf --uninstall
    Start-Sleep -Seconds 3
    Remove-Item $pathZabbixFolder -Force -Recurse
    if (Test-Path -Path C:\zabbix_agent2.log) {
        $logdate = Get-Date -Format "dd.MM.yyyy_HH.mm"
        Rename-Item -Path "C:\zabbix_agent2.log" -NewName "C:\zabbix_agent2_$logdate.log"
        Write-Host "`n[Zabbix Agent 2] Log renamed successfully`n"
    }
    Write-Host "`n[Zabbix Agent 2] removed successfully`n" -ForegroundColor Green
}
elseif ($zabbixService) {
    $null = $zabbixService.Delete()
    Write-Host "`n[Zabbix Agent 2] service stopped and uninstalled successfully`n" -ForegroundColor Green
    
        $registryKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\Zabbix Agent 2"
        if (Test-Path $registryKeyPath) {
            Remove-Item -Path $registryKeyPath -Force
            Write-Host "`n[Zabbix Agent 2] Registry key removed successfully`n" -ForegroundColor Green
    }
}
else {
    Write-Host "`nUnable to find running [Zabbix Agent 2] or installed as a service. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

downloadAgent2

if (Test-Path -Path "$env:TEMP\zabbix_agent2.conf") {
    Remove-Item "C:\zabbix_agent2\conf\zabbix_agent2.conf" -Force
    Move-Item -Path "$env:TEMP\zabbix_agent2.conf" -Destination "C:\zabbix_agent2\conf\zabbix_agent2.conf"
    Write-Host "`n[Zabbix Agent] config restored`n"
}
else {
    Write-Host "`nUnable to find [Zabbix Agent 2] config file. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep -Seconds 5
    exit 1
}

# Install & Run
Start-Sleep -Seconds 1
& C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --install
Start-Sleep -Seconds 1
& C:\zabbix_agent2\bin\zabbix_agent2.exe --config C:\zabbix_agent2\conf\zabbix_agent2.conf --start
Start-Sleep -Seconds 1
$zabbixTime = (Get-Date (Get-Process zabbix_agent2).StartTime)
Write-Host "`n[Zabbix Agent 2] started at -> $zabbixTime`n" -ForegroundColor Green
Start-Sleep -Seconds 1

scriptCleanup
}

function scriptCleanup {
Write-Host "`n[Zabbix Agent] installation script leftovers removing...`n"
Start-Sleep -Seconds 3
Remove-Item $PSCommandPath -Force
Write-Host "`n[Zabbix Agent] installation script leftovers removed successfully`n" -ForegroundColor Green
Write-Host "`nMade with ♥ by bygalacos`n" -ForegroundColor Yellow
Write-Host "`nhttps://github.com/bygalacos`n" -ForegroundColor Yellow
Start-Sleep 3
Write-Host "`n!!!WARNING!!!`n" -ForegroundColor Red
Write-Host "`nThis session will self destruct in 5 seconds...`n" -ForegroundColor Red
Start-Sleep 5
}

function scriptMenu{
Write-Host "Welcome to [Zabbix Agent] installation script, Made with ♥ by bygalacos`n" -ForegroundColor Yellow
Write-Host "1) Install [Zabbix Agent]`n"
Write-Host "2) Install [Zabbix Agent 2]`n"
Write-Host "3) Hot-Update [Zabbix Agent]`n"
Write-Host "4) Hot-Update [Zabbix Agent 2]`n"

$operationSelection = Read-Host "`nPlease Select Your Operation"
    if ($operationSelection -eq 1) {
        ZabbixAgent
    } elseif ($operationSelection -eq 2) {
        ZabbixAgent2
    } elseif ($operationSelection -eq 3) {
        hotUpdate
    } elseif ($operationSelection -eq 4) {
        hotUpdate2
    } else {
        Write-Host "`n[Zabbix Agent] installation script failed due to invalid selection. Terminating execution in 5 seconds.`n" -ForegroundColor Red
        Start-Sleep 5
        exit 1
    }
}

#CLI Launcher
if ($agent -eq 1) {
    ZabbixAgent
}
elseif ($agent -eq 2) {
    ZabbixAgent2
}
else {
    scriptMenu
}