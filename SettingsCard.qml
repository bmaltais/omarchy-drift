// The settings card, laid out after the macOS Drift app: `omarchy-shell io.github.bmaltais.drift open`. Escape or the ✕ closes it.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "Palettes.js" as Palettes

PanelWindow {
  id: win
  required property var drift

  readonly property color cardColor: "#1c1c1c"
  readonly property color rowColor: "#272727"
  readonly property color lineColor: "#363636"
  readonly property color chipColor: "#363636"
  readonly property color textColor: "#f2f2f2"
  readonly property color dimColor: "#8a8a8a"
  readonly property color accent: "#1a7bff"
  readonly property int headerHeight: 140
  readonly property var atmosphereNames: win.drift.generated.length === 8 ? Palettes.names.concat(["Generated"]) : Palettes.names

  visible: win.drift.cardOpen
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  // The window is larger than the card by `pad` on every side: room for the drop shadow.
  readonly property int pad: 28
  readonly property int cardWidth: 372
  implicitWidth: cardWidth + 2 * pad
  implicitHeight: content.implicitHeight + 2 * pad
  anchors { top: true; right: true }
  margins { top: 60 - pad; right: 24 - pad }
  // Only the card takes pointer input; the shadow margin lets clicks through.
  mask: Region { item: card }
  WlrLayershell.namespace: "omarchy-drift-settings"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

  component Separator: Rectangle { width: parent.width - 28; x: 14; height: 1; color: win.lineColor }

  component Heading: Text {
    color: win.textColor; font.pixelSize: 13; font.bold: true; leftPadding: 8; topPadding: 22; bottomPadding: 6
    textFormat: Text.PlainText
  }

  component Group: Rectangle {
    default property alias items: col.data
    width: parent.width; height: col.implicitHeight; radius: 10; color: win.rowColor
    Column { id: col; width: parent.width }
  }

  // A small rounded button: icon text and/or label.
  component Chip: Rectangle {
    id: chip
    property string label
    property alias glyph: glyphText.text
    property int chipHeight: 28
    default property alias custom: customRow.data
    signal clicked()
    height: chipHeight; width: row.implicitWidth + 22; radius: 8; color: chipMouse.containsMouse ? "#424242" : win.chipColor
    Row {
      id: row; anchors.centerIn: parent; spacing: 7
      Row { id: customRow; anchors.verticalCenter: parent.verticalCenter }
      Text { id: glyphText; visible: text !== ""; color: win.textColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
      Text { visible: chip.label !== ""; text: chip.label; color: win.textColor; font.pixelSize: 13; font.weight: Font.Medium; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
    }
    MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; onClicked: chip.clicked() }
  }

  // Footer pill: fully rounded, with a drawn icon (font glyphs for these come out as emoji).
  component Pill: Rectangle {
    id: pill
    default property alias icon: slot.data
    signal clicked()
    height: 28; width: 58; radius: 14; color: pillMouse.containsMouse ? "#424242" : win.chipColor
    Item { id: slot; anchors.centerIn: parent; width: 14; height: 14 }
    MouseArea { id: pillMouse; anchors.fill: parent; hoverEnabled: true; onClicked: pill.clicked() }
  }

  component Toggle: Item {
    id: tg
    property string label
    property string hint: ""
    property bool checked: false
    default property alias trailing: extra.data
    signal flipped(bool value)
    width: parent.width
    height: hint ? 56 : 42
    Column {
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      spacing: 2
      Text { text: tg.label; color: win.textColor; font.pixelSize: 14; textFormat: Text.PlainText }
      Text { visible: tg.hint !== ""; text: tg.hint; color: win.dimColor; font.pixelSize: 11; textFormat: Text.PlainText }
    }
    Row {
      anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
      spacing: 10
      Row { id: extra; anchors.verticalCenter: parent.verticalCenter }
      // macOS switch: blue when on, light grey when off, white knob.
      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 38; height: 22; radius: 11
        color: tg.checked ? win.accent : "#d6d6d6"
        Behavior on color { ColorAnimation { duration: 120 } }
        Rectangle {
          x: tg.checked ? 17 : 2; y: 2; width: 18; height: 18; radius: 9; color: "white"
          border.color: tg.checked ? "transparent" : "#c4c4c4"
          Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
        }
        MouseArea { anchors.fill: parent; onClicked: tg.flipped(!tg.checked) }
      }
    }
  }

  // The slow / fast animals, greyed so they read as silhouettes.
  component Animal: Text {
    width: 26; height: 22; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    font.pixelSize: 20; textFormat: Text.PlainText
    layer.enabled: true
    layer.effect: MultiEffect { saturation: -1.0; brightness: 0.1; contrast: -0.15 }
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
    height: 42
    Text {
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      text: sl.label; color: win.textColor; font.pixelSize: 14; textFormat: Text.PlainText
    }
    Row {
      anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
      spacing: 8
      Animal { visible: sl.leftGlyph !== ""; text: sl.leftGlyph; anchors.verticalCenter: parent.verticalCenter }
      Item {
        id: track
        width: 158; height: 22; anchors.verticalCenter: parent.verticalCenter
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: "#474747" }
        Repeater {
          model: sl.ticks
          Rectangle {
            required property int index
            x: 9 + (track.width - 18) * index / Math.max(1, sl.ticks - 1) - 1
            y: 18; width: 2; height: 2; radius: 1; color: "#6a6a6a"
          }
        }
        Rectangle {
          id: handle
          y: 2; width: 18; height: 18; radius: 9; color: "white"
          x: (track.width - width) * (sl.value - sl.from) / (sl.to - sl.from)
          layer.enabled: true
          layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#80000000"; shadowBlur: 0.5; shadowVerticalOffset: 1 }
        }
        MouseArea {
          anchors.fill: parent
          function pick(mx) {
            const f = Math.max(0, Math.min(1, (mx - 9) / (track.width - 18)))
            const v = sl.from + f * (sl.to - sl.from)
            sl.moved(sl.integer ? Math.round(v) : v)
          }
          onPressed: function(e) { pick(e.x) }
          onPositionChanged: function(e) { if (pressed) pick(e.x) }
        }
      }
      Animal { visible: sl.rightGlyph !== ""; text: sl.rightGlyph; anchors.verticalCenter: parent.verticalCenter }
      Text { visible: sl.showValue; text: Math.round(sl.value); color: win.dimColor; font.pixelSize: 13; width: 20; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
    }
  }

  Item {
    id: card
    x: win.pad; y: win.pad
    width: win.cardWidth; height: content.implicitHeight

  // The window: dark body, hairline border, soft drop shadow.
  Rectangle {
    anchors.fill: parent
    radius: 14
    color: win.cardColor
    border.color: "#3a3a3a"
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#c0000000"; shadowBlur: 1.0; shadowVerticalOffset: 10; shadowScale: 1.0 }
  }

  Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: win.drift.cardOpen = false }

  Column {
    id: content
    width: parent.width

    // Header: the live gradient with a hard lower edge, only the top corners rounded.
    Item {
      width: parent.width; height: win.headerHeight
      Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect { maskEnabled: true; maskSource: headerMask }
        DriftView { anchors.fill: parent; drift: win.drift }
      }
      Item {
        id: headerMask
        anchors.fill: parent; visible: false; layer.enabled: true
        Rectangle { anchors.fill: parent; radius: 14 }
        Rectangle {
          anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
          height: parent.height / 2
        }
      }
      Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 70
        gradient: Gradient {
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 1; color: "#8c000000" }
        }
      }
      Rectangle {
        anchors { left: parent.left; leftMargin: 14; top: parent.top; topMargin: 12 }
        height: 22; width: pillRow.implicitWidth + 22; radius: 11; color: "#70000000"
        Row {
          id: pillRow; anchors.centerIn: parent; spacing: 6
          Rectangle { width: 6; height: 6; radius: 3; anchors.verticalCenter: parent.verticalCenter; color: win.drift.paused || !win.drift.lit ? win.dimColor : "#5ee06a" }
          Text {
            text: !win.drift.lit ? "Off" : win.drift.paused ? "Paused" : win.drift.restDrift && win.drift.pace < 0.05 ? "Resting" : "Evolving"
            color: win.textColor; font.pixelSize: 11; font.weight: Font.DemiBold; textFormat: Text.PlainText
          }
        }
        MouseArea { anchors.fill: parent; onClicked: win.drift.lit = !win.drift.lit }
      }
      // Close: a drawn cross in a dark round button, top right.
      Rectangle {
        anchors { right: parent.right; rightMargin: 14; top: parent.top; topMargin: 12 }
        width: 22; height: 22; radius: 11; color: closeMouse.containsMouse ? "#99000000" : "#70000000"
        Shape {
          anchors.centerIn: parent; width: 8; height: 8
          ShapePath { strokeColor: win.textColor; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 0; startY: 0; PathLine { x: 8; y: 8 } }
          ShapePath { strokeColor: win.textColor; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap
            startX: 8; startY: 0; PathLine { x: 0; y: 8 } }
        }
        MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; onClicked: win.drift.cardOpen = false }
      }
      Column {
        anchors { left: parent.left; leftMargin: 20; bottom: parent.bottom; bottomMargin: 14 }
        spacing: 2
        Text { text: "Drift"; color: "white"; font.pixelSize: 30; font.family: "Noto Serif"; textFormat: Text.PlainText }
        Text { text: "A quiet world, always becoming."; color: "#e0e0e0"; font.pixelSize: 12; textFormat: Text.PlainText }
      }
    }

    Column {
      x: 14; width: parent.width - 28
      bottomPadding: 18

      Heading { text: "Colour"; topPadding: 16 }
      Group {
        Item {
          width: parent.width; height: 46
          Text {
            anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
            text: "Atmosphere"; color: win.textColor; font.pixelSize: 14; textFormat: Text.PlainText
          }
          Row {
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
            spacing: 8
            Rectangle {
              id: dropButton
              height: 28; width: dropRow.implicitWidth + 12; radius: 8; color: "transparent"
              Row {
                id: dropRow; anchors.centerIn: parent; spacing: 8
                Text { text: win.drift.wander ? "Wandering" : win.drift.atmosphere; color: win.textColor; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter; textFormat: Text.PlainText }
                // macOS pop-up stepper: a small rounded box with up/down chevrons.
                Rectangle {
                  width: 20; height: 24; radius: 6; anchors.verticalCenter: parent.verticalCenter; color: win.chipColor
                  Shape {
                    anchors.centerIn: parent; width: 8; height: 12
                    ShapePath { strokeColor: win.textColor; strokeWidth: 1.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                      startX: 0.5; startY: 4; PathLine { x: 4; y: 0.8 } PathLine { x: 7.5; y: 4 } }
                    ShapePath { strokeColor: win.textColor; strokeWidth: 1.4; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                      startX: 0.5; startY: 8; PathLine { x: 4; y: 11.2 } PathLine { x: 7.5; y: 8 } }
                  }
                }
              }
              MouseArea { anchors.fill: parent; onClicked: dropdown.visible = !dropdown.visible }
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
            chipHeight: 26
            visible: win.drift.followWeather && win.drift.weather !== null && win.drift.weather.name !== ""
            label: win.drift.weather ? win.drift.weather.name.split(",")[0] : ""
            // Location arrow.
            Shape {
              width: 11; height: 11
              ShapePath { strokeColor: "transparent"; fillColor: win.textColor
                startX: 10.5; startY: 0.5; PathLine { x: 7; y: 10.5 } PathLine { x: 5; y: 6 } PathLine { x: 0.5; y: 4 } PathLine { x: 10.5; y: 0.5 } }
            }
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
      width: parent.width; height: 52
      Row {
        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
        spacing: 8
        Pill {
          onClicked: win.drift.paused = !win.drift.paused
          Row {
            visible: !win.drift.paused; anchors.centerIn: parent; spacing: 3
            Rectangle { width: 3.5; height: 12; radius: 1; color: win.textColor }
            Rectangle { width: 3.5; height: 12; radius: 1; color: win.textColor }
          }
          Shape {
            visible: win.drift.paused; anchors.centerIn: parent; width: 10; height: 12
            ShapePath { fillColor: win.textColor; strokeColor: "transparent"; startX: 0; startY: 0; PathLine { x: 10; y: 6 } PathLine { x: 0; y: 12 } PathLine { x: 0; y: 0 } }
          }
        }
        Pill {
          onClicked: win.drift.shuffle()
          Shape {
            anchors.centerIn: parent; width: 16; height: 12
            ShapePath { strokeColor: win.textColor; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
              startX: 0; startY: 2; PathCubic { control1X: 6; control1Y: 2; control2X: 7; control2Y: 10; x: 13; y: 10 } }
            ShapePath { strokeColor: win.textColor; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
              startX: 0; startY: 10; PathCubic { control1X: 6; control1Y: 10; control2X: 7; control2Y: 2; x: 13; y: 2 } }
            ShapePath { strokeColor: win.textColor; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
              startX: 11; startY: 0; PathLine { x: 14; y: 2 } PathLine { x: 11; y: 4 } }
            ShapePath { strokeColor: win.textColor; strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
              startX: 11; startY: 8; PathLine { x: 14; y: 10 } PathLine { x: 11; y: 12 } }
          }
        }
      }
    }
  }

  // The atmosphere list opens over the rows below it, inside the card.
  Rectangle {
    id: dropdown
    visible: false
    z: 10
    x: win.width - width - 26
    y: win.headerHeight + 58
    width: 156; height: list.implicitHeight + 12; radius: 10
    color: "#303030"; border.color: "#484848"
    layer.enabled: true
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#90000000"; shadowBlur: 0.6; shadowVerticalOffset: 4 }
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
}
