# Panduan Config — Autofarm Grow a Garden

Semua setting ada di `_G.GAGConfig` di atas script. Kamu boleh isi sedikit saja; sisanya pakai default.

## Cara cepat

Pilih preset:

```lua
_G.GAGConfig = { Preset = "Balanced" }
```

Preset tersedia:
- `Starter` — akun baru, fokus uang awal
- `Balanced` — aman untuk kebanyakan akun
- `Rich` — akun besar, cari nilai tinggi dan batasi plot
- `AltToMain` — farm alt lalu kirim ke akun utama
- `LowPC` — performa paling ringan

Kamu juga bisa override setting setelah preset:

```lua
_G.GAGConfig = {
    Preset = "Balanced",
    ["Mail"] = {
        ["Send To"] = "USERNAME_AKUN_UTAMAMU",
    },
    ["Performance"] = {
        ["FPS Cap"] = 30,
    },
}
```

## Format nilai

| Bentuk | Contoh | Catatan |
|---|---|---|
| toggle | `true` / `false` | nyala / mati |
| angka | `85` | tanpa kutip |
| teks | `"compact"` | pakai kutip |
| daftar | `{ "Apple", "Dragon Fruit" }` | tiap nama dikutip |
| map nama = angka | `{ ["Apple"] = 50 }` | wajib ada angka |

Nama aman untuk semua kasus: pakai `"Nama"` di daftar, dan `["Nama"] = nilai` di map.

## Section pendek juga didukung

Script sekarang menerima bentuk ramah-user ini:

```lua
_G.GAGConfig = {
    ["Harvest"]  = { ["Sell At"] = 85, ["Sell Every"] = 40 },
    ["Planting"] = { ["Layout"] = "compact", ["Minimum Seed"] = "Bamboo" },
    ["Money"]    = { ["Keep Cash"] = 15000, ["Auto Expand Plot"] = true },
}
```

Akan otomatis diubah ke key internal script.

## GUI

Overlay in-game punya tombol:
- Starter
- Balanced
- Rich
- Alt/Main
- Low PC
- Pause/Run

F4 = sembunyikan/tampilkan overlay.

Catatan: ganti preset lewat GUI berlaku untuk runtime saat itu. Kalau mau permanen, tulis preset di `_G.GAGConfig` sebelum run.

## Preset contoh

Lihat file:

`examples/config.presets.lua`

## Peringatan Mail

Mail otomatis benar-benar mengirim item. Test dulu dengan barang murah dan pastikan `Send To` benar.
