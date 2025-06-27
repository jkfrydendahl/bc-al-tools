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
    Remember to change the cd path to wherever the repo is cloned on your machine!
#>

Clear-Host

cd "C:\Dev\MyStuff\bc-al-tools\deprecation-tool"
. .\Invoke-AzDoGetOldApps.ps1

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
        NamingPrefix           = '*'
        AppPublisher           = '*'
        AppPrefix              = '*'
        SourceCodeFolder       = 'src'
    }

    Invoke-AzDoGetOldApps @Parameters
}
