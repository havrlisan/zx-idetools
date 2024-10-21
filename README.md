
<p align="left"><img src="Resources/Logo/ZX-dark.svg" alt="Logo" height="280" width="320" /></p>
<a href="#compatibility"><img src="https://img.shields.io/static/v1?label=RAD%20Studio&message=11%2B&color=silver&style=flat&logo=delphi&logoColor=white" alt="Delphi 11+ support" /></a>

A set of simple IDE tools that I find useful, making my workflow faster and easier. I'll add more as I develop new ideas, and feel free to suggest some as well!

# Summary
- [Debugger visualizers](#debugger-visualizers)
  - [GUID](#guid)
- [KeyBindings](#keybindings)
  - [Disable Ctrl+Enter](#disable-ctrlenter)
  - [Reload LSP Server](#reload-lsp-server)
  - [Reopen Last Closed Tab](#reopen-last-closed-tab)
- [Common](#common)
- [How to use](#how-to-use)

## Debugger visualizers

### GUID
Displays a GUID value in the debugger as the actual GUID representation, instead of a series of integers. This way, you don't need to open the _Evaluate_ window and call _AGUID.ToString_ just to view or copy the GUID.

Before:

![guid-before](https://github.com/user-attachments/assets/75cc004a-07ed-4988-bca0-ca423aa2a4b1)

After:

![guid-after](https://github.com/user-attachments/assets/329ba8b9-cb70-4d84-bfe6-3d7acc4c6726)


*Note*: The Cpp visualizer has not yet been implemented.

## KeyBindings

### Disable Ctrl+Enter
Disables the annoying *Ctrl+Enter* shortcut which triggers the '*Open file*' dialog by adding another shortcut that handles the keybinding execution but does nothing.

### Reload LSP Server
Embarcadero added the '*Reload LSP Server*' menu item to the *Tools* section but didn't assign any shortcut. Since the menu item is added dynamically, it is not accessible through the '*[GExperts](https://blog.dummzeuch.de/experimental-gexperts-version/) IDE Menu Shortcuts*', so I decided to add the shortcut manually.

Default shortcut: *Alt+Shift+W*

### Reopen Last Closed Tab
Reopens the last closed editor tab by digging through _File > Open Recent_ menu items (those prefixed with alphabet letters). 

Default shortcut: *Ctrl+Shift+T*

## Common
A set of utilities used by the tools. Currently contains only the `TZxIDEMessages`.

## How to use
I designed the tools to be as independent as possible, so you can easily add them to your packages and install them manually. However, if you'd prefer a quicker option, there's also the `Zx.IDETools.dproj` package, which installs all the tools simultaneously. If you want to disable some tool or assign a different shortcut, you'll most likely be able to do so in a single unit, [`Zx.IT.Reg.pas`](Source/Zx.IT.Reg.pas).
