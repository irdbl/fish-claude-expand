# Key binding for expand_with_claude
# Default: Ctrl+| (\x1c)
# Override by setting fish_claude_expand_keybind before this plugin loads

if not set -q fish_claude_expand_keybind
    set -g fish_claude_expand_keybind \x1c
end

bind $fish_claude_expand_keybind expand_with_claude
