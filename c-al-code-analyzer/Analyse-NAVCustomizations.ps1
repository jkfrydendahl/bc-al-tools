# NAV Customization Analysis Script
# Analyzes NAV 2017 CAL code export for customizations

param(
    [string]$InputFile = "CAL_OBJECTS_INPUT.txt",
    [string]$OutputFile = "CustomizationAnalysisReport.txt"
)

$ErrorActionPreference = "Stop"

Write-Host "Starting NAV Customization Analysis..." -ForegroundColor Cyan
Write-Host "Input File: $InputFile" -ForegroundColor Gray
Write-Host "Output File: $OutputFile" -ForegroundColor Gray
Write-Host ""

# Initialize tracking variables
$lineCount = 0
$currentObject = $null
$inObjectProperties = $false
$currentVersionList = ""

# Collections for findings
$customObjects = @()  # Objects in 50000-59999 range
$modifiedObjects = @()  # Objects with non-standard version list entries
$codeCustomizations = @()  # Objects with comment markers
$keywordFindings = @()  # Lines with BREDANA or 9A
$patternFindings = @()  # Lines with number-abbreviation patterns

# Regex patterns
$objectPattern = '^OBJECT\s+(Table|Page|Report|Codeunit|Query|XMLport|MenuSuite)\s+(\d+)\s+(.+)$'
$versionListPattern = '^\s*Version List=(.+);?\s*$'
$commentMarkerPattern = '//.*?:>>|//.*?:<<'
$keywordPattern = '\bBREDANA\b|\b9A\b'  # Word boundaries to avoid false matches
# Pattern must be in a comment line and have the format: DD ABC or DD.ABC (where ABC is 2-4 capital letters)
$numberAbbrevPattern1 = '//.*?\b\d{2}\s+[A-Z]{2,4}\b'  # Pattern: // ... 01 LAM
$numberAbbrevPattern2 = '//.*?\b\d{2}\.[A-Z]{2,4}\b'  # Pattern: // ... 02.SHI
$standardVersionPattern = '^(NAVW|NAVDK|NAVNO|NAVSE|NAVFI|NAVIS|NAVAT|NAVBE|NAVCH|NAVDE|NAVFR|NAVGB|NAVIT|NAVNL|NAVRU|NAVES)\d'
$excludeVersionPattern = '^(PM|BSJP)\d'  # Patterns to exclude from version list customizations
$excludeExactVersion = @('CST Konv Temp')  # Exact version list entries to exclude completely

# Helper function to check if version list has customizations
function Test-CustomVersionList {
    param(
        [string]$versionList,
        [int]$objectNumber
    )
    
    # If version list is empty or just whitespace/semicolon
    $cleanVersionList = $versionList.Trim().TrimEnd(';').Trim()
    if ([string]::IsNullOrWhiteSpace($cleanVersionList)) {
        # Don't include blank version lists regardless of range
        return $false
    }
    
    # Split by comma and check each entry
    $entries = $versionList -split ','
    $hasCustomization = $false
    $hasOnlyExcluded = $true
    
    foreach ($entry in $entries) {
        $entry = $entry.Trim()
        if ([string]::IsNullOrWhiteSpace($entry)) {
            continue
        }
        
        # Check if it's a standard version (skip these)
        if ($entry -match $standardVersionPattern) {
            continue
        }
        
        # Check if it's PM* or BSJP* (skip these unless there are other customizations)
        if ($entry -match $excludeVersionPattern) {
            continue
        }
        
        # Check if it's an exact match to excluded versions
        if ($excludeExactVersion -contains $entry) {
            continue
        }
        
        # If we get here, it's a non-standard, non-excluded customization
        $hasCustomization = $true
        $hasOnlyExcluded = $false
    }
    
    return $hasCustomization
}

# Open file for streaming
$reader = [System.IO.StreamReader]::new($InputFile)
$startTime = Get-Date

