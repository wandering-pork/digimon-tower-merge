# Sprite Credits & Sources

This file tracks the source of all sprites used in Digimon Tower Merge.

---

## Download Status (as of 2025-01-31)

| Stage | Downloaded | Available | Coverage |
|-------|------------|-----------|----------|
| Fresh | 4 | 4 | 100% |
| In-Training | 7 | 7 | 100% |
| Rookie | 44 | 49 | 90% |
| Champion | 60 | 60 | 100% |
| Ultimate | 44 | 58 | 76% |
| Mega | 48 | 68 | 71% |
| Ultra | 0 | 3 | 0% |
| **TOTAL** | **207** | **249** | **83%** |

---

## Source: The Spriters Resource - Digimon World DS

- **URL:** https://www.spriters-resource.com/ds_dsi/dgmnworldds/
- **Ripped By:** Various contributors (redblueyellow, Atlanta, and others)
- **License:** Game sprite rips - for non-commercial fan projects only
- **Style:** DS game sprites (animated sprite sheets)
- **Format:** PNG with transparency

### How to Download More Sprites

The download script extracts the correct URL from each asset page:

```bash
download_sprite() {
    local name=$1; local id=$2; local stage=$3
    local media_path=$(curl -s -L -H "User-Agent: Mozilla/5.0" \
        "https://www.spriters-resource.com/ds_dsi/dgmnworldds/asset/${id}/" | \
        grep -oE '/media/assets/[0-9]+/[0-9]+\.png' | head -1)
    if [ -n "$media_path" ]; then
        curl -s -L -o "${stage}/${name}.png" \
            "https://www.spriters-resource.com${media_path}" \
            -H "User-Agent: Mozilla/5.0" \
            -H "Referer: https://www.spriters-resource.com/"
    fi
}

# Example usage:
download_sprite "omnimon" "48624" "ultra"
```

### Asset IDs Reference

**Ultra (need to download):**
- Omnimon: 48624
- Imperialdramon Paladin Mode: 48679
- Gallantmon Crimson Mode: 48622

**Missing Rookies (~5):**
Check main page for remaining IDs

**Missing Ultimates (~14):**
Check main page for remaining IDs

**Missing Megas (~20):**
Check main page for remaining IDs

---

## Alternative Sources (for missing sprites)

### With the Will Forums - V-Pet Sprites
- **URL:** https://withthewill.net/threads/full-color-digimon-dot-sprites.25843/
- **Google Drive:** https://drive.google.com/drive/folders/1EgoXHwlXNiurD4X_9WEgoyzm8OuWf_tf
- **License:** Free to use ("These sprites are all free for anyone to use")
- **Style:** 16x16 pixel v-pet style (will need upscaling)
- **Use for:** Missing Fresh/In-Training if DS versions unavailable

### DragonRod's Sprite Database (DeviantArt)
- **URL:** https://www.deviantart.com/dragonrod342/art/DragonRod-s-Digimon-Sprite-Database-698049391
- **License:** Check DeviantArt page
- **Use for:** Gap filling

### D-1 Tamer Sprites (WonderSwan)
- **URL:** https://www.spriters-resource.com/wonderswan_wsc/digimonadventure02d1tamer/
- **Note:** Only 9 assets total, not sprite sheets - less ideal for animation

---

## Folder Structure

```
assets/sprites/digimon/
├── fresh/           (4 sprites)
├── in_training/     (7 sprites)
├── rookie/          (44 sprites)
├── champion/        (60 sprites)
├── ultimate/        (44 sprites)
├── mega/            (48 sprites)
├── ultra/           (0 sprites - need to download)
└── effects/         (empty - for future VFX)
```

---

## Credits for Game Release

```
SPRITE CREDITS
==============
Digimon World DS Sprites
- Source: The Spriters Resource (https://www.spriters-resource.com/)
- Rippers: redblueyellow, Atlanta, and community contributors

Digimon is a trademark of Bandai Namco Entertainment / Toei Animation.
This is a non-commercial fan project.
```

---

*Last Updated: 2025-01-31*
*Valid Sprites: 207*
*Session Note: User will continue downloading remaining sprites in another session*
