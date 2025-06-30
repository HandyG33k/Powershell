# # Script Name reset_to_Default.ps1
# Purpose Reset ZD410 Label Printer to Default Fixing Most Errors
# Author Michael Randall
# Date 06/24/2025

param(
    [switch]$Help
)

# Help Menu
if ($Help) {
    write-output "This Script will reset a ZD410 to default fixing most errors."
    write-output "Parameters:"
    write-output "Mandatory -IP: This is the IP Address of the Label Printer."
    write-output "Mandatory -SN: This is the Serial Number of the Zebra printer found in Printer Logic."
    exit
}

# Create a session Cookie
$session = $null
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession    

# Prompts
write-output "access help by typing ./reset_to_default"
$IP = Read-Host "Enter the IP Address of the Label Printer"
$SN = Read-Host "Enter the Serial Number of the Zebra printer"

# IP Variables 
$controlip = "$IP/control"
$settingip = "$IP/settings"
$authip = "$IP/authorize"

# Test Connection
try {
    $testresponse = Invoke-WebRequest -Uri $controlip -UseBasicParsing -WebSession $session
    if ($testresponse.StatusCode -eq 200) {
    write-output "Connection to $controlip successful."
    } else {
    write-output "Failed to connect to $controlip. Status code: $($testresponse.StatusCode)"
    exit
    }
    } catch {
    write-output "Error connecting to ${controlip}: ${_}"
    exit
    }
    

# Response Variables
$controlresponse = Invoke-WebRequest -Uri $controlip -UseBasicParsing -WebSession $session
$authform = @{
    "0" = ""
}
Start-Sleep -Seconds 2
$authformresponse = Invoke-WebRequest -Uri $authip -Method Post -Body $authform -ContentType "text/html" -WebSession $session


write-output "Control Response: $($controlresponse.Content)"
write-output "Auth Form Response: $($authformresponse.Content)"


# Regex Variables
$titlematch = [regex]::Match($controlresponse.Content, '<title>(.*?)</title>', 'Ignorecase')
$authtitlematch = [regex]::Match($authformresponse.Content, '<title>(.*?)</title>', 'Ignorecase')

Write-Output "Title Match: $($titlematch.Groups[1].Value)"
Write-Output "Auth Title Match: $($authtitlematch.Groups[1].Value)"

$restoreform = @{
    "4" = 'Restore Default Configuration'
}
$saveform = @{
    "0" = "Save Current Configuration"
}

# Form submit Variables
$restorereponse = Invoke-WebRequest -Uri $settingip -Method Post -Body $restoreform -WebSession $session
$saveresponse = Invoke-WebRequest -Uri $settingip -Method Post -Body $saveform -WebSession $session


write-output "Restore Response: $($restorereponse.Content)"
write-output "Save Response: $($saveresponse.Content)"


# Success Variables
$authsuccess = $authtitlematch.Groups[1].Value -match "Printer Controls" -or $authformresponse.Content -match "Access Granted. This IP Address now has admin access to the restricted printer pages."
$restoresuccess = $restorereponse.Content -match "Factory configuration restored."
$savesuccess = $saveresponse.Content -match "Current configuration saved."

if (-not [System.Net.IPAddress]::TryParse($IP, [ref]$null)) {
    throw "Invalid IP Address Format"
}
if (-not $titlematch.Success) {
    write-output "Failed to Extract title for HTML"
    return
}
$title = $titlematch.Groups[1].Value
if (-not $title -match $SN) {
    write-output "This is the incorrect page"
    return
}
write-output "This is the correct Printer"

if (-not $authsuccess) {
    write-output "Authorization Failed"
    Write-Output $authformresponse
    return
}
Write-Output "Authorization Successful"
if (-not $restoresuccess) {
    Write-Output "Restore Failed"
    return
}
write-output "Restore Default Configuration Successful."
if (-not $savesuccess) {
    Write-Output "Failed to save current configuration."
    return
}
Write-output "Saving the current config was successful."
