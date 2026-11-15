// Drift: an animated gradient wallpaper. State lives here; DriftLayer draws it, SettingsCard edits it.
// `omarchy-shell io.github.bmaltais.drift toggle | on | off | open | close | status | set <key> <value>`
import QtQuick
import Quickshell
import Quickshell.Io
import "Palettes.js" as Palettes

Item {
  id: root
  property var shell: null

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy-drift"
  readonly property string settingsPath: stateDir + "/settings.json"

  // Settings (persisted).
  property bool lit: false
  property string atmosphere: "Ember"
  property bool wander: false
  property bool followDay: true
  property bool followWeather: false
  property real speed: 0.6
  property real grain: 0.4
  property real blobs: 6
  property real interaction: 0.7
  readonly property var keys: ["lit", "atmosphere", "wander", "followDay", "followWeather", "speed", "grain", "blobs", "interaction"]

  property bool loaded: false
  property bool cardOpen: false
  readonly property bool active: lit

  // Clock, local hour, weather.
  property real t: Math.random() * 1000
  property real hour: new Date().getHours() + new Date().getMinutes() / 60
  property var weather: null   // { name, temp, code, isDay }
  readonly property string condition: weather ? Palettes.conditionOf(weather.code) : "clear"
  readonly property string weatherText: weather ? Palettes.describe(weather.code) + ", " + Math.round(weather.temp) + "°" : ""
  readonly property var sky: followWeather && weather ? Palettes.skyFor(condition) : Palettes.skyFor("clear")
  readonly property var light: followDay ? Palettes.daylight(hour) : { brightness: 1, warmth: 0 }
  readonly property real brightness: light.brightness * sky.dim
  readonly property real warmth: light.warmth
  readonly property real desat: sky.desat
  readonly property real rain: sky.rain
  readonly property real snow: sky.snow

  // Cursor, global layout pixels (see the poller below).
  property real cursorX: -10000
  property real cursorY: -10000

  // Colours: crossfade to a new atmosphere, or wander through them all.
  property var fromRgb: Palettes.blend(Palettes.colorsFor("Ember", "clear"), Palettes.colorsFor("Ember", "clear"), 0)
  property var baseColors: Palettes.colorsFor("Ember", "clear")
  property real mixT: 1
  readonly property var shownRgb: Palettes.blend(fromRgb, baseColors, mixT)
  readonly property var colors: shownRgb.map(function(c) { return Qt.rgba(c.r, c.g, c.b, 1) })

  function retarget() {
    if (wander) return
    fromRgb = shownRgb
    baseColors = Palettes.colorsFor(atmosphere, condition)
    mixT = 0
    mixAnim.restart()
  }
  onAtmosphereChanged: { retarget(); touch() }
  onConditionChanged: if (atmosphere === "Weather") retarget()
  onWanderChanged: {
    touch()
    if (wander) { mixAnim.stop(); mixT = 1 }
    else retarget()
  }

  function wanderStep() {
    const names = Palettes.names
    const pos = (t / 45) % names.length
    const k = Math.floor(pos)
    const f = pos - k
    f = f * f * (3 - 2 * f)
    baseColors = Palettes.blend(Palettes.colorsFor(names[k], condition), Palettes.colorsFor(names[(k + 1) % names.length], condition), f)
    mixT = 1
  }

  NumberAnimation { id: mixAnim; target: root; property: "mixT"; from: 0; to: 1; duration: 1400; easing.type: Easing.InOutQuad }

  FrameAnimation {
    running: root.active
    onTriggered: {
      root.t += frameTime * root.speed
      if (root.wander) root.wanderStep()
    }
  }

  Timer {
    interval: 20000; running: root.active && root.followDay; repeat: true
    onTriggered: { const d = new Date(); root.hour = d.getHours() + d.getMinutes() / 60 }
  }

  // --- persistence ---
  Process { id: mkdir; command: ["mkdir", "-p", root.stateDir] }
  FileView {
    id: store
    path: root.settingsPath
    printErrors: false
    onLoaded: root.applySettings(text())
    onLoadFailed: root.loaded = true
  }

  function applySettings(raw) {
    try {
      const data = JSON.parse(raw)
      for (let i = 0; i < keys.length; i++) {
        const k = keys[i]
        if (data[k] !== undefined && typeof data[k] === typeof root[k]) root[k] = data[k]
      }
    } catch (e) {
      console.warn("drift: settings unreadable, using defaults")
    }
    root.loaded = true
  }

  Timer { id: saveTimer; interval: 400; onTriggered: root.save() }
  function save() {
    if (!loaded) return
    const out = {}
    for (let i = 0; i < keys.length; i++) out[keys[i]] = root[keys[i]]
    store.setText(JSON.stringify(out, null, 2) + "\n")
  }
  function touch() { if (loaded) saveTimer.restart() }
  onLitChanged: { touch(); syncStillLayer() }
  onFollowDayChanged: touch()
  onFollowWeatherChanged: { touch(); if (followWeather) fetchWeather() }
  onSpeedChanged: touch()
  onGrainChanged: touch()
  onBlobsChanged: touch()
  onInteractionChanged: touch()
  onLoadedChanged: if (loaded) { syncStillLayer(); if (followWeather) fetchWeather(); retarget() }

  Component.onCompleted: mkdir.running = true

  // --- the stock still wallpaper steps aside, the way a video wallpaper does ---
  property bool suspendedStill: false
  Process { id: suspendProc }
  function syncStillLayer() {
    if (!loaded) return
    if (lit === suspendedStill) return
    suspendedStill = lit
    suspendProc.command = ["omarchy-shell", "-q", "background", "setSuspended", lit ? "true" : "false"]
    suspendProc.running = true
  }
  // The stock background service may load after this one, so ask again once things have settled.
  Timer {
    interval: 3000; running: root.loaded && root.lit; repeat: false
    onTriggered: { root.suspendedStill = false; root.syncStillLayer() }
  }

  // --- weather: the location Omarchy's weather panel uses, else its IP lookup; Open-Meteo for the report ---
  readonly property string weatherScript: [
    'loc="$HOME/.local/state/omarchy/settings/weather.json"',
    'num="^-?[0-9]+(\\.[0-9]+)?$"',
    'read -r lat lon name < <(jq -r \'select(.latitude != null and .longitude != null) | "\\(.latitude) \\(.longitude) \\(.name // "")"\' "$loc" 2>/dev/null)',
    'if ! [[ $lat =~ $num && $lon =~ $num ]]; then',
    '  read -r lat lon name < <(curl -fsS --max-time 5 https://geo.omarchy.org/ | jq -r \'"\\(.latitude) \\(.longitude) \\(.name // "")"\')',
    'fi',
    '[[ $lat =~ $num && $lon =~ $num ]] || exit 1',
    'curl -fsS --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,is_day&timezone=auto" |',
    '  jq -c --arg name "$name" \'{name: $name, temp: .current.temperature_2m, code: .current.weather_code, isDay: .current.is_day}\''
  ].join("\n")

  Process {
    id: weatherProc
    command: ["bash", "-c", root.weatherScript]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const w = JSON.parse(text)
          if (typeof w.code === "number" && typeof w.temp === "number") root.weather = w
        } catch (e) { console.warn("drift: weather report unreadable") }
      }
    }
  }
  function fetchWeather() { if (!weatherProc.running) weatherProc.running = true }
  Timer { interval: 900000; running: root.active && root.followWeather; repeat: true; onTriggered: root.fetchWeather() }

  // --- pointer: a layer under the windows gets no pointer events, so ask the compositor ---
  Process {
    id: cursorProc
    running: root.active && root.interaction > 0
    command: ["bash", "-c", "while :; do hyprctl cursorpos; sleep 0.04; done"]
    stdout: SplitParser {
      onRead: function(line) {
        const m = /^(-?\d+),\s*(-?\d+)$/.exec(line.trim())
        if (m) { root.cursorX = parseInt(m[1]); root.cursorY = parseInt(m[2]) }
      }
    }
  }

  // --- IPC ---
  IpcHandler {
    target: "io.github.bmaltais.drift"
    function toggle(): void { root.lit = !root.lit }
    function on(): void { root.lit = true }
    function off(): void { root.lit = false }
    function open(): void { root.cardOpen = true }
    function close(): void { root.cardOpen = false }
    function set(key: string, value: string): void {
      if (root.keys.indexOf(key) < 0) return
      const cur = root[key]
      if (typeof cur === "boolean") root[key] = value === "true"
      else if (typeof cur === "number") { const n = parseFloat(value); if (!isNaN(n)) root[key] = n }
      else root[key] = value
    }
    // Preview a weather code (WMO: 61 rain, 71 snow, 95 storm) until the next real report.
    function preview(code: string): void { root.weather = { name: "preview", temp: 5, code: parseInt(code), isDay: 1 } }
    function status(): string {
      const out = {}
      for (let i = 0; i < root.keys.length; i++) out[root.keys[i]] = root[root.keys[i]]
      out.weather = root.weatherText
      out.cursor = [root.cursorX, root.cursorY]
      return JSON.stringify(out)
    }
  }

  Variants {
    model: Quickshell.screens
    DriftLayer { required property var modelData; screen: modelData; drift: root }
  }

  SettingsCard { drift: root }
}
