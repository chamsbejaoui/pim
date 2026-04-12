$target = (Get-Location).Path
$sources = @(
  'c:\pim-integ-back-problem\PIM_backend--99ae2ae59c36c20f9bde9b4805c5168b39fd33b4\PIM_backend--99ae2ae59c36c20f9bde9b4805c5168b39fd33b4',
  'c:\pim-integ-back-problem\PIM_backend--amine-v2\PIM_backend--amine-v2',
  'c:\pim-integ-back-problem\PIM_backend--CognitiveMDLRayhanaBack\PIM_backend--CognitiveMDLRayhanaBack\PIM_backend--mahdiii'
)
$excludeDirs = @('node_modules','.git','dist','uploads','data')

function Get-FileIndex([string]$root, [string[]]$excludeDirs) {
  $rootPath = (Resolve-Path $root).Path
  $files = Get-ChildItem -Path $rootPath -Recurse -File | Where-Object {
    $full = $_.FullName
    foreach ($d in $excludeDirs) {
      if ($full -match "[\\/]$d([\\/]|$)") { return $false }
    }
    return $true
  }

  $map = @{}
  foreach ($f in $files) {
    $rel = $f.FullName.Substring($rootPath.Length).TrimStart('\\')
    $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash
    $map[$rel] = $hash
  }
  return $map
}

$targetIndex = Get-FileIndex -root $target -excludeDirs $excludeDirs

foreach ($src in $sources) {
  Write-Host "==== SOURCE: $src ===="
  $srcIndex = Get-FileIndex -root $src -excludeDirs $excludeDirs
  $missing = @()
  $different = @()
  foreach ($k in $srcIndex.Keys) {
    if (-not $targetIndex.ContainsKey($k)) { $missing += $k }
    elseif ($targetIndex[$k] -ne $srcIndex[$k]) { $different += $k }
  }
  Write-Host ("Missing in main: {0}" -f $missing.Count)
  Write-Host ("Different vs main: {0}" -f $different.Count)
  Write-Host 'Top missing:'
  $missing | Sort-Object | Select-Object -First 30 | ForEach-Object { Write-Host "  + $_" }
  Write-Host 'Top different:'
  $different | Sort-Object | Select-Object -First 30 | ForEach-Object { Write-Host "  * $_" }
}
