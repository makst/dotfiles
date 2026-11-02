Debugging
===

nvim is where code is read and edited; VS Code is the visual debugger next to it: breakpoints in the gutter,
variables, watches, the call stack, stepping, conditional breakpoints and logpoints. It covers the backends
and the web: Go (through delve), Node and TypeScript, frontend code running in Chrome, Python. iOS and Android
apps are debugged in Xcode and Android Studio instead, see [mobile](mobile.md).

VS Code isn't a second editor here: it opens on workspace 7, on the second display when there are two (see
[window management](window-management.md#layout)), and nvim's `,vo` takes you to the same line in it.

What's installed
---
- **VS Code** and **delve** (the Go debugger) from the Brewfile.
- `setup_vscode` (part of `setup_dotfiles`) links `config/vscode/settings.json` into VS Code and installs the
  extensions in `config/vscode/extensions.txt`: Go, Python and its debugger, vim keys, the One Dark Pro theme.
  JavaScript and TypeScript debugging, in Node and in Chrome, is built in.
- The settings: Source Code Pro, no format on save (nvim formats, with the project's own formatter), saving
  when VS Code loses focus, so nvim sees the change as soon as you switch back, and no telemetry. VS Code
  writes settings changed in its UI straight into the repo's file, which has no comments as `check_dotfiles`
  parses it as plain JSON.

Setting up a project
---
VS Code needs a `.vscode/launch.json` in the project saying how to start the program, or how to attach to
one that is running. Many projects have one already. Otherwise, in VS Code: Run and Debug (`cmd+shift+d`)
→ *create a launch.json file*, pick the language, and adjust. Typical entries:

```jsonc
{
  "version": "0.2.0",
  "configurations": [
    // Go: run the package of the open file
    { "name": "Go", "type": "go", "request": "launch", "mode": "auto", "program": "${fileDirname}" },
    // Node / TypeScript: an npm script, e.g. `npm run dev`
    { "name": "npm run dev", "type": "node", "request": "launch", "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"], "console": "integratedTerminal" },
    // the frontend in Chrome, served by the dev server
    { "name": "Chrome", "type": "chrome", "request": "launch", "url": "http://localhost:5173",
      "webRoot": "${workspaceFolder}" },
    // Python: the open file
    { "name": "Python", "type": "debugpy", "request": "launch", "program": "${file}" }
  ]
}
```

A program that runs elsewhere, in a container or started from a tmux pane, is *attached* to: start it so it
waits for a debugger (`dlv debug --headless --listen=:2345`, `node --inspect=0.0.0.0:9229`,
`python -m debugpy --listen 0.0.0.0:5678 app.py`), publish that port from the container, and use
`"request": "attach"` with the port.

Whether `.vscode/` is committed is the project's choice: a shared `launch.json` helps everyone, but some
projects ignore the whole directory.

Keys
---
In nvim:

| Key | Does |
|---|---|
| `,vo` | open this file at this line in VS Code, in the project's window (git root) |

In VS Code (with the vim extension, normal vim keys work in the editor). On a Mac keyboard, the F keys need
`fn` unless *Use F1, F2, etc. keys as standard function keys* is on in System Settings → Keyboard.

| Key | Does |
|---|---|
| `F9` | toggle a breakpoint on this line (or click left of the line number) |
| `F5` | start debugging with the selected launch.json entry, or continue |
| `F10` / `F11` / `shift+F11` | step over / into / out |
| `shift+F5` / `cmd+shift+F5` | stop / restart |
| `cmd+shift+d` | Run and Debug: pick the launch.json entry, variables, watches, call stack, breakpoints |

Right-click a breakpoint for a condition or a hit count; a *logpoint* prints a message instead of stopping.

Good to know
---
- **Edit in one place at a time.** VS Code saves when you leave it and nvim reloads changed files when you
  come back, but a file with unsaved changes in both still means one side's changes get lost.
- **Breakpoints in VS Code don't move when nvim edits the file.** After a big edit, check them.
- **Colours**: VS Code can't use the terminal's ANSI colours, so it has its own theme, One Dark Pro, close to
  the base16 scheme; `change_theme` doesn't switch it.
- **A new extension** goes in `config/vscode/extensions.txt` too, so `setup_vscode` installs it on every Mac.
