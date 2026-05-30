# Custom (tab) completions

_tmux_sessions() {
  local -a sessions
  sessions=( ${(f)"$(command tmux 2>/dev/null list-sessions -F '#{session_name}')"} )
  _describe -t sessions 'tmux session' sessions
}
compdef '_arguments "1:session:_tmux_sessions"' tmux-attach
