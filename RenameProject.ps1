<#
PowerShell script to rename C# Project including: 
* Copying project folder to folder with new project name
* Renaming .csproj file and other files with project name
* Changing project name reference in .sln solution file
* Changing RootNamespace and AssemblyName in .csproj file
#>
param(
    [parameter(
        HelpMessage="Existing C# Project path to rename.",
        Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateScript({
        if (Test-Path $_.Trim().Trim('"')) { $true }
        else { throw "Path does not exist: $_" }
    })]
    [string]$ProjectFilePath,
    
    [parameter(
        HelpMessage="New project file name, without extension.",
        Mandatory=$true)]
    [string]$NewProjectName,
 
    [parameter(
        HelpMessage="Path to solution file.",
        Mandatory=$true)]
    [ValidateScript({
        if (Test-Path $_.Trim().Trim('"')) { $true }
        else { throw "Path does not exist: $_" }
    })]
    [string]$SolutionFilePath
)

$ProjectFilePath = $ProjectFilePath.Trim().Trim('"')
$SolutionFilePath = $SolutionFilePath.Trim().Trim('"')

echo "Renaming project from '$OldProjectName' to '$NewProjectName'"
echo "=========="

$ProjectFolder = Split-Path $ProjectFilePath -Parent
echo "Set current location to project folder: '$ProjectFolder'"
cd $ProjectFolder
echo "Done."
        
$OldProjectName=[IO.Path]::GetFileNameWithoutExtension($ProjectFilePath)
 
echo "" "1. Copying project folder"
 
copy . "..\$NewProjectName" -Recurse -WhatIf
copy . "..\$NewProjectName" -Recurse
 
echo "Done."
 
echo "----------"
echo "2. Renaming .proj and other files"
cd "..\$NewProjectName"
dir -Include "$OldProjectName.*" -Recurse | ren -NewName {$_.Name -replace [regex]("^"+$OldProjectName+"\b"), $NewProjectName} # -WhatIf
 
echo "Done."
 
echo "----------"
echo "3. Renaming project name in '$SolutionFilePath' file."
echo "(But first creating solution backup in '$SolutionFilePath.backup')"
copy "$SolutionFilePath" "$SolutionFilePath.backup" -WhatIf
copy "$SolutionFilePath" "$SolutionFilePath.backup"
 
(Get-Content "$SolutionFilePath") |
   % { if ($_ -match ($OldProjectName + "\.csproj")) { $_ -replace [regex]("\b"+$OldProjectName +"\b"), $NewProjectName } else { $_ }} |
   Set-Content "$SolutionFilePath"
 
echo "Done."
 
echo "----------"
echo "4. Renaming project name inside '$ProjectFilePath' file: AssemblyName and RootNamespace"
 
(Get-Content "$NewProjectName.csproj") | 
    % { if ($_ -match ("<(?:AssemblyName|RootNamespace)>(" + $OldProjectName +")</")) { $_ -replace $($matches[1]), $NewProjectName } else { $_ }} |
    Set-Content "$NewProjectName.csproj"
 
echo "Done."
 
echo "=========="
echo "TADAH!"