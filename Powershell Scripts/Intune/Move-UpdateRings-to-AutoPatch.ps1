<#PSScriptInfo
.VERSION 2.0.1
.GUID db5cbf82-a7cc-4c1b-beab-943f541a0895
.AUTHOR AndrewTaylor
.DESCRIPTION Moves all members of current Update Ring groups to new AutoPatch Groups, then unassigns old rings, deletes AzureAD groups and deletes old rings
.COMPANYNAME 
.COPYRIGHT GPL
.TAGS intune endpoint MEM environment autopatch
.LICENSEURI https://github.com/andrew-s-taylor/public/blob/main/LICENSE
.PROJECTURI https://github.com/andrew-s-taylor/public
.ICONURI 
.EXTERNALMODULEDEPENDENCIES AzureADPreview
.REQUIREDSCRIPTS 
.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES
#>
<#
.SYNOPSIS
Moves to Autpatch
.DESCRIPTION
Moves all members of current Update Ring groups to new AutoPatch Groups, then unassigns old rings, deletes AzureAD groups and deletes old rings
.INPUTS
None
.OUTPUTS
Creates a log file in %Temp%
.NOTES
  Version:        2.0.1
  Author:         Andrew Taylor
  Twitter:        @AndrewTaylor_2
  WWW:            andrewstaylor.com
  Creation Date:  06/09/2022
  Modified Date:  30/10/2022
  Purpose/Change: Initial script development
  Change:         Switched to graph API

  
.EXAMPLE
N/A
#>
$ErrorActionPreference = "Continue"
##Start Logging to %TEMP%\autopatch-intune-DATE.log
$date = get-date -format ddMMyyyy
Start-Transcript -Path $env:TEMP\autopatch-intune-$date.log


Function Get-ScriptVersion(){
    
    <#
    .SYNOPSIS
    This function is used to check if the running script is the latest version
    .DESCRIPTION
    This function checks GitHub and compares the 'live' version with the one running
    .EXAMPLE
    Get-ScriptVersion
    Returns a warning and URL if outdated
    .NOTES
    NAME: Get-ScriptVersion
    #>
    
    [cmdletbinding()]
    
    param
    (
        $liveuri
    )
$contentheaderraw = (Invoke-WebRequest -Uri $liveuri -Method Get)
$contentheader = $contentheaderraw.Content.Split([Environment]::NewLine)
$liveversion = (($contentheader | Select-String 'Version:') -replace '[^0-9.]','') | Select-Object -First 1
$currentversion = ((Get-Content -Path $PSCommandPath | Select-String -Pattern "Version: *") -replace '[^0-9.]','') | Select-Object -First 1
if ($liveversion -ne $currentversion) {
write-host "Script has been updated, please download the latest version from $liveuri" -ForegroundColor Red
}
}
Get-ScriptVersion -liveuri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/Powershell%20Scripts/Intune/Move-UpdateRings-to-AutoPatch.ps1"




write-host "Make it So" -ForegroundColor Green

##############################################################################################################
## Your Group Names
$broadname = "Broad"
$pilotname = "Pilot"
$previewname = "Preview"

#######
##Test = Pilot
##First = Preview
##Fast = IGNORED - will auto-populate
##Broad = Broad
##Note: Switching from 3 to 4 ring system

Write-Host "Installing Microsoft Graph modules if required (current user scope)"

#Install MS Graph if not available
if (Get-Module -ListAvailable -Name Microsoft.Graph) {
    Write-Host "Microsoft Graph Already Installed"
} 
else {
    try {
        Install-Module -Name Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force 
    }
    catch [Exception] {
        $_.message 
        exit
    }
}


# Load the Graph module
Import-Module microsoft.graph.groups

