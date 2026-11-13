param(
	[Parameter(Mandatory = $true)][string]$Engine,
	[Parameter(Mandatory = $true)][string]$Out,
	[string]$Platform = "Windows",
	[string]$Name = "WeedFirm",
	[string]$Templates = "",
	[string]$Upx = "upx"
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
if (Test-Path $Engine -PathType Container) {
	$exes = Get-ChildItem $Engine -Filter *.exe
	$exe = $exes | Where-Object { $_.Name -match "console" } | Select-Object -First 1
	if (-not $exe) { $exe = $exes | Where-Object { $_.Name -match "redot|godot" } | Select-Object -First 1 }
	if (-not $exe) { throw "No Redot/Godot executable found in $Engine" }
	$Engine = $exe.FullName
}
$tplName = if ($Platform -eq "Linux") { "linux_release.x86_64" } else { "windows_release_x86_64.exe" }
$outName = if ($Platform -eq "Linux") { "$Name.x86_64" } else { "$Name.exe" }
$roots = @()
if ($Templates -ne "") { $roots += $Templates }
else { foreach ($d in @("Redot", "Godot")) { $p = Join-Path $env:APPDATA "$d\export_templates"; if (Test-Path $p) { $roots += (Get-ChildItem $p -Directory | ForEach-Object { $_.FullName }) } } }
$tpl = $roots | ForEach-Object { Join-Path $_ $tplName } | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $tpl) { throw "Release template $tplName not found. Install the export templates or pass -Templates." }
if (-not (Get-Command $Upx -ErrorAction SilentlyContinue)) { throw "UPX not found. Install it or pass -Upx <path>." }
$work = Join-Path ([IO.Path]::GetTempPath()) ("wf_export_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $work | Out-Null
try {
	$packed = Join-Path $work $tplName
	Copy-Item $tpl $packed
	& $Upx --best --lzma -q $packed | Out-Null
	if ($LASTEXITCODE -ne 0) { throw "UPX failed on the template" }
	$pck = Join-Path $work "game.pck"
	& $Engine --headless --path $project --import | Out-Null
	& $Engine --headless --path $project --export-pack $Platform $pck
	if (-not (Test-Path $pck)) { throw "Could not export the project pack (is the $Platform preset present?)" }
	New-Item -ItemType Directory -Force -Path $Out | Out-Null
	$target = Join-Path (Resolve-Path $Out) $outName
	$fs = [IO.File]::Open($target, [IO.FileMode]::Create)
	try {
		foreach ($f in @($packed, $pck)) { $b = [IO.File]::ReadAllBytes($f); $fs.Write($b, 0, $b.Length) }
		$len = (Get-Item $pck).Length
		$fs.Write([BitConverter]::GetBytes([uint64]$len), 0, 8)
		$fs.Write([BitConverter]::GetBytes([uint32]0x43504447), 0, 4)
	} finally { $fs.Dispose() }
	"{0:N1} MB  {1}" -f ((Get-Item $target).Length / 1MB), $target
} finally { Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue }
