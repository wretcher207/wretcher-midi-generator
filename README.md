> **ReaPack users:** This script is now distributed through the unified Dead Pixel Design repository.
> Add this URL in REAPER under `Extensions → ReaPack → Import repositories`:
> ```
> https://raw.githubusercontent.com/wretcher207/dead-pixel-design/main/index.xml
> ```
> The `index.xml` in this repo is preserved for backward compatibility but will not receive new entries.

---

# Dead Pixel Drum Apparatus

A REAPER script that generates drum MIDI for heavy music. You pick a groove, set a time signature, and it writes the MIDI directly into your project. That is it.

Comes with 43 grooves across 12 categories: thall, djent, death metal, slam, black metal, grindcore, metalcore, doom and sludge, progressive metal, rock, thrash, and breakdowns. Four MIDI map presets are included (Odeholm, RS Monarch, Ultimate Heavy Drums, Sleep Token II by MixWave) with a built-in map editor so you can adjust note assignments without leaving the script.

Other things it does: power hand control (hi-hat, ride, crash, china, stack), configurable time signatures (4/4, 3/4, 7/8, 5/4), loop lengths from 1 to 8 bars, velocity humanization, push/pull timing, and auto tom fills with a crash at the turnaround.

## Requirements

REAPER 6.0 or later. ReaImGui 0.8 or later. Install ReaImGui through ReaPack if you do not have it.

## Installation

### Via ReaPack

Add this repository URL in REAPER: Extensions > ReaPack > Import repositories.

```
https://raw.githubusercontent.com/wretcher207/dead-pixel-design/main/index.xml
```

Then go to Extensions > ReaPack > Browse packages, search for Dead Pixel Drum Apparatus, and install.

### Manual

Download `wretcher-midi-generator.lua` from this repository. Drop it in your REAPER scripts folder. On Windows that is `%APPDATA%\REAPER\Scripts\`. On macOS and Linux it is `~/Library/Application Support/REAPER/Scripts/`. Then load it in REAPER through Actions > Show action list > Load.

## Usage

Select a MIDI or instrument track. Put the edit cursor where you want the pattern. Run Dead Pixel Drum Apparatus from the Actions list. Pick a groove, set your parameters, hit GENERATE GROOVE. The MIDI lands on the track. There is also a RANDOMIZE button if you want the script to pick for you.

The Map Editor at the top of the window lets you view and change MIDI note numbers for each instrument in the active preset. Useful when your drum VST does not match the defaults.

## Author

David W. Russell III / [Dead Pixel Design](https://www.deadpixeldesign.com)

## License

MIT. See [LICENSE](LICENSE).