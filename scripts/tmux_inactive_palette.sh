#!/bin/bash

window_id="$1"
active_pane_id="$2"

lock_name="tmux-inactive-palette-lock"
tmux wait-for -L "$lock_name" 2>/dev/null || exit 0
trap 'tmux wait-for -U "$lock_name" >/dev/null 2>&1' EXIT

if [ -z "$window_id" ]; then
	window_id=$(tmux display-message -p "#{window_id}" 2>/dev/null) || exit 0
fi

if [ -z "$window_id" ]; then
	exit 0
fi

if [ -z "$active_pane_id" ]; then
	active_pane_id=$(tmux list-panes -t "$window_id" -F "#{pane_id} #{pane_active}" 2>/dev/null | awk '$2 == 1 { print $1; exit }') || exit 0
fi

if [ -z "$active_pane_id" ]; then
	exit 0
fi

dim_factor_percent=68
base_palette=(
	"#000000"
	"#685742"
	"#5f875f"
	"#b36d43"
	"#78824b"
	"#bb7744"
	"#c9a554"
	"#d7c483"
	"#666666"
	"#685742"
	"#5f875f"
	"#b36d43"
	"#78824b"
	"#bb7744"
	"#c9a554"
	"#d7c483"
)

dim_hex() {
	local hex="$1"
	local clean="${hex#\#}"
	local r=$((16#${clean:0:2}))
	local g=$((16#${clean:2:2}))
	local b=$((16#${clean:4:2}))

	local dr=$(((r * dim_factor_percent + 50) / 100))
	local dg=$(((g * dim_factor_percent + 50) / 100))
	local db=$(((b * dim_factor_percent + 50) / 100))

	printf '#%02x%02x%02x' "$dr" "$dg" "$db"
}

dim_palette=()
for color in "${base_palette[@]}"; do
	dim_palette+=("$(dim_hex "$color")")
done

pane_ids=$(tmux list-panes -t "$window_id" -F "#{pane_id}" 2>/dev/null) || exit 0

for pane_id in $pane_ids; do
	if [ "$pane_id" = "$active_pane_id" ]; then
		tmux set-option -p -t "$pane_id" -u pane-colours 2>/dev/null || true
		continue
	fi

	tmux set-option -p -t "$pane_id" -u pane-colours 2>/dev/null || true

	for color in "${dim_palette[@]}"; do
		tmux set-option -p -t "$pane_id" -a pane-colours "$color" 2>/dev/null || true
	done
done
