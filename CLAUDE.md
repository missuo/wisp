# CLAUDE.md

Guidance for Claude Code (and other agents) working in this repository.

## What this is

Wisp is a computer-use toolkit for macOS: `wispd` (a menu bar daemon that reads app windows as an indexed
accessibility tree and performs UI actions with an animated cursor), `wisp` (the CLI) and `wisp mcp` (an MCP
server). Chrome tabs can also be driven over the DevTools Protocol. `DESIGN.md` documents the reverse engineering
of the ChatGPT/Codex desktop app's Computer Use (Part 1) and the design this code implements (Part 2).

## Layout

- `Package.swift` - SwiftPM package (Swift 5 language mode, macOS 14+). Products: `wisp`, `wispd`, `WispCore`.
- `Sources/WispCore/` - shared, UI-free code: JSON value type, u32-LE socket framing, error codes, the JSON-RPC
  protocol (`Protocol.swift`), UI tree model, transform passes, renderer with stable indices, revision diffs,
  xdotool-style key parser, policy, paths, version.
- `Sources/wispd/` - the daemon: `Daemon.swift` (actor that owns sessions and dispatches methods), AX snapshot and
  notifications, app/window resolution, event synthesis (`CGEvent.postToPid`), event tap (Esc = intervention),
  cursor overlay, ScreenCaptureKit screenshots, CDP client for Chrome, unix socket server, menu bar/status UI,
  permissions monitor, Sparkle updater.
- `Sources/wisp/` - the CLI: argument parsing, socket client (auto-spawns `wispd`), commands, MCP stdio server.
- `Tests/WispCoreTests/` - unit tests for WispCore.
- `scripts/` - `package.sh` (builds and assembles `Wisp.app` + `wisp`, signs), `bundle.sh` (local install to
  `~/.local/bin`), `set-version.sh` (rewrites `Sources/WispCore/Version.swift`), `e2e.sh` (TextEdit smoke test).
- `integrations/claude-plugin/` - the Claude Code plugin, delivered as a self-contained, directly installable
  directory (`.claude-plugin/plugin.json`, `LICENSE`, `README.md`, `hooks/hooks.json`, `skills/wisp/`). The
  plugin is installed as that directory alone, so it must never reference files outside itself.
  `skills/wisp/SKILL.md` teaches an agent how to use the CLI; keep it in sync with the commands.
- `assets/icon/` - icon sources (SVG, 1024 PNG, `Wisp.icon` Icon Composer document); `assets/sparkle-public-key.txt`.
- `.github/workflows/release.yml` - signed, notarized release pipeline (see below).

## Build, test, run

```bash
swift build                      # debug build of wisp, wispd, WispCore
swift test                       # WispCore unit tests
scripts/e2e.sh                   # end-to-end smoke test against TextEdit (needs Accessibility permission)
scripts/bundle.sh                # release build, Wisp.app + wisp installed into ~/.local/bin
.build/debug/wisp doctor         # daemon status and permissions
.build/debug/wisp daemon restart # pick up a rebuilt daemon
```

The CLI locates the daemon next to itself, inside `Wisp.app`, or via `WISP_DAEMON=/path/to/wispd`. Runtime files:
socket at `~/Library/Application Support/Wisp/wisp.sock`, config and policy under `~/.config/wisp`, screenshots
under `/tmp/wisp`, logs via `wisp daemon log`.

## Conventions

- Everything committed to this repository is written in English: code, comments, docs, commit messages.
- Keep the daemon/CLI split. macOS TCC grants (Accessibility, Screen Recording) are tied to the signed `wispd`
  binary; the CLI itself never needs permissions.
- The bundle id is `sb.moe.wisp` (CLI signing identifier `sb.moe.wisp.cli`). Do not change it: TCC grants are
  keyed on it and every installed user would have to re-authorize.
- Protocol changes go in `Sources/WispCore/Protocol.swift` first, then daemon, CLI, MCP tools, `SKILL.md` and
  README together. Actions return the new state as a diff; keep that contract.
- The repository is also a Claude Code marketplace: `.claude-plugin/marketplace.json` serves the plugin in
  `integrations/claude-plugin`. The marketplace entry carries only `name`, `source` and `category`; every other
  field comes from the plugin's own manifest, so metadata is never written twice. The plugin has its own SemVer
  in `integrations/claude-plugin/.claude-plugin/plugin.json`, independent of the app version - bump it in the
  same commit as any change inside that directory, or installed users never see the update.
- Never commit certificates, private keys or credentials (`*.p12`, `*.key` are gitignored). Signing and
  notarization secrets live only in GitHub Actions secrets.
- The user's own Chrome may already listen on DevTools port 9222. Never assume that port is Wisp's; `wisp chrome
  launch` picks a free port and persists it in `~/.config/wisp/chrome.json`.
- Prefer targeting events at the window under the point (`deliveryFor(point:element:)` in `Daemon.swift`): Open
  and Save panels and sheets are out-of-process windows and ignore events posted to the app's own pid.

## Releases

- Push a tag `vX.Y.Z` or run `gh workflow run release.yml -f version=X.Y.Z`. The workflow builds a universal
  binary, signs with the Developer ID certificate, notarizes and staples the app, DMG and CLI zip, generates the
  Sparkle appcast (EdDSA) and publishes the GitHub release with `SHA256SUMS.txt`.
- The Sparkle build number is the Actions run number; the version string comes from the tag.
- The Sparkle public key in `assets/sparkle-public-key.txt` is meant to be public (it ships in `Info.plist`). Only
  the private key is secret (`SPARKLE_PRIVATE_KEY`).
- After a release, download the assets and check: `lipo -archs`, `spctl -a -vv -t exec Wisp.app`,
  `xcrun stapler validate`, `shasum -a 256 -c SHA256SUMS.txt`, and that `appcast.xml` points at the new version.
