// Bar icon for Drift: left-click opens the settings card, right-click turns the wallpaper on or off.
import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.bmaltais.drift"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    slotSize: Style.bar.statusSlot
    tooltipText: "Drift wallpaper (right-click: on/off)"

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) root.bar.run("omarchy-shell -q io.github.bmaltais.drift toggle")
      else root.bar.run("omarchy-shell -q io.github.bmaltais.drift open")
    }
  }
}
