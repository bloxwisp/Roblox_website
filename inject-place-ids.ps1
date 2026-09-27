# Inject the resolved Roblox place IDs into index.html as GAME_PLACE_IDS.
# Run after resolve-place-ids.ps1. Verifies every game in DATA has an id.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$path = Join-Path $root 'index.html'
$html = Get-Content $path -Raw

function Get-Slug([string]$n) {
  $s = $n.ToLowerInvariant()
  ([regex]::Replace($s, '[^a-z0-9]+', '-')).Trim('-')
}

$ids = @{}
(Get-Content (Join-Path $env:TEMP 'place-ids.json') -Raw | ConvertFrom-Json).PSObject.Properties |
  ForEach-Object { $ids[$_.Name] = [long]$_.Value }
$ids['monday-morning-misery'] = 7205641391L

# every game in DATA must have a place id
$gaps = @()
foreach ($name in ([regex]::Matches($html, '\{name:"([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)) {
  if (-not $ids.ContainsKey((Get-Slug $name))) { $gaps += $name }
}
if ($gaps.Count) { throw "no place id for: $($gaps -join ', ')" }

$lines = $ids.Keys | Sort-Object | ForEach-Object { "  '$($_)': $($ids[$_])" }
$block = "/* Root place ID for every curated game, so a click opens that exact game page on\n   Roblox instead of a search/discover page. Slugs match slugify(game.name). */`nconst GAME_PLACE_IDS = {`n" +
  (($lines -join ",`n")) + "`n};`n"

# drop any previous copy, then insert immediately before GAME_ALIASES
$html = [regex]::Replace($html, "const GAME_PLACE_IDS = \{.*?\n\};\n", '', 'Singleline')
$marker = 'const GAME_ALIASES = {'
if (-not $html.Contains($marker)) { throw 'GAME_ALIASES marker not found' }
$html = $html.Replace($marker, $block + $marker)

Set-Content $path $html -NoNewline -Encoding utf8
Write-Output "injected=$($ids.Count)"
