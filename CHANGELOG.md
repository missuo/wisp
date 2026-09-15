# Changelog

All notable changes to Wisp are documented here. The section for each released version is shown in the Sparkle
update dialog and in the GitHub release. This project follows [Semantic Versioning](https://semver.org).

## [Unreleased]

### Added
- Claude Code plugin in `integrations/claude-plugin`: one install for the skill, a `Stop` hook that ends the
  session (cursor, banner, scratch Chrome tabs) when a turn finishes or the user interrupts, and a `PreToolUse`
  hook that refuses the skill when the `wisp` command is missing instead of loading it to find out. The repository
  doubles as the marketplace (`.claude-plugin/marketplace.json`), so the plugin installs straight from here:
  `/plugin marketplace add missuo/wisp` then `/plugin install wisp@wisp`.

### Changed
- The agent skill moved from `skills/wisp/` to `integrations/claude-plugin/skills/wisp/`; its only content change
  is a line about the plugin's Stop hook.

## [0.1.1] - 2026-09-15

### Added
- The MCP server now mirrors the CLI one to one. New tools: `wisp_windows`, `wisp_activate`, `wisp_move`,
  `wisp_mouse_down`, `wisp_mouse_up`, `wisp_status`, `wisp_doctor`, `wisp_instructions` (list/show),
  `wisp_policy` (get/set with a `changes` object), `wisp_approvals` (list/clear, per app or all) and `wisp_log`.
- Every action tool accepts the shared CLI options: `observe`, `space`, `cursor`, `activate`, `hid`, and the state
  options (`full`, `query`, `screenshot`, `bounds`, `menus`, `maxLines`, `instructions`) for the state returned
  after the action.

## [0.1.0] - 2026-09-15

Feature parity release with the Codex desktop app's Computer Use, based on an audit of what it ships.

### Added
- Per-app instructions: the first state of an app now starts with app-specific guidance, like Codex's
  AppInstructions. 19 built-in files (Slack, Notion, Spotify, iPhone Mirroring, Music, Numbers, Clock, Finder,
  Safari, Mail, Notes, Messages, Calendar, Terminal, Xcode, System Settings, Chrome, a generic browser block for any
  app that handles http links, and Chrome DevTools tabs). Guidance is keyed by bundle id, bundle name or app name,
  concatenated, delivered once per session (`--instructions` repeats it, `--no-instructions` suppresses it), and
  can be overridden or extended with `~/.config/wisp/instructions/<bundle id>.md` (`instructionsMode`
  merge|replace|off). `wisp instructions list|show --app X` explains what applies.
- Model guidance parity in the skill: tool choice, observation discipline, blockers, app resolution, newline
  hazards in composers, interruption phrasing, and a four-tier confirmation policy in
  `skills/wisp/references/confirmations.md`.
- Per-app approval with risk tiers: high-risk apps (System Settings, Terminal, Keychain, Passwords, Mail,
  Messages, Finder) prompt "Allow Wisp to control X?" with once / session / always / deny; a forbidden set
  (login window, SecurityAgent, Wisp itself) can never be allowed; grants persist in
  `~/.config/wisp/approvals.json` (`wisp approvals list|clear`); URL hosts can be blocked
  (`wisp policy set --block-url host`).
- An observing lens indicator with activity states (idle, observing, acting, paused) that shows while Wisp reads
  a window even when the cursor is hidden; the menu bar and banner say whether Wisp is reading or acting.
- Lock-screen monitor: locking the screen cancels the running action, hides the overlays, and invalidates state
  so the next read is a full tree; `wisp status` reports `screenLocked` and `activity`.
- Chrome over DevTools: file uploads without a native panel (`wisp chrome upload`), JavaScript alert/confirm/
  prompt handling (`wisp chrome dialog`), agent-tab lifecycle with deliverable/handoff marks
  (`wisp chrome mark`; a bare `wisp end` closes unmarked agent tabs), and hidden-by-default launch with
  `wisp chrome show|hide` and `wisp chrome launch --visible`.
- Background launch parity: `wisp launch` and the MCP `wisp_launch` start apps in the background
  (`--activate` opts in) and wait for a real window; `wisp_turn_end` MCP tool; MCP cancellation notifications
  cancel the running action; interruption errors read as plain sentences.
- Settle detection waits for visible progress indicators; banner text and hint are configurable
  (`wisp policy set --banner-text`, `--banner-hint`, `--lens on|off`).

### Fixed
- `wisp apps --running` no longer lists multi-process apps (Chrome, Electron) more than once.
- `wisp launch` refuses to start an app while the screen is locked instead of leaving a windowless process behind.

### Changed
- Policy defaults: Terminal, Keychain Access and Passwords moved from the deny list to the high-risk approval
  tier; the login window and SecurityAgent are forbidden outright. Password managers stay denied.

## [0.0.4] - 2026-09-14

### Changed
- Wisp now operates apps in place. It no longer raises the target window or steals focus; a synthetic app-activation
  event makes the app accept input while staying in the background, so you can keep working. Pass `--activate` to
  bring an app forward for the rare one that ignores background input.

### Added
- Vision fallback: when a window exposes no actionable accessibility elements (custom-drawn apps, canvases, games),
  the state includes a window screenshot so an agent can look and click by pixel coordinates. Request one any time
  with `--screenshot`.

## [0.0.3] - 2026-09-14

### Added
- The `wisp` command-line tool now ships inside `Wisp.app`, so the Homebrew cask installs the app and the CLI
  together and the CLI always finds its bundled daemon.
- Release notes are now driven by this changelog: each release shows its section in the Sparkle update dialog.
- Install instructions in the README: Homebrew cask (`brew install --cask owo-network/brew/wisp`), the Claude Code
  skill, and the MCP server. The skill now checks that `wisp` is installed and tells the user how to install it.

## [0.0.2] - 2026-09-14

### Fixed
- Web forms now fill at normal zoom. Controls below the fold were being dropped from a tab's state; they are kept
  and marked offscreen, and clicking one scrolls it into view first.

### Added
- The menu bar shows which app Wisp is currently controlling, and returns to idle when the session ends.

### Changed
- Synthesized pointer events are routed to the window under the point, ignoring unrelated windows and system
  backstops such as the Dock and menu bar.

## [0.0.1] - 2026-09-14

### Added
- First release: the `wispd` daemon, the `wisp` CLI, the `wisp mcp` server, an animated agent cursor, Chrome
  control over the DevTools Protocol, signed and notarized builds, and Sparkle auto-updates.
