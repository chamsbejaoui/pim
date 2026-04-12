param(
  [string]$MainRoot = (Get-Location).Path,
  [string]$SnapshotDirName = 'integration_originals'
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
$snapshotRoot = Join-Path -Path $resolvedMain -ChildPath $SnapshotDirName
if (-not (Test-Path -LiteralPath $snapshotRoot)) {
  New-Item -ItemType Directory -Path $snapshotRoot -Force | Out-Null
}

$added = New-Object System.Collections.Generic.List[object]
$conflicts = New-Object System.Collections.Generic.List[object]
$identical = New-Object System.Collections.Generic.List[object]
$snapshots = New-Object System.Collections.Generic.List[object]
$missingSources = New-Object System.Collections.Generic.List[object]

foreach ($sourceDef in $sourceDefs) {
  $sourceName = $sourceDef.Name
  $sourcePath = $sourceDef.Path

  if (-not (Test-Path -LiteralPath $sourcePath)) {
    $missingSources.Add([pscustomobject]@{
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

    # 1) Keep exact original snapshot for each source file
    $snapshotPath = Join-Path -Path $snapshotRoot -ChildPath (Join-Path -Path $sourceName -ChildPath $relativePath)
    $snapshotDir = Split-Path -Parent $snapshotPath
    if (-not (Test-Path -LiteralPath $snapshotDir)) {
      New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null
    }
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $snapshotPath -Force
    $snapshots.Add([pscustomobject]@{
      source = $sourceName
      relativePath = $relativePath
      snapshotPath = $snapshotPath
    }) | Out-Null

    # 2) Integrate into main additively (never overwrite)
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

    if ($sourceHash -eq $targetHash) {
      $identical.Add([pscustomobject]@{
        source = $sourceName
        relativePath = $relativePath
      }) | Out-Null
    } else {
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
$jsonReportPath = Join-Path -Path $reportDir -ChildPath "integration-originals-summary-$timestamp.json"
$mdReportPath = Join-Path -Path $reportDir -ChildPath "integration-originals-summary-$timestamp.md"

$summary = [pscustomobject]@{
  generatedAt = (Get-Date).ToString('s')
  mainRoot = $resolvedMain
  snapshotRoot = $snapshotRoot
  snapshotCount = $snapshots.Count
  addedCount = $added.Count
  identicalCount = $identical.Count
  conflictCount = $conflicts.Count
  missingSourceCount = $missingSources.Count
  added = $added
  identical = $identical
  conflicts = $conflicts
  missingSources = $missingSources
}

$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $jsonReportPath

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Integration With Originals Summary') | Out-Null
$lines.Add('') | Out-Null
$lines.Add("Generated at: $($summary.generatedAt)") | Out-Null
$lines.Add("Main root: $($summary.mainRoot)") | Out-Null
$lines.Add("Snapshot root: $($summary.snapshotRoot)") | Out-Null
$lines.Add('') | Out-Null
$lines.Add("Snapshot files copied (exact originals): $($summary.snapshotCount)") | Out-Null
$lines.Add("Added files into main: $($summary.addedCount)") | Out-Null
$lines.Add("Identical files (already same as main): $($summary.identicalCount)") | Out-Null
$lines.Add("Conflicts (different from main, preserved in snapshot): $($summary.conflictCount)") | Out-Null
$lines.Add("Missing source roots: $($summary.missingSourceCount)") | Out-Null
$lines.Add('') | Out-Null

$lines.Add('## Added Into Main (first 200)') | Out-Null
$added | Select-Object -First 200 | ForEach-Object {
  $lines.Add("- [$($_.source)] $($_.relativePath)") | Out-Null
}
$lines.Add('') | Out-Null

$lines.Add('## Conflicts Preserved In Snapshot (first 200)') | Out-Null
$conflicts | Select-Object -First 200 | ForEach-Object {
  $lines.Add("- [$($_.source)] $($_.relativePath)") | Out-Null
}
$lines.Add('') | Out-Null

if ($missingSources.Count -gt 0) {
  $lines.Add('## Missing Sources') | Out-Null
  $missingSources | ForEach-Object {
    $lines.Add("- [$($_.source)] $($_.path) ($($_.reason))") | Out-Null
  }
}

$lines | Set-Content -LiteralPath $mdReportPath

Write-Host "Snapshot files copied: $($snapshots.Count)"
Write-Host "Added files into main: $($added.Count)"
Write-Host "Conflicts preserved in snapshot: $($conflicts.Count)"
Write-Host "JSON report: $jsonReportPath"
Write-Host "MD report: $mdReportPath"
