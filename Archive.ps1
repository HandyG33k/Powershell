# Script Name Archive.ps1
# Purpose Archive the .dat file for Tempguard
# Author Michael Randall
# Date 06/18/2025
# Can be modified to move any files from one location $File to another location $Target 
# Make sure to remove the -Filter *.dat if using for other purposes 

# Arguments that need to be passed for script
param(

    [switch]$Help,

    [Parameter(Mandatory = $false)]
    [string] $File,

    [Parameter(Mandatory = $false)]
    [datetime] $StartDate,

    [Parameter(Mandatory = $false)]
    [datetime] $EndDate,

    [Parameter(Mandatory = $false)]
    [string] $Target

)


if ($Help) {
    write-host "This Script will archive the .dat files for TempGuard."
    write-host "Parameters:"
    write-host "Mandatory -File: The file containg the .dat files that need to be archived. If Spaces are in the name use quotes to avoid errors"
    write-host "Mandatory -StartDate: Needs to be in YYYY-MM-DD format. The date you wish to start the archive at."
    write-host "Mandatory -EndDate: Needs to be in YYYY-MM-DD format. The date you wish the archive to end at."
    write-host "Mandatory -Target: This is the file to send the archived files to. This will create a new file if it does not exist."
    exit
} 

if (-not $File) { throw "File parameter is required." }
if (-not $StartDate) { throw "StartDate parameter is required." }
if (-not $EndDate) { throw "EndDate parameter is required." }
if (-not $Target) { throw "Target parameter is required." }


# Validate File containing .dat file exists 

if (Test-Path -Path $File) {
    $True
}
    else {
    Write-Error "File does not exist"        
    }

# Validate the date range

if ($StartDate -gt $EndDate) {
    Write-Error "Start Date must be earlier than or equal to End Date."
}

# Validate Target File if it exists 

if (Test-Path -Path $Target) {
    $True
    Write-Error "This file already exists provide a new file for the new archive"
}
    else {
    New-Item -Path $Target -ItemType Directory
    }

# Move file in the date range from the $File to the $Target archive the data for later use 

Get-ChildItem -Path $File -Filter *.dat | Where-object {
    $_.LastWriteTime -ge $StartDate -and $_.LastWriteTime -le $EndDate
} | Move-Item -Destination $Target
