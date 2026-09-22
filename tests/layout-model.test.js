const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const model = require('../LayoutModel.js')

test('cleans split trees and clamps ratios', () => {
  const tree = model.cleanTree({
    type: 'split', axis: 'vertical', ratio: 9,
    first: { type: 'leaf', appId: 'code.desktop' },
    second: { type: 'leaf', appId: 'org.mozilla.firefox' }
  })
  assert.equal(tree.axis, 'vertical')
  assert.equal(tree.ratio, 1.8)
  assert.deepEqual(model.leafIds(tree), ['desktop:code', 'desktop:org.mozilla.firefox'])
})

test('requires every leaf to have a launcher and allows duplicates', () => {
  const tree = {
    type: 'split', axis: 'horizontal', ratio: 1,
    first: { type: 'leaf', appId: 'code' },
    second: { type: 'leaf', appId: 'code' }
  }
  assert.equal(model.validateTree(tree), '')
  tree.second.appId = ''
  assert.match(model.validateTree(tree), /every pane/)
})

test('edits a leaf without mutating the original tree', () => {
  const original = { type: 'leaf', appId: 'code' }
  const split = model.splitLeaf(original, '', 'horizontal')
  const assigned = model.setLeafApp(split, '1', 'kitty')
  const resized = model.setRatio(assigned, '', 1.4)
  assert.deepEqual(original, { type: 'leaf', appId: 'code' })
  assert.deepEqual(model.leafIds(resized), ['desktop:code', 'desktop:kitty'])
  assert.equal(resized.ratio, 1.4)
  assert.deepEqual(model.collapse(resized, '', true), { type: 'leaf', launcherType: 'desktop', appId: 'kitty', command: '' })
})

test('supports command launchers while preserving old desktop leaves', () => {
  const command = model.setLeafCommand({ type: 'leaf', appId: 'code' }, '', 'kitty --class notes')
  assert.equal(model.validateTree(command), '')
  assert.deepEqual(model.leafIds(command), ['command:kitty --class notes'])
  assert.equal(model.cleanTree({ type: 'leaf', appId: 'code' }).launcherType, 'desktop')
})

test('builds an arbitrary tree top-down for Dwindle', () => {
  const tree = {
    type: 'split', axis: 'horizontal', ratio: 1.2,
    first: { type: 'leaf', appId: 'code' },
    second: {
      type: 'split', axis: 'vertical', ratio: 0.8,
      first: { type: 'leaf', appId: 'firefox' },
      second: { type: 'leaf', appId: 'kitty' }
    }
  }
  assert.deepEqual(model.buildSteps(tree), [
    { launcher: { type: 'leaf', launcherType: 'desktop', appId: 'code', command: '' }, launcherKey: 'desktop:code', stepId: '0', seed: true },
    { launcher: { type: 'leaf', launcherType: 'desktop', appId: 'firefox', command: '' }, launcherKey: 'desktop:firefox', stepId: '10', targetStepId: '0', direction: 'right', ratio: 1.2 },
    { launcher: { type: 'leaf', launcherType: 'desktop', appId: 'kitty', command: '' }, launcherKey: 'desktop:kitty', stepId: '11', targetStepId: '10', direction: 'bottom', ratio: 0.8 }
  ])
})

test('drops duplicate template ids and repairs malformed values', () => {
  const templates = model.cleanTemplates([
    { id: 'one', name: ' Main ', tree: { type: 'leaf', appId: 'code' } },
    { id: 'one', name: 'Duplicate', tree: { type: 'leaf', appId: 'kitty' } },
    { id: 'bad id!', tree: null }
  ])
  assert.equal(templates.length, 2)
  assert.equal(templates[0].name, 'Main')
  assert.equal(templates[0].layoutType, 'dwindle')
  assert.equal(templates[1].id, 'badid')
})

test('version 4 auto-launch ids survive only when they match a cleaned preset', () => {
  const templates = model.cleanTemplates([
    { id: 'morning', name: 'Morning', tree: { type: 'leaf', appId: 'code' } },
    { id: 'bad id!', name: 'Cleaned id', tree: { type: 'leaf', appId: 'kitty' } },
    { id: 'morning', name: 'Duplicate', tree: { type: 'leaf', appId: 'firefox' } }
  ])

  assert.equal(model.cleanAutoLaunchTemplateId('morning', templates), 'morning')
  assert.equal(model.cleanAutoLaunchTemplateId('bad id!', templates), '')
  assert.equal(model.cleanAutoLaunchTemplateId('badid', templates), 'badid')
  assert.equal(model.cleanAutoLaunchTemplateId(123, templates), '')
})

