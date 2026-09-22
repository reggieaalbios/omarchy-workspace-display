function clone(value) {
  return JSON.parse(JSON.stringify(value))
}

function listLike(value) {
  return value && typeof value !== "string" && typeof value.length === "number" ? value : []
}

function clampRatio(value) {
  var number = Number(value)
  if (!isFinite(number)) number = 1.0
  return Math.max(0.2, Math.min(1.8, number))
}

function clampColumnWidth(value) {
  var number = Number(value)
  if (!isFinite(number)) number = 0.5
  return Math.max(0.1, Math.min(1.0, number))
}

function cleanLeaf(node) {
  var id = String(node && node.appId || "").trim().replace(/\.desktop$/, "")
  var command = String(node && node.command || "").replace(/[\x00\r\n]/g, " ").trim()
  var launcherType = String(node && node.launcherType) === "command" ? "command" : "desktop"
  return { type: "leaf", launcherType: launcherType, appId: id.slice(0, 192), command: command.slice(0, 1024) }
}

function launcherKey(node) {
  var leaf = cleanLeaf(node)
  return leaf.launcherType === "command" ? "command:" + leaf.command : "desktop:" + leaf.appId
}

function launcherLabel(node) {
  var leaf = cleanLeaf(node)
  return leaf.launcherType === "command" ? leaf.command : leaf.appId
}

function cleanTree(node, depth) {
  depth = Number(depth || 0)
  if (!node || typeof node !== "object" || depth > 15) return cleanLeaf(null)
  if (String(node.type) !== "split") return cleanLeaf(node)
  return {
    type: "split",
    axis: String(node.axis) === "vertical" ? "vertical" : "horizontal",
    ratio: clampRatio(node.ratio),
    first: cleanTree(node.first, depth + 1),
    second: cleanTree(node.second, depth + 1)
  }
}

function leafIds(node, out) {
  out = out || []
  if (!node || String(node.type) !== "split") {
    out.push(launcherKey(node))
    return out
  }
  leafIds(node.first, out)
  leafIds(node.second, out)
  return out
}

function validateTree(node) {
  var ids = leafIds(cleanTree(node), [])
  for (var i = 0; i < ids.length; i++) {
    if (ids[i] === "desktop:" || ids[i] === "command:") return "Choose an app or enter a command for every pane."
  }
  return ""
}

function cleanScrollingItems(value) {
  var source = listLike(value)
  var out = []
  for (var i = 0; i < source.length && i < 24; i++) {
    var leaf = cleanLeaf(source[i])
    leaf.width = clampColumnWidth(source[i] && source[i].width)
    out.push(leaf)
  }
  if (!out.length) {
    var empty = cleanLeaf(null)
    empty.width = 0.5
    out.push(empty)
  }
  return out
}

function scrollingIds(items) {
  var clean = cleanScrollingItems(items), out = []
  for (var i = 0; i < clean.length; i++) out.push(launcherKey(clean[i]))
  return out
}

function validateIds(ids) {
  for (var i = 0; i < ids.length; i++) {
    if (ids[i] === "desktop:" || ids[i] === "command:") return "Choose an app or enter a command for every pane."
  }
  return ""
}

function validateScrolling(items) {
  return validateIds(scrollingIds(items))
}

function cleanTemplate(template, fallbackId) {
  var value = template && typeof template === "object" ? template : {}
  var id = String(value.id || fallbackId || "").replace(/[^a-zA-Z0-9._-]/g, "").slice(0, 96)
  var name = String(value.name || "").replace(/[\x00-\x1f\x7f]/g, "").trim().slice(0, 48)
  if (!id) return null
  var layoutType = String(value.layoutType) === "scrolling" ? "scrolling" : "dwindle"
  return {
    id: id,
    name: name || "App layout",
    layoutType: layoutType,
    tree: cleanTree(value.tree),
    items: cleanScrollingItems(value.items)
  }
}

function cleanTemplates(value) {
  var source = listLike(value)
  var out = [], ids = {}
  for (var i = 0; i < source.length; i++) {
    var item = cleanTemplate(source[i], "layout-" + (i + 1))
    if (!item || ids[item.id]) continue
    ids[item.id] = true
    out.push(item)
  }
  return out
}

