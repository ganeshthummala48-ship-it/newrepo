# sync_to_hf.ps1
# Syncs farmerai_backend/ -> hf_space/ (only runtime files)
# Usage: .\sync_to_hf.ps1

$src = "$PSScriptRoot\farmerai_backend"
$dst = "$PSScriptRoot\hf_space"

# Files and folders to copy
$include = @(
    "main.py",
    "app.py",
    "requirements.txt",
    "README.md",
    "download_model.py",
    "crop_model.pkl",
    "crop_encoder.pkl",
    "soil_encoder.pkl",
    "season_encoder.pkl",
    "rainfall_encoder.pkl"
)

# Directories to mirror
$includeDirs = @("data", "model")

Write-Host "=== FarmerAI: Syncing farmerai_backend -> hf_space ===" -ForegroundColor Cyan

foreach ($file in $include) {
    $srcPath = Join-Path $src $file
    $dstPath = Join-Path $dst $file
    if (Test-Path $srcPath) {
        Copy-Item -Path $srcPath -Destination $dstPath -Force
        Write-Host "  [OK] $file" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $file (not found)" -ForegroundColor Yellow
    }
}

foreach ($dir in $includeDirs) {
    $srcDir = Join-Path $src $dir
    $dstDir = Join-Path $dst $dir
    if (Test-Path $srcDir) {
        Copy-Item -Path $srcDir -Destination $dstDir -Recurse -Force
        Write-Host "  [OK] $dir/" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $dir/ (not found)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Sync complete! Now commit and push hf_space/ ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "  cd hf_space" -ForegroundColor White
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  git commit -m `"deploy: smooth sync`"" -ForegroundColor White
Write-Host "  git push" -ForegroundColor White
