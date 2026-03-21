# Wretcher Drum Engine

A REAPER ReaScript that generates heavy-music drum MIDI patterns directly into your project. Covers blast beats, djent grooves, thall, death metal, black metal, grindcore, metalcore, doom, sludge, progressive metal, thrash, and more.

## Features

- 12 genre categories with 40+ named grooves
- 4 MIDI map presets (Odeholm, RS Monarch, Ultimate Heavy Drums, Sleep Token II by MixWave) with an in-script map editor
- Power hand control: hi-hat closed/open, ride tip/bell, crash, china, stack
- Configurable time signatures: 4/4, 3/4, 7/8, 5/4
- Loop lengths: 1, 2, 4, or 8 bars
- Velocity humanization and push/pull timing
- Auto-insert tom fill with crash at the end of the loop
- Randomize button for instant inspiration

## Requirements

- [REAPER](https://www.reaper.fm/) 6.0 or later
- [ReaImGui](https://forum.cockos.com/showthread.php?t=250419) extension 0.8 or later (install via ReaPack)

## Installation

### Manual

1. Download `wretcher-midi-generator.lua` from this repository.
2. Place it in your REAPER scripts folder:
   - **Windows:** `%APPDATA%\REAPER\Scripts\`
   - **macOS / Linux:** `~/Library/Application Support/REAPER/Scripts/`
3. In REAPER: **Actions → Show action list → Load** and select the file.
4. Optionally assign it a toolbar button or keyboard shortcut.

### Via ReaPack

> ReaPack support coming soon. Once the index is registered, install via **Extensions → ReaPack → Browse packages**.

## Usage

1. Select a track in REAPER (must be a MIDI or instrument track).
2. Position the edit cursor where you want the pattern to start.
3. Run **Wretcher Drum Engine** from the Actions list.
4. In the UI window:
   - Choose a **Time Signature** and **Pattern Length**.
   - Pick a **Groove** from the dropdown (organized by genre).
   - Select a **Power Hand** kit piece and **Subdivision**.
   - Adjust **Humanize** (timing slop) and **Push / Pull**.
   - Toggle **Auto-Insert Tom Fill** for automatic fills at loop end.
5. Click **GENERATE GROOVE** to write MIDI to the track, or **RANDOMIZE** to pick a random groove first.

The Map Editor (collapsible header at the top) lets you view and edit individual MIDI note numbers per instrument for the active preset.

## License

MIT — see [LICENSE](LICENSE).
