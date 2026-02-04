# Digimon Sprite Downloader for Spriters Resource
# Run this script in PowerShell to download sprites

$baseUrl = "https://www.spriters-resource.com/media/assets"
$outputBase = "E:\code\digimon game\assets\sprites\digimon"

# Function to download sprite
function Download-Sprite {
    param (
        [string]$name,
        [string]$id,
        [string]$folder,
        [string]$stage
    )

    $url = "$baseUrl/$folder/$id.png"
    $outputPath = "$outputBase\$stage\$($name.ToLower()).png"

    Write-Host "Downloading $name ($id) to $stage..." -NoNewline

    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        $webClient.Headers.Add("Referer", "https://www.spriters-resource.com/")
        $webClient.DownloadFile($url, $outputPath)
        Write-Host " OK" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        return $false
    }
}

# Fresh Digimon (folder needs to be determined for each)
Write-Host "`n=== FRESH ===" -ForegroundColor Cyan
Download-Sprite "Chibomon" "48416" "45" "fresh"
Download-Sprite "Poyomon" "13320" "13" "fresh"

# In-Training Digimon
Write-Host "`n=== IN-TRAINING ===" -ForegroundColor Cyan
Download-Sprite "Koromon" "20462" "20" "in_training"
Download-Sprite "Tsunomon" "48285" "45" "in_training"
Download-Sprite "Tokomon" "13322" "13" "in_training"
Download-Sprite "Pagumon" "48414" "45" "in_training"
Download-Sprite "Tanemon" "48413" "45" "in_training"

# Rookie Digimon
Write-Host "`n=== ROOKIE ===" -ForegroundColor Cyan
Download-Sprite "Agumon" "48418" "45" "rookie"
Download-Sprite "Gabumon" "41249" "41" "rookie"
Download-Sprite "Patamon" "48422" "45" "rookie"
Download-Sprite "Guilmon" "24505" "24" "rookie"
Download-Sprite "Renamon" "13321" "13" "rookie"
Download-Sprite "Terriermon" "20467" "20" "rookie"
Download-Sprite "Veemon" "48419" "45" "rookie"
Download-Sprite "Wormmon" "48516" "45" "rookie"
Download-Sprite "Tentomon" "48424" "45" "rookie"
Download-Sprite "Gomamon" "48321" "45" "rookie"
Download-Sprite "Palmon" "48283" "45" "rookie"
Download-Sprite "Biyomon" "48423" "45" "rookie"
Download-Sprite "DemiDevimon" "48429" "45" "rookie"
Download-Sprite "Impmon" "48443" "45" "rookie"
Download-Sprite "Salamon" "48727" "45" "rookie"
Download-Sprite "Lopmon" "24250" "24" "rookie"
Download-Sprite "Hawkmon" "48517" "45" "rookie"
Download-Sprite "Armadillomon" "48518" "45" "rookie"
Download-Sprite "Betamon" "48421" "45" "rookie"
Download-Sprite "Floramon" "48316" "45" "rookie"
Download-Sprite "Hagurumon" "48317" "45" "rookie"

# Champion Digimon
Write-Host "`n=== CHAMPION ===" -ForegroundColor Cyan
Download-Sprite "Greymon" "48406" "45" "champion"
Download-Sprite "GeoGreymon" "48577" "45" "champion"
Download-Sprite "Tyrannomon" "48455" "45" "champion"
Download-Sprite "DarkTyrannomon" "41245" "41" "champion"
Download-Sprite "Growlmon" "20461" "20" "champion"
Download-Sprite "Garurumon" "48583" "45" "champion"
Download-Sprite "Leomon" "48597" "45" "champion"
Download-Sprite "Angemon" "48611" "45" "champion"
Download-Sprite "Gatomon" "48535" "45" "champion"
Download-Sprite "Unimon" "48702" "45" "champion"
Download-Sprite "Devimon" "48593" "45" "champion"
Download-Sprite "Bakemon" "48533" "45" "champion"
Download-Sprite "Wizardmon" "48441" "45" "champion"
Download-Sprite "Kabuterimon" "48595" "45" "champion"
Download-Sprite "Kuwagamon" "41254" "41" "champion"
Download-Sprite "Stingmon" "48591" "45" "champion"
Download-Sprite "Ikkakumon" "48556" "45" "champion"
Download-Sprite "Seadramon" "48602" "45" "champion"
Download-Sprite "Togemon" "48326" "45" "champion"
Download-Sprite "Sunflowmon" "48284" "45" "champion"
Download-Sprite "Kiwimon" "41252" "41" "champion"
Download-Sprite "Birdramon" "48604" "45" "champion"
Download-Sprite "Aquilamon" "46749" "45" "champion"
Download-Sprite "Guardromon" "48615" "45" "champion"
Download-Sprite "ExVeemon" "48586" "45" "champion"
Download-Sprite "Kyubimon" "48589" "45" "champion"
Download-Sprite "Gargomon" "48606" "45" "champion"
Download-Sprite "Ankylomon" "48603" "45" "champion"

