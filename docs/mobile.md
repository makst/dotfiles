Mobile development (iOS and Android)
===

nvim is where you read and edit the code of every project, including iOS and Android apps. Xcode or Android
Studio stays open beside it for what only the IDE does: previews of SwiftUI views or layouts, signing,
profilers, the debugger. Building, running on a simulator or emulator and running the tests work from nvim.
Both edit the same files on disk and each picks up the other's changes (nvim when you come back to it, the
IDE on its own).

AeroSpace puts Xcode on workspace 8 and Android Studio on 9, each with its simulator or emulator floating on
top; with two displays both workspaces stay on the second one, so nvim and the IDE are side by side on
different screens (`alt+8`, `alt+9`). See [window management](window-management.md#layout).

iOS
---

### What's needed
- **Xcode**, from the App Store (it isn't in the Brewfile: it is large, and installing it needs an Apple
  ID). Once, after installing it, make it the active developer directory and accept its licence:
  `sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -license accept`.
- From the Brewfile: `xcode-build-server` (lets sourcekit-lsp understand Xcode projects), `xcbeautify`
  (readable build output) and `swiftformat`.
- `:checkhealth xcodebuild` in nvim lists anything still missing.
- Vim keys in Xcode: Editor → Vim Mode. Plain vim only: Xcode takes no mappings (see [vim-keys](vim-keys.md)).

With only the Command Line Tools, sourcekit-lsp starts but its `sourcekitd` service keeps crashing, so
there is no completion or go-to-definition in Swift until Xcode is installed.

### In nvim
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

### Setting up a project
Once per project, open nvim in its directory and press `,iS`: it asks for the project or workspace, the
scheme, the test plan and the device, then writes `.nvim/xcodebuild/settings.json` and `buildServer.json`
into the project. Your global gitignore (`config/git/ignore`) already ignores both, as they hold your
choices and paths on this Mac. Then `,ib` to build once, so sourcekit-lsp has the index it needs.

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

Debugging stays in Xcode: `,io` takes you to the same line, set the breakpoint there and run with `cmd+r`.

Android
---

### What's needed
- From the Brewfile: **Android Studio**, **kotlin-lsp** (JetBrains' Kotlin language server) and **ktlint**.
- `setup_ideavim` gives Android Studio nvim's keys: IdeaVim and AceJump, and `~/.ideavimrc` from this repo
  (see [vim-keys](vim-keys.md)). It installs the plugins only while Android Studio is closed.
- Open Android Studio once and go through its setup: it installs the SDK into `~/Library/Android/sdk`.
  `zsh/.exports` then puts `adb`, `emulator` and `sdkmanager` on `PATH` and sets `JAVA_HOME` to Android
  Studio's own JDK (unless it is set already), which Gradle needs. Open a new shell (or restart nvim) after.
  With the same JDK, the shell and Android Studio share one Gradle daemon; a project that needs another
  JDK gets `JAVA_HOME` in `~/.config/dotfiles/zshrc` and the same Gradle JDK in Android Studio (Settings →
  Build Tools → Gradle), or two daemons build side by side.
- An emulator: create one in Android Studio, Device Manager; or plug in a phone with USB debugging on.

### In nvim
- **Language server**: kotlin-lsp, built on IntelliJ, so it reads Gradle projects (Android ones included)
  as Android Studio does. Its root is the nearest `settings.gradle(.kts)` or `build.gradle(.kts)`. The
  first time it opens a project it imports it through Gradle, which takes a while; completion and
  go-to-definition come after that. After a change to `build.gradle(.kts)` or the version catalog,
  `:lsp restart` imports it again. It is young (JetBrains calls it pre-alpha): when it gets something
  wrong, Android Studio is one `,ao` away.
- **Highlighting and indentation**: the Kotlin, Groovy (`build.gradle`) and XML (layouts, manifests)
  treesitter parsers.
- **Format on save**: only when the project sets up ktlint in its `.editorconfig` (e.g.
  `ktlint_code_style = android_studio`), nothing otherwise. Projects that format with ktfmt or spotless do
  it through Gradle: `,aa` then `spotlessApply`. kotlin-lsp's own formatting is never used.
- **Build, run, test**: the project's own `./gradlew` and `adb`, in a terminal split at the project root
  (the directory with `gradlew`), one per project. Config in `config/nvim/lua/user/android.lua`.

### Setting up a project
Nothing to set up: open nvim anywhere in the project. The keys find `gradlew` above the current file (or
the working directory), and the app module as the one whose build file applies the Android application
plugin. The package to launch and filter logcat by is read from the APK it built, so an
`applicationIdSuffix` is taken into account.

### Keys
All under `,a` (for Android), in normal mode. They build the debug variant; anything else (another
flavour, `lint`, `clean`, `spotlessApply`) goes through `,aa`.

| Key | Does |
|---|---|
| `,aa` | run any Gradle tasks: asks for them, e.g. `clean lint` |
| `,ab` | build the app (`assembleDebug`) |
| `,ar` | build, install and launch it on the running emulator or device |
| `,ax` | stop the running Gradle task |
| `,at` | run the unit tests (`testDebugUnitTest`) |
| `,ai` | run the instrumented tests on the emulator or device (`connectedDebugAndroidTest`) |
| `,ag` | show or hide the Gradle terminal |
| `,al` | logcat for the app only, in its own terminal; launch the app first |
| `,ae` | start an emulator: pick one of those made in Android Studio |
| `,ao` | open this file at this line in Android Studio (`studio`), e.g. for a layout preview |

With several devices connected, `adb` needs to be told which: `export ANDROID_SERIAL=<id from adb devices>`
before starting nvim. Debugging stays in Android Studio: `,ao` takes you to the same line, set the
breakpoint there and run with the debug button.
