# fish-claude-expand

A fish shell plugin that expands natural language into shell commands using Claude Code.

## Demo

Type a description of what you want to do, press `Ctrl+|`, and watch it transform into a shell command with live streaming.

```
find all python files modified today  →  find . -name "*.py" -mtime 0
```

## Requirements

- [Claude Code CLI](https://github.com/anthropics/claude-code) (`claude`)
- `jq` for JSON parsing
- `stdbuf` (coreutils) for unbuffered streaming

## Installation

Using [Fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install yourusername/fish-claude-expand
```

Or install locally:

```fish
fisher install ~/projects/fish-claude-expand
```

## Usage

1. Type a natural language description of the command you want
2. Press `Ctrl+|` (Ctrl + pipe)
3. Watch the command stream in, then edit or execute it

## Configuration

### Custom keybinding

Set `fish_claude_expand_keybind` before the plugin loads:

```fish
# In ~/.config/fish/config.fish (before fisher loads)
set -g fish_claude_expand_keybind \cx  # Use Ctrl+X instead
```

### Model

Edit the function to change the model from `haiku` to another Claude model.

## License

MIT
