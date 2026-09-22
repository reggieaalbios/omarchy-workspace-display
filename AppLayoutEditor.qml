import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "LayoutModel.js" as LayoutModel

Column {
  id: root
  required property var host
  required property string targetKey
  property var draftTree: ({ type: "leaf", launcherType: "desktop", appId: "", command: "" })
  property var draftItems: [{ type: "leaf", launcherType: "desktop", appId: "", command: "", width: 0.5 }]
  property string draftLayoutType: "dwindle"
  property string draftId: ""
  property string draftName: ""
  property string errorText: ""
  property bool dropdownOpen: false
  property var appChoices: []
  readonly property color surfaceColor: root.host.background
  readonly property color foregroundColor: root.host.foreground
  readonly property string fontFamily: root.host.bar ? root.host.bar.fontFamily : Style.font.family
  width: parent ? parent.width : Style.space(680)
  height: implicitHeight
  spacing: Style.space(8)

  function refreshApps() {
    var values = DesktopEntries.applications && DesktopEntries.applications.values ? DesktopEntries.applications.values : []
    var out = []
    for (var i = 0; i < values.length; i++) {
      var entry = values[i]
      if (!entry || entry.noDisplay || !String(entry.id || "")) continue
      out.push({ value: String(entry.id), label: String(entry.name || entry.id), description: String(entry.genericName || entry.id) })
    }
    out.sort(function(a, b) {
      return a.label.toLowerCase().localeCompare(b.label.toLowerCase())
    })
    root.appChoices = out
  }
  function assignApp(path, id) { root.draftTree = LayoutModel.setLeafApp(root.draftTree, path, id); root.errorText = "" }
  function assignCommand(path, command) { root.draftTree = LayoutModel.setLeafCommand(root.draftTree, path, command); root.errorText = "" }
  function changeLauncherType(path, launcherType) { root.draftTree = LayoutModel.setLeafLauncherType(root.draftTree, path, launcherType); root.errorText = "" }
  function splitPane(path, axis) { root.draftTree = LayoutModel.splitLeaf(root.draftTree, path, axis); root.errorText = "" }
  function changeRatio(path, ratio) { root.draftTree = LayoutModel.setRatio(root.draftTree, path, ratio) }
  function removePane(path) {
    if (!path) return
    var parentPath = path.slice(0, -1)
    var removeFirst = path.slice(-1) === "0"
    root.draftTree = LayoutModel.collapse(root.draftTree, parentPath, removeFirst)
    root.errorText = ""
  }
  function assignScrollingApp(index, id) { root.draftItems = LayoutModel.setScrollingApp(root.draftItems, index, id); root.errorText = "" }
  function assignScrollingCommand(index, command) { root.draftItems = LayoutModel.setScrollingCommand(root.draftItems, index, command); root.errorText = "" }
  function changeScrollingLauncherType(index, launcherType) { root.draftItems = LayoutModel.setScrollingLauncherType(root.draftItems, index, launcherType); root.errorText = "" }
  function changeScrollingWidth(index, width) { root.draftItems = LayoutModel.setScrollingWidth(root.draftItems, index, width) }
  function addScrollingItem() { root.draftItems = LayoutModel.addScrollingItem(root.draftItems); root.errorText = "" }
  function removeScrollingItem(index) { root.draftItems = LayoutModel.removeScrollingItem(root.draftItems, index); root.errorText = "" }
  function moveScrollingItem(index, offset) { root.draftItems = LayoutModel.moveScrollingItem(root.draftItems, index, offset) }
  function changeLayoutType(layoutType) {
    root.draftLayoutType = String(layoutType) === "scrolling" ? "scrolling" : "dwindle"
    root.errorText = ""
  }
  function reset(template) {
    root.draftId = String(template && template.id || "")
    root.draftName = String(template && template.name || "")
    root.draftLayoutType = String(template && template.layoutType) === "scrolling" ? "scrolling" : "dwindle"
    root.draftTree = LayoutModel.cleanTree(template && template.tree)
    root.draftItems = LayoutModel.cleanScrollingItems(template && template.items)
    root.errorText = ""
    nameField.text = root.draftName
    root.refreshApps()
  }
  function save() {
    var name = String(nameField.text || "").trim()
    var draft = { layoutType: root.draftLayoutType, tree: root.draftTree, items: root.draftItems }
    var layoutError = LayoutModel.validateTemplate(draft)
    if (!name) root.errorText = "Enter a layout name."
    else if (layoutError) root.errorText = layoutError
    else root.host.saveTemplate(root.targetKey, root.draftId, name, root.draftLayoutType, root.draftTree, root.draftItems)
  }

  Connections {
    target: DesktopEntries.applications
    function onValuesChanged() { root.refreshApps() }
  }
  Component.onCompleted: root.refreshApps()

  PanelSectionHeader {
    text: (root.draftId ? "EDIT" : "NEW") + " LAUNCH LAYOUT · " + root.host.targetLabel(root.targetKey).toUpperCase()
    foreground: root.foregroundColor
    fontFamily: root.fontFamily
  }

  TextField {
    id: nameField
    width: parent.width
    height: Style.space(36)
    placeholderText: "Layout name"
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
  }

  PanelSeparator {
    foreground: root.foregroundColor
  }

  PanelSectionHeader {
    text: "LAYOUT TYPE"
    foreground: root.foregroundColor
    fontFamily: root.fontFamily
  }

  Row {
    spacing: Style.space(6)
    Button {
      text: "▦  Dwindle"
      selected: root.draftLayoutType === "dwindle"
      bordered: true
      focusable: true
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.changeLayoutType("dwindle")
    }
    Button {
      text: "▤  Scrolling"
      selected: root.draftLayoutType === "scrolling"
      bordered: true
      focusable: true
      fontFamily: root.fontFamily
      fontSize: Style.font.caption
      onClicked: root.changeLayoutType("scrolling")
    }
  }

  Text {
    width: parent.width
    text: root.draftLayoutType === "scrolling"
      ? "Arrange launchers as ordered scrolling columns and choose each column width."
      : "Split panes and drag dividers to define the Dwindle layout."
    color: root.foregroundColor
    opacity: 0.72
    wrapMode: Text.WordWrap
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  PanelSeparator {
    foreground: root.foregroundColor
  }

  LayoutNode {
    visible: root.draftLayoutType === "dwindle"
    width: parent.width
    height: Style.space(430)
    host: root
    node: root.draftTree
    nodePath: ""
  }

  ScrollingLayoutEditor {
    visible: root.draftLayoutType === "scrolling"
    width: parent.width
    height: Style.space(430)
    host: root
    items: root.draftItems
  }

  Text {
    visible: root.errorText !== ""
    width: parent.width
    text: root.errorText
    color: Color.urgent
    wrapMode: Text.WordWrap
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  Row {
    anchors.right: parent.right
    spacing: Style.space(8)
    Button {
      text: "Cancel"
      fontFamily: root.fontFamily
      bordered: true
      focusable: true
      onClicked: root.host.closeTemplateEditor()
    }
    Button {
      text: "Save layout"
      fontFamily: root.fontFamily
      selected: true
      bordered: true
      focusable: true
      onClicked: root.save()
    }
  }
}
