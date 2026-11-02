Mobile development (iOS)
===

nvim is where you read and edit the code of every project, including iOS apps. Xcode stays open beside it
for what only Xcode does: SwiftUI previews, signing and capabilities, Instruments, the visual debugger,
storyboards. Building, running on a simulator and running the tests work from nvim. Both edit the same files
on disk and each picks up the other's changes (nvim when you come back to it, Xcode on its own).

What's needed
---
- **Xcode**, from the App Store (it isn't in the Brewfile: it is large, and installing it needs an Apple
  ID). Once, after installing it, make it the active developer directory and accept its licence:
  `sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -license accept`.
- From the Brewfile: `xcode-build-server` (lets sourcekit-lsp understand Xcode projects), `xcbeautify`
  (readable build output) and `swiftformat`.
- `:checkhealth xcodebuild` in nvim lists anything still missing.

With only the Command Line Tools, sourcekit-lsp starts but its `sourcekitd` service keeps crashing, so
there is no completion or go-to-definition in Swift until Xcode is installed.

In nvim
---
- **Language server**: `sourcekit-lsp`, which comes with Xcode, so not with Mason. It handles Swift and
  Objective-C; C and C++ are left out so it doesn't start in other projects. Its root is the nearest
  `buildServer.json`, `.xcodeproj` or `Package.swift`, not the git root, so each app in a repo is its own
  project.
- **Swift packages** (`Package.swift`) work as they are. **Xcode projects** need a `buildServer.json` in
  the project root: `,iS` writes it (below), and sourcekit-lsp then knows about the project once it has
  been built once (`,ib`).
- **Highlighting and indentation**: the Swift treesitter parser.
- **Format on save**: only when the project has a style set. SwiftFormat with a `.swiftformat` file, Apple's
  swift-format (`swift format`) with a `.swift-format` file, nothing otherwise. sourcekit-lsp's own formatting
  is never used: without a config it would restyle every file.
- **Build, run, test**: [xcodebuild.nvim](https://github.com/wojciech-kulik/xcodebuild.nvim). Config in
  `config/nvim/lua/user/xcodebuild/`.

Setting up a project
---
Once per project, open nvim in its directory and press `,iS`: it asks for the project or workspace, the
scheme, the test plan and the device, then writes `.nvim/xcodebuild/settings.json` and `buildServer.json`
into the project. Add both to the project's `.gitignore` (they hold your choices and local paths). Then
`,ib` to build once, so sourcekit-lsp has the index it needs.

Keys
---
All under `,i` (for iOS), in normal mode.

| Key | Does |
|---|---|
| `,ip` | picker with every xcodebuild.nvim action |
| `,iS` | set up this project: project, scheme, test plan, device |
| `,ib` | build |
| `,ir` | build and run on the selected simulator or device |
| `,ix` | cancel the running build or test run |
| `,it` | run the tests |
| `,if` | run the tests in the class under the cursor |
| `,is` / `,id` | pick the scheme / the simulator or device |
| `,il` | show or hide the build log |
| `,io` | open this file at this line in Xcode (`xed`), e.g. for its preview |

Debugging stays in Xcode: `,io` takes you to the same line, set the breakpoint there and run with `cmd+r`.
