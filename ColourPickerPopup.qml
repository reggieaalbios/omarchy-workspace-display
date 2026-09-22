import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// A separate xdg popup anchored to the colour swatch. It deliberately does
// not share the editor card's layout, so opening it never changes that card's
// geometry.
PopupWindow {
  id: root
  required property Item anchorItem
  property bool open: false
  property int padding: Style.spacing.popupPadding
  property int gap: Style.space(6)
  property int contentWidth: Style.space(244)
  property int contentHeight: Style.space(240)
  property color surfaceColor: Color.background
  property color outlineColor: Color.accent
  property string fontFamily: Style.font.family
  property int fontPixelSize: Style.font.caption
  signal dismissed()

  default property alias contentItem: contentHolder.children
  visible: root.open
  // This is an interactive popup, not a passive overlay. Give it focus so
  // clicking back into any other surface creates a reliable dismissal event.
  grabFocus: true
  color: "transparent"
  implicitWidth: root.contentWidth + root.padding * 2
  implicitHeight: root.contentHeight + root.padding * 2

  function close() { root.dismissed() }

  Connections {
    target: root._backingWindow
    function onActiveChanged() {
      // A click outside the picker transfers focus to its owner (or another
      // window). That is the native equivalent of popup blur and must close it.
      if (root.open && !root._backingWindow.active) root.close()
    }
  }
  function positionInWindow(item, offsetX, offsetY) {
    var x = offsetX
    var y = offsetY
    var current = item
    while (current) {
      x += current.x || 0
      y += current.y || 0
      current = current.parent
    }
    return Qt.point(x, y)
  }

  anchor {
    id: popupAnchor
    window: root.anchorItem ? root.anchorItem.QsWindow.window : null
    adjustment: PopupAdjustment.Slide
    edges: Edges.Top | Edges.Left
    gravity: Edges.Bottom | Edges.Right
    rect.width: 1
    rect.height: 1

    onAnchoring: {
      var target = root.anchorItem
      var window = target ? target.QsWindow.window : null
      if (!target || !window) return
      // Compensate for the popup surface's single-pixel anchor rounding, then let
      // the compositor slide it inward if an output edge leaves insufficient room.
      var point = root.positionInWindow(target, -1, target.height + root.gap)
      popupAnchor.rect.x = Math.round(point.x)
      popupAnchor.rect.y = Math.round(point.y)
    }
  }

  // Keep this independent popup visually identical to the workspace editor.
  // A plain Rectangle draws its full border inside its bounds, avoiding the
  // clipped left edge that can occur when a surface border meets an xdg anchor.
  Rectangle {
    anchors.fill: parent
    color: root.surfaceColor
    radius: 0
    readonly property int outlineWidth: Math.max(1, Style.space(1))
    Item {
      id: contentHolder
      anchors.fill: parent
      anchors.margins: root.padding
    }
    // Explicit edges are deliberate: some compositors can omit one edge of a
    // Rectangle.border on an xdg popup after fractional-scale rounding.
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: parent.outlineWidth; color: root.outlineColor }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: parent.outlineWidth; color: root.outlineColor }
    Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.outlineWidth; color: root.outlineColor }
    Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: parent.outlineWidth; color: root.outlineColor }
  }
}
