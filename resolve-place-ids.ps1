# Resolve the real Roblox root place ID for every game listed in index.html.
# Output: <slug>: <placeId> pairs (JSON) so the site can deep-link to the exact game.
# Re-run after adding games to DATA in index.html.
$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$outFile = Join-Path $env:TEMP 'place-ids.json'
$failFile = Join-Path $env:TEMP 'place-ids-failed.txt'
$logFile = Join-Path $env:TEMP 'place-ids.log'

$html = [System.IO.File]::ReadAllText((Join-Path $root 'index.html'), [System.Text.Encoding]::UTF8)
$names = [regex]::Matches($html, '\{name:"([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

function Get-Slug([string]$n) {
  $s = $n.ToLowerInvariant()
  ([regex]::Replace($s, '[^a-z0-9]+', '-')).Trim('-')
}
function Get-Norm([string]$n) {
  $s = $n.ToLowerInvariant()
  $s = [regex]::Replace($s, '\[[^\]]*\]', ' ')
  [regex]::Replace($s, '[^a-z0-9]+', '')
}

# game slugs whose universeId is already pinned in index.html (GAME_ALIASES)
$alias = @{}
$aliasBlock = [regex]::Match($html, 'const GAME_ALIASES = \{(.*?)\n\};', 'Singleline').Groups[1].Value
foreach ($m in [regex]::Matches($aliasBlock, "'([^']+)':\s*(\d+)")) {
  $alias[$m.Groups[1].Value] = [long]$m.Groups[2].Value
}

$ids = @{}
$failed = @()
$i = 0
foreach ($name in $names) {
  $i++
  $slug = Get-Slug $name
  if ($alias.ContainsKey($slug)) { continue }

  $query = [uri]::EscapeDataString($name)
  try {
    $resp = Invoke-RestMethod "https://apis.roblox.com/search-api/omni-search?searchQuery=$query&pageType=all&sessionId=web"
  } catch {
    $failed += $name
    Add-Content $logFile "ERR  $name"
    continue
  }

  $games = @($resp.searchResults | ForEach-Object { $_.contents }) |
    Where-Object { $_.contentType -eq 'Game' -and $_.rootPlaceId }
  $wanted = Get-Norm $name
  $hit = $games | Where-Object {
    $candidate = Get-Norm $_.name
    $candidate -eq $wanted -or $candidate.StartsWith($wanted) -or $wanted.StartsWith($candidate)
  } | Select-Object -First 1

  if ($hit) {
    $ids[$slug] = [long]$hit.rootPlaceId
    Add-Content $logFile "$slug`t$($hit.rootPlaceId)`t$($hit.name)"
  } else {
    $failed += $name
    Add-Content $logFile "MISS $name"
  }
  Start-Sleep -Milliseconds 120
}

# aliased games: universeId -> rootPlaceId
if ($alias.Count) {
  $universeIds = ($alias.Values | Sort-Object -Unique)
  for ($start = 0; $start -lt $universeIds.Count; $start += 50) {
    $batch = $universeIds[$start..([Math]::Min($start + 49, $universeIds.Count - 1))] -join ','
    $data = Invoke-RestMethod "https://games.roblox.com/v1/games?universeIds=$batch"
    foreach ($g in $data.data) {
      foreach ($slug in $alias.Keys) {
        if ($alias[$slug] -eq $g.id) { $ids[$slug] = [long]$g.rootPlaceId }
      }
    }
  }
}

$ids | ConvertTo-Json | Set-Content $outFile -Encoding utf8
$failed | Set-Content $failFile -Encoding utf8
Write-Output "resolved=$($ids.Count) failed=$($failed.Count) names=$($names.Count)"
Write-Output "out=$outFile"
Write-Output "failed=$failFile"
