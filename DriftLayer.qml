// One wallpaper window: a full-screen shader on the Background layer, click-through so the stock desktop layer keeps its clicks.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: win
  required property var drift

  color: "black"
  visible: win.drift.active
  mask: Region {}
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "omarchy-drift"
  WlrLayershell.layer: WlrLayer.Background
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  anchors { top: true; bottom: true; left: true; right: true }

  ShaderEffect {
    anchors.fill: parent
    fragmentShader: Qt.resolvedUrl("shaders/drift.frag.qsb")

    property color c0: win.drift.colors[0]
    property color c1: win.drift.colors[1]
    property color c2: win.drift.colors[2]
    property color c3: win.drift.colors[3]
    property color c4: win.drift.colors[4]
    property color c5: win.drift.colors[5]
    property color c6: win.drift.colors[6]
    property color c7: win.drift.colors[7]
    property real time: win.drift.t
    property real aspect: width / Math.max(1, height)
    property real blobs: win.drift.blobs
    property real grain: win.drift.grain
    property real brightness: win.drift.brightness
    property real warmth: win.drift.warmth
    property real desat: win.drift.desat
    property real rain: win.drift.rain
    property real snow: win.drift.snow
  }
}
