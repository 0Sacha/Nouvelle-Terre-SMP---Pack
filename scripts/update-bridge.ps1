$packwiz = "$env:USERPROFILE\go\bin\packwiz.exe"
$tomlPath = "$PSScriptRoot\..\mods\nouvelle-terre-bridge.pw.toml"

Write-Host "Recherche de la derniere release..."
$release = Invoke-RestMethod "https://api.github.com/repos/0Sacha/Nouvelle-Terre-SMP---MOD/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "nouvelle-terre-bridge-*.jar" } | Select-Object -First 1

if (-not $asset) {
    Write-Error "Aucun JAR trouve dans la derniere release."
    exit 1
}

$version = $asset.name -replace "nouvelle-terre-bridge-(.+)\.jar", '$1'
$url = $asset.browser_download_url
$tag = $release.tag_name

Write-Host "Version trouvee : $version ($tag)"

$current = Get-Content $tomlPath | Select-String 'filename' | ForEach-Object { $_ -match '"(.+)"'; $matches[1] }
if ($current -eq $asset.name) {
    Write-Host "Deja a jour ($version). Rien a faire."
    exit 0
}

Write-Host "Telechargement pour calcul du hash..."
$tmp = "$env:TEMP\nouvelle-terre-bridge.jar"
Invoke-WebRequest -Uri $url -OutFile $tmp
$hash = (Get-FileHash $tmp -Algorithm SHA1).Hash.ToLower()
Remove-Item $tmp

Write-Host "Hash SHA1 : $hash"

$content = @"
name = "Nouvelle Terre Bridge"
filename = "nouvelle-terre-bridge-$version.jar"
side = "both"

[download]
url = "$url"
hash-format = "sha1"
hash = "$hash"
"@

Set-Content -Path $tomlPath -Value $content -Encoding utf8
Write-Host "Fichier mis a jour."

& $packwiz refresh
git -C "$PSScriptRoot\.." add mods/nouvelle-terre-bridge.pw.toml index.toml pack.toml
git -C "$PSScriptRoot\.." commit -m "chore: update nouvelle-terre-bridge to $version"
git -C "$PSScriptRoot\.." push origin main

Write-Host "Mise a jour deployee ! Les joueurs auront $version au prochain lancement."
