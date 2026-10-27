# Tiny static server for GLM Arcade - pure PowerShell, no dependencies.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File server.ps1 [port]
param([int]$Port = 8137)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = (Resolve-Path $root).Path

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Prefixes.Add("http://localhost:$Port/")
try { $listener.Start() } catch {
  Write-Error "Could not listen on port $Port : $_"
  exit 1
}
Write-Host "GLM Arcade -> http://localhost:$Port  (Ctrl+C to stop)"

$mime = @{
  '.html' = 'text/html; charset=utf-8'
  '.js' = 'text/javascript; charset=utf-8'
  '.webmanifest' = 'application/manifest+json'
  '.json' = 'application/json'
  '.png' = 'image/png'
  '.ico' = 'image/x-icon'
  '.md' = 'text/markdown; charset=utf-8'
  '.cmd' = 'text/plain; charset=utf-8'
  '.ps1' = 'text/plain; charset=utf-8'
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  try {
    $path = $ctx.Request.Url.AbsolutePath
    if ($path -eq '/') { $path = '/index.html' }
    $file = [System.IO.Path]::GetFullPath((Join-Path $root ($path -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    if (-not $file.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
      $ctx.Response.StatusCode = 403
    } elseif (Test-Path -LiteralPath $file -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($file).ToLower()
      if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
      $ctx.Response.Headers['Cache-Control'] = 'no-cache'
      $bytes = [System.IO.File]::ReadAllBytes($file)
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
  } catch {
    try { $ctx.Response.StatusCode = 500 } catch { }
  }
  try { $ctx.Response.Close() } catch { }
}