try {
    while ($null -ne ($line = $reader.ReadLine())) {
        $lineCount++
        
        # Progress indicator every 100,000 lines
        if ($lineCount % 100000 -eq 0) {
            $elapsed = (Get-Date) - $startTime
            Write-Host "Processed $lineCount lines... (Elapsed: $($elapsed.ToString('mm\:ss')))" -ForegroundColor Yellow
        }
        
        # Check for OBJECT declaration
        if ($line -match $objectPattern) {
            $objectType = $Matches[1]
            $objectNumber = [int]$Matches[2]
            $objectName = $Matches[3].Trim()
            
            $currentObject = [PSCustomObject]@{
                Type = $objectType
                Number = $objectNumber
                Name = $objectName
                LineNumber = $lineCount
            }
            
            # Check if it's a custom object (50000-59999 or 70000-79999)
            if (($objectNumber -ge 50000 -and $objectNumber -le 59999) -or ($objectNumber -ge 70000 -and $objectNumber -le 79999)) {
                $customObjects += $currentObject
            }
            
            $inObjectProperties = $false
            $currentVersionList = ""
        }
        
        # Check for OBJECT-PROPERTIES section
        if ($line -match '^\s*OBJECT-PROPERTIES\s*$') {
            $inObjectProperties = $true
        }
        
        # Check for Version List in OBJECT-PROPERTIES
        if ($inObjectProperties -and $line -match $versionListPattern) {
            $currentVersionList = $Matches[1].Trim()
            
            # Skip version list checking for custom objects (50000-59999 or 70000-79999) - they're already tracked as custom
            $isCustomRange = $currentObject -and (($currentObject.Number -ge 50000 -and $currentObject.Number -le 59999) -or ($currentObject.Number -ge 70000 -and $currentObject.Number -le 79999))
            
            # Check if version list has customizations (passing object number for custom range check)
            if ($currentObject -and -not $isCustomRange -and (Test-CustomVersionList $currentVersionList $currentObject.Number)) {
                $modifiedObjects += [PSCustomObject]@{
                    Type = $currentObject.Type
                    Number = $currentObject.Number
                    Name = $currentObject.Name
                    LineNumber = $currentObject.LineNumber
                    VersionList = $currentVersionList
                }
            }
        }
        
        # Exit OBJECT-PROPERTIES when we hit closing brace
        if ($inObjectProperties -and $line -match '^\s*}\s*$') {
            $inObjectProperties = $false
        }
        
        # Check for comment markers (customization indicators)
        if ($line -match $commentMarkerPattern) {
            if ($currentObject) {
                $existing = $codeCustomizations | Where-Object { 
                    $_.Number -eq $currentObject.Number -and $_.Type -eq $currentObject.Type 
                }
                if (-not $existing) {
                    $codeCustomizations += [PSCustomObject]@{
                        Type = $currentObject.Type
                        Number = $currentObject.Number
                        Name = $currentObject.Name
                        LineNumber = $lineCount
                        Sample = $line.Trim()
                    }
                }
            }
        }
        
        # Check for keywords (BREDANA, 9A)
        # Skip if we're inside a custom object (50000-59999 or 70000-79999)
        if ($line -match $keywordPattern) {
            $isCustomObject = $currentObject -and (($currentObject.Number -ge 50000 -and $currentObject.Number -le 59999) -or ($currentObject.Number -ge 70000 -and $currentObject.Number -le 79999))
            if (-not $isCustomObject) {
                $keywordFindings += [PSCustomObject]@{
                    LineNumber = $lineCount
                    ObjectInfo = if ($currentObject) { "$($currentObject.Type) $($currentObject.Number) $($currentObject.Name)" } else { "N/A" }
                    Content = $line.Trim()
                }
            }
        }
        
        # Check for number-abbreviation patterns
        # Skip if we're inside a custom object (50000-59999 or 70000-79999)
        if (($line -match $numberAbbrevPattern1) -or ($line -match $numberAbbrevPattern2)) {
            $isCustomObject = $currentObject -and (($currentObject.Number -ge 50000 -and $currentObject.Number -le 59999) -or ($currentObject.Number -ge 70000 -and $currentObject.Number -le 79999))
            if (-not $isCustomObject) {
                $patternFindings += [PSCustomObject]@{
                    LineNumber = $lineCount
                    ObjectInfo = if ($currentObject) { "$($currentObject.Type) $($currentObject.Number) $($currentObject.Name)" } else { "N/A" }
                    Content = $line.Trim()
                }
            }
        }
    }
}
finally {
    $reader.Close()
}

