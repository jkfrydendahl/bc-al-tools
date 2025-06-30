<#
    .SYNOPSIS
    Invokes AzDoGetOldApps to check for common deprecation rules in a Business Central AL App Project.
    
    .DESCRIPTION
    Tests for the following rules:
    - App name must have prefix equal to the NamingPrefix parameter.
    - APP publisher must be equal to the AppPublisher parameter.
    - Permissionset must be of type .al, not .xml.
    - Permissionset must contain a prefix equal to the NamingPrefix parameter + the first three characters in the project name.
    - Ruleset must have prefix equal to the NamingPrefix parameter.
    - In settings.json, objectNamePrefix must be equal to the NamingPrefix parameter.
    - In settings.json, enableCodeAnalysis must be set to TRUE.
    - In settings.json codeAnalyzers must contain (at least) the analysers set by the CodeAnalysers parameter
    - Also includes a count of all .al objects in the SourceCodeFolder (parameter) that does not have prefix equal to the NamingPrefix parameter  

    .REQUIRED FILES
    token.csv
    - Contains Azure DevOps username (Used for PARAMETER UserName)
    - Contains PAT to Azure DevOps (Used for PARAMETER Token)
    - Requires full permission to:
      - Code
      - Service Connections

    params.csv
    - List of all the Azure DevOps orgs and projects that the script loops through.
    - Contains the Azure DevOps Organisation(s) (Used for PARAMETER OrganisationName)
    - Contains the Azure DevOps Project(s) (Used for PARAMETER ProjectName)

    .NOTES
    - Remember to change the cd path to wherever the repo is cloned on your machine!
    - AzDoGetOldApps contains option to scan repo for custom parameter file that overrides standard params set below.
      To use this functionality, place a .json named CustomDeprecationParameters in the repo root folder.
      Example JSON: 
        {
            "NamingPrefix": "ABC",
            "AppPublisher": "MyPublisher",
            "AppPrefix": "MP",
            "SourceCodeFolder": "src",
            "CodeAnalysers": ["CodeCop","PerTenantExtensionCop","UICop"]
        }
#>

Clear-Host

cd "C:\Dev\MyStuff\bc-al-tools\deprecation-checker-tool"
. .\Invoke-AzDoGetOldApps.ps1

#Set this variable to true if you want to generate a report instead of outputting to console
$CreateReportSetting = $false

if ($CreateReportSetting) {
    Write-Host "CreateReport = TRUE. Results will be sent to log file."

    $timestamp = Get-Date -Format "yyyyMMdd"
    $logFile = ".\logs\log_$timestamp.txt"
    if (Test-Path $logFile) {
        Remove-Item $logFile
    }
}

foreach ($TokenImport in import-csv imports/token.csv) {
    $Token = $TokenImport.Token
    $UserCred = $TokenImport.UserCred
}

foreach ($ProjectEntry in import-csv imports/inputparams.csv) {

    $Organisation = $ProjectEntry.Organisation
    $Project = $ProjectEntry.Project

    $Parameters = @{
        UserName               = $UserCred
        Token                  = $Token
        OrganizationName       = $Organisation
        ProjectName            = $Project
        NamingPrefix           = 'DEFAULT'
        AppPublisher           = 'DEFAULT'
        AppPrefix              = 'DEFAULT'
        SourceCodeFolder       = 'src'
        CodeAnalysers          = @("CodeCop","UICop")
        CreateReport           = $CreateReportSetting
    }

    if ($CreateReportSetting) {
        Invoke-AzDoGetOldApps @Parameters | Out-File $logFile -Append
    } else {
        Invoke-AzDoGetOldApps @Parameters
    }
}
