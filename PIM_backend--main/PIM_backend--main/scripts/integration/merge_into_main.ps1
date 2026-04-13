param(
  [string]$MainRoot = (Get-Location).Path
)

$sourceDefs = @(
  @{
    Name = '99ae'
    Path = 'c:\pim-integ-back-problem\PIM_backend--99ae2ae59c36c20f9bde9b4805c5168b39fd33b4\PIM_backend--99ae2ae59c36c20f9bde9b4805c5168b39fd33b4'
  },
  @{
    Name = 'amine-v2'
    Path = 'c:\pim-integ-back-problem\PIM_backend--amine-v2\PIM_backend--amine-v2'
  },
  @{
    Name = 'mahdiii'
    Path = 'c:\pim-integ-back-problem\PIM_backend--CognitiveMDLRayhanaBack\PIM_backend--CognitiveMDLRayhanaBack\PIM_backend--mahdiii'
  }
)

$excludeDirs = @('node_modules', '.git', 'dist', 'uploads', 'data')
$excludeFiles = @('debug.log', 'seed.log')

function Is-ExcludedPath {
  param(
    [string]$FullPath,
    [string[]]$ExcludeDirs,
    [string[]]$ExcludeFiles
  )

  $fileName = [System.IO.Path]::GetFileName($FullPath)
  if ($ExcludeFiles -contains $fileName) {
    return $true
  }

  foreach ($dir in $ExcludeDirs) {
    if ($FullPath -match "[\\/]$dir([\\/]|$)") {
      return $true
    }
  }

  return $false
}

if (-not (Test-Path -LiteralPath $MainRoot)) {
  throw "Main root not found: $MainRoot"
}

$resolvedMain = (Resolve-Path -LiteralPath $MainRoot).Path
$added = New-Object System.Collections.Generic.List[object]
$conflicts = New-Object System.Collections.Generic.List[object]
$skippedMissingSource = New-Object System.Collections.Generic.List[object]

foreach ($sourceDef in $sourceDefs) {
  $sourceName = $sourceDef.Name
  $sourcePath = $sourceDef.Path

  if (-not (Test-Path -LiteralPath $sourcePath)) {
    $skippedMissingSource.Add([pscustomobject]@{
      source = $sourceName
      path = $sourcePath
      reason = 'Source path not found'
    }) | Out-Null
    continue
  }

  $resolvedSource = (Resolve-Path -LiteralPath $sourcePath).Path
  $sourceFiles = Get-ChildItem -LiteralPath $resolvedSource -Recurse -File

  foreach ($sourceFile in $sourceFiles) {
    if (Is-ExcludedPath -FullPath $sourceFile.FullName -ExcludeDirs $excludeDirs -ExcludeFiles $excludeFiles) {
      continue
    }

    $relativePath = $sourceFile.FullName.Substring($resolvedSource.Length).TrimStart('\', '/')
    if ([string]::IsNullOrWhiteSpace($relativePath)) {
      continue
    }

    $targetPath = Join-Path -Path $resolvedMain -ChildPath $relativePath

    if (-not (Test-Path -LiteralPath $targetPath)) {
      $targetDir = Split-Path -Parent $targetPath
      if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
      }

      Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetPath -Force

      $added.Add([pscustomobject]@{
        source = $sourceName
        relativePath = $relativePath
      }) | Out-Null
      continue
    }

    $sourceHash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $targetPath -Algorithm SHA256).Hash

    if ($sourceHash -ne $targetHash) {
      $conflicts.Add([pscustomobject]@{
        source = $sourceName
        relativePath = $relativePath
      }) | Out-Null
    }
  }
}

$reportDir = Join-Path -Path $resolvedMain -ChildPath 'integration_reports'
if (-not (Test-Path -LiteralPath $reportDir)) {
  New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$jsonReportPath = Join-Path -Path $reportDir -ChildPath "integration-summary-$timestamp.json"
$mdReportPath = Join-Path -Path $reportDir -ChildPath "integration-summary-$timestamp.md"

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('s')
  mainRoot = $resolvedMain
  addedCount = $added.Count
  conflictCount = $conflicts.Count
  missingSourceCount = $skippedMissingSource.Count
  added = $added
  conflicts = $conflicts
  missingSources = $skippedMissingSource
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonReportPath

$mdLines = New-Object System.Collections.Generic.List[string]
$mdLines.Add('# Integration Summary') | Out-Null
$mdLines.Add('') | Out-Null
$mdLines.Add("Generated at: $($summary.generatedAt)") | Out-Null
$mdLines.Add("Main root: $($summary.mainRoot)") | Out-Null
$mdLines.Add('') | Out-Null
$mdLines.Add("Added files: $($summary.addedCount)") | Out-Null
$mdLines.Add("Conflicts (same path, different content): $($summary.conflictCount)") | Out-Null
$mdLines.Add("Missing source roots: $($summary.missingSourceCount)") | Out-Null
$mdLines.Add('') | Out-Null

$mdLines.Add('## Added Files (first 200)') | Out-Null
$added | Select-Object -First 200 | ForEach-Object {
  $mdLines.Add("- [$($_.source)] $($_.relativePath)") | Out-Null
}
$mdLines.Add('') | Out-Null

$mdLines.Add('## Conflicts (first 200)') | Out-Null
$conflicts | Select-Object -First 200 | ForEach-Object {
  $mdLines.Add("- [$($_.source)] $($_.relativePath)") | Out-Null
}
$mdLines.Add('') | Out-Null

if ($skippedMissingSource.Count -gt 0) {
  $mdLines.Add('## Missing Sources') | Out-Null
  $skippedMissingSource | ForEach-Object {
    $mdLines.Add("- [$($_.source)] $($_.path) ($($_.reason))") | Out-Null
  }
}

$mdLines | Set-Content -LiteralPath $mdReportPath

Write-Host "Added files: $($added.Count)"
Write-Host "Conflicts: $($conflicts.Count)"
Write-Host "JSON report: $jsonReportPath"
Write-Host "MD report: $mdReportPath"
