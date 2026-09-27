# Generates raster Goodblox icons (favicon.ico, PNG set) from the SVG mark's geometry.
# Run once:  powershell -ExecutionPolicy Bypass -File .\generate-icons.ps1
Add-Type -AssemblyName System.Drawing

$root = $PSScriptRoot
$outDir = Join-Path $root 'images'
$V = 64.0   # SVG viewBox is 64x64; all coords below are in viewBox units

function New-GoodbloxBitmap([int]$size) {
  $k = $size / $V
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  # Blox tile: squircle (x=3,y=3,w=58,h=58,rx=19), yellow gradient
  $m = 3 * $k
  $side = 58 * $k
  $d = 38 * $k
  $tile = New-Object System.Drawing.Drawing2D.GraphicsPath
  $tile.AddArc($m, $m, $d, $d, 180, 90)
  $tile.AddArc($m + $side - $d, $m, $d, $d, 270, 90)
  $tile.AddArc($m + $side - $d, $m + $side - $d, $d, $d, 0, 90)
  $tile.AddArc($m, $m + $side - $d, $d, $d, 90, 90)
  $tile.CloseFigure()

  $c1 = [System.Drawing.ColorTranslator]::FromHtml('#ffe066')
  $c2 = [System.Drawing.ColorTranslator]::FromHtml('#ffc93c')
  $c3 = [System.Drawing.ColorTranslator]::FromHtml('#f5a300')
  $tileBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.PointF($m, $m)),
    (New-Object System.Drawing.PointF(($m + $side), ($m + $side))),
    $c1, $c3)
  $blend = New-Object System.Drawing.Drawing2D.ColorBlend(3)
  $blend.Colors = @($c1, $c2, $c3)
  $blend.Positions = @(0.0, 0.55, 1.0)
  $tileBrush.InterpolationColors = $blend
  $g.FillPath($tileBrush, $tile)

  # Glossy highlight, top-left
  $glossPath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $glossPath.AddEllipse((4 * $k), (2 * $k), (46 * $k), (36 * $k))
  $gloss = New-Object System.Drawing.Drawing2D.PathGradientBrush($glossPath)
  $gloss.CenterColor = [System.Drawing.Color]::FromArgb(150, 255, 255, 255)
  $gloss.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
  $g.FillPath($gloss, $glossPath)

  # Edge bevel
  $edge = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(90, 255, 255, 255), (1.5 * $k))
  $g.DrawPath($edge, $tile)

  # Blush
  $blushBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(82, 255, 138, 91))
  $g.FillEllipse($blushBrush, ((19 - 4.4) * $k), ((37 - 2.6) * $k), (8.8 * $k), (5.2 * $k))
  $g.FillEllipse($blushBrush, ((45 - 4.4) * $k), ((37 - 2.6) * $k), (8.8 * $k), (5.2 * $k))

  # Eyes
  $ink = [System.Drawing.ColorTranslator]::FromHtml('#3a2600')
  $eyeBrush = New-Object System.Drawing.SolidBrush($ink)
  $eyeR = 3.6 * $k
  $g.FillEllipse($eyeBrush, ((23 * $k) - $eyeR), ((27 * $k) - $eyeR), (2 * $eyeR), (2 * $eyeR))
  $g.FillEllipse($eyeBrush, ((41 * $k) - $eyeR), ((27 * $k) - $eyeR), (2 * $eyeR), (2 * $eyeR))

  # Smile: quadratic M21 38 Q32 49 43 38 -> cubic bezier
  $smile = New-Object System.Drawing.Pen($ink, (4.6 * $k))
  $smile.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $smile.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawBezier(
    $smile,
    (New-Object System.Drawing.PointF((21 * $k), (38 * $k))),
    (New-Object System.Drawing.PointF((28.33 * $k), (45.33 * $k))),
    (New-Object System.Drawing.PointF((35.67 * $k), (45.33 * $k))),
    (New-Object System.Drawing.PointF((43 * $k), (38 * $k))))

  $g.Dispose()
  return $bmp
}

function Get-PngBytes([System.Drawing.Bitmap]$bmp) {
  $stream = New-Object System.IO.MemoryStream
  $bmp.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
  $bytes = $stream.ToArray()
  $stream.Dispose()
  return , $bytes
}

# OneDrive keeps icons as reparse-point placeholders. GDI+ cannot overwrite one in
# place and Remove-Item refuses it, but System.IO.File.Delete clears it cleanly.
function Save-Png([System.Drawing.Bitmap]$bmp, [string]$path) {
  for ($attempt = 0; $attempt -lt 15; $attempt++) {
    try {
      if ([System.IO.File]::Exists($path)) { [System.IO.File]::Delete($path) }
      $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
      return
    } catch {
      if ($attempt -eq 14) { throw }
      Start-Sleep -Milliseconds 800
    }
  }
}

