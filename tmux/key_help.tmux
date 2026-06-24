#!/bin/bash
# Show tmux keymaps with fzf — `<prefix> ?` (i.e., `C-a ?`)
# Better UI/UX than the factory default :-)

set -eu -o pipefail

selected=$(
  tmux list-keys -Na \
    | fzf --tmux="80%" --prompt 'tmux keys> ' --wrap --freeze-left 2 \
)
# TODO: add action on select/accept. e.g. execute the command.
# This seems quite difficult because of quotation
