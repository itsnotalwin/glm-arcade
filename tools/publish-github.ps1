# Pushes this folder to a GitHub repo via the GitHub API (works without a git binary).
# Requires: gh CLI authenticated with repo scope.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tools\publish-github.ps1 -Owner <you> -Repo <name> [-Message "commit msg"]
param(
  [Parameter(Mandatory = $true)][string]$Owner,
  [Parameter(Mandatory = $true)][string]$Repo,
  [string]$Message = 'Update GLM Arcade',
  [string]$Branch = 'main'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$api = "repos/$Owner/$Repo/git"

$files = @(
  'index.html', 'sw.js', 'manifest.webmanifest', 'README.md',
  'server.js', 'server.py', 'server.ps1', 'play.cmd',
  'tools/gen-icons.ps1', 'tools/publish-github.ps1',
  'icons/icon-192.png', 'icons/icon-512.png', 'icons/maskable-512.png',
  'icons/apple-touch-icon.png', 'icons/favicon-32.png'
)

function Post-Json([string]$url, [string]$json) {
  $tmp = Join-Path $env:TEMP ('ga_' + [Guid]::NewGuid().ToString('N') + '.json')
  [IO.File]::WriteAllText($tmp, $json)
  try { return gh api $url -X POST --input $tmp --jq '.' } finally { Remove-Item $tmp -ErrorAction SilentlyContinue }
}

# 1. blobs
$tree = @()
foreach ($f in $files) {
  $p = Join-Path $root ($f -replace '/', '\')
  if (-not (Test-Path $p)) { Write-Warning "missing file: $f"; continue }
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p))
  $res = Post-Json "$api/blobs" (@{ content = $b64; encoding = 'base64' } | ConvertTo-Json -Compress)
  $sha = ($res | ConvertFrom-Json).sha
  $tree += @{ path = $f; mode = '100644'; type = 'blob'; sha = $sha }
  Write-Host ("blob  {0}  ->  {1}" -f $f, $sha.Substring(0, 8))
}

# 2. tree
$res = Post-Json "$api/trees" (@{ tree = $tree } | ConvertTo-Json -Depth 6 -Compress)
$treeSha = ($res | ConvertFrom-Json).sha
Write-Host "tree  -> $treeSha"

# 3. commit (parented on current main if it exists, else root commit)
$parent = $null
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'          # empty repos return HTTP 409 on ref GET - not an error for us
$existing = gh api "$api/ref/heads/$Branch" --jq '.object.sha' 2>$null
$refExists = ($LASTEXITCODE -eq 0 -and $existing)
$ErrorActionPreference = $prevEap
if ($refExists) { $parent = $existing }
$commitBody = @{ message = $Message; tree = $treeSha }
if ($parent) { $commitBody.parents = @($parent) } else { $commitBody.parents = @() }
$res = Post-Json "$api/commits" ($commitBody | ConvertTo-Json -Depth 5 -Compress)
$commitSha = ($res | ConvertFrom-Json).sha
Write-Host "commit -> $commitSha"

# 4. branch: create or fast-forward
if ($parent) {
  $tmp = Join-Path $env:TEMP ('ga_ref.json')
  [IO.File]::WriteAllText($tmp, (@{ sha = $commitSha; force = $false } | ConvertTo-Json -Compress))
  gh api "$api/refs/heads/$Branch" -X PATCH --input $tmp --jq '.object.sha' | Out-Null
} else {
  gh api "$api/refs" -X POST -f "ref=refs/heads/$Branch" -f "sha=$commitSha" --jq '.ref' | Out-Null
}
Write-Host "pushed $Branch -> $commitSha"
