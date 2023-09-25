<#PSScriptInfo
.VERSION 2.0
.GUID 729ebf90-26fe-4795-92dc-ca8f570cdd22
.AUTHOR AndrewTaylor
.DESCRIPTION Builds dynamic AAD groups for licensed users of Visio and Project (including uninstall)
.COMPANYNAME 
.COPYRIGHT GPL
.TAGS az autopilot aad
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
  Builds an AAD Dynamic Group
.DESCRIPTION
Builds dynamic AAD groups for licensed users of Visio and Project (including uninstall)

.INPUTS
None required
.OUTPUTS
Within Azure
.NOTES
  Version:        2.0
  Author:         Andrew Taylor
  Twitter:        @AndrewTaylor_2
  WWW:            andrewstaylor.com
  Creation Date:  01/11/2021
  Updated:      28/10/2022
  Purpose/Change: Initial script development
  Change: Switched to Microsoft Graph for authentication and group creation
  
.EXAMPLE
N/A
#>

Write-Host "Installing Graph modules if required (current user scope)"

#Install Graph Groups module if not available
if (Get-Module -ListAvailable -Name microsoft.graph.groups) {
  Write-Host "Microsoft Graph Groups Module Already Installed"
} 
else {
  try {
      Install-Module -Name microsoft.graph.groups -Scope CurrentUser -Repository PSGallery -Force -AllowClobber 
  }
  catch [Exception] {
      $_.message 
      exit
  }
}

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





write-host "Importing Modules"

import-module -name microsoft.graph.groups


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
write-warning "Script has been updated, please download the latest version from $liveuri"
}
}
Get-ScriptVersion -liveuri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/Powershell%20Scripts/AZ/create-visio-project-groups.ps1"



#Get Creds and connect
write-host "Connect to Graph"
Select-MgProfile -Name Beta
Connect-MgGraph -Scopes Group.ReadWrite.All, GroupMember.ReadWrite.All, openid, profile, email, offline_access


##Create Visio Install Group
$visioinstall = New-MGGroup -DisplayName "Visio-Install" -Description "Dynamic group for Licensed Visio Users" -MailEnabled:$False -MailNickName "visiousers" -SecurityEnabled -GroupTypes "DynamicMembership" -MembershipRule "(user.assignedPlans -any (assignedPlan.servicePlanId -eq ""663a804f-1c30-4ff0-9915-9db84f0d1cea"" -and assignedPlan.capabilityStatus -eq ""Enabled""))" -MembershipRuleProcessingState "On"
#
##Create Visio Uninstall Group
$visiouninstall = New-MGGroup -DisplayName "Visio-Uninstall" -Description "Dynamic group for users without Visio license" -MailEnabled:$False -MailNickName "visiouninstall" -SecurityEnabled -GroupTypes "DynamicMembership" -MembershipRule "(user.assignedPlans -all (assignedPlan.servicePlanId -ne ""663a804f-1c30-4ff0-9915-9db84f0d1cea"" -and assignedPlan.capabilityStatus -ne ""Enabled""))" -MembershipRuleProcessingState "On"
#
##Create Project Install Group
$projectinstall = New-MGGroup -DisplayName "Project-Install" -Description "Dynamic group for Licensed Project Users" -MailEnabled:$False -MailNickName "projectinstall" -SecurityEnabled -GroupTypes "DynamicMembership" -MembershipRule "(user.assignedPlans -any (assignedPlan.servicePlanId -eq ""fafd7243-e5c1-4a3a-9e40-495efcb1d3c3"" -and assignedPlan.capabilityStatus -eq ""Enabled""))" -MembershipRuleProcessingState "On"
#
##Create Project Uninstall Group
$projectuninstall = New-MGGroup -DisplayName "Project-Uninstall" -Description "Dynamic group for users without Project license" -MailEnabled:$False -MailNickName "projectuninstall" -SecurityEnabled -GroupTypes "DynamicMembership" -MembershipRule "(user.assignedPlans -all (assignedPlan.servicePlanId -ne ""fafd7243-e5c1-4a3a-9e40-495efcb1d3c3"" -and assignedPlan.capabilityStatus -ne ""Enabled""))" -MembershipRuleProcessingState "On"
