Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot "f7-pack"
New-Item -ItemType Directory -Force $out | Out-Null
$blue = [System.Drawing.Color]::FromArgb(255, 63, 169, 245)

function Draw-Flake($g, [float]$cx, [float]$cy, [float]$r, $color, [float]$w, [bool]$hex) {
    $pen = New-Object System.Drawing.Pen($color, $w)
    $pen.StartCap = 'Square'; $pen.EndCap = 'Square'
    $inner = if ($hex) { $r * 0.5 } else { 0 }
    for ($i = 0; $i -lt 6; $i++) {
        $a = [Math]::PI / 3 * $i - [Math]::PI / 2
        $dx = [Math]::Cos($a); $dy = [Math]::Sin($a)
        $g.DrawLine($pen, $cx + $dx*$inner, $cy + $dy*$inner, $cx + $dx*$r, $cy + $dy*$r)
        foreach ($t in 0.6, 0.8) {
            $bx = $cx + $dx*$r*$t; $by = $cy + $dy*$r*$t
            $len = $r * 0.18
            foreach ($s in -1, 1) {
                $ba = $a + [Math]::PI + $s * [Math]::PI / 4
                $g.DrawLine($pen, $bx, $by, $bx + [Math]::Cos($ba)*$len*-1, $by + [Math]::Sin($ba)*$len*-1)
            }
        }
    }
    if ($hex) {
        $pts = @()
        for ($i = 0; $i -lt 6; $i++) {
            $a = [Math]::PI / 3 * $i - [Math]::PI / 2
            $pts += New-Object System.Drawing.PointF(($cx + [Math]::Cos($a)*$r*0.46), ($cy + [Math]::Sin($a)*$r*0.46))
        }
        $g.DrawPolygon($pen, [System.Drawing.PointF[]]$pts)
    }
    $pen.Dispose()
}

function New-Canvas($w, $h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
    return $bmp, $g
}

function Draw-F7($g, [float]$cx, [float]$cy, [float]$size, $color) {
    $font = New-Object System.Drawing.Font("Segoe UI", $size, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
    $g.DrawString("F7", $font, (New-Object System.Drawing.SolidBrush($color)), $cx, $cy, $sf)
}

# 1) Logo / elim icon (transparent)
$bmp, $g = New-Canvas 512 512
Draw-Flake $g 256 256 220 $blue 18 $true
Draw-F7 $g 256 258 80 $blue
$bmp.Save("$out\f7_icon.png"); $g.Dispose(); $bmp.Dispose()

# 2) Skybox faces (night blue gradient + snowflakes)
$rand = New-Object System.Random(7)
foreach ($face in "bk","dn","ft","lf","rt","up") {
    $bmp, $g = New-Canvas 1024 1024
    $top = [System.Drawing.Color]::FromArgb(255, 8, 14, 30)
    $bot = [System.Drawing.Color]::FromArgb(255, 22, 52, 96)
    if ($face -eq "up") { $bot = $top }
    if ($face -eq "dn") { $top = $bot }
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(0,0,1024,1024)), $top, $bot, 90)
    $g.FillRectangle($br, 0, 0, 1024, 1024)
    for ($i = 0; $i -lt 160; $i++) {
        $s = $rand.Next(1, 4)
        $g.FillEllipse((New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb($rand.Next(90,220),255,255,255))), $rand.Next(1024), $rand.Next(1024), $s, $s)
    }
    for ($i = 0; $i -lt 10; $i++) {
        $c = [System.Drawing.Color]::FromArgb($rand.Next(40,110), 120, 190, 255)
        Draw-Flake $g $rand.Next(60,964) $rand.Next(60,964) $rand.Next(14,40) $c 3 $false
    }
    $bmp.Save("$out\sky_$face.png"); $g.Dispose(); $bmp.Dispose()
}

# 3) Item background
$bmp, $g = New-Canvas 256 256
$g.Clear([System.Drawing.Color]::FromArgb(230, 14, 22, 36))
$g.DrawRectangle((New-Object System.Drawing.Pen($blue, 6)), 3, 3, 249, 249)
Draw-Flake $g 210 46 30 ([System.Drawing.Color]::FromArgb(70,63,169,245)) 4 $false
$bmp.Save("$out\item_bg.png"); $g.Dispose(); $bmp.Dispose()

Write-Output "Done: $out"
