function expand_with_claude --description "Expand natural language to shell command using Claude"
    set -l query (commandline)

    if test -z "$query"
        return
    end

    # Show thinking indicator
    printf '\r\033[K⏳ thinking...' >/dev/tty

    # Gather context
    set -l os_type (uname -s)
    set -l os_info ""
    set -l pkg_manager ""

    switch $os_type
        case Darwin
            set os_info "macOS "(sw_vers -productVersion 2>/dev/null)
            if command -q brew
                set pkg_manager "homebrew"
            end
        case Linux
            if test -f /etc/os-release
                set os_info (grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
            end
            if command -q apt
                set pkg_manager "apt"
            else if command -q dnf
                set pkg_manager "dnf"
            else if command -q pacman
                set pkg_manager "pacman"
            else if command -q apk
                set pkg_manager "apk"
            end
    end

    # Git context
    set -l git_context ""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1
        set -l git_branch (git branch --show-current 2>/dev/null)
        set -l git_root (git rev-parse --show-toplevel 2>/dev/null)
        set -l git_dirty ""
        if not git diff --quiet 2>/dev/null
            set git_dirty " (dirty)"
        end
        set git_context "Git repo: $git_root, branch: $git_branch$git_dirty."
    end

    set -l context "OS: $os_info. Package manager: $pkg_manager. Current directory: $PWD. $git_context"

    set -l tmpfile (mktemp)
    set -l first_token 1
    set -l cancelled 0

    # Handle Ctrl+C
    function __expand_cleanup --on-signal INT
        set cancelled 1
    end

    # Stream output, display deltas live, save full stream to file
    claude -p --model haiku --max-turns 5 --output-format stream-json --verbose --include-partial-messages \
        "$context Convert this to a single shell command for fish shell. Output ONLY the command, no explanation, no markdown, no code blocks: $query" 2>/dev/null \
    | stdbuf -oL tee $tmpfile \
    | while read -l line
        if test $cancelled -eq 1
            break
        end
        set -l delta (printf '%s' $line | jq -r 'select(.type == "stream_event" and .event.type == "content_block_delta") | .event.delta.text // empty' 2>/dev/null)
        if test -n "$delta"
            if test $first_token -eq 1
                printf '\r\033[K' >/dev/tty
                set first_token 0
            end
            printf '%s' "$delta" >/dev/tty
        end
    end

    # Remove signal handler
    functions -e __expand_cleanup

    # Handle cancellation
    if test $cancelled -eq 1
        printf '\r\033[K\033[90mcancelled\033[0m' >/dev/tty
        sleep 0.5
        printf '\r\033[K' >/dev/tty
        commandline -r $query
        commandline -f repaint
        rm -f $tmpfile
        return
    end

    # Extract final result from saved stream
    set -l result (cat $tmpfile | jq -r 'select(.type == "result") | .result // empty' 2>/dev/null)
    set -l is_error (cat $tmpfile | jq -r 'select(.type == "result") | .is_error // false' 2>/dev/null)
    rm -f $tmpfile

    # Clear streamed output
    printf '\r\033[K' >/dev/tty

    if test "$is_error" = "true"
        printf '\033[91merror: %s\033[0m\n' "$result" >/dev/tty
        commandline -r $query
    else if test -n "$result"
        commandline -r $result
    else
        printf '\033[91merror: no response from Claude\033[0m\n' >/dev/tty
        commandline -r $query
    end
    commandline -f repaint
end
