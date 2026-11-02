# WANZZMIXER V5-PRO (Roblox Luau)

Port Roblox dari simulator lighting **WANZZMIXER V5-PRO | grandMA2 x Pearl 1024B Engine**.
Logika engine sama dengan versi HTML: 28 beam Clara S 14R, 11 gerakan + reset, parameter independen per gerakan (`presetMemory`), slider shape generator, color wheel, dan case bank.

## Isi repo

```
WanzzMixerV5/
├── default.project.json      # konfigurasi Rojo
├── src/
│   ├── WanzzMixer.client.lua # LocalScript utama (mixer + visualizer)
│   └── AutoPower.client.lua  # Auto hidupkan power/panel (ProximityPrompt)
└── README.md
```

## Cara pakai

### Opsi 1: Manual (tanpa Rojo)
1. Buka Roblox Studio.
2. Buat `LocalScript` baru di `StarterPlayer > StarterPlayerScripts`.
3. Salin isi `src/WanzzMixer.client.lua` ke dalamnya.
4. Tekan Play.

### Opsi 2: Rojo
```bash
rojo serve
```
Lalu hubungkan dari plugin Rojo di Studio.

## Auto Power
`AutoPower.client.lua` memindai `ProximityPrompt` yang teksnya mengandung kata kunci (power, panel, hidup, dll)
dan menekannya otomatis sekali per prompt. Sesuaikan `CONFIG.KEYWORDS_ON` dan `CONFIG.KEYWORDS_SKIP`
dengan teks tombol di game. Kalau game memakai RemoteEvent/DMX, isi fungsi `customPowerOn` dengan API resmi developer.

## Catatan teknis
- Canvas diganti `Frame` yang dirotasi + `UIGradient` untuk menggambar beam.
- Slider dibuat manual (drag mouse/sentuh) supaya aman di HP.
- Kecepatan animasi dinormalisasi ke 60 FPS memakai `dt`.
- Gerakan `brutal_shake` dan `strobe_drop` berkedip cepat. Hati-hati untuk pemain yang sensitif cahaya berkedip.
