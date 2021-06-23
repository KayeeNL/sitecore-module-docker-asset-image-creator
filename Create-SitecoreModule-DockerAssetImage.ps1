
<#
    .SYNOPSIS
        Script to handle the auto creation of a Docker Asset Image for a given Sitecore module
    .DESCRIPTION
        The purpose of this script is to create a Docker asset image for your Sitecore module
        The script is intended to automate some steps that need to be taken in order to create a custom 
        Docker Asset Image for your Sitecore module

        I got the inspiration for this project after reading the following blogposts:

        How to create a Docker asset image for your Sitecore Module - Árvai Mihály
        https://medium.com/@mitya_1988/how-to-create-a-docker-asset-image-for-your-sitecore-module-58e1f3a47672

        Creating a Docker Asset Image for Your Sitecore Module and Adding It To Your Site - Erica Stockwell-Alpert
        https://ericastockwellalpert.wordpress.com/2021/02/23/creating-a-docker-asset-image-for-your-sitecore-module-and-adding-it-to-your-site/
    .NOTES
        Version:        1.0
        Author:         Robbert Hock - Kayee - Sitecore MVP 2010-2021
        Creation Date:  June/July 2021
        Purpose/Change: Initial script development 
#>

using module ".\logo.psm1"

#---------------------------------[Parameters]--------------------------------------------------------
param(
    [string] $ModulePackageName = ""
)

#---------------------------------[Read configuration]------------------------------------------------
$configurationPath = "configuration.json"
$jsonConfiguration = Get-Content -Path $configurationPath | ConvertFrom-Json
$satUrl = $jsonConfiguration.Parameters.SitecoreAzureToolkitUrl.DefaultValue
$satPackageName = $jsonConfiguration.Parameters.SitecoreAzureToolkitPackageName.DefaultValue

Show-Start

