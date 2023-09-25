<#PSScriptInfo
.VERSION 2.0.5
.GUID 29d19c3c-8a33-4ada-a7a7-f39bfb439c1b
.AUTHOR AndrewTaylor
.DESCRIPTION Assigns everything within Intune with options to select.  Batch assignment to selected group of all policies, scripts and apps
.COMPANYNAME
.COPYRIGHT GPL
.TAGS intune endpoint MEM environment
.LICENSEURI https://github.com/andrew-s-taylor/public/blob/main/LICENSE
.PROJECTURI https://github.com/andrew-s-taylor/public
.ICONURI
.EXTERNALMODULEDEPENDENCIES microsoft.graph.intune, AzureADPreview
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
#>
<#
.SYNOPSIS
  Bulk Intune Assigment
.DESCRIPTION
Assigns everything within Intune with options to select.  Batch assignment to selected group of all policies, scripts and apps
.INPUTS
Runmode:
GUI to select AAD group and what to assign
.OUTPUTS
Within Azure
.NOTES
  Version:        2.0.5
  Author:         Andrew Taylor
  Twitter:        @AndrewTaylor_2
  WWW:            andrewstaylor.com
  Creation Date:  23/03/2022
  Amended Date:   30/10/2022
  Purpose/Change: Initial script development
  Change: Added option to set apps as Required
  Change: Switched to Graph Authentication
.EXAMPLE
N/A
#>
$ErrorActionPreference = "Continue"

##Start Logging to %TEMP%\intune.log

$date = get-date -format ddMMyyyy

Start-Transcript -Path $env:TEMP\intune-$date.log

###############################################################################################################

######                                         Install Modules                                           ######

###############################################################################################################

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
Import-Module microsoft.graph.authentication  

###############################################################################################################
######                                          Add Functions                                            ######
###############################################################################################################

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
Get-ScriptVersion -liveuri "https://raw.githubusercontent.com/andrew-s-taylor/public/main/Powershell%20Scripts/Intune/bulk-assign-intune.ps1"


####################################################

Function Get-DeviceConfigurationPolicy() { 
    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface

    .DESCRIPTION

    The function connects to the Graph API Interface and gets any device configuration policies

    .EXAMPLE

    Get-DeviceConfigurationPolicy

    Returns any device configuration policies configured in Intune

    .NOTES

    NAME: Get-DeviceConfigurationPolicy

    #>


    [cmdletbinding()]

   

    param

    (

        $name

    )

   

    $graphApiVersion = "beta"

    $DCP_resource = "deviceManagement/deviceConfigurations"

   

    try {

   

        if ($Name) {

   

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=displayName eq '$name'"

            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

   

        }

   

        else {

   

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

   

        }

   

    }

   

    catch {

   

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

       

    

    }

   

}

   

####################################################

 

 

####################################################

   

Function Get-DeviceConfigurationPolicySC() {

   

    <#

            .SYNOPSIS

            This function is used to get device configuration policies from the Graph API REST interface - SETTINGS CATALOG

            .DESCRIPTION

            The function connects to the Graph API Interface and gets any device configuration policies

            .EXAMPLE

            Get-DeviceConfigurationPolicySC

            Returns any device configuration policies configured in Intune

            .NOTES

            NAME: Get-DeviceConfigurationPolicySC

            #>

           

    [cmdletbinding()]

           

    param

    (

        $name

    )

           

    $graphApiVersion = "beta"

    $DCP_resource = "deviceManagement/configurationPolicies"

           

    try {

           

        if ($Name) {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=name eq '$name'"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

           

        }

           

        else {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

           

        }

           

    }

           

    catch {

           

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

               

            

    }

           

}

           

####################################################

 

 

####################################################

   

Function Get-DeviceCompliancePolicy() {

   

    <#

            .SYNOPSIS

            This function is used to get device compliance policies from the Graph API REST interface

            .DESCRIPTION

            The function connects to the Graph API Interface and gets any device compliance policies

            .EXAMPLE

            Get-DeviceCompliancepolicy

            Returns any device compliance policies configured in Intune

            .NOTES

            NAME: Get-devicecompliancepolicy

            #>

           

    [cmdletbinding()]

           

    param

    (

        $name

    )

           

    $graphApiVersion = "beta"

    $DCP_resource = "deviceManagement/deviceCompliancePolicies"

           

    try {

           

        if ($Name) {

            

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=name eq '$name'"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

           

        }

           

        else {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

            

        }

           

    }

           

    catch {

           

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

               

            

    }

           

}

           

 

Function Get-DeviceSecurityPolicy() {

   

    <#

            .SYNOPSIS

            This function is used to get device security policies from the Graph API REST interface

            .DESCRIPTION

            The function connects to the Graph API Interface and gets any device security policies

            .EXAMPLE

            Get-DeviceSecurityPolicy

            Returns any device compliance policies configured in Intune

            .NOTES

            NAME: Get-DeviceSecurityPolicy

            #>

           

    [cmdletbinding()]

           

    param

    (

        $name

    )

           

    $graphApiVersion = "beta"

    $DCP_resource = "deviceManagement/intents"

           

    try {

           

        if ($Name) {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=name eq '$name'"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

           

        }

           

        else {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

           

        }

           

    }

           

    catch {

           

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

                

            

    }

           

}

 

 

Function Get-DeviceManagementScripts() {

   

    <#

            .SYNOPSIS

            This function is used to get device management scripts from the Graph API REST interface

            .DESCRIPTION

            The function connects to the Graph API Interface and gets any device management scripts

            .EXAMPLE

            Get-DeviceManagementScripts

            Returns any device management scripts configured in Intune

            .NOTES

            NAME: Get-DeviceManagementScripts

            #>

           

    [cmdletbinding()]

           

    param

    (

        $name

    )

           

    $graphApiVersion = "beta"

    $DCP_resource = "deviceManagement/deviceManagementScripts"

           

    try {

           

        if ($Name) {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=name eq '$name'"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

           

        }

            

        else {

           

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

                    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

           

        }

           

    }

           

    catch {

           

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

               

            

    }

           

}

           

