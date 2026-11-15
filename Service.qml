// Drift: an animated gradient wallpaper. State lives here; DriftLayer draws it, SettingsCard edits it.
// `omarchy-shell io.github.bmaltais.drift toggle | on | off | open | close | status | set <key> <value>`
pragma ComponentBehavior: Bound
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
  property bool restDrift: false
  property var generated: []
  property bool showTime: false
  property var location: null   // { name, latitude, longitude }; null = use Omarchy's weather location
  readonly property var keys: ["lit", "atmosphere", "wander", "followDay", "followWeather", "speed", "grain", "blobs", "restDrift", "generated", "showTime", "location"]

  property bool loaded: false
  property bool cardOpen: false
  property bool paused: false
  property real pace: 1
  property real restClock: 0
  readonly property bool active: lit

  // Clock, local hour, weather.
  property real t: Math.random() * 1000
  property real hour: new Date().getHours() + new Date().getMinutes() / 60
  property var weather: null   // { name, temp, code, isDay }
  readonly property string condition: weather ? Palettes.conditionOf(weather.code) : "clear"
  readonly property string weatherText: weather ? Palettes.describe(weather.code) + ", " + Math.round(weather.temp) + "°" + (weather.wind >= 5 ? ", wind " + Math.round(weather.wind) + " km/h" : "") : ""
  readonly property var sky: followWeather && weather ? Palettes.skyFor(condition) : Palettes.skyFor("clear")
  readonly property var light: followDay ? Palettes.daylight(hour) : { brightness: 1, warmth: 0 }
  readonly property real brightness: light.brightness * sky.dim
  readonly property real warmth: light.warmth
  readonly property real desat: sky.desat
  readonly property real rain: sky.rain
  readonly property real snow: sky.snow
  // Wind from the weather report: 0 calm .. 1 at 45 km/h and up; direction in radians.
  readonly property real wind: followWeather && weather && weather.wind ? Math.min(1, weather.wind / 45) : 0
  readonly property real windDir: weather && weather.windDir ? weather.windDir * Math.PI / 180 : 0

  // Colours: crossfade to a new atmosphere, or wander through them all.
  property var fromRgb: Palettes.blend(Palettes.colorsFor("Ember", "clear"), Palettes.colorsFor("Ember", "clear"), 0)
  property var baseColors: Palettes.colorsFor("Ember", "clear")
  property real mixT: 1
  readonly property var shownRgb: Palettes.blend(fromRgb, baseColors, mixT)
  // Follow the day pulls the palette toward the sky's colours for the hour.
  property real skyMix: followDay ? 0.65 : 0
  Behavior on skyMix { NumberAnimation { duration: 1200 } }
  readonly property var mixedRgb: skyMix > 0.001 ? Palettes.blend(shownRgb, Palettes.skyAt(hour), skyMix) : shownRgb
  readonly property var colors: mixedRgb.map(function(c) { return Qt.rgba(c.r, c.g, c.b, 1) })

  // The time caption on the wallpaper.
  property string clockText: Qt.formatTime(new Date(), "HH:mm")
  Timer { interval: 5000; running: root.active && root.showTime; repeat: true; triggeredOnStart: true; onTriggered: root.clockText = Qt.formatTime(new Date(), "HH:mm") }

  function generate() {
    generated = Palettes.generate()
    wander = false
    atmosphere = "Generated"
  }
  function shuffle() {
    const names = Palettes.names
    wander = false
    atmosphere = names[Math.floor(Math.random() * names.length)]
  }

  function retarget() {
    if (wander) return
    fromRgb = shownRgb
    baseColors = Palettes.colorsFor(atmosphere, condition, generated, hour)
    mixT = 0
    mixAnim.restart()
  }
  onAtmosphereChanged: { retarget(); touch() }
  onGeneratedChanged: { if (atmosphere === "Generated") retarget(); touch() }
  onHourChanged: if (atmosphere === "Day") retarget()
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
    baseColors = Palettes.blend(Palettes.colorsFor(names[k], condition, generated, hour), Palettes.colorsFor(names[(k + 1) % names.length], condition, generated, hour), f)
    mixT = 1
  }

  NumberAnimation { id: mixAnim; target: root; property: "mixT"; from: 0; to: 1; duration: 1400; easing.type: Easing.InOutQuad }

  FrameAnimation {
    running: root.active && !root.paused
    onTriggered: {
      // Rest & drift: 30 s still, 30 s moving, eased over 3 s at each change.
      if (root.restDrift) {
        root.restClock += frameTime
        const ph = root.restClock % 60
        root.pace = ph < 30 ? 0 : Math.min(1, (ph - 30) / 3) * Math.min(1, (60 - ph) / 3)
      } else root.pace = 1
      root.t += frameTime * root.speed * root.pace
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
        if (k === "generated") { if (Palettes.validGenerated(data[k])) root[k] = data[k] }
        else if (k === "location") {
          const l = data[k]
          if (l && typeof l.name === "string" && isFinite(l.latitude) && isFinite(l.longitude)) root.location = { name: l.name, latitude: Number(l.latitude), longitude: Number(l.longitude) }
        }
        else if (data[k] !== undefined && typeof data[k] === typeof root[k]) root[k] = data[k]
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
  onFollowWeatherChanged: { touch(); if (loaded && followWeather) fetchWeather() }
  onSpeedChanged: touch()
  onGrainChanged: touch()
  onBlobsChanged: touch()
  onRestDriftChanged: touch()
  onShowTimeChanged: touch()
  onLocationChanged: {
    if (!loaded) return
    touch()
    weather = null
    refetchWeather()
  }
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
    'num="^-?[0-9]+(\\.[0-9]+)?$"',
    'if [[ -n ${1:-} ]]; then',
    '  lat=$1; lon=$2; name=${3:-}',
    'else',
    '  loc="$HOME/.local/state/omarchy/settings/weather.json"',
    '  read -r lat lon name < <(jq -r \'select(.latitude != null and .longitude != null) | "\\(.latitude) \\(.longitude) \\(.name // "")"\' "$loc" 2>/dev/null)',
    '  if ! [[ $lat =~ $num && $lon =~ $num ]]; then',
    '    read -r lat lon name < <(curl -fsS --max-time 5 https://geo.omarchy.org/ | jq -r \'"\\(.latitude) \\(.longitude) \\(.name // "")"\')',
    '  fi',
    'fi',
    '[[ $lat =~ $num && $lon =~ $num ]] || exit 1',
    'curl -fsS --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m&timezone=auto" |',
    '  jq -c --arg name "$name" \'{name: $name, temp: .current.temperature_2m, code: .current.weather_code, isDay: .current.is_day, wind: .current.wind_speed_10m, windDir: .current.wind_direction_10m}\''
  ].join("\n")

  // A failed fetch (no network yet at login, a timeout) is retried with a growing delay, so the weather is not
  // missing until the next 15 minute tick.
  property int retryDelay: 15000
  Timer { id: retryTimer; onTriggered: root.fetchWeather() }
  function weatherFailed() {
    if (!followWeather || !active) return
    retryTimer.interval = retryDelay
    retryTimer.restart()
    retryDelay = Math.min(retryDelay * 2, 300000)
  }

  Process {
    id: weatherProc
    stdout: StdioCollector {
      onStreamFinished: {
        if (root.weatherPending) return   // superseded by a newer location; its restart follows the exit
        let ok = false
        try {
          const w = JSON.parse(text)
          if (typeof w.code === "number" && typeof w.temp === "number") {
            root.weather = w
            if (!root.location) root.autoName = String(w.name || "").split(",")[0]
            root.retryDelay = 15000
            ok = true
          }
        } catch (e) { /* empty or unreadable output: handled below */ }
        if (!ok) root.weatherFailed()
      }
    }
    onExited: if (root.weatherPending) { root.weatherPending = false; root.fetchWeather() }
  }
  // The command is built here, not bound: a change handler runs before bindings re-evaluate, and would fetch the old place.
  function fetchWeather() {
    if (weatherProc.running) return
    weatherProc.command = location
      ? ["bash", "-c", weatherScript, "drift", String(location.latitude), String(location.longitude), location.name]
      : ["bash", "-c", weatherScript]
    weatherProc.running = true
  }
  // A new location while a fetch runs: the running one is superseded (its result is ignored) and a new one starts once
  // that process has exited. Starting before it exits would be refused.
  property bool weatherPending: false
  function refetchWeather() {
    if (!followWeather) return
    if (weatherProc.running) { weatherPending = true; weatherProc.running = false }
    else fetchWeather()
  }

  // --- city search (Open-Meteo geocoding): only the typed text leaves the machine ---
  property var places: []
  property string autoName: ""   // the city found automatically, shown next to "Current location"
  property string placeQuery: ""
  property bool searching: false
  property bool searchAgain: false
  function search(q) {
    placeQuery = String(q).trim()
    if (placeQuery.length < 2) { places = []; searching = false; return }
    searching = true
    placeTimer.restart()
  }
  function runSearch() {
    if (geoProc.running) { searchAgain = true; return }
    geoProc.command = ["curl", "-fsS", "--max-time", "6", "-G", "https://geocoding-api.open-meteo.com/v1/search",
      "--data-urlencode", "name=" + placeQuery, "--data-urlencode", "count=6", "--data-urlencode", "language=en"]
    geoProc.running = true
  }
  function chooseLocation(place) { location = { name: place.name, latitude: place.latitude, longitude: place.longitude } }
  function useOmarchyLocation() { location = null }
  Timer { id: placeTimer; interval: 350; onTriggered: root.runSearch() }
  Process {
    id: geoProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const found = JSON.parse(text).results || []
          root.places = found.filter(function(r) { return r.name && isFinite(r.latitude) && isFinite(r.longitude) }).map(function(r) {
            return { name: String(r.name), region: [r.admin1, r.country].filter(function(x) { return !!x }).join(", "), latitude: Number(r.latitude), longitude: Number(r.longitude) }
          })
        } catch (e) { root.places = [] }
        root.searching = false
      }
    }
    onExited: if (root.searchAgain) { root.searchAgain = false; root.runSearch() }
  }
  Timer { interval: 900000; running: root.active && root.followWeather; repeat: true; onTriggered: root.fetchWeather() }

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
      else if (typeof cur === "string") root[key] = value
    }
    // Preview a weather code (WMO: 61 rain, 71 snow, 95 storm) and a wind in km/h until the next real report.
    function preview(code: string, windKmh: string): void { root.weather = { name: "preview", temp: 5, code: parseInt(code), isDay: 1, wind: parseFloat(windKmh) || 0, windDir: 250 } }
    function generate(): void { root.generate() }
    function shuffle(): void { root.shuffle() }
    // Preview a local hour (21.9 = 21:54) until the next 20 s clock tick.
    function previewHour(h: string): void { const n = parseFloat(h); if (!isNaN(n)) root.hour = n }
    function setLocation(name: string, lat: string, lon: string): void {
      if (isFinite(parseFloat(lat)) && isFinite(parseFloat(lon))) root.location = { name: name, latitude: parseFloat(lat), longitude: parseFloat(lon) }
    }
    function clearLocation(): void { root.useOmarchyLocation() }
    function status(): string {
      const out = {}
      for (let i = 0; i < root.keys.length; i++) out[root.keys[i]] = root[root.keys[i]]
      out.weather = root.weatherText
      return JSON.stringify(out)
    }
  }

  Variants {
    model: Quickshell.screens
    DriftLayer { required property var modelData; screen: modelData; drift: root }
  }

  SettingsCard { drift: root }
}
