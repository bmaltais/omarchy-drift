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
}
