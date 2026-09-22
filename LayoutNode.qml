import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui

Item {
  id: root
  property var host: null
  property var node: null
  property string nodePath: ""
  property int gap: Style.space(6)
  readonly property color safeSurfaceColor: root.host ? root.host.surfaceColor : Color.background
  readonly property color safeForegroundColor: root.host ? root.host.foregroundColor : Color.foreground
  readonly property string safeFontFamily: root.host ? root.host.fontFamily : Style.font.family
  readonly property var safeAppChoices: root.host ? root.host.appChoices : []
  readonly property int launcherInputHeight: Style.spacing.controlHeight
  readonly property int leafMinimumWidth: Style.space(190)
  readonly property int leafMinimumHeight: Style.space(128)
  readonly property int dividerSize: Style.space(8)

  function minimumWidth(node) {
    if (!node || String(node.type) !== "split") return root.leafMinimumWidth
    var first = root.minimumWidth(node.first)
    var second = root.minimumWidth(node.second)
    return String(node.axis) === "vertical"
      ? Math.max(first, second)
      : first + root.dividerSize + second
  }

  function minimumHeight(node) {
    if (!node || String(node.type) !== "split") return root.leafMinimumHeight
    var first = root.minimumHeight(node.first)
    var second = root.minimumHeight(node.second)
    return String(node.axis) === "vertical"
      ? first + root.dividerSize + second
      : Math.max(first, second)
  }

  Rectangle {
    id: leafCard
    anchors.fill: parent
    visible: !root.node || String(root.node.type) !== "split"
    color: root.safeSurfaceColor
    border.width: Math.max(1, Style.space(1))
    border.color: Color.popups.border
    readonly property bool compactLauncherHeader: launcherHeader.width < desktopFullButton.implicitWidth
      + commandFullButton.implicitWidth
      + (removePaneButton.visible ? removePaneButton.implicitWidth : 0)
      + launcherHeader.spacing * (removePaneButton.visible ? 3 : 2)

    Button {
      id: desktopFullButton
      visible: false
      iconText: "▦"
      text: "Desktop app"
      fontFamily: root.safeFontFamily
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
      fontFamily: root.safeFontFamily
      fontSize: Style.font.caption
      iconSize: Style.font.caption
      bordered: true
      focusable: true
    }

    Column {
      anchors.fill: parent
      anchors.margins: Style.space(7)
      spacing: Style.space(6)

      Row {
        id: launcherHeader
        width: parent.width
        spacing: Style.space(5)
        Button {
          id: desktopTypeButton
          iconText: "▦"
          text: leafCard.compactLauncherHeader ? "" : "Desktop app"
          width: leafCard.compactLauncherHeader ? removePaneButton.implicitWidth : implicitWidth
          tooltipText: "Desktop app"
          fontFamily: root.safeFontFamily
          fontSize: Style.font.caption
          iconSize: Style.font.caption
          selected: String(root.node && root.node.launcherType || "desktop") === "desktop"
          bordered: true
          focusable: true
          onClicked: {
            if (root.host && !selected) root.host.changeLauncherType(root.nodePath, "desktop")
          }
        }
        Button {
          id: commandTypeButton
          iconText: ">_"
          text: leafCard.compactLauncherHeader ? "" : "Command"
          width: leafCard.compactLauncherHeader ? removePaneButton.implicitWidth : implicitWidth
          tooltipText: "Command"
          fontFamily: root.safeFontFamily
          fontSize: Style.font.caption
          iconSize: Style.font.caption
          selected: String(root.node && root.node.launcherType || "desktop") === "command"
          bordered: true
          focusable: true
          onClicked: {
            if (root.host && !selected) root.host.changeLauncherType(root.nodePath, "command")
          }
        }
        Item {
          width: Math.max(0, parent.width
            - desktopTypeButton.width
            - commandTypeButton.width
            - (removePaneButton.visible ? removePaneButton.implicitWidth : 0)
            - parent.spacing * (removePaneButton.visible ? 3 : 2))
          height: 1
        }
        Button {
          id: removePaneButton
          visible: root.nodePath !== ""
          text: "X"
          tooltipText: "Remove pane"
          fontFamily: root.safeFontFamily
          fontSize: Style.font.caption
          foreground: root.safeForegroundColor
          accent: Color.urgent
          bordered: true
          focusable: true
          onClicked: if (root.host) root.host.removePane(root.nodePath)
        }
      }

      LauncherSearchableDropdown {
        id: appPicker
        visible: String(root.node && root.node.launcherType || "desktop") === "desktop"
        width: parent.width
        height: root.launcherInputHeight
        rowHeight: root.launcherInputHeight
        showLabel: false
        options: root.safeAppChoices
        value: String(root.node && root.node.appId || "")
        triggerLabel: "Choose an application…"
        placeholderText: "Search applications…"
        foreground: root.safeForegroundColor
        background: root.safeSurfaceColor
        fontFamily: root.safeFontFamily
        onChanged: function(value) { if (root.host) root.host.assignApp(root.nodePath, value) }
        onPopupOpenChanged: if (root.host) root.host.dropdownOpen = popupOpen
      }

      TextField {
        id: commandField
        visible: String(root.node && root.node.launcherType || "desktop") === "command"
        width: parent.width
        height: root.launcherInputHeight
        placeholderText: "Command, e.g. kitty --class notes"
        text: String(root.node && root.node.command || "")
        font.family: root.safeFontFamily
        font.pixelSize: Style.font.caption
        onTextEdited: if (root.host) root.host.assignCommand(root.nodePath, text)
      }

      Item {
        width: parent.width
        height: Math.max(0, parent.height - launcherHeader.height - root.launcherInputHeight - parent.spacing * 2)

        Row {
          id: splitControls
          spacing: Style.space(5)
          anchors.centerIn: parent
          Button {
            text: "Split ↔"
            tooltipText: "Split horizontally"
            fontFamily: root.safeFontFamily
            fontSize: Style.font.caption
            bordered: true
            focusable: true
            enabled: root.width >= root.leafMinimumWidth * 2 + root.dividerSize
            onClicked: if (root.host) root.host.splitPane(root.nodePath, "horizontal")
          }
          Button {
            text: "Split ↕"
            tooltipText: "Split vertically"
            fontFamily: root.safeFontFamily
            fontSize: Style.font.caption
            bordered: true
            focusable: true
            enabled: root.height >= root.leafMinimumHeight * 2 + root.dividerSize
            onClicked: if (root.host) root.host.splitPane(root.nodePath, "vertical")
          }
        }
      }
    }
  }

  Item {
    id: splitView
    anchors.fill: parent
    visible: !!root.node && String(root.node.type) === "split"
    readonly property bool vertical: !!root.node && String(root.node.axis) === "vertical"
    readonly property real fraction: root.node ? Number(root.node.ratio || 1) / 2 : 0.5
    property real previewFraction: -1
    property real pointerOffset: 0
    readonly property real requestedFraction: previewFraction >= 0 ? previewFraction : fraction
    readonly property real effectiveFraction: splitView.clampFraction(requestedFraction)
    readonly property int dividerSize: root.dividerSize

    function clampFraction(value) {
      var available = Math.max(1, (splitView.vertical ? splitView.height : splitView.width) - splitView.dividerSize)
      var firstMinimum = splitView.vertical
        ? root.minimumHeight(root.node && root.node.first)
        : root.minimumWidth(root.node && root.node.first)
      var secondMinimum = splitView.vertical
        ? root.minimumHeight(root.node && root.node.second)
        : root.minimumWidth(root.node && root.node.second)
      if (firstMinimum + secondMinimum > available)
        return firstMinimum / Math.max(1, firstMinimum + secondMinimum)
      return Math.max(firstMinimum / available, Math.min(1 - secondMinimum / available, value))
    }

    function updatePreview(mouse) {
      var point = dividerMouse.mapToItem(splitView, mouse.x, mouse.y)
      var available = Math.max(1, (splitView.vertical ? splitView.height : splitView.width) - splitView.dividerSize)
      var position = (splitView.vertical ? point.y : point.x) - splitView.pointerOffset
      splitView.previewFraction = splitView.clampFraction(position / available)
    }

    Loader {
      id: firstLoader
      x: 0
      y: 0
      width: splitView.vertical ? splitView.width : Math.max(1, (splitView.width - splitView.dividerSize) * splitView.effectiveFraction)
      height: splitView.vertical ? Math.max(1, (splitView.height - splitView.dividerSize) * splitView.effectiveFraction) : splitView.height
      active: !!root.node && String(root.node.type) === "split"
      source: active ? "LayoutNode.qml" : ""
      onLoaded: {
        item.host = root.host
        item.node = root.node.first
        item.nodePath = root.nodePath + "0"
      }
    }
    Binding {
      target: firstLoader.item
      property: "node"
      value: root.node ? root.node.first : null
      when: firstLoader.status === Loader.Ready
    }
    Binding {
      target: firstLoader.item
      property: "host"
      value: root.host
      when: firstLoader.status === Loader.Ready
    }
    Binding {
      target: firstLoader.item
      property: "nodePath"
      value: root.nodePath + "0"
      when: firstLoader.status === Loader.Ready
    }

    Rectangle {
      id: divider
      x: splitView.vertical ? 0 : firstLoader.width
      y: splitView.vertical ? firstLoader.height : 0
      width: splitView.vertical ? splitView.width : splitView.dividerSize
      height: splitView.vertical ? splitView.dividerSize : splitView.height
      color: dividerMouse.containsMouse || dividerMouse.pressed ? Color.accent : Color.popups.border

      MouseArea {
        id: dividerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: splitView.vertical ? Qt.SizeVerCursor : Qt.SizeHorCursor
        onPressed: function(mouse) {
          splitView.pointerOffset = splitView.vertical ? mouse.y : mouse.x
          splitView.updatePreview(mouse)
        }
        onPositionChanged: function(mouse) {
          if (pressed) splitView.updatePreview(mouse)
        }
        onReleased: {
          if (root.host && splitView.previewFraction >= 0)
            root.host.changeRatio(root.nodePath, splitView.previewFraction * 2)
          splitView.previewFraction = -1
        }
        onCanceled: splitView.previewFraction = -1
      }
    }

    Loader {
      id: secondLoader
      x: splitView.vertical ? 0 : firstLoader.width + splitView.dividerSize
      y: splitView.vertical ? firstLoader.height + splitView.dividerSize : 0
      width: splitView.vertical ? splitView.width : Math.max(1, splitView.width - x)
      height: splitView.vertical ? Math.max(1, splitView.height - y) : splitView.height
      active: !!root.node && String(root.node.type) === "split"
      source: active ? "LayoutNode.qml" : ""
      onLoaded: {
        item.host = root.host
        item.node = root.node.second
        item.nodePath = root.nodePath + "1"
      }
    }
    Binding {
      target: secondLoader.item
      property: "node"
      value: root.node ? root.node.second : null
      when: secondLoader.status === Loader.Ready
    }
    Binding {
      target: secondLoader.item
      property: "host"
      value: root.host
      when: secondLoader.status === Loader.Ready
    }
    Binding {
      target: secondLoader.item
      property: "nodePath"
      value: root.nodePath + "1"
      when: secondLoader.status === Loader.Ready
    }

  }
}
