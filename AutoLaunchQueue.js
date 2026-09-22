function positiveWorkspaceId(value) {
  var id = Number(value)
  return Number.isInteger(id) && id > 0 ? id : 0
}

function templateExists(entry, templateId) {
  var templates = entry && entry.templates
  if (!templates || typeof templates.length !== "number") return false
  for (var i = 0; i < templates.length; i++)
    if (String(templates[i] && templates[i].id || "") === templateId) return true
  return false
}

function scratchpadItem(entry) {
  var templateId = String(entry && entry.autoLaunchTemplateId || "")
  if (!templateId || !templateExists(entry, templateId)) return null
  // Keep the numeric item's legacy shape intact while making the special
  // target unambiguous to the QML launcher.
  return {
    workspaceId: "special:scratchpad",
    templateId: templateId,
    targetKind: "scratchpad",
    label: "Scratchpad"
  }
}

// Take an immutable, numerically ordered view of the hydrated settings. The
// optional Scratchpad entry is always appended, because special workspaces do
// not participate in numeric ordering. The runtime queue must not change when
// the user edits settings during a session.
//
// Callers with a top-level settings document may use snapshot(workspaces,
// scratchpad). For convenience snapshot({ ..., scratchpad: entry }) also
// works, without treating "scratchpad" as a numeric workspace.
function snapshot(metadata, scratchpad) {
  var out = [], source = metadata && typeof metadata === "object" ? metadata : {}
  for (var key in source) {
    var workspaceId = positiveWorkspaceId(key), entry = source[key]
    var templateId = String(entry && entry.autoLaunchTemplateId || "")
    if (!workspaceId || !templateId || !templateExists(entry, templateId)) continue
    out.push({ workspaceId: workspaceId, templateId: templateId })
  }
  out.sort(function(a, b) { return a.workspaceId - b.workspaceId })
  var special = scratchpad === undefined ? source.scratchpad : scratchpad
  var item = scratchpadItem(special)
  if (item) out.push(item)
  return out
}

function claimLeaf(signature) {
  var value = String(signature || "").replace(/[^A-Za-z0-9_.-]/g, "_").slice(0, 192)
  return value ? "workspace-display-autolaunch-" + value + ".claim" : ""
}

function problemMessage(problems) {
  var values = problems && typeof problems.length === "number" ? problems : []
  return values.length ? "Auto-launch finished with issues: " + Array.prototype.slice.call(values).join("; ") + "." : ""
}

function targetLabel(item) {
  if (item && item.targetKind === "scratchpad") return "Scratchpad"
  var id = positiveWorkspaceId(item && item.workspaceId)
  return id ? "workspace " + id : "workspace"
}

if (typeof module !== "undefined") module.exports = {
  snapshot: snapshot,
  claimLeaf: claimLeaf,
  problemMessage: problemMessage,
  targetLabel: targetLabel
}
