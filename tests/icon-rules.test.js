const test = require('node:test')
const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const vm = require('node:vm')

const source = fs.readFileSync(path.join(__dirname, '..', 'IconRules.js'), 'utf8')
  .replace(/^\.pragma library\s*$/m, '')
const rules = {}
vm.runInNewContext(source, rules, { filename: 'IconRules.js' })

test('uses initial title for a custom-class Kitty auto-launch window', () => {
  const kitty = rules.resolve('kitty', '', '', '')
  assert.equal(rules.resolve('agentic', 'brainfuck: workspace plugin', 'agentic', 'kitty'), kitty)
})

test('keeps an app-specific live title ahead of the terminal initial title', () => {
  const yazi = rules.resolve('yazi', '', '', '')
  assert.equal(rules.resolve('custom-terminal', 'Yazi: nica', 'custom-terminal', 'kitty'), yazi)
})

test('keeps the generic fallback when no window identity matches', () => {
  assert.equal(rules.resolve('unknown-class', 'unknown-title', '', ''), rules.fallback)
})