// An auto-launch selection is meaningful only while its saved layout survives
// cleanup.  Keeping this alongside template cleanup gives loading, deletion,
// and future migrations one canonical dangling-id rule.
function cleanAutoLaunchTemplateId(value, templates) {
  var selected = typeof value === "string" ? value : ""
  if (!selected) return ""
  var clean = cleanTemplates(templates)
  for (var i = 0; i < clean.length; i++) if (clean[i].id === selected) return selected
  return ""
}

function nodeAtPath(tree, path) {
  var node = tree
  var parts = String(path || "").split("")
  for (var i = 0; i < parts.length && node; i++)
    node = parts[i] === "0" ? node.first : node.second
  return node
}

function replaceAtPath(tree, path, replacement) {
  if (!path) return clone(replacement)
  var next = clone(tree)
  var node = next
  for (var i = 0; i < path.length - 1; i++)
    node = path[i] === "0" ? node.first : node.second
  if (path[path.length - 1] === "0") node.first = clone(replacement)
  else node.second = clone(replacement)
  return next
}

function setLeafApp(tree, path, appId) {
  return replaceAtPath(tree, path, { type: "leaf", launcherType: "desktop", appId: String(appId || ""), command: "" })
}

function setLeafCommand(tree, path, command) {
  return replaceAtPath(tree, path, { type: "leaf", launcherType: "command", appId: "", command: String(command || "") })
}

function setLeafLauncherType(tree, path, launcherType) {
  var current = cleanLeaf(nodeAtPath(tree, path))
  current.launcherType = String(launcherType) === "command" ? "command" : "desktop"
  return replaceAtPath(tree, path, current)
}

function splitLeaf(tree, path, axis) {
  var current = nodeAtPath(tree, path)
  if (!current || String(current.type) === "split") return clone(tree)
  return replaceAtPath(tree, path, {
    type: "split",
    axis: String(axis) === "vertical" ? "vertical" : "horizontal",
    ratio: 1.0,
    first: cleanLeaf(current),
    second: cleanLeaf(null)
  })
}

function setRatio(tree, path, ratio) {
  var current = nodeAtPath(tree, path)
  if (!current || String(current.type) !== "split") return clone(tree)
  var replacement = clone(current)
  replacement.ratio = clampRatio(ratio)
  return replaceAtPath(tree, path, replacement)
}

function collapse(tree, path, keepSecond) {
  var current = nodeAtPath(tree, path)
  if (!current || String(current.type) !== "split") return clone(tree)
  return replaceAtPath(tree, path, keepSecond ? current.second : current.first)
}

function replaceScrollingItem(items, index, replacement) {
  var next = cleanScrollingItems(items)
  if (index < 0 || index >= next.length) return next
  var leaf = cleanLeaf(replacement)
  leaf.width = clampColumnWidth(replacement && replacement.width)
  next[index] = leaf
  return next
}

function setScrollingApp(items, index, appId) {
  var current = cleanScrollingItems(items)[index]
  return replaceScrollingItem(items, index, { launcherType: "desktop", appId: String(appId || ""), command: "", width: current && current.width })
}

function setScrollingCommand(items, index, command) {
  var current = cleanScrollingItems(items)[index]
  return replaceScrollingItem(items, index, { launcherType: "command", appId: "", command: String(command || ""), width: current && current.width })
}

function setScrollingLauncherType(items, index, launcherType) {
  var current = cleanScrollingItems(items)[index]
  if (!current) return cleanScrollingItems(items)
  current.launcherType = String(launcherType) === "command" ? "command" : "desktop"
  return replaceScrollingItem(items, index, current)
}

function setScrollingWidth(items, index, width) {
  var current = cleanScrollingItems(items)[index]
  if (!current) return cleanScrollingItems(items)
  current.width = clampColumnWidth(width)
  return replaceScrollingItem(items, index, current)
}

function addScrollingItem(items) {
  var next = cleanScrollingItems(items)
  if (next.length < 24) {
    var leaf = cleanLeaf(null)
    leaf.width = 0.5
    next.push(leaf)
  }
  return next
}

function removeScrollingItem(items, index) {
  var next = cleanScrollingItems(items)
  if (next.length <= 1 || index < 0 || index >= next.length) return next
  next.splice(index, 1)
  return next
}

