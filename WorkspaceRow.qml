import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

Column {
  id: root
  required property var host
  required property int workspaceId
  required property var workspace
  property string previewColor: host.colorFor(workspaceId)
  signal pickerRequested()
  width: parent ? parent.width : Style.space(300)
  height: implicitHeight
  spacing: Style.space(10)

  readonly property Item colorSwatch: swatch
  PanelSectionHeader {
    text: "WORKSPACE STYLE"
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
    fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
  }
  Row {
    width: parent.width; spacing: Style.space(6); height: Style.space(36)
    StyleSelector {
      value: root.host.styleFor(root.workspaceId)
      fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
      labelFontSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
      onSelected: function(value) { root.host.setStyle(root.workspaceId, value) }
    }
  }
  PanelSeparator {
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
  }
  PanelSectionHeader {
    text: "WORKSPACE NAME"
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
    fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
  }
  Row {
    id: editorRow
    width: parent.width
    spacing: Style.space(6)
    TextField {
      id: nameField
      width: parent.width - swatch.width - parent.spacing
      height: swatch.height
      verticalPadding: Style.space(1)
      font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      text: root.host.nameFor(root.workspaceId)
      placeholderText: "Workspace " + root.workspaceId
      onEditingFinished: root.host.setName(root.workspaceId, text)
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.host.setName(root.workspaceId, text)
          event.accepted = true
        }
      }
    }
    Rectangle {
      id: swatch
      width: Style.space(24)
      height: width
      anchors.verticalCenter: parent.verticalCenter
      color: root.previewColor !== "" ? root.previewColor : Color.accent
      border.width: Style.space(1)
      border.color: Color.accent
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.pickerRequested()
      }
    }
  }
}
