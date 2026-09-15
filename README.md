<p align="center">
  <img src="assets/icon/wisp-icon-1024.png" alt="Wisp icon" width="128" height="128">
</p>

<h1 align="center">Wisp</h1>

<p align="center">A computer-use toolkit for macOS: a daemon, a CLI and an MCP server that let AI agents see and drive native apps and Chrome.</p>

Wisp is a computer-use toolkit for macOS: a daemon (`wispd`) that reads app windows as an indexed accessibility
tree and performs UI actions with an animated agent cursor, plus a CLI (`wisp`) and an MCP server (`wisp mcp`)
that any agent (Claude Code, Codex, scripts) can call. Chrome tabs can also be driven over the DevTools Protocol.

It is a from-scratch implementation of the ideas documented in [DESIGN.md](DESIGN.md) (how the ChatGPT/Codex
desktop app's Computer Use works): indexed AX trees with diffs, window-targeted synthesized input that does not
hijack the user's pointer, a glowing cursor with spring motion and click gating, settle detection, Esc to stop,
and a policy file.

## Install

### Homebrew (recommended)

```bash
brew install --cask owo-network/brew/wisp
```

This installs `Wisp.app` and the `wisp` command-line tool together (both signed and notarized). Updates arrive
automatically through Sparkle. Then open the app once and grant permissions:

```bash
open -a Wisp        # menu bar app; guides you through permissions on first run
wisp doctor         # shows what is still missing
```

Grant **Accessibility** (required) and **Screen Recording** (optional, for screenshots) to *Wisp* in
System Settings → Privacy & Security. The menu bar item guides you: it asks for Accessibility with the system
prompt, shows a hint banner, and offers "Grant Accessibility access…" and "Grant Screen Recording…" items that
open the right Settings pane. Once every permission is granted the badge disappears.

### Use with Claude Code

Install the plugin — one step for the skill and the session-cleanup hook:

```text
/plugin marketplace add missuo/wisp
/plugin install wisp@wisp
```

It gives Claude Code a skill that teaches it when and how to drive the UI, and two hooks: one ends the Wisp
session (agent cursor, banner, scratch Chrome tabs) whenever a turn finishes or you interrupt it, even if the
agent forgot to; the other refuses the skill on a machine without the `wisp` command and hands Claude the install
instructions instead. Note that ending without `--app`/`--tab` ends every Wisp session on the machine, not only
the ones this agent opened.

This repository is the marketplace: `.claude-plugin/marketplace.json` serves the plugin directly from
[integrations/claude-plugin](integrations/claude-plugin), so there is no third-party index in between and the
plugin ships with the version that produced it. The skill checks that the CLI is installed and tells you how to
install it if not.

<details>
<summary>Wiring it by hand, or from another agent</summary>

- **MCP server** (Codex, scripts, any MCP client):

  ```bash
  claude mcp add wisp -- wisp mcp
  ```

  Over MCP the `wisp_turn_end` tool replaces the Stop hook: call it when the task is finished or the user
  interrupts.

- **Skill** — from a source checkout: `cp -R integrations/claude-plugin/skills/wisp ~/.claude/skills/wisp`.

- **Stop hook** — in `~/.claude/settings.json`:

  ```json
  {
    "hooks": {
      "Stop": [
        { "hooks": [ { "type": "command", "command": "wisp status >/dev/null 2>&1 && wisp end" } ] }
      ]
    }
  }
  ```

  The `wisp status` guard keeps the hook from starting the daemon on turns that never used Wisp (a bare `wisp end`
  would).

</details>

### From source

```bash
scripts/bundle.sh            # builds release binaries, packages Wisp.app and installs ~/.local/bin/wisp
wisp doctor --request-permissions
```

During development you can run straight from the build tree:
`WISP_DAEMON=.build/debug/wispd .build/debug/wisp doctor` (a terminal that already has Accessibility permission
passes it on to child processes).

App icon: `assets/icon/wisp-icon.svg` is the source (with `wisp-glyph.svg` / `wisp-background.svg` as separate
layers); `assets/icon/*-1024.png` are the rasterized 1024×1024 versions; `assets/icon/Wisp.icon` is the Icon Composer
document. `scripts/bundle.sh` compiles the `.icon` with `actool` into `Assets.car` (Liquid Glass icon on macOS 26)
plus a `Wisp.icns` fallback, or builds the `.icns` from the PNG when the document is absent.

## Use

```bash
wisp apps                                  # running + recently used apps
wisp state --app Safari                    # indexed accessibility tree (diff on later calls)
wisp click --app Safari --el 12            # every action returns the new state diff
wisp set --app Safari --el 4 "openai.com"; wisp key --app Safari Return
wisp type --app Notes "Hello"; wisp paste --app Notes --format md "# Title"
wisp scroll --app Mail --el 22 --down --pages 2
wisp screenshot --app Preview -o shot.png; wisp click --app Preview --at 640,420   # pixels of that screenshot
wisp batch --app TextEdit <<'EOF'
{"kind":"key","key":"cmd+n"}
{"kind":"type","text":"hello"}
{"kind":"state"}
EOF
wisp end --app Safari
```

Chrome over DevTools (dedicated profile, no impact on your main Chrome windows):

```bash
wisp chrome launch                         # Chrome with --remote-debugging-port (first free port from 9222) and its own profile,
                                           # hidden in the background (--visible shows it; `wisp chrome show`/`hide` later)
wisp chrome new https://example.com        # -> tab id
wisp state --tab <id>; wisp click --tab <id> --el 5; wisp chrome eval --tab <id> "document.title"
wisp chrome upload --tab <id> [--el N] /abs/file.pdf   # fill a file input without a picker
wisp chrome dialog --tab <id> accept|dismiss [--text S] # answer an alert/confirm/prompt (state reports it as open)
wisp chrome mark --tab <id> deliverable|handoff        # keep a tab past `wisp end` (unmarked agent tabs are scratch)
```

The chosen port is remembered in `~/Library/Application Support/Wisp/chrome.json`; `wisp chrome launch` reuses a
running Wisp Chrome instead of starting another.

Your existing Chrome windows can be controlled through accessibility instead: `wisp state --app "Google Chrome"`.

The first `state` of an app starts with `<app_specific_instructions>`: built-in guidance for that app (Safari, Mail,
Finder, Slack, Chrome tabs, ...) plus a browser block for anything that handles `http` URLs; `--instructions` repeats
it and `--no-instructions` suppresses it. Drop your own Markdown at `~/.config/wisp/instructions/<bundle id>.md`
to override or extend a text (`wisp instructions list` shows every stem, `wisp instructions show --app X` prints
what an app would receive), and set `instructionsMode` in the policy (`wisp policy set --instructions-mode
merge|replace|off`) to choose whether user files merge with, replace, or switch off the built-in texts.

`wisp --json …` prints machine-readable JSON. `wisp mcp` serves every CLI capability as an MCP tool; add it to
Claude Code with `claude mcp add wisp -- wisp mcp`. The tools mirror the commands one to one:

| Area | Tools |
|---|---|
| Observe | `wisp_apps`, `wisp_windows`, `wisp_state`, `wisp_screenshot` |
| Act (each returns the new state diff; all accept `observe`, `space`, `cursor`, `activate`, `hid` and the state options) | `wisp_click`, `wisp_move`, `wisp_mouse_down`, `wisp_mouse_up`, `wisp_type`, `wisp_key`, `wisp_set`, `wisp_scroll`, `wisp_drag`, `wisp_action`, `wisp_select_text`, `wisp_paste`, `wisp_batch` |
| Apps and sessions | `wisp_launch`, `wisp_activate`, `wisp_end`, `wisp_turn_end`, `wisp_cancel`, `wisp_status` |
| Chrome over DevTools | `wisp_chrome` (status, launch, tabs, new, goto, eval, close, back, forward, reload, upload, dialog, mark, show, hide) |
| Configuration and health | `wisp_instructions`, `wisp_policy`, `wisp_approvals`, `wisp_doctor`, `wisp_log` |

The model-facing guide lives in [integrations/claude-plugin/skills/wisp/SKILL.md](integrations/claude-plugin/skills/wisp/SKILL.md).

## How it works

- **Tree:** `AXUIElementCopyMultipleAttributeValues` per element, visible-children subsets for large tables,
  transform passes (label association, text merging, pruning, child caps), one line per element with a stable
  index; diffs (`~` changed, `+` added, `- [a..b]` removed) against the previous revision.
- **Input:** `CGEvent`s posted with `CGEventPostToPid` to the process that owns the window under the pointer
  (sheets, menus and out-of-process Open/Save panels are separate windows and processes), tagged with a magic
  user-data value, carrying the target window in `kCGMouseEventWindowUnderMousePointer`; keys mapped through the
  active keyboard layout (`UCKeyTranslate`) and delivered to the process that owns keyboard focus; text typed as
  unicode key events or pasted through a restored clipboard. The real pointer never moves and the window is never
  raised: a synthetic app-activation event makes the target accept input while it stays in the background, so you
  can keep working. `--activate` opts into bringing an app forward for the rare one that ignores background input.
- **Vision fallback:** the accessibility tree is preferred, but when a window exposes no actionable elements
  (custom-drawn apps, canvases, games) Wisp attaches a window screenshot so the caller can look and click by pixel
  coordinates (`--at x,y --space screenshot`); `--screenshot` requests one on demand.
- **Cursor:** an overlay `NSPanel` at window level 102 with a glowing arrow; motion uses the spring/path constants
  recovered from Sky (`clickAngle -44°`, scoot under 196 pt, `closeEnough` at 99.5 % / 3.2 pt); the mouse-down is
  posted only when the cursor has visually arrived.
- **Activity lens and banner:** a small sweeping ring next to the cursor (or in the window's top-right corner while
  the cursor is hidden) shows whether Wisp is observing or acting; it turns gray and fades after an intervention.
  `wisp status` reports the current `activity`. The banner text is a policy template (`wisp policy set
  --banner-text "✦ Wisp is controlling {app}" --banner-hint reading`); `--lens off` hides the ring.
- **Settle:** `AXObserver` notifications plus busy flags; a quiet window of 0.3 s after at least 0.25 s, up to 5 s.
  A visible progress or busy indicator in the window keeps the wait going (the state is then marked not settled).
- **Safety:** listen-only event tap for Esc and real user input (`userIntervened`), policy file
  `~/.config/wisp/policy.json`, secure fields are never read or typed into unless allowed, screen-lock check
  before every action and batch step plus a lock monitor that cancels an in-flight action the moment the screen
  locks (`wisp status` shows `screenLocked`), display kept awake while a session runs.
- **Per-app approval:** apps come in tiers. Password managers are denied by default (`deny`); the login window,
  the authentication agent and Wisp itself are forbidden and cannot be allowed at all; high-risk apps (System
  Settings, Terminal, Keychain Access, Passwords, Mail, Messages, Finder) show an on-screen prompt the first time
  an agent touches them, with *Allow Once*, *Allow for This Session*, *Always Allow* and *Don't Allow*
  (the prompt closes as *Don't Allow* after 120 s). `wisp policy set --approval off|high-risk|all` picks when to
  ask (`all` prompts for every app), `--high-risk`/`--forbid` edit the lists, `wisp approvals list|clear` manages
  stored grants (`~/.config/wisp/approvals.json`). `--block-url HOST ...` refuses `wisp chrome new/goto` to those
  hosts (subdomains included, punycode for internationalized names) and refuses actions inside a native window
  whose web content shows one of them.
- **Chrome:** `Accessibility.getFullAXTree` + `DOMSnapshot.captureSnapshot` rendered by the same engine;
  `Input.dispatch*` for actions; `Page.captureScreenshot`; `Runtime.evaluate` for `wisp chrome eval`.

### Safety and confirmations

The daemon enforces the mechanical guardrails (policy file, Esc, intervention detection, secure fields, screen
lock), but deciding *whether* an action should happen is up to the agent. The skill therefore ships a confirmation
policy in four tiers: actions the agent must hand back to the user (submitting credential changes, bypassing
security walls, entering passwords), actions it must confirm right before the effect (deleting, sending, paying,
changing settings or permissions), actions covered by an explicit request (a login or upload the user named), and
everything else, which needs no confirmation. See
[the confirmation tiers](integrations/claude-plugin/skills/wisp/references/confirmations.md).

## Releases and updates

- Pushing a tag `vX.Y.Z` (or running the *Release* workflow manually) builds universal (Apple silicon + Intel)
  `Wisp.app` and `wisp` CLI binaries on GitHub Actions, signs them with the Developer ID certificate, notarizes and
  staples them, produces
  `Wisp-X.Y.Z.zip`, `Wisp-X.Y.Z.dmg`, `wisp-cli-X.Y.Z.zip`, `SHA256SUMS.txt` and a Sparkle `appcast.xml`, and
  publishes everything as a GitHub release.
- The app updates itself with Sparkle (`Check for Updates…` in the menu bar; automatic daily checks). The feed is
  `https://github.com/missuo/wisp/releases/latest/download/appcast.xml`; updates are signed with the EdDSA key whose
  public half is in `assets/sparkle-public-key.txt`.
- Required repository secrets: `MACOS_CERTIFICATE_P12` (base64 .p12), `MACOS_CERTIFICATE_PASSWORD`,
  `KEYCHAIN_PASSWORD`, `NOTARY_APPLE_ID`, `NOTARY_PASSWORD` (app-specific password), `NOTARY_TEAM_ID`,
  `SPARKLE_PRIVATE_KEY` (exported with `generate_keys -x`).
- `scripts/package.sh` is the shared packaging step (used locally by `scripts/bundle.sh` with ad-hoc signing and by
  CI with the Developer ID); `scripts/set-version.sh` stamps `Sources/WispCore/Version.swift`.

## Layout

```
Sources/WispCore   protocol, JSON, framing, UI tree model, transforms, renderer, diff, key parser, policy
Sources/wispd      daemon: AX snapshot, input synthesis, cursor overlay, settle, screenshots, CDP, socket server
Sources/wisp       CLI + MCP server
.claude-plugin/    marketplace.json - serves the plugin below straight from this repository
integrations/      claude-plugin: the Claude Code plugin (skill for agents + session-cleanup Stop hook)
scripts/           package.sh (build+sign), bundle.sh (local install), set-version.sh, e2e.sh (TextEdit smoke test)
.github/workflows  release.yml (sign, notarize, Sparkle appcast, GitHub release)
assets/            app icon sources and the Sparkle public key
```

`swift test` runs the core unit tests; `scripts/e2e.sh` exercises the daemon against TextEdit.

## License

Wisp is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE.md): free to use for any noncommercial
purpose. See the license for the definition of noncommercial and for personal-use and noncommercial-organization
terms. For a commercial license, contact the maintainer.