####################################################

   

 

 

Function Get-AutoPilotProfile() {

   

    <#

                .SYNOPSIS

                This function is used to get autopilot profiles from the Graph API REST interface

                .DESCRIPTION

                The function connects to the Graph API Interface and gets any autopilot profiles

                .EXAMPLE

                Get-AutoPilotProfile

                Returns any autopilot profiles configured in Intune

                .NOTES

                NAME: Get-AutoPilotProfile

                #>

               

    [cmdletbinding()]

               

    param

    (

        $name

    )

                

    $graphApiVersion = "beta"

    $DCP_resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

               

    try {

               

        if ($Name) {

               

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=displayName eq '$name'"

                        (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

               

        }

               

        else {

               

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

                        (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

               

        }

               

    }

               

    catch {

               

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

                   

                

    }

               

}

               

####################################################      

 

 

Function Get-ESPConfiguration() {

   

    <#

                    .SYNOPSIS

                    This function is used to get ESP Configurations from the Graph API REST interface

                    .DESCRIPTION

                    The function connects to the Graph API Interface and gets any ESP Configurations

                    .EXAMPLE

                    Get-ESPConfiguration

                    Returns any ESP Configurations in Intune

                    .NOTES

                    NAME: Get-ESPConfiguration

                    #>

                   

    [cmdletbinding()]

                   

    param

    (

        $name

    )

                   

    $graphApiVersion = "beta"

    $DCP_resource = "devicemanagement/deviceEnrollmentConfigurations"

                   

    try {

                   

        if ($Name) {

                   

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)?`$filter=displayName eq '$name'"

                            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).value

                   

        }

                    

        else {

                   

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"

                            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

                   

        }

                   

    }

                   

    catch {

                   

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

                       

                    

    }

                   

}

                   

####################################################

Function Get-DeviceConfigurationPolicyAssignment() {

   

    <#

    .SYNOPSIS

    This function is used to get device configuration policy assignment from the Graph API REST interface

    .DESCRIPTION

    The function connects to the Graph API Interface and gets a device configuration policy assignment

    .EXAMPLE

    Get-DeviceConfigurationPolicyAssignment $id guid

    Returns any device configuration policy assignment configured in Intune

    .NOTES

    NAME: Get-DeviceConfigurationPolicyAssignment

    #>

   

    [cmdletbinding()]

   

    param

    (

        [Parameter(Mandatory = $true, HelpMessage = "Enter id (guid) for the Device Configuration Policy you want to check assignment")]

        $id

    )

   

    $graphApiVersion = "Beta"

    $DCP_resource = "deviceManagement/deviceConfigurations"

   

    try {

   

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/groupAssignments"

        (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

   

    }

   

    catch {

   

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

       

    

    }

   

}

 

Function Get-DeviceConfigurationPolicyAssignmentSC() {

   

    <#

        .SYNOPSIS

        This function is used to get device configuration policy assignment from the Graph API REST interface - SETTINGS CATALOG Version

        .DESCRIPTION

        The function connects to the Graph API Interface and gets a device configuration policy assignment

        .EXAMPLE

        Get-DeviceConfigurationPolicyAssignmentSC $id guid

        Returns any device configuration policy assignment configured in Intune

        .NOTES

        NAME: Get-DeviceConfigurationPolicyAssignmentSC

        #>

       

    [cmdletbinding()]

       

    param

    (

        [Parameter(Mandatory = $true, HelpMessage = "Enter id (guid) for the Device Configuration Policy you want to check assignment")]

        $id

    )

       

    $graphApiVersion = "Beta"

    $DCP_resource = "deviceManagement/configurationPolicies"

       

    try {

       

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/Assignments"

            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

       

    }

       

    catch {

       

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

           

        

    }

       

}

 

Function Add-DeviceManagementScriptAssignment() {

    <#

.SYNOPSIS

This function is used to add a device configuration policy assignment using the Graph API REST interface

.DESCRIPTION

The function connects to the Graph API Interface and adds a device configuration policy assignment

.EXAMPLE

Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId

Adds a device configuration policy assignment in Intune

.NOTES

NAME: Add-DeviceConfigurationPolicyAssignment

#>

 

    [cmdletbinding()]

 

    param

    (

        $ScriptId,

        $TargetGroupId

    )

 

    $graphApiVersion = "Beta"

    $Resource = "deviceManagement/deviceManagementScripts/$ScriptId/assign"

 

    try {

 

        if (!$ScriptId) {

 

            write-host "No Script Policy Id specified, specify a valid Script Policy Id" -f Red

            break

 

        }

 

        if (!$TargetGroupId) {

 

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

 

        }

 

        $JSON = @"

{

    "deviceManagementScriptGroupAssignments":  [

        {

            "@odata.type":  "#microsoft.graph.deviceManagementScriptGroupAssignment",

            "targetGroupId": "$TargetGroupId",

            "id": "$ScriptId"

        }

    ]

}

"@

 

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

 

    }

 

    catch {

 

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

        break

 

    }

}

 

 

Function Get-DeviceCompliancePolicyAssignment() {

   

    <#

        .SYNOPSIS

        This function is used to get device compliance policy assignment from the Graph API REST interface

        .DESCRIPTION

        The function connects to the Graph API Interface and gets a device compliance policy assignment

        .EXAMPLE

        Get-DeviceCompliancePolicyAssignment $id guid

        Returns any device compliance policy assignment configured in Intune

        .NOTES

        NAME: Get-DeviceCompliancePolicyAssignment

        #>

       

    [cmdletbinding()]

       

    param

    (

        [Parameter(Mandatory = $true, HelpMessage = "Enter id (guid) for the Device Configuration Policy you want to check assignment")]

        $id

    )

       

    $graphApiVersion = "Beta"

    $DCP_resource = "deviceManagement/devicecompliancePolicies"

       

    try {

       

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/assignments"

            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

       

    }

       

    catch {

       

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

           

        

    }

       

}

 

Function Get-DeviceSecurityPolicyAssignment() {

   

    <#

        .SYNOPSIS

        This function is used to get device security policy assignment from the Graph API REST interface

        .DESCRIPTION

        The function connects to the Graph API Interface and gets a device compliance policy assignment

        .EXAMPLE

        Get-DeviceSecurityPolicyAssignment $id guid

        Returns any device security policy assignment configured in Intune

        .NOTES

        NAME: Get-DeviceSecurityPolicyAssignment

        #>

       

    [cmdletbinding()]

       

    param

    (

        [Parameter(Mandatory = $true, HelpMessage = "Enter id (guid) for the Device Security Policy you want to check assignment")]

        $id

    )

       

    $graphApiVersion = "Beta"

    $DCP_resource = "deviceManagement/intents"

       

    try {

       

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/Assignments"

            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

       

    }

       

    catch {

       

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

           

        

    }

       

}

   

####################################################

 

 

Function Get-AutoPilotProfileAssignments() {

   

    <#

        .SYNOPSIS

        This function is used to get AutoPilot Profile assignment from the Graph API REST interface

        .DESCRIPTION

        The function connects to the Graph API Interface and gets an Autopilot profile assignment

        .EXAMPLE

        Get-AutoPilotProfileAssignments $id guid

        Returns any autopilot profile assignment configured in Intune

        .NOTES

        NAME: Get-AutoPilotProfileAssignments

        #>

       

    [cmdletbinding()]

       

    param

    (

        [Parameter(Mandatory = $true, HelpMessage = "Enter id (guid) for the Autopilot Profile you want to check assignment")]

        $id

    )

       

    $graphApiVersion = "Beta"

    $DCP_resource = "deviceManagement/windowsAutopilotDeploymentProfiles"

       

    try {

       

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/Assignments"

            (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

       

    }

       

    catch {

       

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

           

        

    }

       

}

   

####################################################

   

Function Add-DeviceConfigurationPolicyAssignment() {

   

    <#

    .SYNOPSIS

    This function is used to add a device configuration policy assignment using the Graph API REST interface

    .DESCRIPTION

    The function connects to the Graph API Interface and adds a device configuration policy assignment

    .EXAMPLE

    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId

    Adds a device configuration policy assignment in Intune

    .NOTES

    NAME: Add-DeviceConfigurationPolicyAssignment

    #>

   

    [cmdletbinding()]

   

    param

    (

        [parameter(Mandatory = $true)]

        [ValidateNotNullOrEmpty()]

        $ConfigurationPolicyId,

   

        [parameter(Mandatory = $true)]

        [ValidateNotNullOrEmpty()]

        $TargetGroupId,

   

        [parameter(Mandatory = $true)]

        [ValidateSet("Included", "Excluded")]

        [ValidateNotNullOrEmpty()]

        [string]$AssignmentType

    )

   

    $graphApiVersion = "Beta"

    $Resource = "deviceManagement/deviceConfigurations/$ConfigurationPolicyId/assign"

       

    try {

   

        if (!$ConfigurationPolicyId) {

   

            write-host "No Configuration Policy Id specified, specify a valid Configuration Policy Id" -f Red

            break

   

        }

   

        if (!$TargetGroupId) {

   

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

   

        }

   

        # Checking if there are Assignments already configured in the Policy

        $DCPA = Get-DeviceConfigurationPolicyAssignment -id $ConfigurationPolicyId

   

        $TargetGroups = @()

   

        if (@($DCPA).count -ge 1) {

               

            if ($DCPA.targetGroupId -contains $TargetGroupId) {

   

                Write-Host "Group with Id '$TargetGroupId' already assigned to Policy..." -ForegroundColor Red

                Write-Host

               

    

            }

   

            # Looping through previously configured assignements

   

            $DCPA | foreach {

   

                $TargetGroup = New-Object -TypeName psobject

        

                if ($_.excludeGroup -eq $true) {

   

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'

        

                }

        

                else {

        

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'

        

                }

   

                $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value $_.targetGroupId

   

                $Target = New-Object -TypeName psobject

                $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

   

                $TargetGroups += $Target

   

            }

   

            # Adding new group to psobject

            $TargetGroup = New-Object -TypeName psobject

   

            if ($AssignmentType -eq "Excluded") {

   

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'

        

            }

        

            elseif ($AssignmentType -eq "Included") {

        

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'

        

            }

        

            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"

   

            $Target = New-Object -TypeName psobject

            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

   

            $TargetGroups += $Target

   

        }

   

        else {

   

            # No assignments configured creating new JSON object of group assigned

               

            $TargetGroup = New-Object -TypeName psobject

   

            if ($AssignmentType -eq "Excluded") {

   

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'

        

            }

        

            elseif ($AssignmentType -eq "Included") {

        

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'

        

            }

        

            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"

   

            $Target = New-Object -TypeName psobject

            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

   

            $TargetGroups = $Target

   

        }

   

        # Creating JSON object to pass to Graph

        $Output = New-Object -TypeName psobject

   

        $Output | Add-Member -MemberType NoteProperty -Name 'assignments' -Value @($TargetGroups)

   

        $JSON = $Output | ConvertTo-Json -Depth 3

   

        # POST to Graph Service

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

   

    }

       

    catch {

   

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

       

    

    }

   

}

 

Function Add-DeviceConfigurationPolicyAssignmentSC() {

   

    <#

        .SYNOPSIS

        This function is used to add a device configuration policy assignment using the Graph API REST interface  Settings Catalog

        .DESCRIPTION

        The function connects to the Graph API Interface and adds a device configuration policy assignment

        .EXAMPLE

        Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $ConfigurationPolicyId -TargetGroupId $TargetGroupId

        Adds a device configuration policy assignment in Intune

        .NOTES

        NAME: Add-DeviceConfigurationPolicyAssignment

        #>

       

    [cmdletbinding()]

       

    param

    (

        [parameter(Mandatory = $true)]

        [ValidateNotNullOrEmpty()]

        $ConfigurationPolicyId,

        

        [parameter(Mandatory = $true)]

        [ValidateNotNullOrEmpty()]

        $TargetGroupId,

       

        [parameter(Mandatory = $true)]

        [ValidateSet("Included", "Excluded")]

        [ValidateNotNullOrEmpty()]

        [string]$AssignmentType

    )

       

    $graphApiVersion = "Beta"

    $Resource = "deviceManagement/configurationPolicies/$ConfigurationPolicyId/assign"

           

    try {

       

        if (!$ConfigurationPolicyId) {

       

            write-host "No Configuration Policy Id specified, specify a valid Configuration Policy Id" -f Red

            break

       

        }

       

        if (!$TargetGroupId) {

       

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

       

        }

       

        # Checking if there are Assignments already configured in the Policy

        $DCPA = Get-DeviceConfigurationPolicyAssignmentSC -id $ConfigurationPolicyId

       

        $TargetGroups = @()

       

        if (@($DCPA).count -ge 1) {

                   

            if ($DCPA.targetGroupId -contains $TargetGroupId) {

       

                Write-Host "Group with Id '$TargetGroupId' already assigned to Policy..." -ForegroundColor Red

                Write-Host

                   

        

            }

       

            # Looping through previously configured assignements

       

            $DCPA | foreach {

       

                $TargetGroup = New-Object -TypeName psobject

            

                if ($_.excludeGroup -eq $true) {

       

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'

            

                }

            

                else {

            

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'

            

                }

       

                $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value $_.targetGroupId

       

                $Target = New-Object -TypeName psobject

                $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

       

                $TargetGroups += $Target

       

            }

       

            # Adding new group to psobject

            $TargetGroup = New-Object -TypeName psobject

       

            if ($AssignmentType -eq "Excluded") {

       

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'

            

            }

            

            elseif ($AssignmentType -eq "Included") {

            

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'

            

            }

            

            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"

       

            $Target = New-Object -TypeName psobject

            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

       

            $TargetGroups += $Target

       

        }

       

        else {

       

            # No assignments configured creating new JSON object of group assigned

                   

            $TargetGroup = New-Object -TypeName psobject

       

            if ($AssignmentType -eq "Excluded") {

       

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'

            

            }

            

            elseif ($AssignmentType -eq "Included") {

            

                $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'

            

            }

            

            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"

       

            $Target = New-Object -TypeName psobject

            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

       

            $TargetGroups = $Target

       

        }

       

        # Creating JSON object to pass to Graph

        $Output = New-Object -TypeName psobject

       

        $Output | Add-Member -MemberType NoteProperty -Name 'assignments' -Value @($TargetGroups)

       

        $JSON = $Output | ConvertTo-Json -Depth 3

       

        # POST to Graph Service

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

       

    }

           

    catch {

       

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

           

        

    }

       

}

 

   

 

Function Add-DeviceCompliancePolicyAssignment() {

 

    <#

.SYNOPSIS

This function is used to add a device compliance policy assignment using the Graph API REST interface

.DESCRIPTION

The function connects to the Graph API Interface and adds a device compliance policy assignment

.EXAMPLE

Add-DeviceCompliancePolicyAssignment -CompliancePolicyId $CompliancePolicyId -TargetGroupId $TargetGroupId

Adds a device compliance policy assignment in Intune

.NOTES

NAME: Add-DeviceCompliancePolicyAssignment

#>

 

    [cmdletbinding()]

 

    param

    (

        $CompliancePolicyId,

        $TargetGroupId

    )

 

    $graphApiVersion = "v1.0"

    $Resource = "deviceManagement/deviceCompliancePolicies/$CompliancePolicyId/assign"

   

    try {

 

        if (!$CompliancePolicyId) {

 

            write-host "No Compliance Policy Id specified, specify a valid Compliance Policy Id" -f Red

            break

 

        }

 

        if (!$TargetGroupId) {

 

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

 

        }

 

        $JSON = @"

    {

        "assignments": [

        {

            "target": {

            "@odata.type": "#microsoft.graph.groupAssignmentTarget",

            "groupId": "$TargetGroupId"

            }

        }

        ]

    }

   

"@

 

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

 

    }

   

    catch {

 

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

   

 

    }

 

}

 

 

 

Function Add-ESPAssignment() {

 

    <#

    .SYNOPSIS

    This function is used to add an ESP policy assignment using the Graph API REST interface

    .DESCRIPTION

    The function connects to the Graph API Interface and adds an ESP policy assignment

    .EXAMPLE

    Add-ESPAssignment -Id $Id -TargetGroupId $TargetGroupId

    .NOTES

    NAME: Add-ESPAssignment

    #>

   

    [cmdletbinding()]

   

    param

    (

        $Id,

        $TargetGroupId

    )

   

    $graphApiVersion = "beta"

    $Resource = "deviceManagement/deviceEnrollmentConfigurations"       

        

    try {

   

        if (!$id) {

   

            write-host "No ESP Policy Id specified, specify a valid ESP Policy Id" -f Red

            break

   

        }

   

        if (!$TargetGroupId) {

   

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

   

        }

   

        $json = @"

            {

                "enrollmentConfigurationAssignments": [

                    {

                        "target": {

                            "@odata.type": "#microsoft.graph.groupAssignmentTarget",

                            "groupId": "$TargetGroupId"

                        }

                    }

                ]

            }

"@

   

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assign"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

   

    }

       

    catch {

   

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

       

    

    }

   

}

 
Function Add-DeviceSecurityPolicyAssignment() {

 

    <#

    .SYNOPSIS

    This function is used to add a Security policy assignment using the Graph API REST interface

    .DESCRIPTION

    The function connects to the Graph API Interface and adds a Security policy assignment

    .EXAMPLE

    Add-DeviceSecurityPolicyAssignment -Id $Id -TargetGroupId $TargetGroupId

    .NOTES

    NAME: Add-DeviceSecurityPolicyAssignment

    #>

   

    [cmdletbinding()]

   

    param

    (

        $Id,

        $TargetGroupId

    )

   

    $graphApiVersion = "beta"

    $Resource = "deviceManagement/intents/$Id/assign"       

        

    try {

   

        if (!$id) {

   

            write-host "No Security Policy Id specified, specify a valid Security Policy Id" -f Red

            break

   

        }

   

        if (!$TargetGroupId) {

   

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

   

        }

   

        $JSON = @"

            {
        
                "assignments": [
        
                {
        
                    "target": {
        
                    "@odata.type": "#microsoft.graph.groupAssignmentTarget",
        
                    "groupId": "$TargetGroupId"
        
                    }
        
                }
        
                ]
        
            }
        
           
"@

   

        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

   

    }

       

    catch {

   

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

       

    

    }

   

}

Function Add-ESPAssignment() {

 

    <#
    
        .SYNOPSIS
    
        This function is used to add an ESP policy assignment using the Graph API REST interface
    
        .DESCRIPTION
    
        The function connects to the Graph API Interface and adds an ESP policy assignment
    
        .EXAMPLE
    
        Add-ESPAssignment -Id $Id -TargetGroupId $TargetGroupId
    
        .NOTES
    
        NAME: Add-ESPAssignment
    
        #>
    
       
    
    [cmdletbinding()]
    
       
    
    param
    
    (
    
        $Id,
    
        $TargetGroupId
    
    )
    
       
    
    $graphApiVersion = "beta"
    
    $Resource = "deviceManagement/deviceEnrollmentConfigurations"       
    
            
    
    try {
    
       
    
        if (!$id) {
    
       
    
            write-host "No ESP Policy Id specified, specify a valid ESP Policy Id" -f Red
    
            break
    
       
    
        }
    
       
    
        if (!$TargetGroupId) {
    
       
    
            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
    
            break
    
       
    
        }
    
       
    
        $json = @"
    
                {
    
                    "enrollmentConfigurationAssignments": [
    
                        {
    
                            "target": {
    
                                "@odata.type": "#microsoft.graph.groupAssignmentTarget",
    
                                "groupId": "$TargetGroupId"
    
                            }
    
                        }
    
                    ]
    
                }
    
"@
    
       
    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assign"
    
        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"
    
       
    
    }
    
           
    
    catch {
    
       
    
        $ex = $_.Exception
    
        $errorResponse = $ex.Response.GetResponseStream()
    
        $reader = New-Object System.IO.StreamReader($errorResponse)
    
        $reader.BaseStream.Position = 0
    
        $reader.DiscardBufferedData()
    
        $responseBody = $reader.ReadToEnd();
    
        Write-Host "Response content:`n$responseBody" -f Red
    
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    
        write-host
    
           
    
        
    
    }
    
       
    
}
    
Function Add-AutoPilotProfileAssignment() {

   

    <#

        .SYNOPSIS

        This function is used to add an autopilot profile assignment using the Graph API REST interface

        .DESCRIPTION

        The function connects to the Graph API Interface and adds an autopilot profile assignment

        .EXAMPLE

        Add-AutoPilotProfileAssignment -Id $ConfigurationPolicyId -TargetGroupId $TargetGroupId

        Adds a device configuration policy assignment in Intune

        .NOTES

        NAME: Add-AutoPilotProfileAssignment

        #>

       

    [cmdletbinding()]
    param
    
    (
    
        $Id,
    
        $TargetGroupId
    
    )

    $graphApiVersion = "beta"
    $Resource = "deviceManagement/windowsAutopilotDeploymentProfiles"        
    $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource/$id/assignments"        
    
   
    $full_assignment_id = $Id + "_" + $TargetGroupId + "_0" 
    
    $json = @"
    {
        "id": "$full_assignment_id",
        "target": {
            "@odata.type": "#microsoft.graph.groupAssignmentTarget",
            "groupId": "$TargetGroupId"
        }
    }
"@
    
    Write-Verbose "POST $uri`n$json"
    
    try {
        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"
    }
    catch {
        Write-Error $_.Exception 
                
    }

        

  
}

 

 

Function Add-ApplicationAssignment() {

 

    <#

.SYNOPSIS

This function is used to add an application assignment using the Graph API REST interface

.DESCRIPTION

The function connects to the Graph API Interface and adds a application assignment

.EXAMPLE

Add-ApplicationAssignment -ApplicationId $ApplicationId -TargetGroupId $TargetGroupId -InstallIntent $InstallIntent

Adds an application assignment in Intune

.NOTES

NAME: Add-ApplicationAssignment

#>

 

    [cmdletbinding()]

 

    param

    (

        $ApplicationId,

        $TargetGroupId,

        $InstallIntent

    )

 

    $graphApiVersion = "Beta"

    $Resource = "deviceAppManagement/mobileApps/$ApplicationId/assign"

   

    try {

 

        if (!$ApplicationId) {

 

            write-host "No Application Id specified, specify a valid Application Id" -f Red

            break

 

        }

 

        if (!$TargetGroupId) {

 

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red

            break

 

        }

 

       

        if (!$InstallIntent) {

 

            write-host "No Install Intent specified, specify a valid Install Intent - available, notApplicable, required, uninstall, availableWithoutEnrollment" -f Red

            break

 

        }

 

        $JSON = @"

{

    "mobileAppAssignments": [

    {

        "@odata.type": "#microsoft.graph.mobileAppAssignment",

        "target": {

        "@odata.type": "#microsoft.graph.groupAssignmentTarget",

        "groupId": "$TargetGroupId"

        },

        "intent": "$InstallIntent"

    }

    ]

}

"@

 

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

        Invoke-MgGraphRequest -Uri $uri -Method Post -Body $JSON -ContentType "application/json"

 

    }

   

    catch {

 

        $ex = $_.Exception

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

        break

 

    }

 

}

 

 

 

Function Get-IntuneApplication() {

 

    <#

.SYNOPSIS

This function is used to get applications from the Graph API REST interface

.DESCRIPTION

The function connects to the Graph API Interface and gets any applications added

.EXAMPLE

Get-IntuneApplication

.NOTES

NAME: Get-IntuneApplication

#>

 

    [cmdletbinding()]

 

    $graphApiVersion = "Beta"

    $Resource = "deviceAppManagement/mobileApps"

   

    try {

       

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"

    (Invoke-MgGraphRequest -Uri $uri -Method Get -OutputType PSObject).Value

 

    }

   

    catch {

 

        $ex = $_.Exception

        Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red

        $errorResponse = $ex.Response.GetResponseStream()

        $reader = New-Object System.IO.StreamReader($errorResponse)

        $reader.BaseStream.Position = 0

        $reader.DiscardBufferedData()

        $responseBody = $reader.ReadToEnd();

        Write-Host "Response content:`n$responseBody" -f Red

        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"

        write-host

        break

 

    }

 

}

 
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
###############################################################################################################

######                                          Launch Form                                              ######

###############################################################################################################
#Connect to Graph
Connect-ToGraph -Scopes "RoleAssignmentSchedule.ReadWrite.Directory, Domain.Read.All, Domain.ReadWrite.All, Directory.Read.All, Policy.ReadWrite.ConditionalAccess, DeviceManagementApps.ReadWrite.All, DeviceManagementConfiguration.ReadWrite.All, DeviceManagementManagedDevices.ReadWrite.All, openid, profile, email, offline_access"


 
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object system.Windows.Forms.Form
$Form.ClientSize = New-Object System.Drawing.Point(400, 686)
$Form.text = "Form"
$Form.TopMost = $false

$Label1 = New-Object system.Windows.Forms.Label
$Label1.text = "Select Azure AD group"
$Label1.AutoSize = $true
$Label1.width = 25
$Label1.height = 10
$Label1.location = New-Object System.Drawing.Point(16, 73)
$Label1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$aad = New-Object system.Windows.Forms.ComboBox
$aad.text = "AADGroup"
$aad.width = 201
$aad.height = 20
$aad.location = New-Object System.Drawing.Point(170, 69)
$aadgroups = get-mggroup -All | select-object DisplayName
ForEach ($aadgroup in $aadgroups) {
    $aad.Items.Add($aadgroup.DisplayName) 
}
$aad.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$Label2 = New-Object system.Windows.Forms.Label
$Label2.text = "What would you like to assign?"
$Label2.AutoSize = $true
$Label2.width = 25
$Label2.height = 10
$Label2.location = New-Object System.Drawing.Point(89, 110)
$Label2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12)

$Submit = New-Object system.Windows.Forms.Button
$Submit.text = "Assign"
$Submit.width = 60
$Submit.height = 30
$Submit.location = New-Object System.Drawing.Point(161, 641)
$Submit.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$config = New-Object system.Windows.Forms.CheckBox
$config.text = "Config Policies"
$config.AutoSize = $false
$config.width = 200
$config.height = 20
$config.location = New-Object System.Drawing.Point(32, 155)
$config.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$settings = New-Object system.Windows.Forms.CheckBox
$settings.text = "Settings Catalog"
$settings.AutoSize = $false
$settings.width = 200
$settings.height = 20
$settings.location = New-Object System.Drawing.Point(34, 190)
$settings.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$compliance = New-Object system.Windows.Forms.CheckBox
$compliance.text = "Compliance Policies"
$compliance.AutoSize = $false
$compliance.width = 200
$compliance.height = 20
$compliance.location = New-Object System.Drawing.Point(34, 223)
$compliance.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$security = New-Object system.Windows.Forms.CheckBox
$security.text = "Security Policies"
$security.AutoSize = $false
$security.width = 200
$security.height = 20
$security.location = New-Object System.Drawing.Point(34, 260)
$security.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$scripts = New-Object system.Windows.Forms.CheckBox
$scripts.text = "Scripts"
$scripts.AutoSize = $false
$scripts.width = 200
$scripts.height = 20
$scripts.location = New-Object System.Drawing.Point(32, 297)
$scripts.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$autopilot = New-Object system.Windows.Forms.CheckBox
$autopilot.text = "AutoPilot Profiles"
$autopilot.AutoSize = $false
$autopilot.width = 200
$autopilot.height = 20
$autopilot.location = New-Object System.Drawing.Point(34, 331)
$autopilot.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$esp = New-Object system.Windows.Forms.CheckBox
$esp.text = "Enrollment Status Pages"
$esp.AutoSize = $false
$esp.width = 200
$esp.height = 20
$esp.location = New-Object System.Drawing.Point(34, 364)
$esp.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$windows = New-Object system.Windows.Forms.CheckBox
$windows.text = "Windows Apps"
$windows.AutoSize = $false
$windows.width = 200
$windows.height = 20
$windows.location = New-Object System.Drawing.Point(34, 397)
$windows.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$macos = New-Object system.Windows.Forms.CheckBox
$macos.text = "MacOS Apps"
$macos.AutoSize = $false
$macos.width = 200
$macos.height = 20
$macos.location = New-Object System.Drawing.Point(34, 429)
$macos.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$android = New-Object system.Windows.Forms.CheckBox
$android.text = "Android Apps"
$android.AutoSize = $false
$android.width = 200
$android.height = 20
$android.location = New-Object System.Drawing.Point(34, 502)
$android.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$ios = New-Object system.Windows.Forms.CheckBox
$ios.text = "iOS Apps"
$ios.AutoSize = $false
$ios.width = 200
$ios.height = 20
$ios.location = New-Object System.Drawing.Point(34, 464)
$ios.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$Ewfewijpeqwj = New-Object system.Windows.Forms.Label
$Ewfewijpeqwj.text = "Enter your email for AzureAD and Graph"
$Ewfewijpeqwj.AutoSize = $true
$Ewfewijpeqwj.width = 25
$Ewfewijpeqwj.height = 10
$Ewfewijpeqwj.location = New-Object System.Drawing.Point(17, 15)
$Ewfewijpeqwj.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$email = New-Object system.Windows.Forms.TextBox
$email.multiline = $false
$email.width = 309
$email.height = 20
$email.location = New-Object System.Drawing.Point(50, 36)
$email.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$Label3 = New-Object system.Windows.Forms.Label
$Label3.text = "Application Assignment Type:"
$Label3.AutoSize = $true
$Label3.width = 25
$Label3.height = 10
$Label3.location = New-Object System.Drawing.Point(31, 543)
$Label3.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$ComboBox1 = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text = "Available"
$ComboBox1.width = 100
$ComboBox1.height = 20
@('Required', 'Available') | ForEach-Object { [void] $ComboBox1.Items.Add($_) }
$ComboBox1.location = New-Object System.Drawing.Point(127, 572)
$ComboBox1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10)

