// The settings card: `omarchy-shell io.github.bmaltais.drift open`. Escape or the close button hides it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "Palettes.js" as Palettes

PanelWindow {
  id: win
  required property var drift

  readonly property color cardColor: "#232323"
  readonly property color rowColor: "#2c2c2c"
  readonly property color textColor: "#f0f0f0"
  readonly property color dimColor: "#9a9a9a"
  readonly property color accent: "#3b82f6"

  visible: drift.cardOpen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: 340
  implicitHeight: body.implicitHeight + 32
  anchors { top: true; right: true }
  margins { top: 60; right: 24 }
  WlrLayershell.namespace: "omarchy-drift-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  component Toggle: Item {
    id: tg
    property string label
    property string hint: ""
    property bool checked: false
    signal flipped(bool value)
    width: parent.width
    height: hint ? 52 : 40
    Column {
      anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
      spacing: 2
      Text { text: tg.label; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText }
      Text { visible: tg.hint !== ""; text: tg.hint; color: win.dimColor; font.pixelSize: 11; textFormat: Text.PlainText }
    }
    Rectangle {
      anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
      width: 38; height: 22; radius: 11
      color: tg.checked ? win.accent : "#555"
      Rectangle { x: tg.checked ? 18 : 2; y: 2; width: 18; height: 18; radius: 9; color: "white"; Behavior on x { NumberAnimation { duration: 120 } } }
    }
    MouseArea { anchors.fill: parent; onClicked: tg.flipped(!tg.checked) }
  }

  component SliderRow: Item {
    id: sl
    property string label
    property real from: 0
    property real to: 1
    property real value: 0
    property bool integer: false
    signal moved(real value)
    width: parent.width
    height: 40
    Text {
      anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
      text: sl.label; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText
    }
    Item {
      id: track
      anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
      width: 160; height: 20
      Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: "#555" }
      Rectangle { anchors.verticalCenter: parent.verticalCenter; width: handle.x + 8; height: 4; radius: 2; color: win.accent }
      Rectangle {
        id: handle
        y: 2; width: 16; height: 16; radius: 8; color: "white"
        x: (track.width - width) * (sl.value - sl.from) / (sl.to - sl.from)
      }
      MouseArea {
        anchors.fill: parent
        function pick(mx) {
          var f = Math.max(0, Math.min(1, (mx - 8) / (track.width - 16)))
          var v = sl.from + f * (sl.to - sl.from)
          sl.moved(sl.integer ? Math.round(v) : v)
        }
        onPressed: function(e) { pick(e.x) }
        onPositionChanged: function(e) { if (pressed) pick(e.x) }
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: 14
    color: win.cardColor
    border.color: "#3a3a3a"
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.drift.cardOpen = false
  }

  Column {
    id: body
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
    spacing: 6

    Item {
      width: parent.width; height: 44
      Column {
        anchors.verticalCenter: parent.verticalCenter
        Text { text: "Drift"; color: win.textColor; font.pixelSize: 22; font.family: "serif"; textFormat: Text.PlainText }
        Text { text: "A quiet world, always becoming."; color: win.dimColor; font.pixelSize: 11; textFormat: Text.PlainText }
      }
      Text {
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        text: "✕"; color: win.dimColor; font.pixelSize: 14
        MouseArea { anchors.fill: parent; anchors.margins: -8; onClicked: win.drift.cardOpen = false }
      }
    }

    Rectangle {
      width: parent.width; height: switchCol.implicitHeight; radius: 10; color: win.rowColor
      Column {
        id: switchCol
        width: parent.width
        Toggle { label: "Drift wallpaper"; hint: win.drift.lit ? "Replacing the still wallpaper" : "Off, your normal wallpaper shows"; checked: win.drift.lit; onFlipped: function(v) { win.drift.lit = v } }
      }
    }

    Text { text: "Colour"; color: win.textColor; font.pixelSize: 12; font.bold: true; leftPadding: 4; topPadding: 6 }
    Rectangle {
      width: parent.width; height: colourCol.implicitHeight; radius: 10; color: win.rowColor
      Column {
        id: colourCol
        width: parent.width
        Flow {
          width: parent.width - 24; x: 12; spacing: 6; topPadding: 10; bottomPadding: 8
          Repeater {
            model: Palettes.names
            Rectangle {
              required property string modelData
              readonly property bool picked: win.drift.atmosphere === modelData && !win.drift.wander
              height: 26; width: chipText.implicitWidth + 28; radius: 13
              color: picked ? win.accent : "#3a3a3a"
              Row {
                anchors.centerIn: parent; spacing: 6
                Rectangle {
                  width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter
                  gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Palettes.colorsFor(modelData, "clear")[0] }
                    GradientStop { position: 1; color: Palettes.colorsFor(modelData, "clear")[1] }
                  }
                }
                Text { id: chipText; text: modelData; color: win.textColor; font.pixelSize: 12; textFormat: Text.PlainText }
              }
              MouseArea { anchors.fill: parent; onClicked: { win.drift.wander = false; win.drift.atmosphere = modelData } }
            }
          }
        }
        Toggle { label: "Wander through palettes"; checked: win.drift.wander; onFlipped: function(v) { win.drift.wander = v } }
        Toggle { label: "Follow the day"; hint: "Local light, slowly shifting"; checked: win.drift.followDay; onFlipped: function(v) { win.drift.followDay = v } }
        Toggle {
          label: "Follow the weather"
          hint: win.drift.followWeather ? (win.drift.weatherText || "Looking up the weather…") : "Rain, snow and cloud on the glass"
          checked: win.drift.followWeather
          onFlipped: function(v) { win.drift.followWeather = v }
        }
      }
    }

    Text { text: "Motion"; color: win.textColor; font.pixelSize: 12; font.bold: true; leftPadding: 4; topPadding: 6 }
    Rectangle {
      width: parent.width; height: motionCol.implicitHeight; radius: 10; color: win.rowColor
      Column {
        id: motionCol
        width: parent.width
        SliderRow { label: "Speed"; from: 0.05; to: 3; value: win.drift.speed; onMoved: function(v) { win.drift.speed = v } }
        SliderRow { label: "Interaction"; from: 0; to: 1; value: win.drift.interaction; onMoved: function(v) { win.drift.interaction = v } }
      }
    }

    Text { text: "Shape"; color: win.textColor; font.pixelSize: 12; font.bold: true; leftPadding: 4; topPadding: 6 }
    Rectangle {
      width: parent.width; height: shapeCol.implicitHeight; radius: 10; color: win.rowColor
      Column {
        id: shapeCol
        width: parent.width
        SliderRow { label: "Grain"; from: 0; to: 1; value: win.drift.grain; onMoved: function(v) { win.drift.grain = v } }
        SliderRow { label: "Blobs"; from: 2; to: 8; integer: true; value: win.drift.blobs; onMoved: function(v) { win.drift.blobs = v } }
      }
    }
  }
}
