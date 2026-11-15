// The gradient itself: one shader bound to a Drift service. The wallpaper layer and the settings card's preview both use it.
import QtQuick

ShaderEffect {
  id: view
  required property var drift
  fragmentShader: Qt.resolvedUrl("shaders/drift.frag.qsb")

  property color c0: view.drift.colors[0]
  property color c1: view.drift.colors[1]
  property color c2: view.drift.colors[2]
  property color c3: view.drift.colors[3]
  property color c4: view.drift.colors[4]
  property color c5: view.drift.colors[5]
  property color c6: view.drift.colors[6]
  property color c7: view.drift.colors[7]
  property real time: view.drift.t
  property real aspect: width / Math.max(1, height)
  property real blobs: view.drift.blobs
  property real grain: view.drift.grain
  property real brightness: view.drift.brightness
  property real warmth: view.drift.warmth
  property real desat: view.drift.desat
  property real rain: view.drift.rain
  property real snow: view.drift.snow
  property real wind: view.drift.wind
  property real windDir: view.drift.windDir
}
