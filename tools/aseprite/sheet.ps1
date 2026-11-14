# Контактный лист: .\sheet.ps1 out.png 4 file1 file2 ... (увеличение без размытия, зелёный фон)
param([string]$Out, [int]$Scale, [string[]]$Files)
Add-Type -AssemblyName System.Drawing
$imgs = @(); foreach ($f in $Files) { $imgs += [System.Drawing.Image]::FromFile((Resolve-Path $f)) }
$W = 8; $H = 8
foreach ($i in $imgs) { $W += ($i.Width * $Scale + 8); $H = [Math]::Max($H, $i.Height * $Scale + 16) }
$maxw = 1400
$rows = @(); $cur = @(); $cw = 8
foreach ($i in $imgs) { $w = $i.Width * $Scale + 8; if ($cw + $w -gt $maxw -and $cur.Count -gt 0) { $rows += ,$cur; $cur = @(); $cw = 8 }; $cur += $i; $cw += $w }
if ($cur.Count -gt 0) { $rows += ,$cur }
$tot = 8; foreach ($r in $rows) { $mh = 0; foreach ($i in $r) { $mh = [Math]::Max($mh, $i.Height * $Scale) }; $tot += $mh + 8 }
$bmp = New-Object System.Drawing.Bitmap($maxw, $tot)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(255, 96, 132, 84))
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$y = 8
foreach ($r in $rows) { $x = 8; $mh = 0
  foreach ($i in $r) { $g.DrawImage($i, $x, $y, $i.Width * $Scale, $i.Height * $Scale); $x += $i.Width * $Scale + 8; $mh = [Math]::Max($mh, $i.Height * $Scale) }
  $y += $mh + 8 }
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); foreach ($i in $imgs) { $i.Dispose() }
