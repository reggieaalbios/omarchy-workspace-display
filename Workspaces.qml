import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui
import "IconRules.js" as IconRules
import "LayoutModel.js" as LayoutModel
import "AutoLaunchQueue.js" as AutoLaunchQueue

// Local workspace manager derived from Decent Workspaces. Numeric Hyprland
// ids are intentionally the only dispatch contract; presentation is separate.
BarWidget {
  id: root
  moduleName: "io.github.reggieaalbios.workspace-display"

  property var metadata: ({})
  property var scratchpadMetadata: ({})
  property int revision: 0
  property bool editorOpen: false
  property bool editorPickerOpen: false
  property string editorPage: "workspace"
  property string editedTargetKey: "1"
  property string editorPreviewColor: ""
  property var menuAnchor: null
  property string focusedAddress: ""
  property bool launchActive: false
  property bool loginQueueActive: false
  property bool loginClaimAttempted: false
  property bool launchIsAutomatic: false
  property var loginQueue: []
  property int loginQueueIndex: 0
  property var loginQueueProblems: []
  property string launchTargetKey: ""
  property string launchLayoutType: "dwindle"
  property var launchSteps: []
  property int launchIndex: 0
  property var launchAddresses: ({})
  property var launchDesktopAddresses: ({})
  property var launchSeenAddresses: ({})
  property var launchMissing: []
  property var launchBeforeAddresses: ({})
  property int launchWorkspaceWaitAttempts: 0
  property string launchPendingMoveAddress: ""
  property string launchPendingTileAddress: ""
  property int launchTileStableChecks: 0
  property int launchEnforcePassesRemaining: 0
  property string launchNotice: ""
  property bool launchNoticeIsError: false
  property int templateSerial: 0
  // The special workspace has an independent persisted entry so it can use
  // the same editor without ever becoming a numbered workspace.
  readonly property bool showScratchpad: root.setting("showScratchpad", true)
  readonly property string scratchpadName: root.setting("scratchpadName", "special:scratchpad")
  readonly property string scratchpadLabel: root.setting("scratchpadLabel", "S")
  readonly property string scratchpadKey: "scratchpad"
  readonly property string storePath: Quickshell.env("HOME") + "/.config/omarchy/workspace-manager.json"
  readonly property color foreground: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color background: root.bar ? root.bar.background : Color.background

  function validId(id) { return Number.isInteger(id) && id > 0 }
  function cleanName(value) { return String(value === undefined || value === null ? "" : value).replace(/[\x00-\x1f\x7f]/g, "").trim().slice(0, 32) }
  function cleanColor(value) { var s = String(value === undefined || value === null ? "" : value).trim(); return /^#[0-9a-fA-F]{6}$/.test(s) ? s.toLowerCase() : "" }
  function styleValue(value) { var s = String(value || "app-icon"); return ["default", "app-icon", "workspace-name"].indexOf(s) !== -1 ? s : "app-icon" }
  function isScratchpadTarget(key) { return String(key) === root.scratchpadKey }
  function validTarget(key) { return root.isScratchpadTarget(key) || root.validId(Number(key)) }
  function entry(key) {
    var e = root.isScratchpadTarget(key) ? root.scratchpadMetadata : root.metadata[String(Number(key))]
    return e && typeof e === "object" ? e : {}
  }
  function targetLabel(key) { return root.isScratchpadTarget(key) ? "Scratchpad" : "Workspace " + Number(key) }
  function targetFallbackLabel(key) { return root.isScratchpadTarget(key) ? root.scratchpadLabel : "Workspace " + Number(key) }
  function styleFor(key) { return root.styleValue(root.entry(key).style) }
  function nameFor(key) { return root.cleanName(root.entry(key).name) }
  function displayNameFor(key) { var name = root.nameFor(key); return name !== "" ? name : root.targetFallbackLabel(key) }
  function colorFor(key) { return root.cleanColor(root.entry(key).color) }
  function templatesFor(key) { return LayoutModel.cleanTemplates(root.entry(key).templates) }
  function autoLaunchTemplateIdFor(key) { return LayoutModel.cleanAutoLaunchTemplateId(root.entry(key).autoLaunchTemplateId, root.templatesFor(key)) }
  function autoLaunchOptionsFor(key) {
    var options = [{ value: "", label: "Off" }], templates = root.templatesFor(key)
    for (var i = 0; i < templates.length; i++) options.push({ value: templates[i].id, label: templates[i].name })
    return options
  }
  function templateAppCount(template) { return LayoutModel.templateLauncherIds(template).filter(function(id) { return id !== "" }).length }
  function templateLayoutLabel(template) { return String(template && template.layoutType) === "scrolling" ? "Scrolling" : "Dwindle" }
  function templateById(key, templateId) {
    var list = root.templatesFor(key)
    for (var i = 0; i < list.length; i++) if (list[i].id === templateId) return list[i]
    return null
  }
  function copyMap() { var next = {}; for (var k in root.metadata) next[k] = root.metadata[k]; return next }
  function cleanEntry(value) {
    var source = value && typeof value === "object" ? value : {}, item = {}
    for (var sourceKey in source) item[sourceKey] = source[sourceKey]
    item.style = root.styleValue(item.style)
    item.name = root.cleanName(item.name)
    item.color = root.cleanColor(item.color)
    item.templates = LayoutModel.cleanTemplates(item.templates)
    item.autoLaunchTemplateId = LayoutModel.cleanAutoLaunchTemplateId(item.autoLaunchTemplateId, item.templates)
    if (item.style === "app-icon") delete item.style
    if (item.name === "") delete item.name
    if (item.color === "") delete item.color
    if (item.templates.length === 0) delete item.templates
    if (item.autoLaunchTemplateId === "") delete item.autoLaunchTemplateId
    return item
  }
  function writeMetadata() { storeFile.setText(JSON.stringify({ version: 5, workspaces: root.metadata, scratchpad: root.scratchpadMetadata }, null, 2) + "\n") }
  function updateEntry(key, patch) {
    if (!root.validTarget(key)) return
    var next = root.copyMap(), old = root.entry(key), item = {}
    for (var k in old) item[k] = old[k]
    for (var p in patch) item[p] = patch[p]
    item = root.cleanEntry(item)
    if (root.isScratchpadTarget(key)) root.scratchpadMetadata = item
    else if (Object.keys(item).length === 0) delete next[String(Number(key))]
    else next[String(Number(key))] = item
    root.metadata = next
    root.writeMetadata()
    root.revision++
  }
  function setStyle(key, value) { root.updateEntry(key, { style: value }) }
  function setName(key, value) { root.updateEntry(key, { name: value }) }
  function setColor(key, value) { root.updateEntry(key, { color: value }) }
  function setTemplates(key, value) { root.updateEntry(key, { templates: value }) }
  function setAutoLaunchTemplateId(key, value) { root.updateEntry(key, { autoLaunchTemplateId: value }) }
  function loadMetadata(payload) {
    try {
      var parsed = JSON.parse(payload || "{}"), source = parsed && parsed.workspaces ? parsed.workspaces : {}, next = {}
      for (var key in source) {
        var id = parseInt(key, 10), item = source[key]
        if (!root.validId(id) || !item || typeof item !== "object") continue
        var clean = root.cleanEntry(item)
        if (Object.keys(clean).length) next[String(id)] = clean
      }
      root.metadata = next
      root.scratchpadMetadata = root.cleanEntry(parsed && parsed.scratchpad)
      root.revision++
      root.claimLoginAutoLaunch()
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

  // mkdir is the atomic once-per-compositor-session claim.  The directory is
  // namespaced by HYPRLAND_INSTANCE_SIGNATURE under the user runtime dir, so a
  // shell rescan/restart cannot replay the queue while a new Hyprland session
  // receives a fresh claim.
  Process {
    id: loginClaimProcess
    onExited: function(exitCode) {
      if (exitCode !== 0) return
      root.loginQueue = AutoLaunchQueue.snapshot(root.metadata, root.scratchpadMetadata)
      root.loginQueueIndex = 0
      root.loginQueueProblems = []
      if (root.loginQueue.length) {
        root.loginQueueActive = true
        root.startNextLoginLaunch()
      }
    }
  }

  Timer { id: launchWorkspaceWait; interval: 80; repeat: true; onTriggered: root.checkLaunchWorkspaceReady() }
  Timer { id: launchNextDelay; interval: 180; onTriggered: root.runNextLaunchStep() }
  Timer { id: launchPoll; interval: 140; repeat: true; onTriggered: root.checkLaunchWindow() }
  Timer { id: launchWindowTimeout; interval: 12000; onTriggered: root.markLaunchMissing() }
  Timer { id: launchEnforceTimer; interval: 160; repeat: true; onTriggered: root.reassertDesktopLaunchWindows() }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) if (values[i].id === id) return values[i]
    return null
  }
  function workspaceForTarget(key) { return root.isScratchpadTarget(key) ? root.scratchpadWorkspace : root.workspaceById(Number(key)) }
  function targetWorkspaceId(key) {
    var workspace = root.workspaceForTarget(key)
    return workspace ? Number(workspace.id) : (root.isScratchpadTarget(key) ? 0 : Number(key))
  }
  function targetWorkspaceName(key) { return root.isScratchpadTarget(key) ? root.scratchpadName : String(Number(key)) }
  function hasWindows(workspace) { return !!(workspace && workspace.toplevels && workspace.toplevels.values && workspace.toplevels.values.length) }
  function occupied(key) { var ws = root.workspaceForTarget(key); return !!(ws && ws.toplevels && ws.toplevels.values && ws.toplevels.values.length) }
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
  function windowInitialClass(t) { var ipc = t ? t.lastIpcObject : null; return String((ipc && ipc.initialClass) || (t && t.initialClass) || "") }
  function windowInitialTitle(t) { var ipc = t ? t.lastIpcObject : null; return String((ipc && ipc.initialTitle) || (t && t.initialTitle) || "") }
  function iconFor(t) {
    return IconRules.resolve(
      root.windowClass(t).toLowerCase(),
      root.windowTitle(t).toLowerCase(),
      root.windowInitialClass(t).toLowerCase(),
      root.windowInitialTitle(t).toLowerCase()
    )
  }
  function isFocused(t) { var a = String(t && (t.address || (t.lastIpcObject && t.lastIpcObject.address)) || ""); return a !== "" && a === root.focusedAddress }
  function previewFor(key) {
    var ws = root.workspaceForTarget(key), icons = ws && ws.toplevels ? ws.toplevels.values : []
    var style = root.styleFor(key), label = style === "workspace-name" ? root.displayNameFor(key) : root.targetFallbackLabel(key)
    if (style !== "app-icon") return label
    var shown = []; for (var i = 0; i < icons.length && i < 2; i++) shown.push(root.iconFor(icons[i]))
    return label + (shown.length ? " " + shown.join(" ") : "")
  }
  function makeTemplateId() {
    root.templateSerial++
    return "layout-" + Date.now().toString(36) + "-" + root.templateSerial.toString(36)
  }
  function openTemplateEditor(key, templateId) {
    var template = root.templateById(key, templateId)
    if (!template) template = {
      id: "", name: "", layoutType: "dwindle",
      tree: { type: "leaf", launcherType: "desktop", appId: "", command: "" },
      items: [{ type: "leaf", launcherType: "desktop", appId: "", command: "", width: 0.5 }]
    }
    root.editedTargetKey = String(key)
    root.editorPage = "layout"
    root.editorPickerOpen = false
    layoutEditor.reset(template)
  }
  function closeTemplateEditor() { root.editorPage = "workspace" }
  function saveTemplate(key, templateId, name, layoutType, tree, items) {
    var list = root.templatesFor(key), nextId = templateId || root.makeTemplateId()
    var clean = LayoutModel.cleanTemplate({ id: nextId, name: name, layoutType: layoutType, tree: tree, items: items }, nextId)
    if (!clean || LayoutModel.validateTemplate(clean) !== "") return
    var replaced = false
    for (var i = 0; i < list.length; i++) {
      if (list[i].id === clean.id) { list[i] = clean; replaced = true; break }
    }
    if (!replaced) list.push(clean)
    root.setTemplates(key, list)
    root.editorPage = "workspace"
  }
  function removeTemplate(key, templateId) {
    var list = root.templatesFor(key), next = []
    for (var i = 0; i < list.length; i++) if (list[i].id !== templateId) next.push(list[i])
    root.setTemplates(key, next)
  }
  function canLaunch(key) { return !root.launchActive && !root.loginQueueActive && !root.occupied(key) }

  function claimLoginAutoLaunch() {
    if (root.loginClaimAttempted) return
    root.loginClaimAttempted = true
    var signature = Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    var runtimeDir = String(Quickshell.env("XDG_RUNTIME_DIR") || "").replace(/\/$/, "")
    var leaf = AutoLaunchQueue.claimLeaf(signature)
    if (!runtimeDir || !leaf) return
    loginClaimProcess.command = ["mkdir", runtimeDir + "/" + leaf]
    loginClaimProcess.running = true
  }

  function addLoginQueueProblem(message) {
    var next = root.loginQueueProblems.slice()
    next.push(String(message))
    root.loginQueueProblems = next
  }

  function startNextLoginLaunch() {
    if (!root.loginQueueActive || root.launchActive) return
    if (root.loginQueueIndex >= root.loginQueue.length) {
      root.finishLoginQueue()
      return
    }
    var item = root.loginQueue[root.loginQueueIndex++]
    var target = item.targetKind === "scratchpad" ? root.scratchpadKey : String(item.workspaceId)
    var label = AutoLaunchQueue.targetLabel(item)
    if (root.occupied(target)) {
      root.addLoginQueueProblem(label + " skipped (occupied)")
      Qt.callLater(function() { root.startNextLoginLaunch() })
      return
    }
    if (!root.beginLayoutLaunch(target, item.templateId, true)) {
      root.addLoginQueueProblem(label + " failed (preset unavailable)")
      Qt.callLater(function() { root.startNextLoginLaunch() })
    }
  }

  function finishLoginQueue() {
    root.loginQueueActive = false
    root.launchIsAutomatic = false
    var message = AutoLaunchQueue.problemMessage(root.loginQueueProblems)
    if (message)
      Quickshell.execDetached(["omarchy-shell", "osd", "show", JSON.stringify({ icon: "⚠", message: message, duration: 5000 })])
  }
  function desktopEntry(appId) {
    try { return DesktopEntries.byId(String(appId || "").replace(/\.desktop$/, "")) }
    catch (e) { return null }
  }
  function desktopName(appId) {
    var entry = root.desktopEntry(appId)
    return String(entry && entry.name || appId || "application")
  }
  function launcherName(launcher) {
    return String(launcher && launcher.launcherType) === "command" ? String(launcher.command || "command") : root.desktopName(launcher && launcher.appId)
  }
  function normalizedAppToken(value) {
    return String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]/g, "")
  }
  function windowAddress(t) {
    var address = String(t && (t.address || (t.lastIpcObject && t.lastIpcObject.address)) || "").trim()
    if (!address) return ""
    return "0x" + address.replace(/^0x/i, "")
  }
  function windowMatchesApp(t, appId) {
    var entry = root.desktopEntry(appId)
    var ipc = t ? t.lastIpcObject : null
    var wmClass = String((ipc && (ipc.class || ipc.initialClass)) || (t && (t.appId || t.class)) || "")
    var windowToken = root.normalizedAppToken(wmClass)
    var startupToken = root.normalizedAppToken(entry && entry.startupClass)
    var idToken = root.normalizedAppToken(appId)
    if (startupToken && (windowToken === startupToken || windowToken.indexOf(startupToken) === 0)) return true
    if (idToken && windowToken && (windowToken === idToken || windowToken.indexOf(idToken) === 0 || idToken.indexOf(windowToken) === 0)) return true
    try {
      var guessed = DesktopEntries.heuristicLookup(wmClass)
      return !!guessed && root.normalizedAppToken(guessed.id) === idToken
    } catch (e) { return false }
  }
  function workspaceAddresses(id) {
    var out = {}, workspace = root.workspaceById(id)
    var values = workspace && workspace.toplevels && workspace.toplevels.values ? workspace.toplevels.values : []
    for (var i = 0; i < values.length; i++) {
      var address = root.windowAddress(values[i])
      if (address) out[address] = true
    }
    return out
  }
  function allWindowAddresses() {
    var out = {}, values = Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : []
    for (var i = 0; i < values.length; i++) {
      var address = root.windowAddress(values[i])
      if (address) out[address] = true
    }
    return out
  }
  function windowWorkspaceId(t) {
    var ipc = t ? t.lastIpcObject : null
    return Number((ipc && ipc.workspace && ipc.workspace.id) || (t && t.workspace && t.workspace.id) || 0)
  }
  function windowIsFloating(t) {
    var ipc = t ? t.lastIpcObject : null
    return !!((ipc && ipc.floating) || (t && t.floating))
  }
  function firstLaunchAddress() {
    for (var id in root.launchAddresses) if (root.launchAddresses[id]) return root.launchAddresses[id]
    return ""
  }
  function findNewLaunchWindow(launcher) {
    var values = Hyprland.toplevels && Hyprland.toplevels.values ? Hyprland.toplevels.values : []
    var candidates = []
    var isCommand = String(launcher && launcher.launcherType) === "command"
    for (var i = 0; i < values.length; i++) {
      var address = root.windowAddress(values[i])
      if (!address || root.launchBeforeAddresses[address] || root.launchSeenAddresses[address]) continue
      candidates.push(values[i])
      if (!isCommand && root.windowMatchesApp(values[i], launcher && launcher.appId)) return values[i]
    }
    // Some desktop files intentionally launch a generic terminal class (for
    // example TUI.float), so StartupWMClass cannot identify them. Launches are
    // serialized; when exactly one window appeared, it is the safe fallback.
    return candidates.length === 1 ? candidates[0] : null
  }
  function enforceDesktopAddresses(addresses) {
    var calls = []
    for (var address in addresses) {
      if (!/^0x[0-9a-f]+$/i.test(address)) continue
      var selector = "address:" + address
      // Desktop entries may inherit Omarchy rules that float, maximize, pin,
      // or pseudotile them. Override only captured launch windows so ordinary
      // application launches keep their configured behavior.
      // Use hyprctl's native batch protocol here. In-process dispatch did not
      // reliably override rules applied after map, and eval needlessly wraps
      // already-structured dispatchers in another Lua execution layer.
      calls.push('dispatch hl.dsp.window.float({ action = "off", window = "' + selector + '" })')
      calls.push('dispatch hl.dsp.window.fullscreen({ mode = "fullscreen", action = "unset", layout_aware = false, window = "' + selector + '" })')
      calls.push('dispatch hl.dsp.window.fullscreen({ mode = "maximized", action = "unset", layout_aware = false, window = "' + selector + '" })')
      calls.push('dispatch hl.dsp.window.pin({ action = "off", window = "' + selector + '" })')
      calls.push('dispatch hl.dsp.window.pseudo({ action = "off", window = "' + selector + '" })')
    }
    if (calls.length) Quickshell.execDetached(["hyprctl", "--batch", calls.join("; ")])
  }
  function enforceDesktopAddress(address) {
    var addresses = {}
    if (address) addresses[address] = true
    root.enforceDesktopAddresses(addresses)
  }
  function enforceDesktopLaunchWindow(step, address) {
    if (String(step && step.launcher && step.launcher.launcherType) === "command") return
    root.enforceDesktopAddress(address)
  }
  function rememberDesktopLaunchWindow(step, address) {
    if (String(step && step.launcher && step.launcher.launcherType) === "command" || !address) return
    var addresses = {}
    for (var known in root.launchDesktopAddresses) addresses[known] = true
    addresses[address] = true
    root.launchDesktopAddresses = addresses
    root.launchEnforcePassesRemaining = 10
    launchEnforceTimer.restart()
  }
  function reassertDesktopLaunchWindows() {
    if (root.launchEnforcePassesRemaining <= 0) { launchEnforceTimer.stop(); return }
    root.enforceDesktopAddresses(root.launchDesktopAddresses)
    root.launchEnforcePassesRemaining--
    if (root.launchEnforcePassesRemaining <= 0) launchEnforceTimer.stop()
  }
  function launchTemplate(key, templateId) {
    if (root.loginQueueActive) return
    root.beginLayoutLaunch(key, templateId, false)
  }
  function beginLayoutLaunch(key, templateId, automatic) {
    key = String(key)
    var template = root.templateById(key, templateId)
    if (!template || root.launchActive) return false
    if (root.occupied(key)) {
      if (!automatic) {
        root.launchNotice = "Close existing windows on " + root.targetLabel(key).toLowerCase() + " before launching this layout."
        root.launchNoticeIsError = true
      }
      return false
    }
    var error = LayoutModel.validateTemplate(template)
    if (error) {
      if (!automatic) { root.launchNotice = error; root.launchNoticeIsError = true }
      return false
    }
    root.launchSteps = LayoutModel.buildTemplateSteps(template)
    root.launchIndex = 0
    root.launchTargetKey = key
    root.launchLayoutType = String(template.layoutType) === "scrolling" ? "scrolling" : "dwindle"
    root.launchAddresses = ({})
    root.launchDesktopAddresses = ({})
    root.launchSeenAddresses = ({})
    root.launchMissing = []
    root.launchPendingMoveAddress = ""
    root.launchPendingTileAddress = ""
    root.launchTileStableChecks = 0
    root.launchIsAutomatic = !!automatic
    root.launchNotice = automatic ? "" : "Launching " + template.name + "…"
    root.launchNoticeIsError = false
    root.launchActive = true
    root.close()
    root.applyLaunchWorkspaceLayout()
    root.waitForLaunchWorkspace()
    return true
  }
  function applyLaunchWorkspaceLayout() {
    var options = root.launchLayoutType === "scrolling" ? ', layout_opts = { direction = "right" }' : ""
    var expression = 'hl.workspace_rule({ workspace = "' + root.targetWorkspaceName(root.launchTargetKey) + '", layout = "' + root.launchLayoutType + '"' + options + ' })'
    Quickshell.execDetached(["hyprctl", "eval", expression])
  }
  function waitForLaunchWorkspace() {
    root.launchWorkspaceWaitAttempts = 0
    root.focusTarget(root.launchTargetKey)
    launchWorkspaceWait.restart()
  }
  function checkLaunchWorkspaceReady() {
    if (!root.launchActive) { launchWorkspaceWait.stop(); return }
    Hyprland.refreshWorkspaces()
    var workspace = root.workspaceForTarget(root.launchTargetKey)
    var ipc = workspace ? workspace.lastIpcObject : null
    var layout = String(ipc && ipc.tiledLayout || "")
    if (root.targetIsFocused(root.launchTargetKey) && layout === root.launchLayoutType) {
      launchWorkspaceWait.stop()
      root.runNextLaunchStep()
      return
    }
    root.launchWorkspaceWaitAttempts++
    if (root.launchWorkspaceWaitAttempts >= 25) {
      launchWorkspaceWait.stop()
      root.cancelLaunch("Could not activate " + root.targetLabel(root.launchTargetKey).toLowerCase() + " with " + root.launchLayoutType + " layout.")
    }
  }
  function runNextLaunchStep() {
    if (!root.launchActive) return
    if (root.launchIndex >= root.launchSteps.length) { root.finishLaunch(); return }
    if (root.launchIndex === 0 && root.occupied(root.launchTargetKey)) {
      root.cancelLaunch(root.targetLabel(root.launchTargetKey) + " is no longer empty.")
      return
    }
    if (!root.targetIsFocused(root.launchTargetKey)) { root.waitForLaunchWorkspace(); return }
    var step = root.launchSteps[root.launchIndex]
    var workspace = root.workspaceForTarget(root.launchTargetKey)
    var ipc = workspace ? workspace.lastIpcObject : null
    var layout = String(ipc && ipc.tiledLayout || "dwindle")
    if (layout && layout !== root.launchLayoutType) {
      root.cancelLaunch(root.targetLabel(root.launchTargetKey) + " uses " + layout + "; expected " + root.launchLayoutType + ".")
      return
    }
    if (root.launchLayoutType === "dwindle" && !step.seed) {
      var target = String(root.launchAddresses[step.targetStepId] || root.firstLaunchAddress())
      if (target) Hyprland.dispatch('hl.dsp.focus({ window = "address:' + target + '" })')
      Hyprland.dispatch('hl.dsp.layout("preselect ' + (step.direction === "bottom" ? "d" : "r") + '")')
    }
    root.launchBeforeAddresses = root.allWindowAddresses()
    if (String(step.launcher && step.launcher.launcherType) === "command")
      Quickshell.execDetached(["uwsm-app", "--", "sh", "-lc", String(step.launcher.command || "")])
    else
      Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", String(step.launcher && step.launcher.appId) + ".desktop"])
    launchWindowTimeout.restart()
    launchPoll.restart()
  }
  function checkLaunchWindow() {
    if (!root.launchActive || root.launchIndex >= root.launchSteps.length) return
    Hyprland.refreshWorkspaces()
    Hyprland.refreshToplevels()
    var step = root.launchSteps[root.launchIndex]
    var window = root.findNewLaunchWindow(step.launcher)
    if (!window) return
    var address = root.windowAddress(window)
    if (root.windowWorkspaceId(window) !== root.targetWorkspaceId(root.launchTargetKey)) {
      if (root.launchPendingMoveAddress !== address) {
        root.launchPendingMoveAddress = address
        Hyprland.dispatch('hl.dsp.window.move({ workspace = "' + root.targetWorkspaceName(root.launchTargetKey) + '", follow = false, window = "address:' + address + '" })')
      }
      return
    }
    root.launchPendingMoveAddress = ""
    root.rememberDesktopLaunchWindow(step, address)
    if (String(step && step.launcher && step.launcher.launcherType) !== "command") {
      if (root.launchPendingTileAddress !== address) {
        root.launchPendingTileAddress = address
        root.launchTileStableChecks = 0
        root.enforceDesktopLaunchWindow(step, address)
        return
      }
      if (root.windowIsFloating(window)) {
        root.launchTileStableChecks = 0
        root.enforceDesktopLaunchWindow(step, address)
        return
      }
      root.launchTileStableChecks++
      if (root.launchTileStableChecks < 2) return
    }
    root.launchPendingTileAddress = ""
    root.launchTileStableChecks = 0
    launchPoll.stop()
    launchWindowTimeout.stop()
    var addresses = {}, seen = {}
    for (var appId in root.launchAddresses) addresses[appId] = root.launchAddresses[appId]
    for (var prior in root.launchSeenAddresses) seen[prior] = true
    addresses[step.stepId] = address
    seen[address] = true
    root.launchAddresses = addresses
    root.launchSeenAddresses = seen
    if (root.launchLayoutType === "scrolling") {
      Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
      Hyprland.dispatch('hl.dsp.layout("colresize ' + Number(step.width).toFixed(3) + '")')
    } else if (!step.seed) {
      Hyprland.dispatch('hl.dsp.focus({ window = "address:' + address + '" })')
      Hyprland.dispatch('hl.dsp.layout("splitratio ' + Number(step.ratio).toFixed(3) + ' exact")')
    }
    root.launchIndex++
    launchNextDelay.restart()
  }
  function markLaunchMissing() {
    launchPoll.stop()
    if (!root.launchActive || root.launchIndex >= root.launchSteps.length) return
    var step = root.launchSteps[root.launchIndex]
    var missing = root.launchMissing.slice()
    missing.push(root.launcherName(step.launcher))
    root.launchMissing = missing
    root.launchPendingMoveAddress = ""
    root.launchPendingTileAddress = ""
    root.launchTileStableChecks = 0
    root.launchIndex++
    launchNextDelay.restart()
  }
  function finishLaunch() {
    launchPoll.stop(); launchWindowTimeout.stop(); launchNextDelay.stop(); launchWorkspaceWait.stop()
    if (root.launchLayoutType === "dwindle") Hyprland.dispatch('hl.dsp.layout("preselect clear")')
    var automatic = root.launchIsAutomatic
    root.launchActive = false
    root.launchIsAutomatic = false
    root.launchPendingMoveAddress = ""
    root.launchPendingTileAddress = ""
    root.launchTileStableChecks = 0
    if (automatic) {
      if (root.launchMissing.length)
        root.addLoginQueueProblem(root.targetLabel(root.launchTargetKey) + " missing " + root.launchMissing.join(", "))
      root.launchNotice = ""
      root.launchNoticeIsError = false
      root.startNextLoginLaunch()
    } else if (root.launchMissing.length) {
      root.launchNotice = "Layout finished. Missing: " + root.launchMissing.join(", ") + "."
      root.launchNoticeIsError = true
      Quickshell.execDetached(["omarchy-shell", "osd", "show", JSON.stringify({ icon: "⚠", message: root.launchNotice, duration: 4000 })])
    } else {
      root.launchNotice = ""
      root.launchNoticeIsError = false
    }
  }
  function cancelLaunch(message) {
    launchPoll.stop(); launchWindowTimeout.stop(); launchNextDelay.stop(); launchWorkspaceWait.stop()
    if (root.launchLayoutType === "dwindle") Hyprland.dispatch('hl.dsp.layout("preselect clear")')
    var automatic = root.launchIsAutomatic
    root.launchActive = false
    root.launchIsAutomatic = false
    root.launchPendingMoveAddress = ""
    root.launchPendingTileAddress = ""
    root.launchTileStableChecks = 0
    if (automatic) {
      root.addLoginQueueProblem(root.targetLabel(root.launchTargetKey) + " failed (" + String(message || "launch cancelled") + ")")
      root.launchNotice = ""
      root.launchNoticeIsError = false
      root.startNextLoginLaunch()
    } else {
      root.launchNotice = String(message || "Launch layout cancelled.")
      root.launchNoticeIsError = true
      Quickshell.execDetached(["omarchy-shell", "osd", "show", JSON.stringify({ icon: "⚠", message: root.launchNotice, duration: 4000 })])
    }
  }
  function focusWorkspace(id) {
    var ws = root.workspaceById(id)
    if (ws) ws.activate()
    else if (root.bar) root.bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.focus({ workspace = "' + id + '" })'))
  }
  function targetIsFocused(key) { return root.isScratchpadTarget(key) ? root.scratchpadOpen : root.activeId === Number(key) }
  function focusTarget(key) {
    if (root.isScratchpadTarget(key)) {
      if (!root.scratchpadOpen) root.toggleScratchpad()
    } else root.focusWorkspace(Number(key))
  }
  function toggleScratchpad() {
    if (!root.bar) return
    var name = root.scratchpadName.indexOf("special:") === 0 ? root.scratchpadName.slice(8) : root.scratchpadName
    root.bar.run("hyprctl dispatch " + Util.shellQuote('hl.dsp.workspace.toggle_special("' + name + '")'))
  }
  function openEditor(key, anchor) {
    if (!root.validTarget(key)) return
    root.editedTargetKey = String(key)
    root.editorPreviewColor = root.colorFor(key)
    root.editorPickerOpen = false
    root.editorPage = "workspace"
    root.menuAnchor = anchor || root
    root.editorOpen = true
  }
  function open() { root.openEditor(root.validId(root.activeId) ? String(root.activeId) : "1", root) }
  function close() { root.editorPickerOpen = false; root.editorOpen = false; root.editorPage = "workspace" }
  function toggle() { root.editorOpen ? root.close() : root.open() }
  function openPicker(id) {
    root.openEditor(id, root)
    Qt.callLater(function() { root.showPicker() })
  }
  function showPicker() {
    root.editorPreviewColor = root.colorFor(root.editedTargetKey)
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
    function workspace(id: int): void { root.openEditor(String(id), root) }
    function scratchpad(): void { root.openEditor(root.scratchpadKey, root) }
    function picker(id: int): void { root.openPicker(String(id)) }
    function layouts(id: int): void { root.openEditor(String(id), root); root.openTemplateEditor(String(id), "") }
    function launch(id: int, templateId: string): void { root.launchTemplate(String(id), templateId) }
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
        readonly property color scratchpadColor: root.colorFor(root.scratchpadKey) || Color.accent
        readonly property string scratchpadStyle: root.styleFor(root.scratchpadKey)
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
            text: scratchpad.scratchpadStyle === "workspace-name" ? root.displayNameFor(root.scratchpadKey) : root.targetFallbackLabel(root.scratchpadKey)
            visible: scratchpad.scratchpadStyle !== "app-icon" && text !== ""
            color: scratchpad.scratchpadColor
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.body
          }
          Repeater {
            visible: scratchpad.scratchpadStyle !== "workspace-name"
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
    contentWidth: fittedContentWidth(Style.space(root.editorPage === "layout" ? 900 : 348))
    contentHeight: fittedContentHeight(
      root.editorPage === "layout" ? layoutEditor.implicitHeight : workspaceEditor.implicitHeight,
      Style.space(root.editorPage === "layout" ? 760 : 560)
    )
    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.editorPage === "layout" && layoutEditor.dropdownOpen
      onCloseRequested: if (!root.closePicker()) root.close()
    }
    Flickable {
      id: workspaceScroller
      anchors.fill: parent
      visible: root.editorPage === "workspace"
      clip: true
      contentWidth: width
      contentHeight: workspaceEditor.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
      WorkspaceRow {
        id: workspaceEditor
        width: workspaceScroller.width
        host: root
        targetKey: root.editedTargetKey
        workspace: root.workspaceForTarget(root.editedTargetKey)
        previewColor: root.editorPreviewColor
        onPickerRequested: root.editorPickerOpen ? root.closePicker() : root.showPicker()
      }
    }
    AppLayoutEditor {
      id: layoutEditor
      anchors.fill: parent
      visible: root.editorPage === "layout"
      host: root
      targetKey: root.editedTargetKey
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
        root.setColor(root.editedTargetKey, hex)
        root.editorPreviewColor = root.colorFor(root.editedTargetKey)
      }
    }
  }
}
