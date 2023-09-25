# Debloat script

Fork van: **https://andrewstaylor.com/2022/08/09/removing-bloatware-from-windows-10-11-via-script/** om er voor te zorgen dat we niet per ongeluk malicious code naar binnen halen.  
Deze code dient eens in de zoveel tijd gecontroleerd te worden voor updates en dan geupdatet te worden.


# Deployment Intune
Deploy het als een script zodat het uitgevoerd wordt voordat de apps worden geinstalleerd van Intune.  
Gebruik onderstaande code of download het vooraf gemaakte bestand: **https://github.com/JustsparkNL/scriptsandchips/blob/master/De-Bloat/debloat_updatechecker.ps1**

**Run in 64-bit context - gebruik NIET het script van bovengenoemde bron.**


```PowerShell
$DebloatFolder = "C:\ProgramData\Debloat"
If (Test-Path $DebloatFolder) {
    Write-Output "$DebloatFolder exists. Skipping."
}
Else {
    Write-Output "The folder '$DebloatFolder' doesn't exist. This folder will be used for storing logs created after the script runs. Creating now."
    Start-Sleep 1
    New-Item -Path "$DebloatFolder" -ItemType Directory
    Write-Output "The folder $DebloatFolder was successfully created."
}

$templateFilePath = "C:\ProgramData\Debloat\removebloat.ps1"

Invoke-WebRequest `
-Uri "https://raw.githubusercontent.com/JustsparkNL/scriptsandchips/master/De-Bloat/RemoveBloat.ps1" `
-OutFile $templateFilePath `
-UseBasicParsing `
-Headers @{"Cache-Control"="no-cache"}

invoke-expression -Command $templateFilePath
```

Debug informatie zal in de map C:\ProgramData\Debloat\Debloat.log worden geplaatst.
