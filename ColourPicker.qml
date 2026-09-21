import QtQuick
import qs.Commons
import qs.Ui

Column {
  id: root
  required property color initialColor
  property real hue: 0.58
  property real saturation: 0.75
  property real value: 0.85
  property string pendingHex: ""
  property bool hexDirty: false
  property bool colorDirty: false
  property string fontFamily: Style.font.family
  property int fontPixelSize: Style.font.caption
  signal previewChanged(string hex)
  signal committed(string hex)
  signal dismissed()
  spacing: Style.space(6)
  width: Style.space(244)

  function clamp(v) { return Math.max(0, Math.min(1, v)) }
  function hexPart(v) {
    var s = Math.round(Math.max(0, Math.min(255, v))).toString(16)
    return s.length === 1 ? "0" + s : s
  }
  function hsvHex(h, s, v) {
    var i = Math.floor(h * 6), f = h * 6 - i
    var p = v * (1 - s), q = v * (1 - f * s), t = v * (1 - (1 - f) * s)
    var r, g, b
    switch (i % 6) {
    case 0: r = v; g = t; b = p; break
    case 1: r = q; g = v; b = p; break
    case 2: r = p; g = v; b = t; break
    case 3: r = p; g = q; b = v; break
    case 4: r = t; g = p; b = v; break
    default: r = v; g = p; b = q
    }
    return "#" + hexPart(r * 255) + hexPart(g * 255) + hexPart(b * 255)
  }
  function currentHex() { return hsvHex(root.hue, root.saturation, root.value) }
  function emitPreview() { root.pendingHex = root.currentHex(); root.previewChanged(root.pendingHex) }
  function setFromPoint(x, y, width, height) {
    root.saturation = root.clamp(x / width)
    root.value = root.clamp(1 - y / height)
    root.colorDirty = true
    root.emitPreview()
  }
  function setHueFromPoint(x, width) {
    root.hue = root.clamp(x / width)
    root.colorDirty = true
    root.emitPreview()
  }
  function setFromHex(text) {
    var hex = String(text).trim()
    if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return false
    var n = parseInt(hex.slice(1), 16), r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255
    var max = Math.max(r, g, b) / 255, min = Math.min(r, g, b) / 255, d = max - min
    var h = 0, s = max === 0 ? 0 : d / max
    if (d !== 0) {
      if (max === r / 255) h = ((g - b) / 255 / d) % 6
      else if (max === g / 255) h = (b - r) / 255 / d + 2
      else h = (r - g) / 255 / d + 4
      h /= 6; if (h < 0) h += 1
    }
    root.hue = h; root.saturation = s; root.value = max
    root.pendingHex = hex.toLowerCase()
    root.previewChanged(root.pendingHex)
    return true
  }
  function commit() {
    if (!root.colorDirty) return
    root.committed(root.pendingHex !== "" ? root.pendingHex : root.currentHex())
    root.colorDirty = false
  }
  function close() { root.commit(); root.dismissed() }
  function commitHex(text) {
    if (root.setFromHex(text)) {
      root.colorDirty = true
      root.commit()
    }
    else hexField.text = root.currentHex()
    root.hexDirty = false
  }
  function reset(color) {
    root.colorDirty = false
    root.hexDirty = false
    root.setFromHex(/^#[0-9a-fA-F]{6}$/.test(String(color)) ? String(color) : "#2bb8cd")
    root.colorDirty = false
  }

  Component.onCompleted: root.reset(root.initialColor)

  Item {
    id: sv
    width: parent.width
    height: Style.space(182)
    Rectangle {
      anchors.fill: parent
      color: Qt.hsva(root.hue, 1, 1, 1)
      border.width: Math.max(1, Style.space(1))
      border.color: Color.accent
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: "white" }
          GradientStop { position: 1; color: "transparent" }
        }
      }
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Vertical
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 1; color: "black" }
        }
      }
    }
    Rectangle {
      width: Style.space(14); height: width; radius: width / 2
      x: root.saturation * sv.width - width / 2
      y: (1 - root.value) * sv.height - height / 2
      color: "transparent"; border.width: Style.space(1)
      border.color: root.value > 0.5 ? "black" : "white"
    }
    MouseArea {
      anchors.fill: parent
      onPressed: function(mouse) { root.setFromPoint(mouse.x, mouse.y, width, height) }
      onPositionChanged: function(mouse) { if (pressed) root.setFromPoint(mouse.x, mouse.y, width, height) }
      onReleased: root.commit()
    }
  }

  Item {
    id: hueBar
    width: parent.width; height: Style.space(20)
    Rectangle {
      anchors.fill: parent
      border.width: Math.max(1, Style.space(1))
      border.color: Color.accent
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.00; color: "#ff0000" }
        GradientStop { position: 0.17; color: "#ffff00" }
        GradientStop { position: 0.33; color: "#00ff00" }
        GradientStop { position: 0.50; color: "#00ffff" }
        GradientStop { position: 0.67; color: "#0000ff" }
        GradientStop { position: 0.83; color: "#ff00ff" }
        GradientStop { position: 1; color: "#ff0000" }
      }
    }
    Rectangle { width: Style.space(5); height: parent.height + Style.space(4); x: root.hue * hueBar.width - width / 2; anchors.verticalCenter: parent.verticalCenter; color: "transparent"; border.width: 1; border.color: Color.foreground }
    MouseArea {
      anchors.fill: parent
      onPressed: function(mouse) { root.setHueFromPoint(mouse.x, width) }
      onPositionChanged: function(mouse) { if (pressed) root.setHueFromPoint(mouse.x, width) }
      onReleased: root.commit()
    }
  }

  Row {
    width: parent.width
    spacing: Style.space(8)
    Text {
      id: hexLabel
      text: "hex"
      color: Color.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontPixelSize
      anchors.verticalCenter: parent.verticalCenter
    }
    TextField {
      id: hexField
      width: parent.width - hexLabel.implicitWidth - parent.spacing
      placeholderText: "#RRGGBB"
      text: root.pendingHex !== "" ? root.pendingHex : root.currentHex()
      font.family: root.fontFamily
      font.pixelSize: root.fontPixelSize
      foreground: Color.foreground
      accent: Color.accent
      onTextEdited: root.hexDirty = true
      onActiveFocusChanged: if (!activeFocus && root.hexDirty) root.commitHex(text)
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.close()
          event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.commitHex(text)
          event.accepted = true
        }
      }
    }
  }
}