test('auto-launch keeps at most one preset per workspace and permits gaps', () => {
  const workspaces = {
    2: { templates: [{ id: 'work', tree: { type: 'leaf', appId: 'code' } }], autoLaunchTemplateId: 'work' },
    7: { templates: [{ id: 'chat', tree: { type: 'leaf', appId: 'signal' } }], autoLaunchTemplateId: 'chat' }
  }
  const selections = Object.keys(workspaces).map(id =>
    model.cleanAutoLaunchTemplateId(workspaces[id].autoLaunchTemplateId, workspaces[id].templates))

  assert.deepEqual(selections, ['work', 'chat'])
  assert.equal(typeof selections[0], 'string')
})

test('deleting the selected preset resets auto-launch to Off', () => {
  const templates = [
    { id: 'keep', tree: { type: 'leaf', appId: 'code' } },
    { id: 'remove', tree: { type: 'leaf', appId: 'kitty' } }
  ]
  const remaining = templates.filter(template => template.id !== 'remove')

  assert.equal(model.cleanAutoLaunchTemplateId('remove', remaining), '')
  assert.equal(model.cleanAutoLaunchTemplateId('keep', remaining), 'keep')
})

test('metadata loader remains compatible with version 1 through 4 files', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  for (const version of [1, 2, 3, 4]) {
    const payload = JSON.stringify({
      version,
      workspaces: { 3: { templates: [{ id: 'legacy', tree: { type: 'leaf', appId: 'code' } }] } }
    })
    const parsed = JSON.parse(payload)
    assert.equal(model.cleanTemplates(parsed.workspaces['3'].templates)[0].id, 'legacy')
  }
  assert.match(source, /JSON\.stringify\(\{ version: 5, workspaces: root\.metadata, scratchpad: root\.scratchpadMetadata \}/)
  assert.doesNotMatch(source, /parsed\.version\s*[!=]==?\s*5/)
})

test('version 5 keeps Scratchpad metadata separate and cleans its selected layout', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  const templates = model.cleanTemplates([{ id: 'scratch-layout', tree: { type: 'leaf', appId: 'kitty' } }])
  assert.equal(model.cleanAutoLaunchTemplateId('scratch-layout', templates), 'scratch-layout')
  assert.equal(model.cleanAutoLaunchTemplateId('missing', templates), '')
  assert.match(source, /property var scratchpadMetadata: \(\{\}\)/)
  assert.match(source, /function isScratchpadTarget\(key\) \{ return String\(key\) === root\.scratchpadKey \}/)
  assert.match(source, /root\.scratchpadMetadata = root\.cleanEntry\(parsed && parsed\.scratchpad\)/)
  assert.match(source, /if \(root\.isScratchpadTarget\(key\)\) root\.scratchpadMetadata = item/)
  assert.match(source, /version: 5, workspaces: root\.metadata, scratchpad: root\.scratchpadMetadata/)
})

test('persistence exposes one immediate auto-launch selection per target', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  assert.match(source, /function autoLaunchTemplateIdFor\(key\)/)
  assert.match(source, /function autoLaunchOptionsFor\(key\)[\s\S]*value: "", label: "Off"/)
  assert.match(source, /function setAutoLaunchTemplateId\(key, value\) \{ root\.updateEntry\(key, \{ autoLaunchTemplateId: value \}\) \}/)
  assert.match(source, /item\.autoLaunchTemplateId = LayoutModel\.cleanAutoLaunchTemplateId\(item\.autoLaunchTemplateId, item\.templates\)/)
  assert.match(source, /root\.scratchpadMetadata = root\.cleanEntry\(parsed && parsed\.scratchpad\)[\s\S]*root\.claimLoginAutoLaunch\(\)/)
})

test('cleans and edits scrolling columns without mutating the source', () => {
  const original = [{ launcherType: 'desktop', appId: 'code.desktop', width: 9 }]
  const added = model.addScrollingItem(original)
  const commanded = model.setScrollingCommand(added, 1, 'kitty --class notes')
  const resized = model.setScrollingWidth(commanded, 1, 0.667)
  const moved = model.moveScrollingItem(resized, 1, -1)

  assert.deepEqual(original, [{ launcherType: 'desktop', appId: 'code.desktop', width: 9 }])
  assert.equal(moved[0].command, 'kitty --class notes')
  assert.equal(moved[0].width, 0.667)
  assert.equal(moved[1].appId, 'code')
  assert.equal(moved[1].width, 1)
  assert.equal(model.removeScrollingItem(moved, 0).length, 1)
})

