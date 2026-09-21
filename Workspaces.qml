import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "IconRules.js" as IconRules

// Local workspace manager derived from Decent Workspaces. Numeric Hyprland
// ids are intentionally the only dispatch contract; presentation is separate.
BarWidget {
  id: root
  moduleName: "io.github.reggieaalbios.workspace-display"

  property var metadata: ({})
  property int revision: 0
  property bool editorOpen: false
  property bool editorPickerOpen: false
  property int editedWorkspaceId: 0
  property string editorPreviewColor: ""
  property var menuAnchor: null
  property string focusedAddress: ""
  // Preserve Decent Workspaces' lightweight special:scratchpad affordance
  // without mixing a special workspace into numeric workspace metadata.
  readonly property bool showScratchpad: root.setting("showScratchpad", true)
  readonly property string scratchpadName: root.setting("scratchpadName", "special:scratchpad")
  readonly property string scratchpadLabel: root.setting("scratchpadLabel", "S")
  readonly property string storePath: Quickshell.env("HOME") + "/.config/omarchy/workspace-manager.json"
  readonly property color foreground: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color background: root.bar ? root.bar.background : Color.background

  function validId(id) { return Number.isInteger(id) && id > 0 }
  function cleanName(value) { return String(value === undefined || value === null ? "" : value).replace(/[\x00-\x1f\x7f]/g, "").trim().slice(0, 32) }
  function cleanColor(value) { var s = String(value === undefined || value === null ? "" : value).trim(); return /^#[0-9a-fA-F]{6}$/.test(s) ? s.toLowerCase() : "" }
  function styleValue(value) { var s = String(value || "app-icon"); return ["default", "app-icon", "workspace-name"].indexOf(s) !== -1 ? s : "app-icon" }
  function entry(id) { var e = root.metadata[String(id)]; return e && typeof e === "object" ? e : {} }
  function styleFor(id) { return root.styleValue(root.entry(id).style) }
  function nameFor(id) { return root.cleanName(root.entry(id).name) }
  function displayNameFor(id) { var name = root.nameFor(id); return name !== "" ? name : "Workspace " + id }
  function colorFor(id) { return root.cleanColor(root.entry(id).color) }
  function copyMap() { var next = {}; for (var k in root.metadata) next[k] = root.metadata[k]; return next }
  function writeMetadata() { storeFile.setText(JSON.stringify({ version: 1, workspaces: root.metadata }, null, 2) + "\n") }
  function updateEntry(id, patch) {
    if (!root.validId(id)) return
    var next = root.copyMap(), old = root.entry(id), item = {}
    for (var k in old) item[k] = old[k]
    for (var p in patch) item[p] = patch[p]
    item.style = root.styleValue(item.style)
    item.name = root.cleanName(item.name)
    item.color = root.cleanColor(item.color)
    // Sparse format: defaults are represented by absence, not duplicated data.
    if (item.style === "app-icon") delete item.style
    if (item.name === "") delete item.name
    if (item.color === "") delete item.color
    if (Object.keys(item).length === 0) delete next[String(id)]
    else next[String(id)] = item
    root.metadata = next
    root.writeMetadata()
    root.revision++
  }
  function setStyle(id, value) { root.updateEntry(id, { style: value }) }
  function setName(id, value) { root.updateEntry(id, { name: value }) }
  function setColor(id, value) { root.updateEntry(id, { color: value }) }
  function loadMetadata(payload) {
    try {
      var parsed = JSON.parse(payload || "{}"), source = parsed && parsed.workspaces ? parsed.workspaces : {}, next = {}
      for (var key in source) {
        var id = parseInt(key, 10), item = source[key]
        if (!root.validId(id) || !item || typeof item !== "object") continue
        var clean = {}
        if (root.styleValue(item.style) !== "app-icon") clean.style = root.styleValue(item.style)
        if (root.cleanName(item.name) !== "") clean.name = root.cleanName(item.name)
        if (root.cleanColor(item.color) !== "") clean.color = root.cleanColor(item.color)
        if (Object.keys(clean).length) next[String(id)] = clean
      }
      root.metadata = next; root.revision++
    } catch (e) { /* preserve the last good in-memory map during a partial write */ }
  }

  FileView {
    id: storeFile
    path: root.storePath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadMetadata(text())
    onFileChanged: reload()
  }

  Process {
    id: activeWindowProcess
    command: ["hyprctl", "-j", "activewindow"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: { try { root.focusedAddress = String(JSON.parse(text || "{}").address || "") } catch (e) { root.focusedAddress = "" } }
    }
  }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) if (values[i].id === id) return values[i]
    return null
  }
  function hasWindows(workspace) { return !!(workspace && workspace.toplevels && workspace.toplevels.values && workspace.toplevels.values.length) }
  function occupied(id) { var ws = root.workspaceById(id); return !!(ws && ws.toplevels && ws.toplevels.values && ws.toplevels.values.length) }
  function metadataIds() { var out = []; for (var k in root.metadata) { var id = parseInt(k, 10); if (root.validId(id)) out.push(id) } return out }
  readonly property var runtimeIds: {
    var _ = root.revision, out = [], values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) if (root.validId(values[i].id)) out.push(values[i].id)
    return out
  }
  readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
  readonly property var barWindow: root.QsWindow ? root.QsWindow.window : null
  readonly property string screenName: barWindow && barWindow.screen ? String(barWindow.screen.name || "") : ""
  readonly property var hyprMonitor: {
    var _ = root.revision, monitors = Hyprland.monitors.values
    for (var i = 0; i < monitors.length; i++) if (String(monitors[i].name || "") === root.screenName) return monitors[i]
    return null
  }
  readonly property var scratchpadWorkspace: {
    var _ = root.revision, values = Hyprland.workspaces.values
    if (!root.showScratchpad) return null
    for (var i = 0; i < values.length; i++) if (String(values[i].name || "") === root.scratchpadName) return values[i]
    return null
  }
  readonly property bool scratchpadVisible: root.showScratchpad && root.hasWindows(root.scratchpadWorkspace)
  readonly property bool scratchpadOpen: {
    var _ = root.revision, ipc = root.hyprMonitor ? root.hyprMonitor.lastIpcObject : null
    var special = ipc ? ipc.specialWorkspace : null
    return !!special && String(special.name || "") === root.scratchpadName
  }
  readonly property var visibleIds: {
    var _ = root.revision, ids = [1, 2, 3, 4, 5], candidates = root.runtimeIds.concat(root.metadataIds())
    if (root.validId(root.activeId)) candidates.push(root.activeId)
    for (var i = 0; i < candidates.length; i++) {
      var id = candidates[i]
      if (root.occupied(id) || root.validId(root.activeId) && id === root.activeId || root.metadataIds().indexOf(id) !== -1) if (ids.indexOf(id) === -1) ids.push(id)
    }
    ids.sort(function(a, b) { return a - b }); return ids
  }

  function windowClass(t) { var ipc = t ? t.lastIpcObject : null; return String((ipc && ipc.class) || (t && (t.class || t.appId)) || "") }
  function windowTitle(t) { var ipc = t ? t.lastIpcObject : null; return String((t && t.title) || (ipc && ipc.title) || "") }
  function iconFor(t) { return IconRules.resolve(root.windowClass(t).toLowerCase(), root.windowTitle(t).toLowerCase()) }
  function isFocused(t) { var a = String(t && (t.address || (t.lastIpcObject && t.lastIpcObject.address)) || ""); return a !== "" && a === root.focusedAddress }
  function previewFor(id) {
    var ws = root.workspaceById(id), icons = ws && ws.toplevels ? ws.toplevels.values : []
    var style = root.styleFor(id), label = style === "workspace-name" ? root.displayNameFor(id) : String(id)
    if (style !== "app-icon") return label
    var shown = []; for (var i = 0; i < icons.length && i < 2; i++) shown.push(root.iconFor(icons[i]))
    return label + (shown.length ? " " + shown.join(" ") : "")
  }
  function focusWorkspace(id) {
    var ws = root.workspaceById(id)
    if (ws) ws.activate()
    else if (root.bar) root.bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + id + '" })'))
  }
  function toggleScratchpad() {
    if (!root.bar) return
    var name = root.scratchpadName.indexOf("special:") === 0 ? root.scratchpadName.slice(8) : root.scratchpadName
    root.bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.workspace.toggle_special("' + name + '")'))
  }
  function openEditor(id, anchor) {
    if (!root.validId(id)) return
    root.editedWorkspaceId = id
    root.editorPreviewColor = root.colorFor(id)
    root.editorPickerOpen = false
    root.menuAnchor = anchor || root
    root.editorOpen = true
  }
  function open() { root.openEditor(root.validId(root.activeId) ? root.activeId : 1, root) }
  function close() { root.editorPickerOpen = false; root.editorOpen = false }
  function toggle() { root.editorOpen ? root.close() : root.open() }
  function openPicker(id) {
    root.openEditor(id, root)
    Qt.callLater(function() { root.showPicker() })
  }
  function showPicker() {
    root.editorPreviewColor = root.colorFor(root.editedWorkspaceId)
    editorPicker.reset(root.editorPreviewColor || String(Color.accent))
    root.editorPickerOpen = true
    editorPicker.forceActiveFocus()
  }
  function closePicker() {
    if (!root.editorPickerOpen) return false
    editorPickerPopup.close()
    return true
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      root.revision++
      if (["openwindow", "closewindow", "movewindow", "windowtitle", "activewindow", "urgent"].indexOf(event.name) !== -1) {
        Hyprland.refreshWorkspaces(); Hyprland.refreshToplevels(); if (!activeWindowProcess.running) activeWindowProcess.running = true
      }
      if (["activespecial", "activespecialv2"].indexOf(event.name) !== -1) {
        Hyprland.refreshWorkspaces(); Hyprland.refreshMonitors()
      }
    }
  }
  Component.onCompleted: { if (!activeWindowProcess.running) activeWindowProcess.running = true }

  // The module id itself belongs to Omarchy's bar-level summon/hide route,
  // which has no argument payload for a bar widget.  Keep the parameterized
  // workspace editor on its own target.
  IpcHandler {
    target: "io.github.reggieaalbios.workspace-display.settings"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function picker(id: int): void { root.openPicker(id) }
  }

  implicitWidth: root.vertical ? root.barSize : strip.implicitWidth + Style.spaceReal(8)
  implicitHeight: root.vertical ? strip.implicitHeight : root.barSize
  Item {
    id: strip
    anchors.left: parent.left; anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
    implicitWidth: row.implicitWidth + Style.spaceReal(8); implicitHeight: row.implicitHeight + Style.spaceReal(8)
    GridLayout {
      id: row; anchors.centerIn: parent
      columns: root.vertical ? 1 : root.visibleIds.length + (root.scratchpadVisible ? 1 : 0)
      columnSpacing: Style.spaceReal(4)
      rowSpacing: Style.spaceReal(4)
      Repeater {
        model: root.visibleIds
        BorderSurface {
          required property int modelData
          readonly property int wsId: modelData
          readonly property bool active: wsId === root.activeId
          readonly property color workspaceColor: root.colorFor(wsId) || Color.accent
          // Inherited from idan.workspace-names: the active tag carries a
          // restrained tint, while inactive tags retain a quieter outline.
          // The square shape remains intentional for this workspace strip.
          opacity: active ? 1 : 0.78
          color: active ? Util.alpha(workspaceColor, 0.18) : "transparent"
          borderSpec: ({
            color: Util.alpha(workspaceColor, active ? 0.45 : 0.28),
            widths: { top: Math.max(1, Style.space(1)), right: Math.max(1, Style.space(1)), bottom: Math.max(1, Style.space(1)), left: Math.max(1, Style.space(1)) },
            gradient: { colors: [], angle: 0, enabled: false }
          })
          implicitWidth: buttonContent.implicitWidth + Style.spaceReal(12); implicitHeight: root.barSize - Style.spaceReal(8)
          Layout.fillWidth: root.vertical
          Layout.alignment: Qt.AlignVCenter
          Row { id: buttonContent; anchors.centerIn: parent; spacing: Style.spaceReal(3)
            Text { text: root.styleFor(wsId) === "workspace-name" ? root.displayNameFor(wsId) : String(wsId); color: workspaceColor; font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.body }
            Repeater { model: root.styleFor(wsId) === "app-icon" && root.workspaceById(wsId) ? root.workspaceById(wsId).toplevels.values : []
              Text { required property var modelData; text: root.iconFor(modelData); color: workspaceColor; font.family: root.bar ? root.bar.fontFamily : Style.font.family; font.pixelSize: Style.font.body }
            }
          }
          MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton; cursorShape: Qt.PointingHandCursor; onClicked: function(mouse) { if (mouse.button === Qt.RightButton) root.openEditor(wsId, parent); else root.focusWorkspace(wsId) } }
        }
      }
      Rectangle {
        id: scratchpad
        visible: root.scratchpadVisible
        readonly property color scratchpadColor: Color.accent
        opacity: scratchpadOpen ? 1 : 0.78
        color: scratchpadOpen ? Util.alpha(scratchpadColor, 0.18) : "transparent"
        border.width: Math.max(1, Style.space(1))
        border.color: Util.alpha(scratchpadColor, scratchpadOpen ? 0.45 : 0.28)
        implicitWidth: scratchpadContent.implicitWidth + Style.spaceReal(12)
        implicitHeight: root.barSize - Style.spaceReal(8)
        Layout.fillWidth: root.vertical
        Layout.alignment: Qt.AlignVCenter
        Row {
          id: scratchpadContent
          anchors.centerIn: parent
          spacing: Style.spaceReal(3)
          Text {
            text: root.scratchpadLabel
            visible: text !== ""
            color: scratchpad.scratchpadColor
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }
          Repeater {
            model: root.scratchpadWorkspace && root.scratchpadWorkspace.toplevels ? root.scratchpadWorkspace.toplevels.values : []
            Text {
              required property var modelData
              text: root.iconFor(modelData)
              color: root.isFocused(modelData) ? Color.accent : scratchpad.scratchpadColor
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.body
            }
          }
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.toggleScratchpad()
        }
      }
    }
  }

  // Keep KeyboardPanel's close/coordinator behavior without marking the
  // workspace widget itself as the bar's active popout (which draws an
  // unwanted underline beneath the workspace strip).
  QtObject {
    id: editorPanelOwner
    function close() { root.close() }
  }

  KeyboardPanel {
    id: editorPanel
    anchorItem: root.menuAnchor || root
    owner: editorPanelOwner; bar: root.bar; open: root.editorOpen; focusTarget: keyCatcher
    borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(1)))
    contentWidth: fittedContentWidth(Style.space(340))
    contentHeight: fittedContentHeight(workspaceEditor.implicitHeight, Style.space(480))
    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: if (!root.closePicker()) root.close()
    }
    WorkspaceRow {
      id: workspaceEditor
      anchors.fill: parent
      host: root
      workspaceId: root.editedWorkspaceId
      workspace: root.workspaceById(root.editedWorkspaceId)
      previewColor: root.editorPreviewColor
      onPickerRequested: root.editorPickerOpen ? root.closePicker() : root.showPicker()
    }
  }

  ColourPickerPopup {
      id: editorPickerPopup
      anchorItem: workspaceEditor.colorSwatch
      open: root.editorPickerOpen
      contentWidth: Style.space(244)
      contentHeight: editorPicker.implicitHeight
      surfaceColor: root.background
      outlineColor: Color.accent
      fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
      fontPixelSize: Style.font.caption
      onDismissed: root.editorPickerOpen = false
      ColourPicker {
      id: editorPicker
      anchors.fill: parent
      initialColor: root.editorPreviewColor || String(Color.accent)
      fontFamily: editorPickerPopup.fontFamily
      fontPixelSize: editorPickerPopup.fontPixelSize
      onPreviewChanged: function(hex) { root.editorPreviewColor = hex }
      onCommitted: function(hex) {
        root.setColor(root.editedWorkspaceId, hex)
        root.editorPreviewColor = root.colorFor(root.editedWorkspaceId)
      }
    }
  }
}
