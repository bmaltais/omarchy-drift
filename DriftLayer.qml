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

  DriftView { anchors.fill: parent; drift: win.drift }

  // Optional time caption, bottom left, after the Drift app's "Follow the day" demo.
  Column {
    visible: win.drift.showTime
    anchors { left: parent.left; leftMargin: 56; bottom: parent.bottom; bottomMargin: 48 }
    spacing: 4
    Text {
      visible: win.drift.followDay
      text: "FOLLOW THE DAY"
      color: "#c0ffffff"; font.pixelSize: 13; font.weight: Font.DemiBold; font.letterSpacing: 3.5; font.family: "monospace"
      textFormat: Text.PlainText
    }
    Text {
      text: win.drift.clockText
      color: "white"; font.pixelSize: 56; font.family: "Noto Serif"
      textFormat: Text.PlainText
    }
  }
}