test('preserves QML list-like scrolling columns after reload', () => {
  const qmlList = {
    0: { launcherType: 'desktop', appId: 'brave-browser', width: 0.5 },
    1: { launcherType: 'desktop', appId: 'disk-usage', width: 0.5 },
    2: { launcherType: 'desktop', appId: 'btop', width: 0.5 },
    length: 3
  }
  assert.equal(Array.isArray(qmlList), false)
  assert.equal(model.cleanScrollingItems(qmlList).length, 3)
})

test('validates and builds ordered scrolling launch steps', () => {
  const template = {
    id: 'scroll', name: 'Tape', layoutType: 'scrolling',
    items: [
      { launcherType: 'desktop', appId: 'code', width: 0.333 },
      { launcherType: 'command', command: 'kitty --class monitor btop', width: 0.667 }
    ]
  }
  assert.equal(model.validateTemplate(template), '')
  assert.deepEqual(model.buildTemplateSteps(template), [
    { launcher: { type: 'leaf', launcherType: 'desktop', appId: 'code', command: '' }, launcherKey: 'desktop:code', stepId: 'column:0', seed: true, width: 0.333 },
    { launcher: { type: 'leaf', launcherType: 'command', appId: '', command: 'kitty --class monitor btop' }, launcherKey: 'command:kitty --class monitor btop', stepId: 'column:1', seed: false, width: 0.667 }
  ])

  template.items[1] = { launcherType: 'desktop', appId: 'code', width: 0.5 }
  assert.equal(model.validateTemplate(template), '')
})

test('duplicate Dwindle launchers retain distinct pane identities', () => {
  const steps = model.buildSteps({
    type: 'split', axis: 'horizontal', ratio: 1,
    first: { type: 'leaf', appId: 'kitty' },
    second: { type: 'leaf', appId: 'kitty' }
  })
  assert.equal(steps[0].launcherKey, steps[1].launcherKey)
  assert.notEqual(steps[0].stepId, steps[1].stepId)
  assert.equal(steps[1].targetStepId, steps[0].stepId)
})

