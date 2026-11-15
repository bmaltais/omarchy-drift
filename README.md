# Drift for Omarchy

An animated gradient wallpaper for the Omarchy shell, after the macOS app Drift: soft colour blobs
that wander, grain, and light that follows the day and the weather. It is a shader (Qt RHI), drawn
on the background layer of every screen.

- **Atmospheres**: Ember, Iris, Lagoon, Dusk, Aurora, Sage, Mono, and Weather (colours chosen by the sky). Or wander through them all.
- **Follow the day**: brightness and warmth from the local hour; warm at dawn and dusk, dark and cool at night.
- **Follow the weather**: Open-Meteo for the location of Omarchy's weather panel (`omarchy-weather-location`, else its IP lookup at geo.omarchy.org). Cloud greys the colours, rain beads on the glass, snow falls, a storm darkens.
- **Speed, grain, blob count** sliders. (Pointer interaction is left out for now; the shader still has the input.)

## Install

```sh
ln -s ~/StartFS/github/omarchy-drift ~/.config/omarchy/plugins/io.github.bmaltais.drift
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
