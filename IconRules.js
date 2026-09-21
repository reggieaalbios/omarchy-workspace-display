.pragma library

var rules = [
  { pattern: "firefox|brave|chrom|browser", icon: "󰈹" },
  { pattern: "kitty|foot|alacritty|ghostty|terminal", icon: "󰆍" },
  { pattern: "code|zed|vim|neovim", icon: "󰨞" },
  { pattern: "discord|telegram|signal|slack", icon: "󰙯" },
  { pattern: "spotify|mpv|vlc", icon: "󰐹" },
  { pattern: "thunar|nautilus|nemo", icon: "󰝰" },
  { pattern: "figma|github", icon: "󰊤" }
]
var fallback = "󰘔"
var compiled = null
function resolve(cls, title) {
  if (!compiled) {
    compiled = []
    for (var i = 0; i < rules.length; i++) compiled.push({ re: new RegExp(rules[i].pattern, "i"), icon: rules[i].icon })
  }
  for (var j = 0; j < compiled.length; j++) if (compiled[j].re.test(cls) || compiled[j].re.test(title)) return compiled[j].icon
  return fallback
}
