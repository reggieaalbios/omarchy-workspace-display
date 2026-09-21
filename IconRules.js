.pragma library

var rules = [
  // Browser classes and well-known browser window titles.
  { pattern: "firefox|brave|chromium|google-chrome|vivaldi|librewolf|zen-browser|qutebrowser|epiphany|tor-browser", icon: "󰈹" },
  // Terminal emulators; avoid a generic `terminal` title match.
  { pattern: "kitty|foot|alacritty|ghostty|wezterm|konsole|xterm|urxvt|st-256color|rio|hyper|blackbox|ptyxis|kgx", icon: "󰆍" },
  // Editors and IDEs. `code` is deliberately bounded to prevent title collisions.
  { pattern: "(^|[^a-z])code([^a-z]|$)|code-oss|code-url-handler|vscodium|zed|neovim|nvim|(^|[^a-z])vim([^a-z]|$)|emacs|sublime|jetbrains|idea|pycharm|webstorm|clion|android-studio|lapce", icon: "󰨞" },
  // Chat and communication clients.
  { pattern: "discord|vesktop|telegram|signal|slack|element|teams|whatsapp|mumble|ferdium|franz", icon: "󰙯" },
  // Music, video, and recording applications.
  { pattern: "spotify|mpv|vlc|celluloid|amberol|rhythmbox|strawberry|audacious|kodi|musicbrainz|deadbeef", icon: "󰐹" },
  { pattern: "obs|simplescreenrecorder|kooha|wf-recorder", icon: "󰑋" },
  // File managers and terminal file browsers.
  { pattern: "thunar|nautilus|nemo|dolphin|pcmanfm|caja|yazi|ranger|lf|nnn", icon: "󰝰" },
  // Creative and design tools.
  { pattern: "figma|inkscape|gimp|krita|blender|penpot|drawio|diagrams", icon: "󰊤" },
  // Notes, office, image viewing, development collaboration, and games.
  { pattern: "obsidian|logseq|joplin|notion|zettlr", icon: "󰎞" },
  { pattern: "libreoffice|onlyoffice|wps|calibre", icon: "󰈙" },
  { pattern: "imv|loupe|eog|feh|nomacs|gwenview|ristretto|sxiv|nsxiv", icon: "󰋩" },
  { pattern: "github-desktop|gitkraken|lazygit|sourcetree", icon: "󰊢" },
  { pattern: "steam|lutris|heroic|bottles|retroarch|minecraft|prismlauncher", icon: "󰊖" },
  { pattern: "pavucontrol|blueman|nm-connection-editor|gnome-control-center|systemsettings", icon: "󰒓" }
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
