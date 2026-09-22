import QtQuick
import qs.Commons
import qs.Ui

Row {
  id: root
  required property string value
  property string fontFamily: Style.font.family
  property int labelFontSize: Style.font.bodySmall
  property int controlWidth: Style.space(100)
  property int controlHeight: Style.space(36)
  property bool cursorActive: false
  property int cursorIndex: 0
  signal selected(string value)
  signal hovered(int index, bool isHovered)
  spacing: Style.space(6)
  width: controlWidth * 3 + spacing * 2

  function activate(index) {
    var item = choices.itemAt(index)
    if (item) root.selected(item.modelData.key)
  }
  function cursorItem(index) { return choices.itemAt(index) }

  Repeater {
    id: choices
    model: [
      { key: "default", label: "Default" },
      { key: "app-icon", label: "App Icon" },
      { key: "workspace-name", label: "Workspace Name" }
    ]
    CursorSurface {
      required property var modelData
      required property int index
      width: (root.width - root.spacing * 2) / 3
      implicitWidth: root.controlWidth
      implicitHeight: root.controlHeight
      hasCursor: root.cursorActive && root.cursorIndex === index
      current: root.value === modelData.key
      bordered: true
      foreground: Color.foreground
      accent: Color.accent
      Text {
        id: label
        anchors.centerIn: parent
        text: parent.modelData.label
        width: parent.width - Style.space(10)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: parent.current ? Color.accent : Color.foreground
        font.family: root.fontFamily
        font.pixelSize: root.labelFontSize
      }
      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: root.hovered(parent.index, containsMouse)
        onClicked: root.selected(parent.modelData.key)
      }
    }
  }
}
