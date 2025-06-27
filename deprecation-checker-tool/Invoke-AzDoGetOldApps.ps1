function Invoke-AzDoGetOldApps {
    
    param(
        [Parameter(Mandatory = $true)]
        [String]$UserName,
        [Parameter(Mandatory = $true)]
        [String]$Token,
        [Parameter(Mandatory = $true)]
        [String]$OrganizationName,
        [Parameter(Mandatory = $true)]
        [String]$ProjectName,
        [Parameter(Mandatory = $false)]
        [String]$SourceRepoName,
        [Parameter(Mandatory = $true)]
        [String]$NamingPrefix,
        [Parameter(Mandatory = $true)]
        [String]$AppPublisher,
        [Parameter(Mandatory = $true)]
        [String]$AppPrefix,
        [Parameter(Mandatory = $true)]
        [String]$SourceCodeFolder
    )

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $UserName, $Token)))
    $Header = @{
        Authorization = ("Basic {0}" -f $base64AuthInfo)
    }

    $BaseURL = "https://dev.azure.com/$OrganizationName"

    Write-Host " "
    Write-Host "-----------------------------------------------------------------"
    Write-Host "INFO: NOW RUNNING CHECK ON $ProjectName" -ForegroundColor White -BackgroundColor Black
    Write-Host "-----------------------------------------------------------------"

    $RepositoryURL = "$BaseURL/$ProjectName/_apis/git/repositories?api-version=6.0"

    # Collect all Repo's by default.
    Try {
        $AllRepos = (Invoke-RestMethod $RepositoryURL -Headers $Header).value
    }
    Catch {
        if ($_ -match "Access Denied") {
            Throw "Access has been denied, please check your token"
        }
        else {
            Throw $_
        }
    }
    # if a specific repo is specified, only that repo will be collected.
    if ($RepoName) {
        Write-Host "Found RepoName: $RepoName" -ForegroundColor -Gray
        $AllRepos = $AllRepos | Where-Object { $_.name -eq $RepoName }
    }
    #Write-Host "Found $($AllRepos.Count) repos" -ForegroundColor Gray
    $LoopCount = 0
    foreach ($Repo in $AllRepos) {

        $DoRun = $true
        if ($repo.name -match 'Upgrade') {
            $DoRun = $false
        }
        if ($repo.name -match 'Utilities') {
            $DoRun = $false
        }
        if ($repo.name -match 'FixData') {
            $DoRun = $false
        }

        if ($DoRun -eq $true) {
            $LoopCount++
            $RepoName = $Repo.name
            $RulePrefix = $NamingPrefix + $RepoName.Substring(0,3)
            # Check if the repo is not empty.
            try {
                $AllItems = Invoke-RestMethod "$($Repo.url)/items?recursionLevel=Full&api-version=6.0" -Headers $Header -ErrorAction Stop

                $App = $AllItems.value | Where-Object { $_.path -like '*app.json' }
                $PermissionSet = $AllItems.value | Where-Object { $_.path -like '*permissionset.*' }
                
                foreach ($Rec in $App){
                    $AppFile = Invoke-RestMethod "$($Repo.url)/items?path=$($Rec.path)&api-version=6.0" -Headers $Header -ErrorAction Stop
                }

                $FindApp = Invoke-RestMethod "$($Repo.url)/items?path=/app.json&api-version=6.0" -Headers $Header -Erroraction stop
                $FindValidRuleSet = Invoke-RestMethod "$($Repo.url)/items?path=/$($NamingPrefix).ruleset.json&api-version=6.0" -Headers $Header -Erroraction stop
                $FindValidSettings = Invoke-RestMethod "$($Repo.url)?path=../.vscode/settings.json&api-version=6.0" -Headers $Header -Erroraction stop

                $Errormessage = "none"
            }
            catch {
                $Errormessage = $_.ErrorDetails.Message

            }
            if ($Errormessage -like "*Cannot find any branches*" ) {
                Write-Host "INFO: Repo is empty" -ForegroundColor Gray
            }
            else {
                $errorCount = 0
                Write-Host " "
                Write-Host "Checking for deprecation errors in $($repo.name):" -ForegroundColor White

                    if ($AppFile.name -notlike "$($AppPrefix)") {
                        $errorCount += 1
                        Write-host "   - Missing or deprecated app name prefix (correct prefix = $($AppPrefix))" -ForegroundColor Gray
                    }
                    if ($FindApp.publisher -ne "$($AppPublisher)") {
                        $errorCount += 1
                        Write-host "   - Deprecated app publisher $($FindApp.publisher) (expected publisher $($AppPublisher))" -ForegroundColor Gray
                    }

                    if ($PermissionSet -eq '') {
                        $errorCount += 1
                        Write-Host "   - Missing permission set" -ForegroundColor Gray
                    }
                        elseif ($PermissionSet.path -like '*.xml') {
                            $errorCount += 1
                            Write-host "   - Deprecated XML permission set (file type must me .al)" -ForegroundColor Gray
                        } elseif ($PermissionSet.path -notlike "$($RulePrefix)*") {
                            $errorCount += 1
                            Write-host "   - Permissionset does not have correct prefix ($($RulePrefix))" -ForegroundColor Gray
                        }

                    if ($FindValidRuleSet -eq $null) {
                        $errorCount += 1
                        Write-host "   - Missing or deprecated ruleset file" -ForegroundColor Gray
                    }

                    $deprecatedFilePrefixCount = 0
                    $ALFiles = $AllItems.value | Where-Object {$_.path -like "/$($SourceCodeFolder)/*.al"}

                    foreach($File in $ALFiles) {
                        #$FileToCheck = Invoke-RestMethod "$($Repo.url)/items?path=$($File.path)&api-version=6.0" -Headers $Header -Erroraction stop
                        $FileName = ([System.IO.Path]::GetFileName($File.path))
                        if (-not $FileName.StartsWith("$($NamingPrefix)")) {
                            $deprecatedFilePrefixCount += 1
                        }
                    }
                        if ($deprecatedFilePrefixCount -gt 0) {
                            Write-host "   - $($deprecatedFilePrefixCount) AL file(s) found with missing $($NamingPrefix) prefix" -ForegroundColor Gray
                        }
                
                if ($errorCount -eq 0) {
                    write-host "   - No errors detected" -ForegroundColor Gray
                }    
            }
        }
   }
            
    #Write-Host "INFO: done with project" -ForegroundColor White -BackgroundColor Blue
}
