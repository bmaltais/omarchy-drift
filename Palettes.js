.pragma library

// Eight colours per atmosphere; a blob count under 8 uses the first N.
var atmospheres = {
  "Ember":  ["#c9362e", "#7a1540", "#d9532b", "#9e2236", "#e0724f", "#5e1238", "#b83a3a", "#c96a55"],
  "Iris":   ["#3a4fc4", "#7b5ec0", "#c43a8e", "#a63f2e", "#5a52c8", "#9a4fb8", "#d0507a", "#8a64c8"],
  "Lagoon": ["#2b9bb5", "#2a2f9a", "#35b0c0", "#1f4aa8", "#4fc0cc", "#1c2680", "#2a7fb8", "#7ad0d8"],
  "Dusk":   ["#e0703a", "#7a3a8a", "#2f3a8a", "#d04a6a", "#f0a050", "#4a2a7a", "#b04a8a", "#24306a"],
  "Aurora": ["#1f9e7a", "#2a4fb0", "#6a3fb8", "#25c0a0", "#1a3a80", "#8a50d0", "#3ab0d0", "#143a5a"],
  "Sage":   ["#6a8a6a", "#a8b890", "#3f5f50", "#c8c8a0", "#587a6a", "#8aa088", "#2f4a42", "#b0c0a8"],
  "Mono":   ["#3a3a40", "#6a6a74", "#1e1e24", "#8a8a94", "#505058", "#2a2a30", "#74747e", "#46464e"]
}

// What "Weather" looks like for each condition.
var weatherAtmospheres = {
  "clear":  ["#3a9ad9", "#f0c060", "#5ab0e8", "#2a70c0", "#f5d890", "#4a88d0", "#82c4ee", "#e8a850"],
  "cloudy": ["#7a8a9a", "#a0aab4", "#5a6a7c", "#8a98a8", "#6a7a8c", "#b4bcc4", "#4a5a6c", "#94a0ac"],
  "fog":    ["#a8b0b8", "#c4c8cc", "#8c949c", "#b8bec4", "#98a0a8", "#d0d4d8", "#7c848c", "#acb4bc"],
  "rain":   ["#2b9bb5", "#2a2f9a", "#35a0b8", "#1f3a98", "#3a8fa8", "#1c2680", "#2a6aa8", "#4a7fb8"],
  "snow":   ["#c8d8e8", "#e8eef4", "#a8bcd0", "#f0f4f8", "#b8c8d8", "#d8e4ee", "#90a8c0", "#e0e8f0"],
  "storm":  ["#3a2a6a", "#1a1a3a", "#5a3a8a", "#242a5a", "#4a2a7a", "#12122c", "#6a4a9a", "#2a2050"]
}

var names = ["Ember", "Iris", "Lagoon", "Dusk", "Aurora", "Sage", "Mono", "Weather"]

function conditionOf(code) {
  // WMO weather codes as returned by Open-Meteo.
  if (code === 0 || code === 1) return "clear"
  if (code === 2 || code === 3) return "cloudy"
  if (code === 45 || code === 48) return "fog"
  if (code >= 95) return "storm"
  if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow"
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rain"
  return "clear"
}

function describe(code) {
  var c = conditionOf(code)
  if (c === "clear") return code === 0 ? "Clear" : "Mostly clear"
  if (c === "cloudy") return code === 2 ? "Partly cloudy" : "Overcast"
  return { fog: "Fog", rain: "Rain", snow: "Snow", storm: "Thunderstorm" }[c]
}

function colorsFor(name, condition) {
  if (name === "Weather") return weatherAtmospheres[condition] || weatherAtmospheres.clear
  return atmospheres[name] || atmospheres.Ember
}

function hex(h) {
  return { r: parseInt(h.substr(1, 2), 16) / 255, g: parseInt(h.substr(3, 2), 16) / 255, b: parseInt(h.substr(5, 2), 16) / 255 }
}

// A linear blend of two colour lists (hex strings or {r,g,b}), as plain {r,g,b} objects.
function blend(a, b, t) {
  var out = []
  for (var i = 0; i < 8; i++) {
    var x = typeof a[i] === "string" ? hex(a[i]) : a[i]
    var y = typeof b[i] === "string" ? hex(b[i]) : b[i]
    out.push({ r: x.r + (y.r - x.r) * t, g: x.g + (y.g - x.g) * t, b: x.b + (y.b - x.b) * t })
  }
  return out
}

// Follow the day: brightness and warmth from the local hour (0..24). Dawn and dusk are warm, night is dark and cool.
function daylight(hour) {
  var day = Math.max(0, Math.sin(Math.PI * (hour - 6) / 12))
  var warm = Math.exp(-Math.pow(hour - 7, 2) / 2) + Math.exp(-Math.pow(hour - 18.5, 2) / 2)
  return { brightness: 0.45 + 0.55 * Math.sqrt(day), warmth: warm * 0.9 - (1 - day) * 0.45 }
}

// Weather -> shader inputs.
function skyFor(condition) {
  switch (condition) {
    case "cloudy": return { desat: 0.35, rain: 0, snow: 0, dim: 0.95 }
    case "fog":    return { desat: 0.6,  rain: 0, snow: 0, dim: 1.0 }
    case "rain":   return { desat: 0.15, rain: 1, snow: 0, dim: 0.88 }
    case "snow":   return { desat: 0.2,  rain: 0, snow: 1, dim: 1.0 }
    case "storm":  return { desat: 0.1,  rain: 1, snow: 0, dim: 0.7 }
    default:       return { desat: 0,    rain: 0, snow: 0, dim: 1.0 }
  }
}
