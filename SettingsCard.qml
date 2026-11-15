// The settings card, laid out after the macOS Drift app: `omarchy-shell io.github.bmaltais.drift open`. Escape or the red dot closes it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "Palettes.js" as Palettes

PanelWindow {
  id: win
  required property var drift

  readonly property color cardColor: "#1f1f1f"
  readonly property color rowColor: "#2a2a2a"
  readonly property color lineColor: "#383838"
  readonly property color chipColor: "#383838"
  readonly property color textColor: "#f0f0f0"
  readonly property color dimColor: "#8e8e8e"
  readonly property color accent: "#2f80ff"
  readonly property int headerHeight: 150
  readonly property var atmosphereNames: win.drift.generated.length === 8 ? Palettes.names.concat(["Generated"]) : Palettes.names

  visible: win.drift.cardOpen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  implicitWidth: 360
  implicitHeight: content.implicitHeight
  anchors { top: true; right: true }
  margins { top: 60; right: 24 }
  WlrLayershell.namespace: "omarchy-drift-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  component Separator: Rectangle { width: parent.width - 24; x: 12; height: 1; color: win.lineColor }

  component Heading: Text {
    color: win.textColor; font.pixelSize: 12; font.bold: true; leftPadding: 6; topPadding: 10; bottomPadding: 2
    textFormat: Text.PlainText
  }

  component Group: Rectangle {
    default property alias items: col.data
    width: parent.width; height: col.implicitHeight; radius: 10; color: win.rowColor
    Column { id: col; width: parent.width }
  }

  component Chip: Rectangle {
    id: chip
    property string label
    property alias glyph: glyphText.text
    signal clicked()
    height: 26; width: row.implicitWidth + 20; radius: 7; color: win.chipColor
    Row {
      id: row; anchors.centerIn: parent; spacing: 6
      Text { id: glyphText; visible: text !== ""; color: win.textColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
      Text { visible: chip.label !== ""; text: chip.label; color: win.textColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
    }
    MouseArea { anchors.fill: parent; onClicked: chip.clicked() }
  }

  component Toggle: Item {
    id: tg
    property string label
    property string hint: ""
    property bool checked: false
    default property alias trailing: extra.data
    signal flipped(bool value)
    width: parent.width
    height: hint ? 52 : 40
    Column {
      anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
      spacing: 2
      Text { text: tg.label; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText }
      Text { visible: tg.hint !== ""; text: tg.hint; color: win.dimColor; font.pixelSize: 11; textFormat: Text.PlainText }
    }
    Row {
      anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
      spacing: 10
      Row { id: extra; anchors.verticalCenter: parent.verticalCenter }
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 40; height: 22; radius: 11
        color: tg.checked ? win.accent : "#555"
        Rectangle { x: tg.checked ? 20 : 2; y: 2; width: 18; height: 18; radius: 9; color: "white"; Behavior on x { NumberAnimation { duration: 120 } } }
        MouseArea { anchors.fill: parent; onClicked: tg.flipped(!tg.checked) }
      }
    }
  }

  component SliderRow: Item {
    id: sl
    property string label
    property real from: 0
    property real to: 1
    property real value: 0
    property bool integer: false
    property int ticks: 0
    property bool showValue: false
    property string leftGlyph: ""
    property string rightGlyph: ""
    signal moved(real value)
    width: parent.width
    height: 40
    Text {
      anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
      text: sl.label; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText
    }
    Row {
      anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
      spacing: 8
      Text { text: sl.leftGlyph; width: 16; color: win.dimColor; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
      Item {
        id: track
        width: 150; height: 20; anchors.verticalCenter: parent.verticalCenter
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: "#555" }
        Repeater {
          model: sl.ticks
          Rectangle {
            required property int index
            x: 8 + (track.width - 16) * index / Math.max(1, sl.ticks - 1) - 1
            y: 15; width: 2; height: 2; color: win.dimColor
          }
        }
        Rectangle {
          id: handle
          y: 2; width: 16; height: 16; radius: 8; color: "white"
          x: (track.width - width) * (sl.value - sl.from) / (sl.to - sl.from)
        }
        MouseArea {
          anchors.fill: parent
          function pick(mx) {
            const f = Math.max(0, Math.min(1, (mx - 8) / (track.width - 16)))
            const v = sl.from + f * (sl.to - sl.from)
            sl.moved(sl.integer ? Math.round(v) : v)
          }
          onPressed: function(e) { pick(e.x) }
          onPositionChanged: function(e) { if (pressed) pick(e.x) }
        }
      }
      Text { text: sl.rightGlyph; width: 16; color: win.dimColor; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
      Text { text: sl.showValue ? Math.round(sl.value) : ""; color: win.dimColor; font.pixelSize: 12; width: 12; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: 14
    color: win.cardColor
    border.color: "#383838"
  }

  Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: win.drift.cardOpen = false }

  Column {
    id: content
    width: parent.width

    // Header: the live gradient, fading into the card.
    Item {
      width: parent.width; height: win.headerHeight
      Rectangle {
        anchors.fill: parent; radius: 14; clip: true; color: "black"
        DriftView { anchors.fill: parent; drift: win.drift }
      }
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 90
        gradient: Gradient {
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 1; color: win.cardColor }
        }
      }
      Rectangle {
        x: 14; y: 14; width: 12; height: 12; radius: 6; color: "#ff5f57"
        MouseArea { anchors.fill: parent; anchors.margins: -4; onClicked: win.drift.cardOpen = false }
      }
      Rectangle {
        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 12 }
        height: 22; width: pill.implicitWidth + 22; radius: 11; color: "#66000000"
        Row {
          id: pill; anchors.centerIn: parent; spacing: 6
          Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: win.drift.paused || !win.drift.lit ? win.dimColor : "#5ee06a" }
          Text {
            text: !win.drift.lit ? "Off" : win.drift.paused ? "Paused" : win.drift.restDrift && win.drift.pace < 0.05 ? "Resting" : "Evolving"
            color: win.textColor; font.pixelSize: 11; textFormat: Text.PlainText
          }
        }
        MouseArea { anchors.fill: parent; onClicked: win.drift.lit = !win.drift.lit }
      }
      Column {
        anchors { left: parent.left; leftMargin: 18; bottom: parent.bottom; bottomMargin: 6 }
        Text { text: "Drift"; color: "white"; font.pixelSize: 28; font.family: "serif"; textFormat: Text.PlainText }
        Text { text: "A quiet world, always becoming."; color: "#d0d0d0"; font.pixelSize: 11; textFormat: Text.PlainText }
      }
    }

    Column {
      x: 16; width: parent.width - 32
      bottomPadding: 14

      Heading { text: "Colour" }
      Group {
        Item {
          width: parent.width; height: 44
          Text {
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            text: "Atmosphere"; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText
          }
          Row {
            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 8
            Rectangle {
              id: dropButton
              height: 26; width: dropRow.implicitWidth + 18; radius: 7; color: dropMouse.containsMouse || dropdown.visible ? win.lineColor : "transparent"
              Row {
                id: dropRow; anchors.centerIn: parent; spacing: 8
                Text { text: win.drift.wander ? "Wandering" : win.drift.atmosphere; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText }
                Text { text: "⌃\n⌄"; color: win.dimColor; font.pixelSize: 8; lineHeight: 0.55; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
              }
              MouseArea { id: dropMouse; anchors.fill: parent; hoverEnabled: true; onClicked: dropdown.visible = !dropdown.visible }
            }
            Chip { label: "Generate"; glyph: "✦"; onClicked: { dropdown.visible = false; win.drift.generate() } }
          }
        }
        Separator {}
        Toggle { label: "Wander through palettes"; checked: win.drift.wander; onFlipped: function(v) { win.drift.wander = v } }
        Separator {}
        Toggle { label: "Follow the day"; hint: "Local light, slowly shifting"; checked: win.drift.followDay; onFlipped: function(v) { win.drift.followDay = v } }
        Separator {}
        Toggle {
          label: "Follow the weather"
          hint: win.drift.followWeather ? (win.drift.weatherText || "Looking up the weather…") : "Rain, snow and cloud on the glass"
          checked: win.drift.followWeather
          onFlipped: function(v) { win.drift.followWeather = v }
          Chip {
            visible: win.drift.followWeather && win.drift.weather !== null && win.drift.weather.name !== ""
            glyph: "➤"; label: win.drift.weather ? win.drift.weather.name.split(",")[0] : ""
          }
        }
      }

      Heading { text: "Motion" }
      Group {
        SliderRow { label: "Speed"; from: 0.05; to: 3; value: win.drift.speed; leftGlyph: "🐢"; rightGlyph: "🐇"; onMoved: function(v) { win.drift.speed = v } }
        Separator {}
        Toggle { label: "Rest & drift"; hint: "Hold still, then gently drift for 30 seconds"; checked: win.drift.restDrift; onFlipped: function(v) { win.drift.restDrift = v } }
      }

      Heading { text: "Shape" }
      Group {
        SliderRow { label: "Grain"; from: 0; to: 1; value: win.drift.grain; onMoved: function(v) { win.drift.grain = v } }
        Separator {}
        SliderRow { label: "Blobs"; from: 2; to: 8; integer: true; ticks: 7; showValue: true; value: win.drift.blobs; onMoved: function(v) { win.drift.blobs = v } }
      }
    }

    Rectangle { width: parent.width; height: 1; color: win.lineColor }
    Item {
      width: parent.width; height: 50
      Row {
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        spacing: 8
        Chip { glyph: win.drift.paused ? "▶" : "⏸"; onClicked: win.drift.paused = !win.drift.paused }
        Chip { glyph: "⤮"; onClicked: win.drift.shuffle() }
      }
    }
  }

  // The atmosphere list opens over the rows below it, inside the card.
  Rectangle {
    id: dropdown
    visible: false
    z: 10
    x: win.width - width - 24
    y: win.headerHeight + 62
    width: 150; height: list.implicitHeight + 12; radius: 9
    color: "#2f2f2f"; border.color: "#454545"
    Column {
      id: list
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
      Repeater {
        model: win.atmosphereNames
        Rectangle {
          id: entry
          required property string modelData
          readonly property bool picked: !win.drift.wander && win.drift.atmosphere === modelData
          width: list.width; height: 26; radius: 6
          color: entryMouse.containsMouse ? win.accent : "transparent"
          Text { x: 8; anchors.verticalCenter: parent.verticalCenter; text: entry.picked ? "✓" : ""; color: win.textColor; font.pixelSize: 12; textFormat: Text.PlainText }
          Text { x: 26; anchors.verticalCenter: parent.verticalCenter; text: entry.modelData; color: win.textColor; font.pixelSize: 13; textFormat: Text.PlainText }
          MouseArea {
            id: entryMouse; anchors.fill: parent; hoverEnabled: true
            onClicked: { win.drift.wander = false; win.drift.atmosphere = entry.modelData; dropdown.visible = false }
          }
        }
      }
    }
  }
}
