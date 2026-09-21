# Workspace Display

Workspace Display is a personal Omarchy bar widget shared as-is. It displays
numeric workspaces with optional app icons, names, and colours, plus a compact
scratchpad indicator.

It targets Omarchy Quattro with Hyprland and Quickshell. It is not a workspace
creation or layout manager.

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

## Data and attribution

Workspace presentation metadata is stored in
`~/.config/omarchy/workspace-manager.json`. The plugin writes only values that
differ from its defaults through Quickshell's atomic `FileView` path. It does
not read or modify Decent Workspaces data.

This project was derived from [Decent Workspaces](https://github.com/TheTrueFerret/omarchy-decent-workspaces-plugin). Its MIT copyright notice is retained in [LICENSE](LICENSE), alongside the copyright for this project.
