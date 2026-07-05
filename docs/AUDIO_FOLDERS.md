# Audio Folders

Stage 38 adds audio folders for future music and sound effects without adding real audio files.

## Folders

- `assets/audio/music/` is reserved for music tracks. Prefer `.ogg` for looping/background music.
- `assets/audio/sfx/` is reserved for short sound effects. Prefer `.wav` or `.ogg` for SFX.

## Missing Audio Behavior

Audio files are optional in this stage. `AudioAssetCatalog` checks `ResourceLoader.exists(path)` before loading, returns `null` for missing or non-audio resources, and caches missing keys so repeated events stay cheap.

`AudioManager` treats a missing stream as a no-op. Missing music or SFX must never crash the game, block input, or change gameplay timing.

No real audio files are included in Stage 38.
