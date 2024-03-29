﻿#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  22.12.2022
#  Purpose/Change: Initial script development

param (
    [string]$ip,
    [string]$hostname
)

clear

$validArguments = @("-ip", "-hostname")
$unexpectedArguments = $args | Where-Object { $_ -notin $validArguments }
if ($unexpectedArguments.Count -gt 0) {
    Write-Host "Usage: script.ps1 -ip <IP_Address> -hostname <HostName>"
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

# Check If Zabbix Agent Running
$zabbixProcess = Get-WmiObject -Class Win32_Process -Filter 'Name="zabbix_agentd.exe"'
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
else {
    Write-Host "`nUnable to find running [Zabbix Agent], continuing...`n"
}

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
if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    Write-Host "`n[Zabbix Agent] Detected System Architecture: AMD64`n"
    $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.25/zabbix_agent-6.0.25-windows-amd64.zip"
} 
elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
    Write-Host "`n[Zabbix Agent] Detected System Architecture: x86`n"
    $zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.0/6.0.25/zabbix_agent-6.0.25-windows-i386.zip"
}
else {
    Write-Host "`n[Zabbix Agent] Unsupported System Architecture. Terminating execution in 5 seconds.`n" -ForegroundColor Red
    Start-Sleep 5
    exit 1
}
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

# Script Cleanup
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
stop-process -Id $PID