$endTime = Get-Date
$totalTime = $endTime - $startTime

Write-Host ""
Write-Host "Analysis Complete!" -ForegroundColor Green
Write-Host "Total lines processed: $lineCount" -ForegroundColor Green
Write-Host "Time elapsed: $($totalTime.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host ""

# Generate report
$report = @"
================================================================================
NAV 2017 CUSTOMIZATION ANALYSIS REPORT
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================

FILE INFORMATION
----------------
Input File: $InputFile
Total Lines Processed: $lineCount
Processing Time: $($totalTime.ToString('hh\:mm\:ss'))

SUMMARY
-------
Custom Objects (50000-59999, 70000-79999): $($customObjects.Count)
Modified Standard Objects (Version List): $($modifiedObjects.Count)
Keyword Findings (BREDANA, 9A): $($keywordFindings.Count)
Number-Abbreviation Pattern Findings: $($patternFindings.Count)

================================================================================
DETAILED FINDINGS
================================================================================

1. CUSTOM OBJECTS (Range 50000-59999, 70000-79999)
--------------------------------------
$($customObjects.Count) custom objects found:

$($customObjects | ForEach-Object { "$($_.Type) $($_.Number): $($_.Name)" } | Out-String)

2. MODIFIED STANDARD OBJECTS (Non-Standard Version List)
---------------------------------------------------------
$($modifiedObjects.Count) modified objects found:
(Excludes PM*, BSJP*, 'CST Konv Temp' only modifications, and custom object ranges)

$($modifiedObjects | ForEach-Object { "$($_.Type) $($_.Number): $($_.Name)`n   Version List: $($_.VersionList)`n" } | Out-String)

3. KEYWORD FINDINGS (BREDANA, 9A)
----------------------------------
$($keywordFindings.Count) occurrences found:

$(if ($keywordFindings.Count -le 500) {
    $keywordFindings | ForEach-Object { "Line $($_.LineNumber) [$($_.ObjectInfo)]`n   $($_.Content)`n" } | Out-String
} else {
    "Too many findings ($($keywordFindings.Count)). Showing first 500:`n"
    $keywordFindings | Select-Object -First 500 | ForEach-Object { "Line $($_.LineNumber) [$($_.ObjectInfo)]`n   $($_.Content)`n" } | Out-String
})

4. NUMBER-ABBREVIATION PATTERNS (e.g., 01 LAM, 02.SHI)
-------------------------------------------------------
$($patternFindings.Count) occurrences found:

$(if ($patternFindings.Count -le 500) {
    $patternFindings | ForEach-Object { "Line $($_.LineNumber) [$($_.ObjectInfo)]`n   $($_.Content)`n" } | Out-String
} else {
    "Too many findings ($($patternFindings.Count)). Showing first 500:`n"
    $patternFindings | Select-Object -First 500 | ForEach-Object { "Line $($_.LineNumber) [$($_.ObjectInfo)]`n   $($_.Content)`n" } | Out-String
})

================================================================================
END OF REPORT
================================================================================
"@

# Write report to file
$report | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Report generated: $OutputFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor White
Write-Host "  Custom Objects: $($customObjects.Count)" -ForegroundColor White
Write-Host "  Modified Objects: $($modifiedObjects.Count)" -ForegroundColor White
Write-Host "  Code Customizations: $($codeCustomizations.Count)" -ForegroundColor White
Write-Host "  Keyword Findings: $($keywordFindings.Count)" -ForegroundColor White
Write-Host "  Pattern Findings: $($patternFindings.Count)" -ForegroundColor White