# Utility functions and aliases

# joinby <delimeter> [args...]
# e.g. joinby : foo 'bar 42' baz => 'foo:bar 42:baz'
function joinby {
  local delimeter=${1-} first=${2-}
  if [ "$#" -le 1 ]; then
    >&2 echo "ERROR: arguments required"
    return 1
  fi
  shift 2
  printf %s "$first" "${@/#/$delimeter}"
}

alias "joinby:"='joinby :'
alias "joinby,"='joinby ,'