test('uses structured window selectors and confirms the launch workspace', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  assert.match(source, /focus\(\{ window = \"address:/)
  assert.match(source, /window\.move\(\{ workspace =[\s\S]*window = \"address:/)
  assert.doesNotMatch(source, /hl\.get_window\(/)
  assert.match(source, /root\.targetIsFocused\(root\.launchTargetKey\)/)
  assert.match(source, /hl\.dsp\.window\.move\(\{ workspace =/)
  assert.match(source, /return "0x" \+ address\.replace\(\/\^0x\/i, ""\)/)
  assert.match(source, /hl\.workspace_rule\(\{ workspace =/)
  assert.match(source, /hl\.dsp\.layout\(\"colresize /)
  assert.match(source, /layout === root\.launchLayoutType/)
})

test('desktop-entry launches override per-app window state without changing commands', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  assert.match(source, /function enforceDesktopLaunchWindow\(step, address\)/)
  assert.match(source, /return candidates\.length === 1 \? candidates\[0\] : null/)
  assert.match(source, /launcherType\) === "command"\) return/)
  assert.match(source, /dispatch hl\.dsp\.window\.fullscreen\(\{ mode = "fullscreen", action = "unset"/)
  assert.match(source, /dispatch hl\.dsp\.window\.fullscreen\(\{ mode = "maximized", action = "unset"/)
  assert.match(source, /dispatch hl\.dsp\.window\.pin\(\{ action = "off"/)
  assert.match(source, /dispatch hl\.dsp\.window\.pseudo\(\{ action = "off"/)
  assert.match(source, /dispatch hl\.dsp\.window\.float\(\{ action = "off"/)
  assert.match(source, /Quickshell\.execDetached\(\["hyprctl", "--batch", calls\.join\("; "\)\]\)/)
  assert.match(source, /function rememberDesktopLaunchWindow\(step, address\)/)
  assert.match(source, /launchEnforcePassesRemaining = 10/)
  assert.match(source, /Timer \{ id: launchEnforceTimer; interval: 160; repeat: true/)
  assert.match(source, /root\.enforceDesktopAddresses\(root\.launchDesktopAddresses\)/)
  assert.match(source, /root\.rememberDesktopLaunchWindow\(step, address\)/)
  assert.match(source, /launchPendingTileAddress !== address[\s\S]*root\.enforceDesktopLaunchWindow\(step, address\)[\s\S]*return/)
  assert.match(source, /root\.windowIsFloating\(window\)[\s\S]*root\.enforceDesktopLaunchWindow\(step, address\)[\s\S]*return/)
  assert.match(source, /launchTileStableChecks\+\+[\s\S]*launchTileStableChecks < 2\) return[\s\S]*launchPoll\.stop\(\)/)
  assert.doesNotMatch(source, /windowrulev2|hyprctl keyword/)
})

test('recursive layout nodes keep host bindings and safe theme fallbacks', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'LayoutNode.qml'), 'utf8')
  assert.match(source, /property: "host"[\s\S]*value: root\.host/)
  assert.match(source, /property: "nodePath"[\s\S]*value: root\.nodePath/)
  assert.match(source, /root\.host \? root\.host\.surfaceColor : Color\.background/)
  assert.doesNotMatch(source, /color: root\.host\.surfaceColor/)
})

test('split controls resize live and remove individual panes', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'LayoutNode.qml'), 'utf8')
  assert.match(source, /readonly property real requestedFraction: previewFraction >= 0 \? previewFraction : fraction/)
  assert.match(source, /readonly property real effectiveFraction: splitView\.clampFraction\(requestedFraction\)/)
  assert.match(source, /property real pointerOffset: 0/)
  assert.match(source, /splitView\.updatePreview\(mouse\)/)
  assert.match(source, /splitView\.previewFraction \* 2/)
  assert.match(source, /text: "X"/)
  assert.match(source, /tooltipText: "Remove pane"/)
  assert.match(source, /root\.host\.removePane\(root\.nodePath\)/)
  assert.doesNotMatch(source, /ratioText|Remove split|Keep [12]|drag\.target/)
  assert.match(source, /id: splitControls[\s\S]*?anchors\.centerIn: parent/)
  assert.match(source, /parent\.height - launcherHeader\.height - root\.launcherInputHeight - parent\.spacing \* 2/)
  assert.match(source, /text: "Split ↔"[\s\S]*?tooltipText: "Split horizontally"[\s\S]*?bordered: true[\s\S]*?focusable: true/)
  assert.match(source, /text: "Split ↕"[\s\S]*?tooltipText: "Split vertically"[\s\S]*?bordered: true[\s\S]*?focusable: true/)

  const editor = fs.readFileSync(path.join(__dirname, '..', 'AppLayoutEditor.qml'), 'utf8')
  assert.match(editor, /function removePane\(path\)/)
  assert.match(editor, /var removeFirst = path\.slice\(-1\) === "0"/)
  assert.match(editor, /LayoutModel\.collapse\(root\.draftTree, parentPath, removeFirst\)/)
})

test('Dwindle panes preserve usable dimensions and compact launcher controls only when needed', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'LayoutNode.qml'), 'utf8')
  assert.match(source, /readonly property int leafMinimumWidth: Style\.space\(190\)/)
  assert.match(source, /readonly property int leafMinimumHeight: Style\.space\(128\)/)
  assert.match(source, /function minimumWidth\(node\)/)
  assert.match(source, /function minimumHeight\(node\)/)
  assert.match(source, /function clampFraction\(value\)/)
  assert.match(source, /firstMinimum \+ secondMinimum > available/)
  assert.match(source, /enabled: root\.width >= root\.leafMinimumWidth \* 2 \+ root\.dividerSize/)
  assert.match(source, /enabled: root\.height >= root\.leafMinimumHeight \* 2 \+ root\.dividerSize/)
  assert.match(source, /readonly property bool compactLauncherHeader: launcherHeader\.width < desktopFullButton\.implicitWidth/)
  assert.match(source, /id: desktopTypeButton[\s\S]*?iconText: "▦"[\s\S]*?text: leafCard\.compactLauncherHeader \? "" : "Desktop app"[\s\S]*?width: leafCard\.compactLauncherHeader \? removePaneButton\.implicitWidth : implicitWidth[\s\S]*?iconSize: Style\.font\.caption/)
  assert.match(source, /id: commandTypeButton[\s\S]*?iconText: ">_"[\s\S]*?text: leafCard\.compactLauncherHeader \? "" : "Command"[\s\S]*?width: leafCard\.compactLauncherHeader \? removePaneButton\.implicitWidth : implicitWidth[\s\S]*?iconSize: Style\.font\.caption/)
  assert.match(source, /desktopTypeButton\.width[\s\S]*?commandTypeButton\.width/)
})

test('layout editor controls expose selected, hover, and keyboard focus states', () => {
  const node = fs.readFileSync(path.join(__dirname, '..', 'LayoutNode.qml'), 'utf8')
  assert.match(node, /selected: String\(root\.node && root\.node\.launcherType \|\| "desktop"\) === "desktop"/)
  assert.match(node, /selected: String\(root\.node && root\.node\.launcherType \|\| "desktop"\) === "command"/)
  assert.doesNotMatch(node, /enabled: String\(root\.node && root\.node\.launcherType/)
  assert.ok((node.match(/bordered: true/g) || []).length >= 3)
  assert.ok((node.match(/focusable: true/g) || []).length >= 3)

  const editor = fs.readFileSync(path.join(__dirname, '..', 'AppLayoutEditor.qml'), 'utf8')
  assert.doesNotMatch(editor, /text: "← Back"/)
  assert.match(editor, /text: "Cancel"[\s\S]*bordered: true[\s\S]*focusable: true/)
  assert.match(editor, /text: "Save layout"[\s\S]*selected: true[\s\S]*bordered: true[\s\S]*focusable: true/)
})

test('workspace panel stays compact outside the layout editor', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  const row = fs.readFileSync(path.join(__dirname, '..', 'WorkspaceRow.qml'), 'utf8')
  const selector = fs.readFileSync(path.join(__dirname, '..', 'StyleSelector.qml'), 'utf8')
  assert.match(source, /root\.editorPage === "layout" \? 900 : 348/)
  assert.match(source, /root\.editorPage === "layout" \? 760 : 560/)
  assert.match(source, /function launch\(id: int, templateId: string\): void \{ root\.launchTemplate\(String\(id\), templateId\) \}/)
  assert.match(row, /StyleSelector \{\s+width: parent\.width/)
  assert.match(selector, /width: \(root\.width - root\.spacing \* 2\) \/ 3/)
})

test('workspace and Scratchpad IPC bindings toggle their exact editor target', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  assert.match(source, /function toggleEditorFor\(key, anchor\)/)
  assert.match(source, /root\.editorOpen && root\.editedTargetKey === key/)
  assert.match(source, /function workspace\(id: int\): void \{ root\.toggleEditorFor\(String\(id\), root\) \}/)
  assert.match(source, /function scratchpad\(\): void \{ root\.toggleEditorFor\(root\.scratchpadKey, root\) \}/)
})

test('workspace auto-launch dropdown owns arrow keys while open', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')
  const row = fs.readFileSync(path.join(__dirname, '..', 'WorkspaceRow.qml'), 'utf8')
  assert.match(row, /readonly property bool dropdownOpen: autoLaunchDropdown\.popupOpen/)
  assert.match(source, /root\.editorPage === "workspace" && workspaceEditor\.dropdownOpen/)
})

test('launch layout rows use two-line content with centered icon actions', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'WorkspaceRow.qml'), 'utf8')
  assert.match(source, /id: layoutIcon[\s\S]*anchors\.verticalCenter: parent\.verticalCenter/)
  assert.match(source, /id: actionButtons[\s\S]*anchors\.verticalCenter: parent\.verticalCenter/)
  assert.match(source, /text: String\(templateCard\.modelData\.name \|\| "Launch layout"\)/)
  assert.match(source, /templateLayoutLabel\(templateCard\.modelData\)[\s\S]*" apps"/)
  assert.match(source, /id: launchButton[\s\S]*tooltipText: templateCard\.isRunning \? "Launching layout" : "Launch layout"/)
  assert.match(source, /id: editButton[\s\S]*tooltipText: "Edit layout"/)
  assert.match(source, /id: deleteButton[\s\S]*iconText: templateCard\.deleteArmed \? "󰄬" : "󰆴"/)
  assert.match(source, /tooltipText: templateCard\.deleteArmed \? "Confirm delete" : "Delete layout"/)
  assert.match(source, /id: deleteArmTimeout[\s\S]*interval: 3000/)
  assert.doesNotMatch(source, /id: moreButton|id: morePopup/)
  assert.doesNotMatch(source, /\(templateCard\.index \+ 1\) \+ "\. "/)
})

test('target auto-launch uses the themed dropdown and persists changes immediately', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'WorkspaceRow.qml'), 'utf8')
  assert.match(source, /text: "AUTO-LAUNCH AT LOGIN"/)
  assert.match(source, /Column \{\s+width: parent\.width\s+spacing: Style\.space\(6\)\s+Row \{[\s\S]*text: "LAUNCH LAYOUTS"[\s\S]*text: "AUTO-LAUNCH AT LOGIN"/)
  assert.match(source, /required property string targetKey/)
  assert.match(source, /function autoLaunchOptions\(\) \{[\s\S]*\{ value: "", label: "Off" \}[\s\S]*templatesFor\(root\.targetKey\)/)
  assert.match(source, /Dropdown \{[\s\S]*id: autoLaunchDropdown[\s\S]*value: root\.host\.autoLaunchTemplateIdFor\(root\.targetKey\)[\s\S]*options: root\.autoLaunchOptions\(\)/)
  assert.match(source, /onChanged: function\(templateId\) \{\s*root\.host\.setAutoLaunchTemplateId\(root\.targetKey, templateId\)\s*\}/)

  const heading = source.indexOf('text: "AUTO-LAUNCH AT LOGIN"')
  const cards = source.indexOf('model: root.host.templatesFor(root.targetKey)', heading)
  assert.ok(heading !== -1 && cards > heading)
})

test('exactly one selected target preset card can show the AUTO badge', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'WorkspaceRow.qml'), 'utf8')
  assert.equal((source.match(/id: autoBadge\b/g) || []).length, 1)
  assert.equal((source.match(/text: "AUTO"/g) || []).length, 1)
  assert.match(source, /id: autoBadge[\s\S]*visible: root\.host\.autoLaunchTemplateIdFor\(root\.targetKey\) === templateCard\.modelData\.id/)
  assert.match(source, /Repeater \{\s*model: root\.host\.templatesFor\(root\.targetKey\)/)
})

test('workspace editor components use target keys so Scratchpad shares the full editor', () => {
  const row = fs.readFileSync(path.join(__dirname, '..', 'WorkspaceRow.qml'), 'utf8')
  const editor = fs.readFileSync(path.join(__dirname, '..', 'AppLayoutEditor.qml'), 'utf8')
  assert.match(row, /text: root\.host\.targetLabel\(root\.targetKey\)/)
  assert.match(row, /placeholderText: root\.host\.targetFallbackLabel\(root\.targetKey\)/)
  assert.match(row, /root\.host\.openTemplateEditor\(root\.targetKey,/)
  assert.match(row, /root\.host\.launchTemplate\(root\.targetKey,/)
  assert.match(editor, /required property string targetKey/)
  assert.match(editor, /root\.host\.saveTemplate\(root\.targetKey,/)
  assert.match(editor, /root\.host\.targetLabel\(root\.targetKey\)\.toUpperCase\(\)/)
  assert.doesNotMatch(editor, /required property int workspaceId/)
})

test('layout preview has no redundant outer container', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'AppLayoutEditor.qml'), 'utf8')
  assert.match(source, /LayoutNode \{[\s\S]*?width: parent\.width\s+height: Style\.space\(430\)/)
  assert.doesNotMatch(source, /anchors\.margins: Style\.space\(8\)/)
})

test('layout editor separates its name and layout sections', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'AppLayoutEditor.qml'), 'utf8')
  assert.match(source, /id: nameField[\s\S]*?PanelSeparator \{[\s\S]*?PanelSectionHeader \{\s+text: "LAYOUT TYPE"/)
  assert.match(source, /text: "LAYOUT TYPE"[\s\S]*?Row \{\s+spacing: Style\.space\(6\)\s+Button \{\s+text: "▦  Dwindle"/)
  assert.match(source, /Button \{\s+text: "▤  Scrolling"/)
  assert.equal((source.match(/PanelSeparator \{/g) || []).length, 2)
  assert.match(source, /define the Dwindle layout\."[\s\S]*?PanelSeparator \{[\s\S]*?LayoutNode \{/)
})

test('layout editor exposes separate Dwindle and Scrolling modes', () => {
  const editor = fs.readFileSync(path.join(__dirname, '..', 'AppLayoutEditor.qml'), 'utf8')
  const scrolling = fs.readFileSync(path.join(__dirname, '..', 'ScrollingLayoutEditor.qml'), 'utf8')
  assert.match(editor, /text: "▦  Dwindle"/)
  assert.match(editor, /text: "▤  Scrolling"/)
  assert.match(editor, /ScrollingLayoutEditor/)
  assert.match(scrolling, /text: "\+ Add column"/)
  assert.match(scrolling, /model: \[0\.333, 0\.5, 0\.667, 1\.0\]/)
  assert.match(scrolling, /root\.host\.moveScrollingItem/)
  assert.match(scrolling, /readonly property int columnWidth: Style\.space\(280\)/)
  assert.ok((scrolling.match(/width: root\.columnWidth/g) || []).length >= 2)
  assert.match(scrolling, /id: addColumnCard[\s\S]*?border\.color: Color\.popups\.border[\s\S]*?anchors\.centerIn: parent[\s\S]*?text: "\+ Add column"/)
})

test('scrolling column move controls are centered on both axes', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'ScrollingLayoutEditor.qml'), 'utf8')
  assert.match(source, /id: moveControls\s+anchors\.centerIn: parent/)
  assert.doesNotMatch(source, /anchors\.horizontalCenter: parent\.horizontalCenter[\s\S]*?text: "← Move"/)
})

test('scrolling column sections have readable vertical separation', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'ScrollingLayoutEditor.qml'), 'utf8')
  assert.match(source, /id: columnSections\s+anchors\.fill: parent\s+anchors\.margins: Style\.space\(7\)\s+spacing: Style\.space\(9\)/)
})

test('scrolling launcher controls show labels until the column becomes too narrow', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'ScrollingLayoutEditor.qml'), 'utf8')
  assert.match(source, /readonly property bool compactLauncherHeader: launcherHeader\.width < desktopFullButton\.implicitWidth/)
  assert.match(source, /id: desktopButton[\s\S]*?iconText: "▦"[\s\S]*?text: card\.compactLauncherHeader \? "" : "Desktop app"/)
  assert.match(source, /id: commandButton[\s\S]*?iconText: ">_"[\s\S]*?text: card\.compactLauncherHeader \? "" : "Command"/)
})

test('scrolling width options stay contained in narrow cards', () => {
  const source = fs.readFileSync(path.join(__dirname, '..', 'ScrollingLayoutEditor.qml'), 'utf8')
  assert.match(source, /Text \{\s+text: "COLUMN WIDTH"[\s\S]*?Flow \{\s+width: parent\.width/)
  assert.match(source, /model: \[0\.333, 0\.5, 0\.667, 1\.0\][\s\S]*?width: Math\.max\(implicitWidth, \(parent\.width - Style\.space\(3\) \* 3\) \/ 4\)[\s\S]*?text: Math\.round\(modelData \* 100\) \+ "%"/)
})

test('desktop and command launcher inputs use the same theme-native height', () => {
  for (const file of ['LayoutNode.qml', 'ScrollingLayoutEditor.qml']) {
    const source = fs.readFileSync(path.join(__dirname, '..', file), 'utf8')
    assert.match(source, /readonly property int launcherInputHeight: Style\.spacing\.controlHeight/)
    assert.match(source, /height: root\.launcherInputHeight\s+rowHeight: root\.launcherInputHeight/)
    assert.ok((source.match(/height: root\.launcherInputHeight/g) || []).length >= 2)
  }
})

test('application selectors toggle closed when their trigger is clicked again', () => {
  const dropdown = fs.readFileSync(path.join(__dirname, '..', 'LauncherSearchableDropdown.qml'), 'utf8')
  const node = fs.readFileSync(path.join(__dirname, '..', 'LayoutNode.qml'), 'utf8')
  const scrolling = fs.readFileSync(path.join(__dirname, '..', 'ScrollingLayoutEditor.qml'), 'utf8')
  assert.match(dropdown, /import qs\.Ui/)
  assert.match(dropdown, /closePolicy: QQC\.Popup\.CloseOnEscape \| QQC\.Popup\.CloseOnPressOutsideParent/)
  assert.match(node, /LauncherSearchableDropdown \{/)
  assert.match(scrolling, /LauncherSearchableDropdown \{/)
})
