# Script to remove animation code from remaining screen files
# Pattern: remove flutter_animate import, AnimationController, TickerProviderStateMixin, _staggeredItem, _staggerController

$libPath = "c:\Users\welcome\Desktop\NEWMOM\lib"

# Get all .dart files that still import flutter_animate
$files = Get-ChildItem -Path $libPath -Recurse -Filter "*.dart" | Where-Object {
    (Get-Content $_.FullName -Raw) -match 'flutter_animate'
}

foreach ($file in $files) {
    Write-Host "Processing: $($file.FullName)"
}

Write-Host "`nTotal files remaining: $($files.Count)"
