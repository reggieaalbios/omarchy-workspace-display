import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Rectangle {
  id: root
  required property var host
  property var items: []
  readonly property color surfaceColor: root.host ? root.host.surfaceColor : Color.background
  readonly property color foregroundColor: root.host ? root.host.foregroundColor : Color.foreground
  readonly property string fontFamily: root.host ? root.host.fontFamily : Style.font.family
  readonly property var appChoices: root.host ? root.host.appChoices : []
  readonly property int launcherInputHeight: Style.spacing.controlHeight
  readonly property int columnWidth: Style.space(280)
  color: "transparent"
  border.width: Math.max(1, Style.space(1))
  border.color: Color.popups.border

  Flickable {
    id: scroller
    anchors.fill: parent
    anchors.margins: Style.space(7)
    clip: true
    contentWidth: columns.implicitWidth
    contentHeight: height
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.HorizontalFlick

    Row {
      id: columns
      height: scroller.height
      spacing: Style.space(7)

      Repeater {
        model: root.items.length

        Rectangle {
          id: card
          required property int index
          readonly property var launcher: root.items[index] || ({})
          width: root.columnWidth
          height: columns.height
          color: root.surfaceColor
          border.width: Math.max(1, Style.space(1))
          border.color: Color.popups.border
          readonly property bool compactLauncherHeader: launcherHeader.width < desktopFullButton.implicitWidth
            + commandFullButton.implicitWidth
            + removeButton.implicitWidth
            + launcherHeader.spacing * 3

          Button {
            id: desktopFullButton
            visible: false
            iconText: "▦"
            text: "Desktop app"
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            iconSize: Style.font.caption
            bordered: true
            focusable: true
          }

          Button {
            id: commandFullButton
            visible: false
            iconText: ">_"
            text: "Command"
            fontFamily: root.fontFamily
            fontSize: Style.font.caption
            iconSize: Style.font.caption
            bordered: true
            focusable: true
          }

          Column {
            id: columnSections
            anchors.fill: parent
            anchors.margins: Style.space(7)
            spacing: Style.space(9)

            Text {
              text: "COLUMN " + (card.index + 1)
              color: root.foregroundColor
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.weight: Font.DemiBold
            }

            Row {
              id: launcherHeader
              width: parent.width
              spacing: Style.space(4)

              Button {
                id: desktopButton
                iconText: "▦"
                text: card.compactLauncherHeader ? "" : "Desktop app"
                width: card.compactLauncherHeader ? removeButton.implicitWidth : implicitWidth
                tooltipText: "Desktop app"
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                iconSize: Style.font.caption
                selected: String(card.launcher.launcherType || "desktop") === "desktop"
                bordered: true
                focusable: true
                onClicked: if (!selected) root.host.changeScrollingLauncherType(card.index, "desktop")
              }
              Button {
                id: commandButton
                iconText: ">_"
                text: card.compactLauncherHeader ? "" : "Command"
                width: card.compactLauncherHeader ? removeButton.implicitWidth : implicitWidth
                tooltipText: "Command"
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                iconSize: Style.font.caption
                selected: String(card.launcher.launcherType || "desktop") === "command"
                bordered: true
                focusable: true
                onClicked: if (!selected) root.host.changeScrollingLauncherType(card.index, "command")
              }
              Item {
                width: Math.max(0, parent.width - desktopButton.width - commandButton.width - removeButton.implicitWidth - parent.spacing * 3)
                height: 1
              }
              Button {
                id: removeButton
                text: "X"
                tooltipText: "Remove column"
                fontFamily: root.fontFamily
                fontSize: Style.font.caption
                foreground: root.foregroundColor
                accent: Color.urgent
                bordered: true
                focusable: true
                enabled: root.items.length > 1
                onClicked: root.host.removeScrollingItem(card.index)
              }
            }

            LauncherSearchableDropdown {
              visible: String(card.launcher.launcherType || "desktop") === "desktop"
              width: parent.width
              height: root.launcherInputHeight
              rowHeight: root.launcherInputHeight
              showLabel: false
              options: root.appChoices
              value: String(card.launcher.appId || "")
              triggerLabel: "Choose an application…"
              placeholderText: "Search applications…"
              foreground: root.foregroundColor
              background: root.surfaceColor
              fontFamily: root.fontFamily
              onChanged: function(value) { root.host.assignScrollingApp(card.index, value) }
              onPopupOpenChanged: root.host.dropdownOpen = popupOpen
            }

            TextField {
              visible: String(card.launcher.launcherType || "desktop") === "command"
              width: parent.width
              height: root.launcherInputHeight
              placeholderText: "Command, e.g. kitty --class notes"
              text: String(card.launcher.command || "")
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              onTextEdited: root.host.assignScrollingCommand(card.index, text)
            }

            Text {
              text: "COLUMN WIDTH"
              color: root.foregroundColor
              opacity: 0.7
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
            }

            Flow {
              width: parent.width
              spacing: Style.space(3)
              Repeater {
                model: [0.333, 0.5, 0.667, 1.0]
                Button {
                  required property real modelData
                  width: Math.max(implicitWidth, (parent.width - Style.space(3) * 3) / 4)
                  text: Math.round(modelData * 100) + "%"
                  fontFamily: root.fontFamily
                  fontSize: Style.font.caption
                  selected: Math.abs(Number(card.launcher.width || 0.5) - modelData) < 0.01
                  bordered: true
                  focusable: true
                  onClicked: root.host.changeScrollingWidth(card.index, modelData)
                }
              }
            }

          }

          Row {
            id: moveControls
            anchors.centerIn: parent
            spacing: Style.space(5)
            Button {
              text: "← Move"
              enabled: card.index > 0
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              bordered: true
              focusable: true
              onClicked: root.host.moveScrollingItem(card.index, -1)
            }
            Button {
              text: "Move →"
              enabled: card.index + 1 < root.items.length
              fontFamily: root.fontFamily
              fontSize: Style.font.caption
              bordered: true
              focusable: true
              onClicked: root.host.moveScrollingItem(card.index, 1)
            }
          }
        }
      }

      Rectangle {
        id: addColumnCard
        width: root.columnWidth
        height: columns.height
        color: root.surfaceColor
        border.width: Math.max(1, Style.space(1))
        border.color: Color.popups.border

        Button {
          anchors.centerIn: parent
          text: "+ Add column"
          enabled: root.items.length < 24
          fontFamily: root.fontFamily
          fontSize: Style.font.caption
          bordered: true
          focusable: true
          onClicked: root.host.addScrollingItem()
        }
      }
    }
  }
}
