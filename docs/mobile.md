Mobile development (iOS and Android)
===

nvim is where you read and edit the code of every project, including iOS and Android apps. Xcode or Android
Studio stays open beside it for what only the IDE does: previews of SwiftUI views or layouts, signing,
profilers, the debugger. Building, running on a simulator or emulator and running the tests work from nvim.
Both edit the same files on disk and each picks up the other's changes (nvim when you come back to it, the
IDE on its own).

AeroSpace puts Xcode on workspace 8 and Android Studio on 9, each with its simulator or emulator floating on
top; with two displays both workspaces stay on the second one, so nvim and the IDE are side by side on
different screens (`alt+8`, `alt+9`). See [window management](window-management.md#what-it-is).

iOS
---

### What it is
- **Language server**: `sourcekit-lsp`, which comes with Xcode, so not from the Brewfile. It handles Swift and
  Objective-C; C and C++ are left out so it doesn't start in other projects. Its root is the nearest
  `buildServer.json`, `.xcodeproj` or `Package.swift`, not the git root, so each app in a repo is its own
  project.
- **Highlighting and indentation**: the Swift treesitter parser.
- **Format on save**: only when the project has a style set. SwiftFormat with a `.swiftformat` file, Apple's
  swift-format (`swift format`) with a `.swift-format` file, nothing otherwise. sourcekit-lsp's own formatting
  is never used: without a config it would restyle every file.
- **Build, run, test**: [xcodebuild.nvim](https://github.com/wojciech-kulik/xcodebuild.nvim). Config in
  `config/nvim/lua/user/xcodebuild/`.

### Once per Mac
`setup_dotfiles` installs from the Brewfile `xcode-build-server` (lets sourcekit-lsp understand Xcode
projects), `xcbeautify` (readable build output) and `swiftformat`. Then:

1. Install **Xcode** from the App Store (it isn't in the Brewfile: it is large, and installing it needs an
   Apple ID).
2. Make it the active toolchain and accept its licence:
   ```sh
   sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -license accept
   ```
3. In nvim, `:checkhealth xcodebuild` should show nothing missing.
4. In Xcode, Editor → Vim Mode, for vim keys there too. Plain vim only: Xcode takes no mappings, so not
   nvim's own keys (see [vim-keys](vim-keys.md)).

### Once per project
In nvim at the project's root:

1. `,iS`: pick the project or workspace, the scheme, the test plan and the device. This writes
   `.nvim/xcodebuild/settings.json` and `buildServer.json` into the project; the global gitignore
   (`config/git/ignore`) keeps them out of git, as they hold your choices and paths on this Mac.
2. `,ib` to build once, so sourcekit-lsp has an index: completion and go-to-definition work from then on.

Swift packages (`Package.swift`) need neither step for the language server. Then `,ir` builds and runs,
`,it` runs the tests and `,io` opens the current line in Xcode.

### Keys
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

### To look out for
- With only the Command Line Tools and no Xcode, sourcekit-lsp starts but its `sourcekitd` service keeps
  crashing: no completion or go-to-definition in Swift.
- sourcekit-lsp learns about new files, targets and packages from a build: when go-to-definition misses
  something new, `,ib` again.
- `buildServer.json` and `.nvim/xcodebuild/` aren't committed, so a fresh clone (or another Mac) needs `,iS`
  again. `,is` / `,id` change the scheme or device later.
- Swift is formatted on save only when the project has a `.swiftformat` or `.swift-format`; otherwise
  nothing touches the style.
- Breakpoints and the debugger are Xcode's: `,io` takes you to the same line, set the breakpoint there and
  run with `cmd+r`.

Android
---

### What it is
- **Language server**: kotlin-lsp, built on IntelliJ, so it reads Gradle projects (Android ones included)
  as Android Studio does. Its root is the nearest `settings.gradle(.kts)` or `build.gradle(.kts)`. It is
  young (JetBrains calls it pre-alpha).
- **Highlighting and indentation**: the Kotlin, Groovy (`build.gradle`) and XML (layouts, manifests)
  treesitter parsers.
- **Format on save**: only when the project sets up ktlint in its `.editorconfig` (e.g.
  `ktlint_code_style = android_studio`), nothing otherwise. kotlin-lsp's own formatting is never used.
- **Build, run, test**: the project's own `./gradlew` and `adb`, in a tmux pane below nvim at the project
  root (the directory with `gradlew`), one for Gradle and one for logcat per project. Config in
  `config/nvim/lua/user/android/` (`config.lua`, keys in `keymaps.lua`).

### Once per Mac
`setup_dotfiles` installs from the Brewfile **Android Studio**, **kotlin-lsp** (JetBrains' Kotlin language
server) and **ktlint**, and `setup_ideavim` gives Android Studio nvim's keys: IdeaVim and AceJump, and
`~/.ideavimrc` from this repo (see [vim-keys](vim-keys.md)). Then:

1. Open Android Studio and go through its setup wizard: it downloads the Android SDK into
   `~/Library/Android/sdk`. `zsh/.exports` then puts `adb`, `emulator` and `sdkmanager` on `PATH` and sets
   `JAVA_HOME` to Android Studio's own JDK (unless it is set already), which Gradle needs.
2. In its Device Manager, create an emulator (or connect a phone with USB debugging on).
3. If Android Studio was open during `setup_dotfiles`, close it and run `setup_ideavim`: it installs the
   plugins only while Android Studio is closed.
4. Open a new shell and restart nvim, so they see the SDK: `adb devices` should work, and lists the phone
   or a running emulator.
5. Check kotlin-lsp in an Android project: open a `.kt` file, give the first Gradle import a minute, then
   `gd` on a name should jump to its definition (`:checkhealth vim.lsp` shows the server if not).

### Once per project
Nothing: open nvim anywhere in the project. The keys find `gradlew` above the current file (or the working
directory), and the app module as the one whose build file applies the Android application plugin. The
package to launch and filter logcat by is read from the APK it built, so an `applicationIdSuffix` is taken
into account. The first time, kotlin-lsp imports the project through Gradle, so completion and
go-to-definition take a minute to arrive.

Then `,ae` starts an emulator, `,ar` builds, installs and launches the app, `,at` runs the unit tests, `,al`
shows the app's logcat and `,ao` opens the current line in Android Studio.

### Keys
All under `,a` (for Android), in normal mode. They build the debug variant; anything else (another
flavour, `lint`, `clean`, `spotlessApply`) goes through `,aa`. Gradle and logcat run in two shells in tmux
panes below nvim, one pair per project, like `,tt` ([tmux](tmux.md)); the cursor stays in nvim. A new command
stops what still runs in its shell first, and the shells keep their output when hidden or after nvim quits.

| Key | Does |
|---|---|
| `,aa` | run any Gradle tasks: asks for them, e.g. `clean lint` |
| `,ab` | build the app (`assembleDebug`) |
| `,ar` | build, install and launch it on the running emulator or device |
| `,ax` | stop the running Gradle task |
| `,at` | run the unit tests (`testDebugUnitTest`) |
| `,ai` | run the instrumented tests on the emulator or device (`connectedDebugAndroidTest`) |
| `,ag` | show or hide the Gradle shell |
| `,al` | logcat for the app only, in its own shell; launch the app first |
| `,ae` | start an emulator: pick one of those made in Android Studio |
| `,ao` | open this file at this line in Android Studio (`studio`), e.g. for a layout preview |

### To look out for
- `adb`, the emulator and `JAVA_HOME` only exist once the SDK is installed: open a new shell and restart
  nvim after Android Studio's setup.
- Gradle from the shell uses Android Studio's own JDK, so both share one Gradle daemon. A project that
  needs another JDK: set `JAVA_HOME` in `~/.config/dotfiles/zshrc`, and the same Gradle JDK in Android
  Studio (Settings → Build Tools → Gradle), or two daemons build side by side.
- After changing `build.gradle(.kts)` or the version catalog, `:lsp restart` makes kotlin-lsp import the
  project again. When kotlin-lsp gets something wrong, `,ao` and use Android Studio.
- The keys build the debug variant of the app module. Other flavours and tasks go through `,aa`, e.g.
  `installFreeDebug`.
- With a phone and an emulator connected at once, adb needs to be told which:
  `export ANDROID_SERIAL=<id from adb devices>` before starting nvim.
- `,al` follows the running app: launch it first (`,ar`), and again after it restarts.
- Kotlin is formatted on save only when the project's `.editorconfig` sets up ktlint; projects on ktfmt or
  spotless run `,aa` `spotlessApply`.
- Breakpoints and the debugger are Android Studio's: `,ao` takes you to the same line, set the breakpoint
  there and run with the debug button.

Decisions
---
- **Xcode isn't in the Brewfile**: it is large, and installing it needs an Apple ID.
- **No formatting by the language servers**: without a config, sourcekit-lsp would restyle every file; Swift
  and Kotlin are formatted only when the project sets a style.
- **sourcekit-lsp leaves C and C++ alone**, so it doesn't start in other projects.
- **The IDE debugs**: breakpoints and the debugger are Xcode's and Android Studio's; `,io` / `,ao` take you to
  the same line.