function moveScrollingItem(items, index, offset) {
  var next = cleanScrollingItems(items)
  var target = index + Number(offset || 0)
  if (index < 0 || index >= next.length || target < 0 || target >= next.length) return next
  var item = next[index]
  next[index] = next[target]
  next[target] = item
  return next
}

function firstLeafRef(node, path) {
  var current = node
  var currentPath = String(path || "")
  while (current && String(current.type) === "split") {
    current = current.first
    currentPath += "0"
  }
  return { node: current, path: currentPath || "root" }
}

// Dwindle starts with one leaf. Each step expands an existing leaf, so every
// binary tree can be constructed top-down without parking or moving windows.
function buildSteps(tree) {
  var root = cleanTree(tree)
  var seedRef = firstLeafRef(root, "")
  var seed = seedRef.node
  if (!seed || !launcherLabel(seed)) return []
  var out = [{ launcher: cleanLeaf(seed), launcherKey: launcherKey(seed), stepId: seedRef.path, seed: true }]
  function expand(node, path) {
    if (!node || String(node.type) !== "split") return
    var anchorRef = firstLeafRef(node.first, path + "0")
    var siblingRef = firstLeafRef(node.second, path + "1")
    var anchor = anchorRef.node
    var sibling = siblingRef.node
    if (anchor && sibling && launcherLabel(anchor) && launcherLabel(sibling)) {
      out.push({
        launcher: cleanLeaf(sibling),
        launcherKey: launcherKey(sibling),
        stepId: siblingRef.path,
        targetStepId: anchorRef.path,
        direction: node.axis === "vertical" ? "bottom" : "right",
        ratio: clampRatio(node.ratio)
      })
    }
    expand(node.first, path + "0")
    expand(node.second, path + "1")
  }
  expand(root, "")
  return out
}

function validateTemplate(template) {
  var clean = cleanTemplate(template, "validation")
  return clean && clean.layoutType === "scrolling" ? validateScrolling(clean.items) : validateTree(clean && clean.tree)
}

function templateLauncherIds(template) {
  var clean = cleanTemplate(template, "count")
  return clean && clean.layoutType === "scrolling" ? scrollingIds(clean.items) : leafIds(clean && clean.tree, [])
}

function buildTemplateSteps(template) {
  var clean = cleanTemplate(template, "launch")
  if (!clean) return []
  if (clean.layoutType !== "scrolling") return buildSteps(clean.tree)
  var out = []
  for (var i = 0; i < clean.items.length; i++) {
    var launcher = cleanLeaf(clean.items[i])
    if (!launcherLabel(launcher)) return []
    out.push({
      launcher: launcher,
      launcherKey: launcherKey(launcher),
      stepId: "column:" + i,
      seed: i === 0,
      width: clampColumnWidth(clean.items[i].width)
    })
  }
  return out
}

if (typeof module !== "undefined") module.exports = {
  clone: clone,
  clampRatio: clampRatio,
  clampColumnWidth: clampColumnWidth,
  cleanTree: cleanTree,
  cleanScrollingItems: cleanScrollingItems,
  leafIds: leafIds,
  scrollingIds: scrollingIds,
  validateTree: validateTree,
  validateScrolling: validateScrolling,
  validateTemplate: validateTemplate,
  cleanTemplate: cleanTemplate,
  cleanTemplates: cleanTemplates,
  cleanAutoLaunchTemplateId: cleanAutoLaunchTemplateId,
  templateLauncherIds: templateLauncherIds,
  nodeAtPath: nodeAtPath,
  replaceAtPath: replaceAtPath,
  setLeafApp: setLeafApp,
  setLeafCommand: setLeafCommand,
  setLeafLauncherType: setLeafLauncherType,
  splitLeaf: splitLeaf,
  setRatio: setRatio,
  collapse: collapse,
  setScrollingApp: setScrollingApp,
  setScrollingCommand: setScrollingCommand,
  setScrollingLauncherType: setScrollingLauncherType,
  setScrollingWidth: setScrollingWidth,
  addScrollingItem: addScrollingItem,
  removeScrollingItem: removeScrollingItem,
  moveScrollingItem: moveScrollingItem,
  buildSteps: buildSteps,
  buildTemplateSteps: buildTemplateSteps
}
