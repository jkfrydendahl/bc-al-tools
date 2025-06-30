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
        [Array]$CodeAnalysers,
        [Parameter(Mandatory = $true)]
        [Boolean]$CreateReport

    )

    # Custom write function for outputting to either console or report
    function Write-Message {
        param(
            [string]$Message,
            [string]$ForegroundColor = $null,
            [string]$BackgroundColor = $null
        )
        
        if ($CreateReport) {
            Write-Output $Message
        } else {
            if ($ForegroundColor -and $BackgroundColor) {
                Write-Host $Message -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
            } elseif ($ForegroundColor) {
                Write-Host $Message -ForegroundColor $ForegroundColor
            } else {
                Write-Host $Message
            }
        }
    }

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $UserName, $Token)))
    $Header = @{
        Authorization = ("Basic {0}" -f $base64AuthInfo)
    }

    $BaseURL = "https://dev.azure.com/$OrganizationName"

    Write-Message " "
    Write-Message "-----------------------------------------------------------------"
    Write-Message "INFO: NOW RUNNING CHECK ON $ProjectName" -ForegroundColor White -BackgroundColor Black
    Write-Message "-----------------------------------------------------------------"

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
        Write-Message "Found RepoName: $RepoName" -ForegroundColor -Gray
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
        if ($repo.name -match 'Temp') {
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
                Write-Message "INFO: Repo $($Repo.Name) is empty" -ForegroundColor Gray
            }
            else {
                $ErrorCount = 0
                $EffortCount = 0
                Write-Message " "
                Write-Message "Checking for deprecation errors in $($repo.name):" -ForegroundColor White
                Write-Message " "
                if ($CustomParameters -ne $null) {
                        Write-Message "Custom parameter file detected" -ForegroundColor Cyan
                        Write-Message " "
                    }

                    if ($AppFileName.name -notlike "$($CurrentAppPrefix)*") {
                        $ErrorCount += 1
                        Write-Message "   - Missing or deprecated app name prefix (correct prefix = $($CurrentAppPrefix))" -ForegroundColor Gray
                        # Estimated time to fix: 5 minutes
                        $EffortCount += 5
                    }
                    if ($App.publisher -ne "$($CurrentAppPublisher)") {
                        $ErrorCount += 1
                        Write-Message "   - Deprecated app publisher $($FindApp.publisher) (expected publisher $($CurrentAppPublisher))" -ForegroundColor Gray
                        # Estimated time to fix: 5 minutes
                        $EffortCount += 5
                    }

                    if ($PermissionSet -eq '') {
                        $ErrorCount += 1
                        Write-Message "   - Missing permission set" -ForegroundColor Gray
                        # Estimated time to fix: 30 minutes
                        $EffortCount += 30
                    }
                        elseif ($PermissionSet.path -like '*.xml') {
                            $ErrorCount += 1
                            Write-Message "   - Deprecated XML permission set (file type must me .al)" -ForegroundColor Gray
                            # Estimated time to fix: 40 minutes
                            $EffortCount += 40
                        } elseif ($PermissionSet.path -notlike "$($RulePrefix)*") {
                            $ErrorCount += 1
                            Write-Message "   - Permissionset does not have correct prefix ($($RulePrefix))" -ForegroundColor Gray
                            # Estimated time to fix: 40 minutes
                            $EffortCount += 40
                        }

                    if ($RuleSet.path -notlike "/$($CurrentNamingPrefix)*") {
                        $ErrorCount += 1
                        Write-Message "   - RuleSet file is missing or does not have correct name ($($CurrentNamingPrefix).RuleSet.json)" -ForegroundColor Gray
                        # Estimated time to fix: 10 minutes
                        $EffortCount += 30
                    }

                    if ($Settings -is [string]) {
                        if ($Settings -notmatch '"CRS\.ObjectNamePrefix":\s*"' + [regex]::Escape($CurrentNamingPrefix) + '"') {
                            $ErrorCount += 1
                            Write-Message "   - Settings.json CRS.ObjectNamePrefix parameter is missing or deprecated" -ForegroundColor Gray
                            # Estimated time to fix: 5 minutes
                            $EffortCount += 5
                        }
                        if ($Settings -notmatch '"al.enableCodeAnalysis":\s*true') {
                            $ErrorCount += 1
                            Write-Message "   - Settings.json al.enableCodeAnalysis parameter is missing or set to false" -ForegroundColor Gray
                            # Estimated time to fix: 5 minutes
                            $EffortCount += 5
                        }
                        if ($CustomParameters -like "*CodeAnalysers*") {
                            foreach ($CodeAnalyser in $CustomParameters.CodeAnalysers) {
                                    if ($Settings -notmatch "`"al\.codeAnalyzers`":\s*\[.*`"\$\{$($CodeAnalyser)\}`".*\]") {
                                        $ErrorCount += 1
                                        Write-Message "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyzer" -ForegroundColor Gray
                                        # Estimated time to fix: 5 minutes
                                        $EffortCount += 5
                                    }
                            }
                        } else {
                            foreach($CodeAnalyser in $CodeAnalysers) {
                                 if ($Settings -notmatch "{$($CodeAnalyser)}") {
                                    $ErrorCount += 1
                                    Write-Message "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyzer" -ForegroundColor Gray
                                    # Estimated time to fix: 5 minutes
                                    $EffortCount += 5
                                }
                            }
                          }
                    }
                    else
                    {
                        if ($Settings.'CRS.ObjectNamePrefix' -ne $CurrentNamingPrefix) {
                            $ErrorCount += 1
                            Write-Message "   - Settings.json CRS.ObjectNamePrefix parameter is missing or deprecated" -ForegroundColor Gray
                            # Estimated time to fix: 5 minutes
                            $EffortCount += 5
                        }
                        if ($Settings.'al.enableCodeAnalysis' -ne $true) {
                            $ErrorCount += 1
                            Write-Message "   - Settings.json al.enableCodeAnalysis parameter is missing or set to false" -ForegroundColor Gray
                            # Estimated time to fix: 5 minutes
                            $EffortCount += 5
                        }
                        if ($CustomParameters -like "*CodeAnalysers*") {
                            foreach ($CodeAnalyser in $CustomParameters.CodeAnalysers) {
                            $pattern = "`${$($CodeAnalyser)}"
                            $analyzersString = $Settings.'al.codeAnalyzers' -join ' '
                                if ($analyzersString -notlike "*$pattern*") {
                                    $ErrorCount += 1
                                    Write-Message "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyser" -ForegroundColor Gray
                                    # Estimated time to fix: 5 minutes
                                    $EffortCount += 5
                                }
                            }
                        } else {
                            foreach($CodeAnalyser in $CodeAnalysers) {
                                $pattern = "`${$($CodeAnalyser)}"
                                $analyzersString = $Settings.'al.codeAnalyzers' -join ' '
                                if ($analyzersString -notlike "*$pattern*") {
                                    $ErrorCount += 1
                                    Write-Message "   - Settings.json al.codeAnalyzers parameter is missing $($CodeAnalyser) analyser" -ForegroundColor Gray
                                    # Estimated time to fix: 5 minutes
                                    $EffortCount += 5
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
                            # Estimated time to fix (per file): 10 minutes
                            $EffortCount += 10
                        }
                    }
                        if ($deprecatedFilePrefixCount -gt 0) {
                            Write-Message "   - $($deprecatedFilePrefixCount) AL file(s) found with missing $($CurrentNamingPrefix) prefix" -ForegroundColor Gray
                        }
                
                if ($EffortCount -gt 0) {
                    $HoursToFix = [Math]::Ceiling($EffortCount/60)
                    $HoursToFixFiles = [Math]::Ceiling(($deprecatedFilePrefixCount*10)/60)
                    Write-Message " "
                    Write-Message "   - Estimated hours needed to fix all deprecation issues: $($HoursToFix) hour(s)" -ForegroundColor Gray
                    Write-Message "     (of these, $($HoursToFixFiles) hour(s) consist of AL file prefix renames)" -ForegroundColor Gray
                }
                if ($ErrorCount -eq 0) {
                    Write-Message "   - No errors detected" -ForegroundColor Gray
                }  
            }
        }
   }
}
