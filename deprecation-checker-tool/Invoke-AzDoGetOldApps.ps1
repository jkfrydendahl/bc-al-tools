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
        [String]$SourceCodeFolder,
        [Parameter(Mandatory = $true)]
        [Array]$CodeAnalysers
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
            # Check if the repo is not empty.
            try {
                $AllItems = Invoke-RestMethod "$($Repo.url)/items?recursionLevel=Full&api-version=6.0" -Headers $Header -ErrorAction Stop

                try {
                    $CustomParameters = Invoke-RestMethod "$($Repo.url)/items?path=CustomDeprecationParameters.json&api-version=6.0" -Headers $Header -Erroraction stop
                }
                catch {
                    $CustomParameters = $null
                }

                $CurrentNamingPrefix = $NamingPrefix
                $CurrentAppPublisher = $AppPublisher
                $CurrentAppPrefix = $AppPrefix
                $CurrentSourceCodeFolder = $SourceCodeFolder

                if ($CustomParameters -and $CustomParameters.NamingPrefix -and $CustomParameters.NamingPrefix -ne '') {
                    $CurrentNamingPrefix = $CustomParameters.NamingPrefix
                }

                if ($CustomParameters -and $CustomParameters.AppPublisher -and $CustomParameters.AppPublisher -ne '') {
                    $CurrentAppPublisher = $CustomParameters.AppPublisher
                }

                if ($CustomParameters -and $CustomParameters.AppPrefix -and $CustomParameters.AppPrefix -ne '') {
                    $CurrentAppPrefix = $CustomParameters.AppPrefix
                }

                if ($CustomParameters -and $CustomParameters.SourceCodeFolder -and $CustomParameters.SourceCodeFolder -ne '') {
                    $CurrentSourceCodeFolder = $CustomParameters.SourceCodeFolder
                }

                $RulePrefix = $CurrentNamingPrefix + $RepoName.Substring(0,3)

                $App = Invoke-RestMethod "$($Repo.url)/items?path=/app.json&api-version=6.0" -Headers $Header -Erroraction stop
                $AppName = $AllItems.value | Where-Object { $_.path -like '*app.json' }
                foreach ($Rec in $AppName){
                    $AppFileName = Invoke-RestMethod "$($Repo.url)/items?path=$($Rec.path)&api-version=6.0" -Headers $Header -ErrorAction Stop
                }

                $RuleSet = $AllItems.value | Where-Object { $_.path -like '*ruleset.json' }
                $PermissionSet = $AllItems.value | Where-Object { $_.path -like '*permissionset.*' }

                $Settings = Invoke-RestMethod "$($Repo.url)/items?path=/.vscode/settings.json&api-version=6.0" -Headers $Header -Erroraction stop

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
                if ($CustomParameters -ne $null) {
                        Write-Host "Custom parameter file detected" -ForegroundColor Cyan
                        Write-Host " "
                    }

                    if ($AppFileName.name -notlike "$($CurrentAppPrefix)*") {
                        $errorCount += 1
                        Write-host "   - Missing or deprecated app name prefix (correct prefix = $($CurrentAppPrefix))" -ForegroundColor Gray
                    }
                    if ($App.publisher -ne "$($CurrentAppPublisher)") {
                        $errorCount += 1
                        Write-host "   - Deprecated app publisher $($FindApp.publisher) (expected publisher $($CurrentAppPublisher))" -ForegroundColor Gray
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

                    if ($RuleSet.path -notlike "/$($CurrentNamingPrefix)*") {
                        $errorCount += 1
                        Write-host "   - RuleSet file is missing or does not have correct name ($($CurrentNamingPrefix).RuleSet.json)" -ForegroundColor Gray
                    }

                    if ($Settings -is [string]) {
                        if ($Settings -notmatch '"CRS\.ObjectNamePrefix":\s*"' + [regex]::Escape($CurrentNamingPrefix) + '"') {
                            $errorCount += 1
                            Write-host "   - Settings.json CRS.ObjectNamePrefix parameter is missing or deprecated" -ForegroundColor Gray
                        }
                        if ($Settings -notmatch '"al.enableCodeAnalysis":\s*true') {
                            $errorCount += 1
                            Write-host "   - Settings.json al.enableCodeAnalysis parameter is missing or set to false" -ForegroundColor Gray
                        }
                        if ($CustomParameters -like "*CodeAnalysers*") {
                            foreach ($CodeAnalyser in $CustomParameters.CodeAnalysers) {
                                    if ($Settings -notmatch "`"al\.codeAnalyzers`":\s*\[.*`"\$\{$($CodeAnalyser)\}`".*\]") {
                                        $errorCount += 1
                                        Write-host "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyzer" -ForegroundColor Gray
                                    }
                            }
                        } else {
                            foreach($CodeAnalyser in $CodeAnalysers) {
                                 if ($Settings -notmatch "{$($CodeAnalyser)}") {
                                    $errorCount += 1
                                    Write-host "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyzer" -ForegroundColor Gray
                                }
                            }
                          }
                    }
                    else
                    {
                        if ($Settings.'CRS.ObjectNamePrefix' -ne $CurrentNamingPrefix) {
                            $errorCount += 1
                            Write-host "   - Settings.json CRS.ObjectNamePrefix parameter is missing or deprecated" -ForegroundColor Gray
                        }
                        if ($Settings.'al.enableCodeAnalysis' -ne $true) {
                            $errorCount += 1
                            Write-host "   - Settings.json al.enableCodeAnalysis parameter is missing or set to false" -ForegroundColor Gray
                        }
                        if ($CustomParameters -like "*CodeAnalysers*") {
                            foreach ($CodeAnalyser in $CustomParameters.CodeAnalysers) {
                            $pattern = "`${$($CodeAnalyser)}"
                            $analyzersString = $Settings.'al.codeAnalyzers' -join ' '
                                if ($analyzersString -notlike "*$pattern*") {
                                    $errorCount += 1
                                    Write-host "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyser" -ForegroundColor Gray
                                }
                            }
                        } else {
                            foreach($CodeAnalyser in $CodeAnalysers) {
                                $pattern = "`${$($CodeAnalyser)}"
                                $analyzersString = $Settings.'al.codeAnalyzers' -join ' '
                                if ($analyzersString -notlike "*$pattern*") {
                                    $errorCount += 1
                                    Write-host "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyser" -ForegroundColor Gray
                                }
                            }
                        }
                    }

                    $deprecatedFilePrefixCount = 0
                    $ALFiles = $AllItems.value | Where-Object {$_.path -like "/$($CurrentSourceCodeFolder)/*.al"}

                    foreach($File in $ALFiles) {
                        #$FileToCheck = Invoke-RestMethod "$($Repo.url)/items?path=$($File.path)&api-version=6.0" -Headers $Header -Erroraction stop
                        $FileName = ([System.IO.Path]::GetFileName($File.path))
                        if (-not $FileName.StartsWith("$($CurrentNamingPrefix)")) {
                            $deprecatedFilePrefixCount += 1
                        }
                    }
                        if ($deprecatedFilePrefixCount -gt 0) {
                            Write-host "   - $($deprecatedFilePrefixCount) AL file(s) found with missing $($CurrentNamingPrefix) prefix" -ForegroundColor Gray
                        }
                
                if ($errorCount -eq 0) {
                    write-host "   - No errors detected" -ForegroundColor Gray
                }    
            }
        }
   }
            
    #Write-Host "INFO: done with project" -ForegroundColor White -BackgroundColor Blue
}