Function Connect-ToGraph {
    <#
.SYNOPSIS
Authenticates to the Graph API via the Microsoft.Graph.Authentication module.
 
.DESCRIPTION
The Connect-ToGraph cmdlet is a wrapper cmdlet that helps authenticate to the Intune Graph API using the Microsoft.Graph.Authentication module. It leverages an Azure AD app ID and app secret for authentication or user-based auth.
 
.PARAMETER Tenant
Specifies the tenant (e.g. contoso.onmicrosoft.com) to which to authenticate.
 
.PARAMETER AppId
Specifies the Azure AD app ID (GUID) for the application that will be used to authenticate.
 
.PARAMETER AppSecret
Specifies the Azure AD app secret corresponding to the app ID that will be used to authenticate.

.PARAMETER Scopes
Specifies the user scopes for interactive authentication.
 
.EXAMPLE
Connect-ToGraph -TenantId $tenantID -AppId $app -AppSecret $secret
 
-#>
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $false)] [string]$Tenant,
        [Parameter(Mandatory = $false)] [string]$AppId,
        [Parameter(Mandatory = $false)] [string]$AppSecret,
        [Parameter(Mandatory = $false)] [string]$scopes
    )

    Process {
        Import-Module Microsoft.Graph.Authentication
        $version = (get-module microsoft.graph.authentication | Select-Object -expandproperty Version).major

        if ($AppId -ne "") {
            $body = @{
                grant_type    = "client_credentials";
                client_id     = $AppId;
                client_secret = $AppSecret;
                scope         = "https://graph.microsoft.com/.default";
            }
     
            $response = Invoke-RestMethod -Method Post -Uri https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token -Body $body
            $accessToken = $response.access_token
     
            $accessToken
            if ($version -eq 2) {
                write-host "Version 2 module detected"
                $accesstokenfinal = ConvertTo-SecureString -String $accessToken -AsPlainText -Force
            }
            else {
                write-host "Version 1 Module Detected"
                Select-MgProfile -Name Beta
                $accesstokenfinal = $accessToken
            }
            $graph = Connect-MgGraph  -AccessToken $accesstokenfinal 
            Write-Host "Connected to Intune tenant $TenantId using app-based authentication (Azure AD authentication not supported)"
        }
        else {
            if ($version -eq 2) {
                write-host "Version 2 module detected"
            }
            else {
                write-host "Version 1 Module Detected"
                Select-MgProfile -Name Beta
            }
            $graph = Connect-MgGraph -scopes $scopes
            Write-Host "Connected to Intune tenant $($graph.TenantId)"
        }
    }
}    
#Connect to Graph
Connect-ToGraph -Scopes "Groups.ReadWrite.All, RoleAssignmentSchedule.ReadWrite.Directory, Domain.Read.All, Domain.ReadWrite.All, Directory.Read.All, Policy.ReadWrite.ConditionalAccess, DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, openid, profile, email, offline_access"


###############################################################################################################
######                                          Add Functions                                            ######
###############################################################################################################


###############################################################################################################
######                                          Time to Boogie                                           ######
###############################################################################################################

#Create Folder
$csvfolder = "C:\ProgramData\UpdateRings"
If (Test-Path $csvfolder) {
    Write-Output "$csvfolder exists. Skipping."
}
Else {
    Write-Output "The folder '$csvfolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path "$csvfolder" -ItemType Directory
    Write-Output "The folder $csvfolder was successfully created."
}


#Get Update Rings
##Filter to only Update Policies
$updateringsurl = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$filter=(isof('microsoft.graph.windowsUpdateForBusinessConfiguration'))"

write-host "Getting Update Rings"
##Grab the Value
$currentpolicies = (Invoke-MgGraphRequest -Uri $updateringsurl -Method Get -OutputType PSObject).Value

write-host "Getting Policy IDs"
##Find each policy ID
foreach ($currentpolicy in $currentpolicies) {
$policyname = $currentpolicy.DisplayName

##Broad - Ignoring new Autopatch Group for now
if (($policyname -like "*$broadname*") -and ($policyname -ne "Modern Workplace Update Policy [Broad]-[Windows Autopatch]")) {
$broadid = $currentpolicy.Id
write-host "Broad ring is $broadid"
}
}

##Preview - Ignoring new Autopatch Group for now
if (($policyname -like "*$previewname*") -and ($policyname -ne "Modern Workplace Update Policy [Fast]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [First]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [Test]-[Windows Autopatch]")) {
$previewid = $currentpolicy.Id
write-host "Preview ring is $previewid"
}


##Pilot - Ignoring new Autopatch Group for now
if (($policyname -like "*$pilotname*") -and ($policyname -ne "Modern Workplace Update Policy [Fast]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [First]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [Test]-[Windows Autopatch]")) {
$pilotid = $currentpolicy.Id
write-host "Pilot ring is $pilotid"
}




#Get the Group ID Assigned

write-host "Finding AAD Group IDs currently used"
$broaduricurrent = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$broadid/groupAssignments"
$previewuricurrent = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$previewid/groupAssignments"
$piloturicurrent = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$pilotid/groupAssignments"

