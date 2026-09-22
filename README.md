# Workspace Display

Workspace Display enhances Omarchy's numeric workspace bar with per-workspace
names, colours, app glyphs, Scratchpad presentation, saved Dwindle or Scrolling
layouts, manual workspace app launch, and login auto-launch.

It targets Omarchy Quattro with Hyprland and Quickshell. Saved layouts create
an initial arrangement when their applications launch; they do not continuously
enforce window geometry afterward.

![Workspace Display layout and login auto-launch controls](preview.png)

## Install

```bash
omarchy plugin add https://github.com/reggieaalbios/omarchy-workspace-display.git --enable
```

## Update, disable, and remove

```bash
omarchy plugin update io.github.reggieaalbios.workspace-display
omarchy plugin disable io.github.reggieaalbios.workspace-display
omarchy plugin remove io.github.reggieaalbios.workspace-display
```

## Controls

- Left-click a workspace to switch to it.
- Right-click a workspace to open its display editor.
- Add multiple named app-launch layouts for numeric workspaces and the
  Scratchpad.
- Build a visual **Dwindle** split tree with horizontal or vertical divisions,
  or an ordered **Scrolling** tape with 33%, 50%, 67%, and 100% columns.
- Select one saved layout per workspace or Scratchpad for login auto-launch.
  Numeric workspaces launch in ascending order, followed by the Scratchpad.
- Launch a saved layout manually only while its target is empty. Existing
  windows are never moved or closed by the plugin.
- Click the scratchpad indicator to toggle the scratchpad.

Login auto-launch runs once per Hyprland session. Occupied targets are left
untouched while the queue continues, successful runs remain silent, and skipped
or failed entries are reported together after the queue finishes.

Applications are selected from Quickshell's desktop-entry catalogue and launch
through Omarchy's UWSM-safe `uwsm-app` route. Each pane can use an installed
desktop entry through `gtk-launch` or an explicit custom command through
`sh -lc`. Desktop-entry windows captured by a launch are normalized into tiled
state so application-specific floating, pinned, fullscreen, maximized, or
pseudotiled defaults cannot bypass the saved arrangement. These overrides apply
only to the exact windows created by that launch. Custom commands retain their
defined behavior.

Launches are serialized and wait for each new window before continuing. When an
application does not produce a matching window before the timeout, the plugin
continues with the remaining applications and reports the missing entry.

## Keybindings

The plugin does not change Hyprland bindings when it is installed. To open the
editor for workspaces 1 through 10 with `SUPER + CTRL + ALT + 1…0`, add the
following to `~/.config/hypr/bindings.lua`:

```lua
-- Warning: these bindings replace existing SUPER + CTRL + ALT + 1…0 and S bindings.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  hl.unbind("SUPER + CTRL + ALT + " .. key)
  o.bind("SUPER + CTRL + ALT + " .. key,
    "Workspace " .. workspace .. " display settings",
    "omarchy-shell io.github.reggieaalbios.workspace-display.settings workspace " .. workspace)
end

hl.unbind("SUPER + CTRL + ALT + S")
o.bind("SUPER + CTRL + ALT + S", "Scratchpad display settings",
  "omarchy-shell io.github.reggieaalbios.workspace-display.settings scratchpad")
```

Run `hyprctl reload` after changing your bindings.

## Data and attribution

Workspace presentation metadata, app-launch layouts, and login auto-launch
selections are stored in `~/.config/omarchy/workspace-manager.json` through
Quickshell's atomic `FileView` path. Data from schema versions 1 through 4 is
loaded without migration loss; version 5 stores Scratchpad presentation,
layouts, and its selected login layout separately from numeric workspaces. The
plugin does not read or modify Decent Workspaces data.

This project was derived from [Decent Workspaces](https://github.com/TheTrueFerret/omarchy-decent-workspaces-plugin). Its MIT copyright notice is retained in [LICENSE](LICENSE), alongside the copyright for this project.