function Add-UInt16([System.Collections.Generic.List[byte]]$list, [int]$value) {
  $list.Add([byte]($value -band 0xFF))
  $list.Add([byte](($value -shr 8) -band 0xFF))
}

function Add-UInt32([System.Collections.Generic.List[byte]]$list, [int]$value) {
  for ($shift = 0; $shift -lt 32; $shift += 8) {
    $list.Add([byte](($value -shr $shift) -band 0xFF))
  }
}

# PNG set
$pngTargets = @(
  @{ Size = 48;  Name = 'favicon-48.png' },
  @{ Size = 96;  Name = 'favicon-96.png' },
  @{ Size = 180; Name = 'apple-touch-icon.png' },
  @{ Size = 192; Name = 'icon-192.png' },
  @{ Size = 512; Name = 'icon-512.png' }
)
foreach ($target in $pngTargets) {
  $bmp = New-GoodbloxBitmap $target.Size
  Save-Png $bmp (Join-Path $outDir $target.Name)
  $bmp.Dispose()
}

# Square 512 logo for schema.org Organization + Open Graph fallback
$logoBmp = New-GoodbloxBitmap 512
Save-Png $logoBmp (Join-Path $outDir 'logo.png')
$logoBmp.Dispose()

# Wide 1200x630 social / Open Graph card: mark + wordmark
$ogW = 1200; $ogH = 630
$og = New-Object System.Drawing.Bitmap($ogW, $ogH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$ogG = [System.Drawing.Graphics]::FromImage($og)
$ogG.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$ogG.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$ogG.Clear([System.Drawing.ColorTranslator]::FromHtml('#0a0912'))

$glow = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
  (New-Object System.Drawing.PointF(0, 0)),
  (New-Object System.Drawing.PointF($ogW, $ogH)),
  [System.Drawing.Color]::FromArgb(60, 255, 201, 60),
  [System.Drawing.Color]::FromArgb(0, 10, 9, 18))
$ogG.FillRectangle($glow, 0, 0, $ogW, $ogH)

$mark = New-GoodbloxBitmap 200
$ogG.DrawImage($mark, 92, 215, 200, 200)
$mark.Dispose()

$nameFont = New-Object System.Drawing.Font('Arial', 96, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$nameBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$nameAccent = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#ffc93c'))
$nameX = 340
$goodWidth = $ogG.MeasureString('good', $nameFont).Width
$ogG.DrawString('good', $nameFont, $nameBrush, $nameX, 240)
$ogG.DrawString('blox', $nameFont, $nameAccent, $nameX + $goodWidth - 10, 240)
$tagFont = New-Object System.Drawing.Font('Consolas', 30, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$ogG.DrawString('GOOD ROBLOX GAMES TO PLAY', $tagFont, (New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#84809a'))), 344, 360)

$ogG.Dispose()
Save-Png $og (Join-Path $outDir 'og-image.png')
$og.Dispose()

# favicon.ico at site root, wrapping 48px + 96px PNGs (both multiples of 48)
$icoSizes = @(48, 96)
$payloads = New-Object 'System.Collections.Generic.List[byte[]]'
foreach ($size in $icoSizes) {
  $bmp = New-GoodbloxBitmap $size
  $payloads.Add((Get-PngBytes $bmp))
  $bmp.Dispose()
}

$header = New-Object System.Collections.Generic.List[byte]
Add-UInt16 $header 0   # reserved
Add-UInt16 $header 1   # type: icon
Add-UInt16 $header $icoSizes.Count
$offset = 6 + 16 * $icoSizes.Count
for ($i = 0; $i -lt $icoSizes.Count; $i++) {
  $header.Add([byte]$icoSizes[$i])   # width
  $header.Add([byte]$icoSizes[$i])   # height
  $header.Add([byte]0)               # palette
  $header.Add([byte]0)               # reserved
  Add-UInt16 $header 1               # color planes
  Add-UInt16 $header 32              # bits per pixel
  Add-UInt32 $header $payloads[$i].Length
  Add-UInt32 $header $offset
  $offset += $payloads[$i].Length
}

$icoPath = Join-Path $root 'favicon.ico'
$file = [System.IO.File]::Create($icoPath)
foreach ($b in $header) { $file.WriteByte($b) }
foreach ($payload in $payloads) { $file.Write($payload, 0, $payload.Length) }
$file.Dispose()

Write-Host "Generated:"
Get-ChildItem $outDir -Filter '*.png' | Where-Object { $_.Name -match 'icon|apple' } | ForEach-Object { Write-Host "  images/$($_.Name)  ($($_.Length) bytes)" }
Write-Host "  favicon.ico  ($((Get-Item $icoPath).Length) bytes)"
