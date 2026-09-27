# Verify every GAME_PLACE_IDS entry points at the game it claims to.
# placeId -> universeId -> canonical game name, compared after stripping
# [bracketed] prefixes / emoji / punctuation (same idea as the site's cleanGameName).
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Get-Content (Join-Path $root 'index.html') -Raw

function Get-Norm([string]$n) {
  $s = $n.ToLowerInvariant()
  $s = [regex]::Replace($s, '\[[^\]]*\]', ' ')
  [regex]::Replace($s, '[^a-z0-9]+', '')
}

function Invoke-Roblox([string]$url) {
  for ($try = 1; $try -le 5; $try++) {
    try { return Invoke-RestMethod $url }
    catch {
      if ($try -eq 5) { return $null }
      Start-Sleep -Milliseconds (600 * $try)
    }
  }
}

$block = [regex]::Match($html, 'const GAME_PLACE_IDS = \{(.*?)\n\};', 'Singleline').Groups[1].Value
$placeIds = @{}
foreach ($m in [regex]::Matches($block, "'([^']+)':\s*(\d+)")) { $placeIds[$m.Groups[1].Value] = [long]$m.Groups[2].Value }

$universe = @{}
foreach ($slug in ($placeIds.Keys | Sort-Object)) {
  $res = Invoke-Roblox "https://apis.roblox.com/universes/v1/places/$($placeIds[$slug])/universe"
  $universe[$slug] = if ($res) { $res.universeId } else { 0 }
  Start-Sleep -Milliseconds 250
}

$names = @{}
$ids = @($universe.Values | Where-Object { $_ -gt 0 } | Sort-Object -Unique)
for ($i = 0; $i -lt $ids.Count; $i += 50) {
  $batch = $ids[$i..([Math]::Min($i + 49, $ids.Count - 1))] -join ','
  $res = Invoke-Roblox "https://games.roblox.com/v1/games?universeIds=$batch"
  if ($res) { foreach ($g in $res.data) { $names[$g.id] = $g.name } }
  Start-Sleep -Milliseconds 400
}

$bad = @(); $ok = 0
foreach ($slug in ($placeIds.Keys | Sort-Object)) {
  $live = $names[$universe[$slug]]
  if (-not $live) { $bad += "$slug : cannot verify (place $($placeIds[$slug]))"; continue }
  $liveNorm = Get-Norm $live
  # the slug is "ability-wars" but live names may add prefixes, so compare loosely
  $wantedNorm = Get-Norm ($slug -replace '-', ' ')
  if ($liveNorm.Contains($wantedNorm) -or $wantedNorm.Contains($liveNorm)) { $ok++ }
  else { $bad += "$slug -> '$live' (place $($placeIds[$slug]))" }
}
Write-Output "verified=$ok total=$($placeIds.Count) problems=$($bad.Count)"
$bad | ForEach-Object { Write-Output "  $_" }
