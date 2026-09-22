const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const queue = require('../AutoLaunchQueue.js')
const source = fs.readFileSync(path.join(__dirname, '..', 'Workspaces.qml'), 'utf8')

function preset(id) { return { id, name: id } }

test('snapshots configured workspaces in numeric order and preserves gaps', () => {
  const metadata = {
    10: { autoLaunchTemplateId: 'ten', templates: [preset('ten')] },
    2: { autoLaunchTemplateId: 'two', templates: [preset('two')] },
    6: { autoLaunchTemplateId: 'six', templates: [preset('six')] }
  }
  assert.deepEqual(queue.snapshot(metadata), [
    { workspaceId: 2, templateId: 'two' },
    { workspaceId: 6, templateId: 'six' },
    { workspaceId: 10, templateId: 'ten' }
  ])
})

test('snapshot ignores dangling selections and is independent of later edits', () => {
  const metadata = {
    1: { autoLaunchTemplateId: 'gone', templates: [preset('kept')] },
    3: { autoLaunchTemplateId: 'three', templates: [preset('three')] }
  }
  const result = queue.snapshot(metadata)
  metadata[3].autoLaunchTemplateId = ''
  assert.deepEqual(result, [{ workspaceId: 3, templateId: 'three' }])
})

test('appends a valid Scratchpad layout after numeric workspaces', () => {
  const metadata = {
    8: { autoLaunchTemplateId: 'eight', templates: [preset('eight')] },
    2: { autoLaunchTemplateId: 'two', templates: [preset('two')] }
  }
  const scratchpad = { autoLaunchTemplateId: 'tools', templates: [preset('tools')] }
  assert.deepEqual(queue.snapshot(metadata, scratchpad), [
    { workspaceId: 2, templateId: 'two' },
    { workspaceId: 8, templateId: 'eight' },
    { workspaceId: 'special:scratchpad', templateId: 'tools', targetKind: 'scratchpad', label: 'Scratchpad' }
  ])
})

test('supports top-level Scratchpad metadata and ignores dangling layouts', () => {
  const metadata = {
    3: { autoLaunchTemplateId: 'three', templates: [preset('three')] },
    scratchpad: { autoLaunchTemplateId: 'gone', templates: [preset('kept')] }
  }
  assert.deepEqual(queue.snapshot(metadata), [{ workspaceId: 3, templateId: 'three' }])
  assert.equal(queue.targetLabel({ workspaceId: 'special:scratchpad', targetKind: 'scratchpad' }), 'Scratchpad')
  assert.equal(queue.targetLabel({ workspaceId: 3 }), 'workspace 3')
})

test('creates a session-specific safe atomic-claim leaf', () => {
  assert.equal(queue.claimLeaf('instance/with unsafe chars'), 'workspace-display-autolaunch-instance_with_unsafe_chars.claim')
  assert.equal(queue.claimLeaf(''), '')
})

test('aggregates queue problems into one report and stays silent on success', () => {
  assert.equal(queue.problemMessage([]), '')
  assert.equal(queue.problemMessage(['workspace 2 skipped (occupied)', 'workspace 8 failed']),
    'Auto-launch finished with issues: workspace 2 skipped (occupied); workspace 8 failed.')
})

test('claims one compositor session atomically before starting the queue', () => {
  assert.match(source, /Quickshell\.env\("HYPRLAND_INSTANCE_SIGNATURE"\)/)
  assert.match(source, /loginClaimProcess\.command = \["mkdir", runtimeDir \+ "\/" \+ leaf\]/)
  assert.match(source, /onExited: function\(exitCode\) \{[\s\S]*if \(exitCode !== 0\) return[\s\S]*AutoLaunchQueue\.snapshot/)
})

test('skips occupied workspaces, continues failures, and disables manual launch', () => {
  assert.match(source, /var target = item\.targetKind === "scratchpad" \? root\.scratchpadKey : String\(item\.workspaceId\)[\s\S]*if \(root\.occupied\(target\)\) \{[\s\S]*skipped \(occupied\)[\s\S]*startNextLoginLaunch/)
  assert.match(source, /if \(automatic\) \{[\s\S]*failed \([\s\S]*root\.startNextLoginLaunch\(\)/)
  assert.match(source, /function canLaunch\(key\) \{ return !root\.launchActive && !root\.loginQueueActive/)
  assert.match(source, /function launchTemplate\(key, templateId\) \{\s*if \(root\.loginQueueActive\) return/)
})

test('focus advances only when a workspace actually begins and reports once', () => {
  const queueSection = source.slice(source.indexOf('function startNextLoginLaunch'), source.indexOf('function desktopEntry'))
  assert.doesNotMatch(queueSection, /focusWorkspace/)
  assert.match(source, /root\.beginLayoutLaunch\(target, item\.templateId, true\)/)
  assert.match(source, /function waitForLaunchWorkspace\(\) \{[\s\S]*root\.focusTarget\(root\.launchTargetKey\)/)
  assert.match(source, /function finishLoginQueue\(\) \{[\s\S]*AutoLaunchQueue\.problemMessage[\s\S]*omarchy-shell", "osd", "show"/)
})
