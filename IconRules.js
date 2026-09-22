.pragma library

// Dynamic Nerd Font glyph lookup adapted from Decent Workspaces / the
// MIT-licensed saif.workspaces map. Hyprland class is preferred over title:
// an app keeps its glyph even when its window title describes web content.
var rules = [
  { pattern: "windows", icon: "" },
  { pattern: "ai.opencode.desktop|opencode", icon: "" },
  { pattern: "org.jellyfin.jellyfindesktop|jellyfin", icon: "󰼁" },
  { pattern: "chrome-claude.ai__-default|claude", icon: "󰭹" },
  { pattern: ".*amazon.*", icon: "󰸩" },
  { pattern: ".*github.*", icon: "󰊤" },
  { pattern: ".*figma.*", icon: "󰣙" },
  { pattern: ".*jira.*", icon: "󰗃" },
  { pattern: ".*youtube.*", icon: "󰗃" },
  { pattern: ".*reddit.*", icon: "󰑍" },
  { pattern: ".*facebook.*", icon: "󰈎" },
  { pattern: ".*messenger.*", icon: "󰈎" },
  { pattern: ".*whatsapp.*", icon: "󰖣" },
  { pattern: ".*zapzap.*", icon: "󰖣" },
  { pattern: ".*gmail.*", icon: "󰊫" },
  { pattern: ".*proton.*mail.*", icon: "󰊫" },
  { pattern: ".*chatgpt.*|.*deepseek.*|.*qwen.*", icon: "󰭹" },
  { pattern: ".*monkeytype.*", icon: "󰌌" },
  { pattern: ".*picture-in-picture.*", icon: "󰐹" },
  { pattern: "brave-x.com.*|twitter-x", icon: "󰕄" },
  { pattern: "brave-mail.proton.me.*", icon: "󰊫" },

  // Browsers
  { pattern: "firefox|org.mozilla.firefox|librewolf|floorp|mercury-browser|cachy-browser", icon: "󰈹" },
  { pattern: "zen", icon: "󰈹" },
  { pattern: "waterfox|waterfox-bin", icon: "󰈹" },
  { pattern: "microsoft-edge", icon: "󰇩" },
  { pattern: "brave-browser|brave", icon: "" },
  { pattern: "tor browser|tor-browser", icon: "󰖂" },
  { pattern: "chromium|thorium|google-chrome|chrome", icon: "󰊯" },
  { pattern: "vivaldi", icon: "" },
  { pattern: "qutebrowser", icon: "󰈹" },

  // Chat, mail, terminals, editors, and IDEs
  { pattern: "signal", icon: "󰍡" },
  { pattern: "telegram-desktop|org.telegram.desktop|io.github.tdesktop_x64.tdesktop", icon: "󰘦" },
  { pattern: "discord|webcord|vesktop", icon: "󰙯" },
  { pattern: "slack", icon: "󰒱" },
  { pattern: "element", icon: "󰘦" },
  { pattern: "teams", icon: "󰊻" },
  { pattern: "thunderbird|betterbird|claws-mail", icon: "󰇮" },
  { pattern: "org.gnome.evolution|org.gnome.geary", icon: "󰊫" },
  { pattern: "zoom", icon: "󰕧" },
  { pattern: "kitty", icon: "󰄛" },
  { pattern: "com.mitchellh.ghostty|ghostty", icon: "󰊠" },
  { pattern: "org.wezfurlong.wezterm|wezterm", icon: "󰆍" },
  { pattern: "konsole|foot|alacritty|xterm|urxvt|st-256color|rio|hyper|blackbox|ptyxis|kgx", icon: "󰆍" },
  { pattern: ".*n?vim.*", icon: "" },
  { pattern: "emacs", icon: "" },
  { pattern: "vscode|code-url-handler|code-oss|codium|vscodium|(^|[^a-z])code([^a-z]|$)", icon: "󰨞" },
  { pattern: "dev.zed.zed|zed", icon: "󱓞" },
  { pattern: "subl", icon: "󰅳" },
  { pattern: "codeblocks|geany|jetbrains-idea|idea", icon: "󰅩" },
  { pattern: "android-studio", icon: "󰀴" },
  { pattern: "mousepad", icon: "󰇾" },
  { pattern: "ghostwriter|org.kde.ghostwriter|org.gnome.texteditor", icon: "󰷈" },

  // Office, documents, files, and notes
  { pattern: "libreoffice-writer", icon: "󰈙" },
  { pattern: "libreoffice-calc", icon: "󰧷" },
  { pattern: "libreoffice-impress", icon: "󰈧" },
  { pattern: "libreoffice-startcenter|libreoffice", icon: "󰏆" },
  { pattern: "zathura", icon: "󰈦" },
  { pattern: "org.gnome.contacts", icon: "󰀉" },
  { pattern: "thunar|nemo|org.gnome.nautilus|nautilus", icon: "󰝰" },
  { pattern: "dolphin|pcmanfm|caja", icon: "󰉋" },
  { pattern: "yazi|ranger|(^|[^a-z])lf([^a-z]|$)|(^|[^a-z])nnn([^a-z]|$)", icon: "󰇥" },
  { pattern: "obsidian", icon: "󱙟" },
  { pattern: "logseq", icon: "󱓞" },
  { pattern: "joplin", icon: "󰠮" },
  { pattern: "zettlr", icon: "󰈙" },
  { pattern: "calibre", icon: "󰂺" },

  // Media and creative applications
  { pattern: "mpv|celluloid", icon: "󰐹" },
  { pattern: "vlc", icon: "󰕼" },
  { pattern: ".*cmus.*|elisa|lollypop|org.gnome.music|rhythmbox", icon: "󰝚" },
  { pattern: "spotify", icon: "󰓇" },
  { pattern: "cider|audacious", icon: "󰎆" },
  { pattern: "obs|com.obsproject.studio", icon: "󰐍" },
  { pattern: "gimp", icon: "󰏘" },
  { pattern: "inkscape", icon: "󰕙" },
  { pattern: "krita", icon: "󰏙" },
  { pattern: "blender", icon: "󰂫" },
  { pattern: "figma|penpot", icon: "󰣙" },
  { pattern: "drawio|diagrams", icon: "󰕮" },
  { pattern: "imv|loupe|eog|feh|nomacs|gwenview|ristretto|sxiv|nsxiv", icon: "󰋩" },

  // System, development, and gaming tools
  { pattern: "github-desktop|gitkraken|lazygit|sourcetree", icon: "󰊢" },
  { pattern: "cake_wallet|feather|exodus", icon: "󰠓" },
  { pattern: "transmission|fragments", icon: "󰄠" },
  { pattern: "virt-manager|virt-manager-wrapped|virtualbox", icon: "󰍺" },
  { pattern: "remmina", icon: "󰢹" },
  { pattern: "polkit-gnome-authentication-agent-1", icon: "󰒃" },
  { pattern: "nwg-look", icon: "󰔡" },
  { pattern: "pavucontrol|org.pulseaudio.pavucontrol|helvum", icon: "󰓃" },
  { pattern: "gparted", icon: "󰋊" },
  { pattern: "steam", icon: "󰓓" },
  { pattern: "lutris|heroic", icon: "󰊖" },
  { pattern: "bottles", icon: "󰡴" },
  { pattern: "retroarch|emulator", icon: "󰄭" },
  { pattern: "prismlauncher|minecraft", icon: "󰍳" },
  { pattern: "prusaslicer|ultimaker-cura|orcaslicer", icon: "󰐫" }
]

var fallback = "󰘔"
var compiled = null
var cache = {}
var cacheCount = 0
var cacheLimit = 500

function patterns() {
  if (compiled) return compiled
  compiled = []
  for (var i = 0; i < rules.length; i++) compiled.push({ re: new RegExp(rules[i].pattern, "i"), icon: rules[i].icon })
  return compiled
}

function resolve(cls, title, initialClass, initialTitle) {
  var values = [cls, initialClass, title, initialTitle]
  var key = values.join("\u0001")
  var hit = cache[key]
  if (hit !== undefined) return hit

  var set = patterns()
  var icon = fallback
  for (var valueIndex = 0; valueIndex < values.length && icon === fallback; valueIndex++) {
    var value = String(values[valueIndex] || "")
    for (var ruleIndex = 0; ruleIndex < set.length; ruleIndex++) {
      if (set[ruleIndex].re.test(value)) { icon = set[ruleIndex].icon; break }
    }
  }

  if (cacheCount >= cacheLimit) { cache = {}; cacheCount = 0 }
  cache[key] = icon
  cacheCount++
  return icon
}
