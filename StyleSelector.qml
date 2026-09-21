import QtQuick
import qs.Commons

Row {
  id: root
  required property string value
  property string fontFamily: Style.font.family
  property int labelFontSize: Style.font.bodySmall
  property int controlWidth: Style.space(100)
  property int controlHeight: Style.space(36)
  signal selected(string value)
  spacing: Style.space(6)
  width: controlWidth * 3 + spacing * 2

  Repeater {
    model: [
      { key: "default", label: "Default" },
      { key: "app-icon", label: "App Icon" },
      { key: "workspace-name", label: "Workspace Name" }
    ]
    Rectangle {
      required property var modelData
      width: root.controlWidth
      implicitWidth: root.controlWidth
      implicitHeight: root.controlHeight
      color: "transparent"
      border.width: Style.space(1)
      border.color: root.value === modelData.key ? Color.accent : Color.foreground
      Text {
        id: label
        anchors.centerIn: parent
        text: parent.modelData.label
        width: parent.width - Style.space(10)
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: parent.border.color
        font.family: root.fontFamily
        font.pixelSize: root.labelFontSize
      }
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selected(parent.modelData.key)
      }
    }
  }
}
