# Generates GLM Arcade PWA icons (neon snake glyph) - no dependencies beyond .NET System.Drawing.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File tools\gen-icons.ps1
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dir  = Join-Path (Split-Path -Parent $root) 'icons'
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$bg    = [System.Drawing.Color]::FromArgb(255, 8, 12, 26)
$green = [System.Drawing.Color]::FromArgb(255, 0, 255, 136)
$pink  = [System.Drawing.Color]::FromArgb(255, 255, 70, 120)
$dark  = [System.Drawing.Color]::FromArgb(255, 8, 12, 26)

function New-Icon([int]$Size, [string]$Name, [double]$Glyph, [bool]$FullBleed) {
  $bmp = New-Object System.Drawing.Bitmap -ArgumentList $Size, $Size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

  if ($FullBleed) {
    # maskable / apple-touch: background must bleed to every edge
    $b = New-Object System.Drawing.SolidBrush -ArgumentList $bg
    $g.FillRectangle($b, 0, 0, $Size, $Size)
    $b.Dispose()
  } else {
    $r = $Size * 0.225
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc(0, 0, 2*$r, 2*$r, 180, 90)
    $p.AddArc($Size - 2*$r, 0, 2*$r, 2*$r, 270, 90)
    $p.AddArc($Size - 2*$r, $Size - 2*$r, 2*$r, 2*$r, 0, 90)
    $p.AddArc(0, $Size - 2*$r, 2*$r, 2*$r, 90, 90)
    $p.CloseFigure()
    $b = New-Object System.Drawing.SolidBrush -ArgumentList $bg
    $g.FillPath($b, $p)
    $b.Dispose(); $p.Dispose()
  }

  # snake glyph: S-shaped polyline (fractions of size), scaled about the center
  $raw = @(
    @(0.26, 0.22), @(0.68, 0.22), @(0.68, 0.50),
    @(0.32, 0.50), @(0.32, 0.78), @(0.62, 0.78)
  )
  $pts = New-Object 'System.Drawing.PointF[]' $raw.Count
  for ($i = 0; $i -lt $raw.Count; $i++) {
    $x = 0.5 + ($raw[$i][0] - 0.5) * $Glyph
    $y = 0.5 + ($raw[$i][1] - 0.5) * $Glyph
    $pts[$i] = New-Object System.Drawing.PointF -ArgumentList ([float]($x * $Size)), ([float]($y * $Size))
  }

  $w = $Size * 0.105 * $Glyph

  foreach ($layer in @(@{ W = $w + $Size * 0.075; A = 38 }, @{ W = $w + $Size * 0.035; A = 72 })) {
    $pen = New-Object System.Drawing.Pen -ArgumentList ([System.Drawing.Color]::FromArgb($layer.A, 0, 255, 136)), ([float]$layer.W)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    $g.DrawLines($pen, $pts)
    $pen.Dispose()
  }
  $pen = New-Object System.Drawing.Pen -ArgumentList $green, ([float]$w)
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $g.DrawLines($pen, $pts)
  $pen.Dispose()

  # head at the end of the path (heading right) + two dark eyes
  $head = $pts[$pts.Count - 1]
  $hr = $w * 0.78
  $b2 = New-Object System.Drawing.SolidBrush -ArgumentList $green
  $g.FillEllipse($b2, $head.X - $hr, $head.Y - $hr, 2 * $hr, 2 * $hr)
  $b2.Dispose()
  $er = [Math]::Max(2.0, $Size * 0.016)
  $eb = New-Object System.Drawing.SolidBrush -ArgumentList $dark
  $g.FillEllipse($eb, $head.X + $hr * 0.15 - $er, $head.Y - $hr * 0.55 - $er, 2 * $er, 2 * $er)
  $g.FillEllipse($eb, $head.X + $hr * 0.15 - $er, $head.Y + $hr * 0.55 - $er, 2 * $er, 2 * $er)
  $eb.Dispose()

  # food dot with halo, top-right
  $fx = (0.5 + (0.84 - 0.5) * $Glyph) * $Size
  $fy = (0.5 + (0.30 - 0.5) * $Glyph) * $Size
  $fr = $Size * 0.045 * $Glyph
  $halo = New-Object System.Drawing.SolidBrush -ArgumentList ([System.Drawing.Color]::FromArgb(60, 255, 70, 120))
  $g.FillEllipse($halo, $fx - 2.2 * $fr, $fy - 2.2 * $fr, 4.4 * $fr, 4.4 * $fr)
  $halo.Dispose()
  $fb = New-Object System.Drawing.SolidBrush -ArgumentList $pink
  $g.FillEllipse($fb, $fx - $fr, $fy - $fr, 2 * $fr, 2 * $fr)
  $fb.Dispose()

  $g.Dispose()
  $out = Join-Path $dir $Name
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host ("icon: " + $out)
}

New-Icon 192 'icon-192.png'         0.90 $false
New-Icon 512 'icon-512.png'         0.90 $false
New-Icon 512 'maskable-512.png'     0.72 $true
New-Icon 180 'apple-touch-icon.png' 0.78 $true
New-Icon 32  'favicon-32.png'       0.90 $false
Write-Host 'done'