$Form.controls.AddRange(@($Label1, $aad, $Label2, $Submit, $config, $settings, $compliance, $security, $scripts, $autopilot, $esp, $windows, $macos, $android, $ios, $Ewfewijpeqwj, $email, $Label3, $ComboBox1))

$Submit.Add_Click({ 
 
   

 

 

 

 

        ###############################################################################################################

        ######                                          Group Details                                           ######

        ###############################################################################################################


        ##Get Group ID


        $aadgroup2 = $aad.SelectedItem
        $intunegrp = Get-MgGroup -Filter "DisplayName eq '$aadgroup2'" | Select-Object Id, DisplayName
 

        ###############################################################################################################

        ######                                          MS Graph Implementations                                 ######

        ###############################################################################################################



        ###############################################################################################################

        ######                                          Assign Everything                                        ######

        ###############################################################################################################

        $assignmenttype = $comboBox1.SelectedItem
 

        ##Anything to Ignore, Add here

        $dontuse = ""

 

 
        if ($config.checked -eq $True) {
            ##Assign Config Policies

            $configuration = Get-DeviceConfigurationPolicy

 

            foreach ($policy in $configuration) {

                if ($dontuse.contains($policy.displayName )) {

 

                    write-host "NOT Assigning" + $policy.displayName

 

                }

                else {

                    Write-Host "Assigned $($intunegrp.DisplayName) to $($policy.displayName)/$($policy.id)" -ForegroundColor Green

 

                    Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $policy.id -TargetGroupId $intunegrp.Id -AssignmentType Included

                }

 

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Config Policies Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
 
        }
 

 
        if ($settings.checked -eq $True) {
            ##Assign Settings Catalog Policies

            $configurationsc = Get-DeviceConfigurationPolicySC

 

            foreach ($policy in $configurationsc) {

                if ($dontuse.contains($policy.name )) {

                    write-host "NOT Assigning" + $policy.name

 

                }

                else {

                    Write-Host "Assigned $($intunegrp.DisplayName) to $($policy.displayName)/$($policy.id)" -ForegroundColor Green

 

                    Add-DeviceConfigurationPolicyAssignmentSC -ConfigurationPolicyId $policy.id -TargetGroupId $intunegrp.Id -AssignmentType Included
  
                }

 

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Settings Catalog Assigned"
            [System.Windows.MessageBox]::Show($msgBody) 
        }
 

 
        if ($compliance.checked -eq $True) {
            ##Assign Compliance Policies

            $compliance = Get-DeviceCompliancePolicy

 

            foreach ($policy in $compliance) {

                if ($dontuse.contains($policy.displayName )) {

                    write-host "NOT Assigning" + $policy.displayName

 

                }

                else {

                    Write-Host "Assigned $($intunegrp.DisplayName) to $($policy.displayName)/$($policy.id)" -ForegroundColor Green

                    Add-DeviceCompliancePolicyAssignment -CompliancePolicyId $policy.id -TargetGroupId $intunegrp.Id

                }

 

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Compliance Policies Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
        }
 

        if ($security.checked -eq $True) {
            ##Assign Security Policies

            $security = Get-DeviceSecurityPolicy

 

            foreach ($policy in $security) {

                if ($dontuse.contains($policy.displayName )) {

                    write-host "NOT Assigning" + $policy.displayName

 

                }

                else {

                    Write-Host "Assigned $($intunegrp.DisplayName) to $($policy.displayName)/$($policy.id)" -ForegroundColor Green

                    Add-DeviceSecurityPolicyAssignment -Id $policy.id -TargetGroupId $intunegrp.Id
  
                }

 

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Security Policies Assigned"
            [System.Windows.MessageBox]::Show($msgBody) 
        }
 

 
        if ($scripts.checked -eq $True) {
            ##Assign Scripts

            $scripts = Get-DeviceManagementScripts

 

            foreach ($script in $scripts) {

                if ($dontuse.contains($script.displayName )) {

                    write-host "NOT Assigning" + $script.displayName

 

                }

                else {

                    Write-Host "Assigned $($intunegrp.DisplayName) to $($script.displayName)/$($script.id)" -ForegroundColor Green

                    Add-DeviceManagementScriptAssignment -ScriptId $script.id -TargetGroupId $intunegrp.Id
  
                }

 

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Scripts Assigned"
            [System.Windows.MessageBox]::Show($msgBody) 
        }
 

 
        if ($autopilot.checked -eq $True) {
            ##Assign Autopilot Profile

            $approfiles = Get-AutoPilotProfile

            foreach ($approfile in $approfiles) {
                Add-AutoPilotProfileAssignment -Id $approfile.id -TargetGroupId $intunegrp.Id
                Write-Host "Assigned $($intunegrp.DisplayName) to $($approfile.displayName)/$($approfile.id)" -ForegroundColor Green
 
            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Autopilot Profiles Assigned"
            [System.Windows.MessageBox]::Show($msgBody)  
        }
 

 
        if ($esp.Checked -eq $True) {
            ##Assign ESP

            $espprofiles = Get-ESPConfiguration

            foreach ($espprofile in $espprofiles) {
                Add-ESPAssignment -Id $espprofile.Id -TargetGroupId $intunegrp.Id
                Write-Host "Assigned $($intunegrp.DisplayName) to $($espprofile.displayName)/$($espprofile.id)" -ForegroundColor Green
            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "ESP Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
        }
 

 

        #Get Apps
        write-host "Getting Applications"
        $apps = Get-IntuneApplication

 

        ##Query
        ##Windows app types
        $windowslist = "#microsoft.graph.officeSuiteApp", "#microsoft.graph.windowsMicrosoftEdgeApp", "#microsoft.graph.microsoftStoreForBusinessApp", "#microsoft.graph.win32LobApp", "#microsoft.graph.windowsUniversalAppX", "#microsoft.graph.windowsMobileMSI", "#microsoft.graph.microsoftStoreForBusinessContainedApp", "#microsoft.graph.webApp", "#microsoft.graph.windowsAppX", "#microsoft.graph.windowsUniversalAppXContainedApp"
        ##Set array
        $windowsapps = @()
        ##iOS App Types
        $ioslist = "#microsoft.graph.iosVppApp", "#microsoft.graph.iosLobApp", "#microsoft.graph.iosStoreApp", "#microsoft.graph.managedIOSLobApp", "#microsoft.graph.managedIOSStoreApp"
        ##Set Array
        $iosapps = @()
        ##Android app types
        $androidlist = "#microsoft.graph.managedAndroidStoreApp", "#microsoft.graph.androidForWorkApp", "#microsoft.graph.androidLobApp", "#microsoft.graph.androidManagedStoreWebApp", "#microsoft.graph.androidStoreApp", "#microsoft.graph.managedAndroidLobApp"
        ##Set Array
        $androidapps = @()
        ##MacOS App Types
        $macoslist = "#microsoft.graph.macOSLobApp", "#microsoft.graph.macOSIncludedApp", "#microsoft.graph.macOsVppApp", "#microsoft.graph.macOSOfficeSuiteApp", "#microsoft.graph.macOSMicrosoftEdgeApp", "#microsoft.graph.macOSDmgApp", "#microsoft.graph.macOSMdatpApp"
        ##Set Array
        $macosapps = @()

 

        ##Windows

        foreach ($app in $apps) {

            if ($windowslist.contains($app."@Odata.type" )) {

                $windowsapps += $app

            }

        }

 

 

        ##IOS

        foreach ($app in $apps) {

            if ($ioslist.contains($app."@Odata.type" )) {

                $iosapps += $app

            }

        }

 

        ##Android

        foreach ($app in $apps) {

            if ($androidlist.contains($app."@Odata.type" )) {

                $androidapps += $app

            }

        }

 

        ##MacOS

        foreach ($app in $apps) {

            if ($macoslist.contains($app."@Odata.type" )) {

                $macosapps += $app

            }

        }

 
        if ($windows.checked -eq $True) {
            ##Assign Windows apps

            foreach ($windowsapp in $windowsapps) {
                Add-ApplicationAssignment -ApplicationId $windowsapp.id -TargetGroupId $intunegrp.Id -InstallIntent $assignmenttype
                Write-Host "Assigned $($intunegrp.DisplayName) to $($windowsapp.displayName)/$($windowsapp.id)" -ForegroundColor Green
            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Windows Apps Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
        }
 

        if ($macos.checked -eq $True) {
            ##Assign MAC apps

            foreach ($macosapp in $macosapps) {
                Add-ApplicationAssignment -ApplicationId $macosapp.id -TargetGroupId $intunegrp.Id -InstallIntent "Required"
                Write-Host "Assigned $($intunegrp.DisplayName) to $($macosapp.displayName)/$($macosapp.id)" -ForegroundColor Green

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "MacOS Apps Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
        }
 
 
        if ($android.Checked -eq $True) {
            ##Assign Android apps

            foreach ($androidapp in $androidapps) {
                Add-ApplicationAssignment -ApplicationId $androidapp.id -TargetGroupId $intunegrp.Id -InstallIntent $assignmenttype
                Write-Host "Assigned $($intunegrp.DisplayName) to $($androidapp.displayName)/$($androidapp.id)" -ForegroundColor Green

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "Android Apps Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
        }

        if ($ios.checked -eq $True) {
            ##Assign iOS apps

            foreach ($iosapp in $iosapps) {
                Add-ApplicationAssignment -ApplicationId $iosapp.id -TargetGroupId $intunegrp.Id -InstallIntent $assignmenttype
                Write-Host "Assigned $($intunegrp.DisplayName) to $($iosapp.displayName)/$($iosapp.id)" -ForegroundColor Green

            }
            Add-Type -AssemblyName PresentationCore, PresentationFramework
            $msgBody = "iOS Apps Assigned"
            [System.Windows.MessageBox]::Show($msgBody)   
        }
 
    })


[void]$Form.ShowDialog()
 