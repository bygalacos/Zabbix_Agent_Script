#  Version:        1.0
#  Author:         bygalacos
#  Github:         github.com/bygalacos
#  Creation Date:  22.12.2022
#  Purpose/Change: Initial script development

# Grant Administrator Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
   Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" `"$args`"" -Verb RunAs; exit
}
else 
{
   Write-Host "`nAdministrator Privileges granted, continuing...`n" -ForegroundColor Green
}

# Check If Zabbix Agent Running
if (Get-WmiObject -class Win32_Process -Filter 'Name="zabbix_agentd.exe"' -ErrorAction SilentlyContinue)
{ 
   $pathZabbixExe = (Get-WmiObject -class Win32_Process -Filter 'Name="zabbix_agentd.exe"').path
   $pathZabbixFolder = (Get-WmiObject -class Win32_Process -Filter 'Name="zabbix_agentd.exe"').path.SubString(0, (Get-WmiObject -class Win32_Process -Filter 'Name="zabbix_agentd.exe"').path.LastIndexOf('\')) | Split-Path
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
else 
{
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
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType] 'Ssl3, Tls, Tls11, Tls12, Tls13'
$zipUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.2/6.2.9/zabbix_agent-6.2.9-windows-amd64.zip"
$extractPath = "C:\zabbix_agent"
if (Test-Path -Path $env:TEMP\zabbix_agent.zip) {
    Remove-Item C:\zabbix_agentd.log -Force
}
Invoke-WebRequest -Uri $zipUrl -OutFile "$env:TEMP\zabbix_agent.zip"
Start-Sleep -Seconds 3
if (!(Test-Path -Path $env:TEMP\zabbix_agent.zip)) {
    Write-Host "`n[Zabbix Agent] download failed. Terminating execution.`n" -ForegroundColor Red
    exit 1
}
Expand-Archive -Path "$env:TEMP\zabbix_agent.zip" -DestinationPath $extractPath
Remove-Item "$env:TEMP\zabbix_agent.zip" -Force
if (!(Test-Path -Path C:\zabbix_agent)) {
    Write-Host "`n[Zabbix Agent] installation failed. Terminating execution.`n" -ForegroundColor Red
    exit 1
}
Write-Host "`n[Zabbix Agent] files installed successfully`n" -ForegroundColor Green
Start-Sleep -Seconds 3

# Set Variables
$confFile = "C:\zabbix_agent\conf\zabbix_agentd.conf"
$hostname = hostname.exe

# Check if arguments were provided if not ask user to input
if ($args) {
    $zabbixIP = $args[0]
} else {
    $zabbixIP = Read-Host 'Enter the IP address of the Zabbix server'
}

# Change Value (LF)
(Get-Content $confFile) -join "`n" -replace "Server=127.0.0.1", "Server=$zabbixIP" | Set-Content $confFile
(Get-Content $confFile) -join "`n" -replace "ServerActive=127.0.0.1", "ServerActive=$zabbixIP" | Set-Content $confFile
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
Remove-Item $MyInvocation.MyCommand.Source
Write-Host "`n[Zabbix Agent] installation script leftovers removed successfully`n" -ForegroundColor Green
Write-Host "`nMade with ♥ by bygalacos`n" -ForegroundColor Yellow
Write-Host "`nhttps://github.com/bygalacos`n" -ForegroundColor Yellow
Start-Sleep 3
Write-Host "`n!!!WARNING!!!`n" -ForegroundColor Red
Write-Host "`nThis session will self destruct in 5 seconds...`n" -ForegroundColor Red
Start-Sleep 5
stop-process -Id $PID