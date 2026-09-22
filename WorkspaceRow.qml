import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Ui

Column {
  id: root
  required property var host
  required property string targetKey
  required property var workspace
  property string previewColor: host.colorFor(targetKey)
  readonly property bool dropdownOpen: autoLaunchDropdown.popupOpen
  signal pickerRequested()
  width: parent ? parent.width : Style.space(300)
  height: implicitHeight
  spacing: Style.space(10)

  readonly property Item colorSwatch: swatch
  function moveDropdownCursor(delta) { autoLaunchDropdown.moveCursor(delta) }
  function activateDropdownCursor() { autoLaunchDropdown.activateCursor() }
  function closeDropdown() { autoLaunchDropdown.close() }
  function autoLaunchOptions() {
    var options = [{ value: "", label: "Off" }]
    var templates = root.host.templatesFor(root.targetKey)
    for (var i = 0; i < templates.length; i++)
      options.push({ value: templates[i].id, label: templates[i].name })
    return options
  }
  Text {
    width: parent.width
    text: root.host.targetLabel(root.targetKey)
    color: root.host.foreground
    font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.heading
    font.weight: Font.DemiBold
  }
  PanelSeparator {
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
  }
  PanelSectionHeader {
    text: "DISPLAY"
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
    fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
  }
  Row {
    width: parent.width; spacing: Style.space(6); height: Style.space(36)
    StyleSelector {
      width: parent.width
      value: root.host.styleFor(root.targetKey)
      fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
      labelFontSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
      onSelected: function(value) { root.host.setStyle(root.targetKey, value) }
    }
  }
  PanelSeparator {
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
  }
  PanelSectionHeader {
    text: "NAME"
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
      text: root.host.nameFor(root.targetKey)
      placeholderText: root.host.targetFallbackLabel(root.targetKey)
      onEditingFinished: root.host.setName(root.targetKey, text)
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          root.host.setName(root.targetKey, text)
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

  PanelSeparator {
    foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
  }
  Column {
    width: parent.width
    spacing: Style.space(6)
    Row {
      width: parent.width
      spacing: Style.space(8)
      PanelSectionHeader {
        text: "LAUNCH LAYOUTS"
        width: parent.width - addLayoutButton.width - parent.spacing
        anchors.verticalCenter: parent.verticalCenter
        foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
        fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
      }
      Button {
        id: addLayoutButton
        text: "+ New Layout"
        fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
        fontSize: Style.font.caption
        onClicked: root.host.openTemplateEditor(root.targetKey, "")
      }
    }

    PanelSectionHeader {
      text: "AUTO-LAUNCH AT LOGIN"
      foreground: root.host.bar ? root.host.bar.foreground : Color.foreground
      fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
    }
  }
  WorkspaceDropdown {
    id: autoLaunchDropdown
    width: parent.width
    showLabel: false
    value: root.host.autoLaunchTemplateIdFor(root.targetKey)
    options: root.autoLaunchOptions()
    foreground: root.host.foreground
    fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
    onChanged: function(templateId) {
      root.host.setAutoLaunchTemplateId(root.targetKey, templateId)
    }
  }

  Repeater {
    model: root.host.templatesFor(root.targetKey)
    BorderSurface {
      id: templateCard
      required property var modelData
      required property int index
      property bool deleteArmed: false
      readonly property bool isRunning: root.host.launchActive && root.host.launchTargetKey === root.targetKey
      width: root.width
      implicitHeight: Style.space(56)
      height: implicitHeight
      radius: Style.cornerRadius
      color: Util.alpha(Color.foreground, 0.05)
      borderSpec: Border.none()

      Text {
        id: layoutIcon
        anchors.left: parent.left
        anchors.leftMargin: Style.space(10)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(24)
        textFormat: Text.PlainText
        text: String(templateCard.modelData.layoutType) === "scrolling" ? "󰕭" : "󰕮"
        color: root.host.foreground
        horizontalAlignment: Text.AlignHCenter
        font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
        font.pixelSize: Style.font.title
      }

      Row {
        id: actionButtons
        anchors.right: parent.right
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        PanelActionButton {
          id: launchButton
          size: Style.space(32)
          iconText: templateCard.isRunning ? "󰑐" : "󰐊"
          tooltipText: templateCard.isRunning ? "Launching layout" : "Launch layout"
          enabled: root.host.canLaunch(root.targetKey)
          fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
          fontSize: Style.font.title
          foreground: root.host.foreground
          focusable: true
          onClicked: root.host.launchTemplate(root.targetKey, templateCard.modelData.id)
        }

        PanelActionButton {
          id: editButton
          size: Style.space(32)
          iconText: "󰏫"
          tooltipText: "Edit layout"
          fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
          fontSize: Style.font.title
          foreground: root.host.foreground
          focusable: true
          onClicked: root.host.openTemplateEditor(root.targetKey, templateCard.modelData.id)
        }

        PanelActionButton {
          id: deleteButton
          size: Style.space(32)
          iconText: templateCard.deleteArmed ? "󰄬" : "󰆴"
          tooltipText: templateCard.deleteArmed ? "Confirm delete" : "Delete layout"
          fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
          fontSize: Style.font.title
          foreground: templateCard.deleteArmed ? Color.urgent : root.host.foreground
          hoverColor: Color.urgent
          focusable: true
          onClicked: {
            if (templateCard.deleteArmed) {
              deleteArmTimeout.stop()
              root.host.removeTemplate(root.targetKey, templateCard.modelData.id)
            } else {
              templateCard.deleteArmed = true
              deleteArmTimeout.restart()
            }
          }
        }
      }

      Timer {
        id: deleteArmTimeout
        interval: 3000
        onTriggered: templateCard.deleteArmed = false
      }

      Column {
        anchors.left: layoutIcon.right
        anchors.leftMargin: Style.space(10)
        anchors.right: autoBadge.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(1)

        Row {
          width: parent.width
          spacing: Style.space(6)

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: String(templateCard.modelData.name || "Launch layout")
            color: root.host.foreground
            elide: Text.ElideRight
            font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
            font.bold: true
          }

        }

        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: root.host.templateLayoutLabel(templateCard.modelData) + " · " + root.host.templateAppCount(templateCard.modelData) + " apps"
          color: root.host.foreground
          opacity: 0.62
          elide: Text.ElideRight
          font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }

      Rectangle {
        id: autoBadge
        visible: root.host.autoLaunchTemplateIdFor(root.targetKey) === templateCard.modelData.id
        anchors.right: actionButtons.left
        anchors.rightMargin: Style.space(8)
        width: visible ? autoBadgeText.implicitWidth + Style.space(8) : 0
        height: Style.space(16)
        y: Math.round((templateCard.height - height) / 2)
        radius: Style.cornerRadius
        color: Util.alpha(Color.accent, 0.16)
        border.width: Math.max(1, Style.space(1))
        border.color: Color.accent

        Text {
          id: autoBadgeText
          anchors.centerIn: parent
          text: "AUTO"
          color: Color.accent
          font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
        }
      }

    }
  }

  Text {
    visible: !root.host.canLaunch(root.targetKey) && !root.host.launchActive && root.host.templatesFor(root.targetKey).length > 0
    width: parent.width
    text: "Close existing windows on " + root.host.targetLabel(root.targetKey) + " to launch a saved layout."
    color: root.host.foreground
    opacity: 0.72
    wrapMode: Text.WordWrap
    font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
  }

  Text {
    visible: root.host.launchNotice !== ""
    width: parent.width
    text: root.host.launchNotice
    color: root.host.launchNoticeIsError ? Color.urgent : Color.accent
    wrapMode: Text.WordWrap
    font.family: root.host.bar ? root.host.bar.fontFamily : Style.font.family
    font.pixelSize: Style.font.caption
  }
}