if (!$ModulePackageName) {
    Write-Host "================================================================================================================================="
    Write-Host "`n"
    Write-Host "ERROR - Make sure you pass in the -ModulePackageName parameter. e.g. .\\Create-SitecoreModule-DockerAssetImage.ps1 -ModulePackageName 'YOUR PACKAGE NAME'" -ForegroundColor Red
    Write-Host "`n"
    Write-Host "================================================================================================================================="
}
else {
    Write-Host "================================================================================================================================="
    Write-Host "`n"
    Write-Host "START - [Sitecore Azure Toolkit download]"
    Write-Host "`n"

    $satDirecory = $PSScriptRoot + "\SAT"

    If (!(Test-Path($satDirecory))) {
        New-Item -ItemType Directory -Force -Path $satDirecory
    }

    if (Test-Path -Path "$satDirecory\$satPackageName") {
        Write-Host "SKIPPING - $satDirecory folder already contains the $satPackageName file" -ForegroundColor Cyan
    }
    else {
        Write-Host "START - downloading the $satPackageName file from dev.sitecore.net"
        Invoke-WebRequest -Uri $satUrl -OutFile "$satDirecory\$satPackageName"
        Write-Host "`n"
        Write-Host "SUCCESS - Downloaded the $satPackageName file from dev.sitecore.net" -ForegroundColor Green
    }

    Write-Host "`n"

    Write-Host "=================================================================================================================================="
    Write-Host "`n"
    Write-Host "START - [Sitecore Azure Toolkit extract]"
    Write-Host "`n"

    if (-not(Test-Path "$satDirecory\tools\Sitecore.Cloud.Cmdlets.dll")) {
        Expand-Archive -Path "$satDirecory\$satPackageName" -DestinationPath "$satDirecory" -Force
        Write-Host "SUCCESS - Extracted $satPackageName to the $satDirecory directory" -ForegroundColor Green
        Write-Host "`n"
    }
    else {
        Write-Host "SKIPPING - $satPackageName is already extracted to the $satDirecory directory" -ForegroundColor Cyan
        Write-Host "`n"
    }

    Write-Host "=================================================================================================================================="
    Write-Host "`n"
    Write-Host "START - [Convert Sitecore Module to .scwdp]"
    Write-Host "`n"

    $packagePath = $PSScriptRoot + "\Package\$ModulePackageName"
    $scwdpDirectory = $PSScriptRoot + "\scwpd"

    Import-Module .\SAT\tools\Sitecore.Cloud.Cmdlets.psm1
    Import-Module .\SAT\tools\Sitecore.Cloud.Cmdlets.dll

    If (!(Test-Path($packagePath))) {
        Write-Host "ERROR - Make sure the $packagePath exists!" -ForegroundColor Red
    }
    else {
        If (!(Test-Path($scwdpDirectory))) {
            New-Item -ItemType Directory -Force -Path $scwdpDirectory
        }

        Get-ChildItem -Path $scwdpDirectory -Recurse | Foreach-object { Remove-item -Recurse -path $_.FullName }

        $scwdpPath = ConvertTo-SCModuleWebDeployPackage -Path $packagePath -Destination $scwdpDirectory -Force
        Write-Host "SUCCESS - Your Sitecore Module was converted to a Sitecore WebDeploy package and is located at:" -ForegroundColor Green
        Write-Host "`n"
        Write-Host "$scwdpPath" -ForegroundColor Yellow
        Write-Host "`n"

        Write-Host "=================================================================================================================================="
        Write-Host "`n"
        Write-Host "START - [Extracting Sitecore WebDeploy package]"
        Write-Host "`n"

        $extractSCwdpDirectory = $scwdpDirectory + "\extract"

        if (!(Test-Path($extractSCwdpDirectory))) {
            New-Item -ItemType Directory -Force -Path $extractSCwdpDirectory
        }

        Expand-Archive -Path "$scwdpPath" -DestinationPath "$extractSCwdpDirectory" -Force

        Write-Host "=================================================================================================================================="
        Write-Host "`n"
        Write-Host "START - [Creating Sitecore module asset image structure]"
        Write-Host "`n"

        $moduleDirectory = $PSScriptRoot + "\Module"
        $cmContentDirectory = $moduleDirectory + "\cm\content"
        $dbDirectory = $moduleDirectory + "\db"
        $solrDirectory = $moduleDirectory + "\solr"
        $toolsDirectory = $moduleDirectory + "\tools"

        If (!(Test-Path($moduleDirectory))) {
            New-Item -ItemType Directory -Force -Path $moduleDirectory
        }

        Remove-Item -Path $moduleDirectory -Recurse

        If (!(Test-Path($cmContentDirectory))) {
            New-Item -ItemType Directory -Force -Path $cmContentDirectory
        }

        If (!(Test-Path($dbDirectory))) {
            New-Item -ItemType Directory -Force -Path $dbDirectory
        }

        If (!(Test-Path($solrDirectory))) {
            New-Item -ItemType Directory -Force -Path $solrDirectory
        }

        If (!(Test-Path($toolsDirectory))) {
            New-Item -ItemType Directory -Force -Path $toolsDirectory
        }

        Write-Host "=================================================================================================================================="
        Write-Host "`n"
        Write-Host "START - [Copying over .scwdp contents to Sitecore module asset image structure]"
        Write-Host "`n"

        # Copy content
        Copy-Item -Path "$extractSCwdpDirectory\Content\Website\*" -Destination $cmContentDirectory -PassThru -Recurse

        # Copy dacpacs + rename
        if (Test-Path("$extractSCwdpDirectory\core.dacpac")) {
            Copy-Item -Path "$extractSCwdpDirectory\core.dacpac" -Destination $dbDirectory -PassThru
            Rename-Item -Path "$dbDirectory\core.dacpac" -NewName "Sitecore.Core.dacpac"
        }

        if (Test-Path("$extractSCwdpDirectory\master.dacpac")) {
            Copy-Item -Path "$extractSCwdpDirectory\master.dacpac" -Destination $dbDirectory -PassThru
            Rename-Item -Path "$dbDirectory\master.dacpac" -NewName "Sitecore.Master.dacpac"
        }
    
        Write-Host "=================================================================================================================================="
        Write-Host "`n"
        Write-Host "START - [Copying over dockerfile]"
        Write-Host "`n"

        Copy-Item -Path "$PSScriptRoot\dockerfile" -Destination $moduleDirectory -PassThru

        Write-Host "=================================================================================================================================="
        Write-Host "`n"
        Write-Host "SUCCESS - Succesfully created the Docker Asset Image structure in directory $moduleDirectory" -ForegroundColor Green
        Write-Host "`n"

        tree $moduleDirectory /f /a

        Write-Host "`n"
        Write-Host "=================================================================================================================================="
        Write-Host "`n"
    }
}

Show-Stop

# Cleaning up the modules
Get-Module | Remove-Module