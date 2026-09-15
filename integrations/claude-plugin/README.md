# Wisp for Claude Code

Computer use for macOS. Wisp reads an app window as an indexed accessibility tree and performs UI
actions — click, type, set fields, scroll, drag, press keys, screenshot — with an animated agent
cursor. Chrome tabs can also be driven over the DevTools Protocol. Every action returns the new
state as a diff, so an agent rarely needs a separate read.

Part of <https://github.com/missuo/wisp>, which doubles as the marketplace that serves this plugin.

## Install

```text
/plugin marketplace add missuo/wisp
/plugin install wisp@wisp
```

## Runtime requirement

The plugin ships guidance, not the binaries. Install the app and CLI first (both signed and
notarized, installed together by the cask):

```bash
brew install --cask owo-network/brew/wisp
open -a Wisp        # menu bar app; guides you through permissions on first run
wisp doctor         # shows what is still missing
```

Grant **Accessibility** (required) and **Screen Recording** (optional, for screenshots) to *Wisp*
in System Settings → Privacy & Security. The skill checks `wisp doctor` before its first action and
stops with install instructions when the CLI is missing, so an unconfigured machine fails loudly
instead of silently doing nothing.

Runtime files live in the user's home: socket at `~/Library/Application Support/Wisp/wisp.sock`,
config and policy under `~/.config/wisp`, screenshots under `/tmp/wisp`.

## What the plugin adds

- **`wisp` skill** — when and how to drive the UI: picking a target, the read → act → read-the-diff loop, index
  discipline, text entry, key syntax, Chrome specifics, interruption handling, and the confirmation tiers in
  `skills/wisp/references/confirmations.md` that gate risky actions (sending, deleting, paying).
- **`Stop` hook** — ends the Wisp session (agent cursor, banner, scratch Chrome tabs) whenever a turn finishes or
  the user interrupts, even if the agent forgot to. It no-ops when `wisp` is absent or no session is open, and
  never fails a turn.

  Note that ending without `--app`/`--tab` ends every Wisp session on the machine, not only the ones this agent
  opened.
- **`PreToolUse` hook** — refuses the skill when the `wisp` command is missing, and hands Claude the install
  instructions to pass on. The skill checks too, but only after its body is in the context window, so this
  answers first. Other skills pass straight through.

## License

PolyForm Noncommercial 1.0.0 — see `LICENSE`. Same terms as the upstream project.