$broadgroupscurrent = ((Invoke-MgGraphRequest -Uri $broaduricurrent -Method Get -OutputType PSObject).Value).TargetGroupID
write-host "Broad Ring uses $broadgroupscurrent"
$previewgroupscurrent = ((Invoke-MgGraphRequest -Uri $previewuricurrent -Method Get -OutputType PSObject).Value).TargetGroupID
write-host "Preview Ring uses $previewgroupscurrent"
$pilotgroupscurrent = ((Invoke-MgGraphRequest -Uri $piloturicurrent -Method Get -OutputType PSObject).Value).TargetGroupID
write-host "Pilot Ring uses $pilotgroupscurrent"


write-host "Groups grabbed, removing assignments"
##Delete Old Assignments
foreach ($currentpolicy in $currentpolicies) {
$policyname = $currentpolicy.DisplayName

if (($policyname -ne "Modern Workplace Update Policy [Fast]-[Windows Autopatch]") -and ($policyname -ne "Modern Workplace Update Policy [First]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [Test]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [Broad]-[Windows Autopatch]")) {
$policyid = $currentpolicy.Id
write-host "Unassigning $policyname"
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyid/assign"
$json = @"
{
    "assignments":  [
    ]

} 
"@
Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"
write-host "$policyname unassigned"
}
}


write-host "Assignments removed, populating groups"

connect-azureAD

##Move Broad Group Members
write-host "Getting members of Broad Group"
$currentbroadmembers = Get-MgGroupMember -GroupID $broadgroupscurrent -All $true
$newbroadgroupid = (Get-MgGroup -Search "Windows Autopatch Device Registration").ObjectID
write-host "Exporting Pilot Members to CSV"
$currentbroadmembers | Export-Csv "$csvfolder\BroadMembers.csv"

write-host "Adding to Windows Autopatch Device Registration"
foreach ($broadmember in $currentbroadmembers) {
    New-MgGroupMember -GroupID $newbroadgroupid -DirectoryObjectID $broadmember.ObjectID
write-host "Added $broadmember.DisplayName to Windows Autopatch Device Registration"
}
##Remove Broad Group
write-host "Removing Broad AAD Group"
Remove-MgGroup -GroupID $broadgroupscurrent
write-host "Broad Group AAD Removed"


##Move Preview Group Members
write-host "Getting members of Preview Group"
$previewbroadmembers = Get-MgGroupMember -GroupID $previewgroupscurrent -All $true
$newpreviewgroupid = (Get-MgGroup -Search "Windows Autopatch Device Registration").ObjectID
write-host "Exporting Pilot Members to CSV"
$previewbroadmembers | Export-Csv "$csvfolder\PreviewMembers.csv"

write-host "Adding to Windows Autopatch Device Registration"
foreach ($previewmember in $previewbroadmembers) {
New-MgGroupMember -GroupID $newpreviewgroupid -DirectoryObjectID $previewmember.ObjectID
write-host "Added $previewmember.DisplayName to Windows Autopatch Device Registration"
}
##Remove Broad Group
write-host "Removing Preview AAD Group"
Remove-MgGroup -GroupID $previewgroupscurrent
write-host "Preview Group AAD Removed"

##Move Pilot Group 
write-host "Getting members of Pilot Group"
$pilotbroadmembers = Get-MgGroupMember -GroupID $pilotgroupscurrent -All $true
$newpilotgroupid = (Get-MgGroup -Search "Windows Autopatch Device Registration").ObjectID
write-host "Exporting Pilot Members to CSV"
$pilotbroadmembers | Export-Csv "$csvfolder\PilotMembers.csv"
write-host "Adding to Windows Autopatch Device Registration"

foreach ($pilotmember in $pilotbroadmembers) {
New-MgGroupMember -GroupID $newpilotgroupid -DirectoryObjectID $pilotmember.ObjectID
write-host "Added $pilotmember.DisplayName to Windows Autopatch Device Registration"
}
##Remove Broad Group
write-host "Removing Pilot AAD Group"
Remove-MgGroup -GroupID $pilotgroupscurrent
write-host "Pilot Group AAD Removed"


write-host "Groups populated, and old groups removed"
write-host "Removing old policies"
##Finally Remove Policies
foreach ($currentpolicy in $currentpolicies) {
$policyname = $currentpolicy.DisplayName

if (($policyname -ne "Modern Workplace Update Policy [Fast]-[Windows Autopatch]") -and ($policyname -ne "Modern Workplace Update Policy [First]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [Test]-[Windows Autopatch]")-and ($policyname -ne "Modern Workplace Update Policy [Broad]-[Windows Autopatch]")) {
$policyid = $currentpolicy.Id
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations/$policyid"
Invoke-MgGraphRequest -Uri $uri -Method Delete
write-host "$policyname Deleted"
}
}
write-host "Policies removed, script complete"
invoke-item $csvfolder