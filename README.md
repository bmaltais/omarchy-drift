# Drift for Omarchy

An animated gradient wallpaper for the Omarchy shell, inspired by Drift, the macOS app by [@ow](https://x.com/ow) (not affiliated with it): soft colour blobs
that wander, grain, and light that follows the day and the weather. It is a shader (Qt RHI), drawn
on the background layer of every screen.

- **Atmospheres** (a dropdown, plus Generate for a random new one and a shuffle button): Ember, Iris, Lagoon, Dusk, Aurora, Sage, Mono, and Weather (colours chosen by the sky). Or wander through them all.
- **Follow the day**: the palette is pulled toward the sky's colours for the local hour (indigo night, orange and magenta at dawn and dusk, blue, pink and orange at midday). Optional "Show the time" adds a small clock caption bottom left (`preview-hour` via `previewHour` for testing).
- **Follow the weather**: Open-Meteo for the location of Omarchy's weather panel (`omarchy-weather-location`, else its IP lookup at geo.omarchy.org). Click the city chip to search for another place (Open-Meteo geocoding; only the typed text is sent); it is saved in Drift's own settings and does not change Omarchy's location. "Current location" (always listed first) goes back to automatic. Cloud greys the colours, rain beads on the glass, snow falls, a storm darkens, and wind (speed and direction) swirls the colours.
- **Bar icon** (a droplet): left-click opens the settings card under the pointer (one `hyprctl cursorpos` lookup at click time; centred on it, kept on the screen), right-click turns Drift on or off. Add `{ "id": "io.github.bmaltais.drift" }` to a bar section in `shell.json`.
- **Speed, grain, blob count** sliders, and Rest & drift (30 s still, 30 s moving). The card follows the Mac app: live preview header, pause, shuffle. (Pointer interaction is left out for now; the shader still has the input.)

## Install

```sh
git clone https://github.com/bmaltais/omarchy-drift ~/.config/omarchy/plugins/io.github.bmaltais.drift
```
Add `{ "id": "io.github.bmaltais.drift" }` to the top-level `plugins` list of `~/.config/omarchy/shell.json`, then restart the shell.

## Use

```sh
omarchy-shell io.github.bmaltais.drift toggle      # on / off (also on, off)
omarchy-shell io.github.bmaltais.drift open        # the settings card (Escape closes it)
omarchy-shell io.github.bmaltais.drift set atmosphere Iris
omarchy-shell io.github.bmaltais.drift preview 63  # force a weather code (61 rain, 71 snow, 95 storm)
omarchy-shell io.github.bmaltais.drift status
```
Settings persist in `~/.local/state/omarchy-drift/settings.json`. While on, Drift suspends the stock still
wallpaper through the same hook a video wallpaper uses (`omarchy-shell background setSuspended`), and hands it back when off. Theme wallpapers
keep working underneath; they just are not shown. Do not combine it with a video wallpaper.

## Develop

`shaders/drift.frag` compiles to the committed `shaders/drift.frag.qsb`: run `scripts/build-shaders.sh` after editing it
(needs `qsb` from qt6-shadertools). Test in a nested session with the devkit (`omarchy-plugin-devkit`): `dev up`, `dev reload`,
`dev ipc io.github.bmaltais.drift on`, `dev shot`. `qmllint` baselines only toolchain limits (Quickshell types the linter cannot see).

## Credits

The idea, the look and the name come from **Drift**, a native macOS app (a Metal shader) by [@ow](https://x.com/ow):
[the original post](https://x.com/ow/status/2121743789702467904). This is an independent Linux/Omarchy implementation
written from the author's public screenshots and description; it shares no code with the Mac app and is not affiliated with or endorsed by it.