# Ultimate Digimon
Write-Host "`n=== ULTIMATE ===" -ForegroundColor Cyan
Download-Sprite "MetalGreymon" "48322" "45" "ultimate"
Download-Sprite "RizeGreymon" "48543" "45" "ultimate"
Download-Sprite "SkullGreymon" "48329" "45" "ultimate"
Download-Sprite "WarGrowlmon" "48670" "45" "ultimate"
Download-Sprite "WereGarurumon" "48684" "45" "ultimate"
Download-Sprite "MagnaAngemon" "48701" "45" "ultimate"
Download-Sprite "Angewomon" "48625" "45" "ultimate"
Download-Sprite "Silphymon" "48683" "45" "ultimate"
Download-Sprite "Myotismon" "48609" "45" "ultimate"
Download-Sprite "LadyDevimon" "48617" "45" "ultimate"
Download-Sprite "MegaKabuterimon" "48528" "45" "ultimate"
Download-Sprite "Okuwamon" "48618" "45" "ultimate"
Download-Sprite "Zudomon" "48539" "45" "ultimate"
Download-Sprite "MegaSeadramon" "48628" "45" "ultimate"
Download-Sprite "Lillymon" "41255" "41" "ultimate"
Download-Sprite "Blossomon" "48534" "45" "ultimate"
Download-Sprite "Garudamon" "48715" "45" "ultimate"
Download-Sprite "Andromon" "48685" "45" "ultimate"
Download-Sprite "Megadramon" "48682" "45" "ultimate"
Download-Sprite "Paildramon" "48721" "45" "ultimate"
Download-Sprite "Taomon" "48728" "45" "ultimate"
Download-Sprite "Rapidmon" "48693" "45" "ultimate"
Download-Sprite "Antylamon" "48703" "45" "ultimate"

# Mega Digimon
Write-Host "`n=== MEGA ===" -ForegroundColor Cyan
Download-Sprite "WarGreymon" "48613" "45" "mega"
Download-Sprite "BlackWarGreymon" "48585" "45" "mega"
Download-Sprite "Gallantmon" "48623" "45" "mega"
Download-Sprite "MetalGarurumon" "48720" "45" "mega"
Download-Sprite "SaberLeomon" "48454" "45" "mega"
Download-Sprite "Seraphimon" "48694" "45" "mega"
Download-Sprite "VenomMyotismon" "48729" "45" "mega"
Download-Sprite "Beelzemon" "48550" "45" "mega"
Download-Sprite "Daemon" "48448" "45" "mega"
Download-Sprite "Lilithmon" "48673" "45" "mega"
Download-Sprite "Piedmon" "48435" "45" "mega"
Download-Sprite "HerculesKabuterimon" "48530" "45" "mega"
Download-Sprite "GranKuwagamon" "48716" "45" "mega"
Download-Sprite "Vikemon" "48538" "45" "mega"
Download-Sprite "Neptunemon" "48552" "45" "mega"
Download-Sprite "Leviamon" "48437" "45" "mega"
Download-Sprite "Rosemon" "48453" "45" "mega"
Download-Sprite "Phoenixmon" "48722" "45" "mega"
Download-Sprite "Machinedramon" "48695" "45" "mega"
Download-Sprite "Sakuyamon" "48726" "45" "mega"
Download-Sprite "MegaGargomon" "48725" "45" "mega"
Download-Sprite "CherubimonVaccine" "48560" "45" "mega"
Download-Sprite "CherubimonVirus" "48561" "45" "mega"
Download-Sprite "Imperialdramon_FM" "48680" "45" "mega"

# Ultra/DNA Digimon
Write-Host "`n=== ULTRA ===" -ForegroundColor Cyan
Download-Sprite "Omegamon" "48624" "45" "ultra"
Download-Sprite "Imperialdramon_PM" "48679" "45" "ultra"
Download-Sprite "Gallantmon_CM" "48622" "45" "ultra"

Write-Host "`n=== DOWNLOAD COMPLETE ===" -ForegroundColor Green
Write-Host "Check the output folders for downloaded sprites."
Write-Host "Some may have failed if the folder number was wrong - check manually."
