#!/bin/bash

# nlof - Neovim oldfiles picker using fzf
# Add to .zshrc, for example:
# alias nlof='~/path/to/nlof'

# ------------------------------------------------------------
# Matugen colors
# ------------------------------------------------------------

MATUGEN_COLORS="$HOME/.local/state/quickshell/user/generated/colors.json"

matugen_color() {
  local name="$1"

  if [[ -f "$MATUGEN_COLORS" ]] && command -v jq >/dev/null 2>&1; then
    jq -r --arg name "$name" '
      if .[$name] | type == "object" then
        (.[$name].default.hex // .[$name].hex // .[$name].value // empty)
      elif .[$name] | type == "string" then
        .[$name]
      else
        empty
      end
    ' "$MATUGEN_COLORS" 2>/dev/null
  fi
}

# Material 3 palette
surface="#000000"
surface_container="#111111"
surface_container_high="#181818"

on_surface="$(matugen_color on_surface)"
on_surface_variant="$(matugen_color on_surface_variant)"

primary="$(matugen_color primary)"
on_primary="$(matugen_color on_primary)"

primary_container="$(matugen_color primary_container)"
on_primary_container="$(matugen_color on_primary_container)"

outline="$(matugen_color outline)"
outline_variant="$(matugen_color outline_variant)"

# ------------------------------------------------------------
# Fallback colors
# ------------------------------------------------------------

surface="${surface:-#000000}"
surface_container="${surface_container:-#111111}"
surface_container_high="${surface_container_high:-#181818}"

on_surface="${on_surface:-#e6e1e5}"
on_surface_variant="${on_surface_variant:-#cac4d0}"

primary="${primary:-#d0bcff}"
on_primary="${on_primary:-#381e72}"

primary_container="${primary_container:-#4f378b}"
on_primary_container="${on_primary_container:-#eaddff}"

outline="${outline:-#938f99}"
outline_variant="${outline_variant:-#49454f}"

# ------------------------------------------------------------
# Get Neovim oldfiles
# ------------------------------------------------------------

list_oldfiles() {
  local oldfiles
  local file
  local first_dir

  # Read oldfiles without loading user's normal config
  mapfile -t oldfiles < <(
    nvim -u NONE --headless \
      +'lua io.write(table.concat(vim.v.oldfiles, "\n") .. "\n")' \
      +qa
  )

  # Filter invalid paths / files that no longer exist
  local valid_files=()

  for file in "${oldfiles[@]}"; do
    [[ -f "$file" ]] && valid_files+=("$file")
  done

  # Nothing to show
  if [[ ${#valid_files[@]} -eq 0 ]]; then
    printf '\033[33mNo recent Neovim files found.\033[0m\n'
    return 0
  fi

  # --------------------------------------------------------
  # FZF picker
  # --------------------------------------------------------

  local files=()

  mapfile -t files < <(
    printf '%s\n' "${valid_files[@]}" |
      grep -v '\[.*' |
      fzf \
        --multi \
        --ansi \
        --height=70% \
        --layout=reverse \
        --border=rounded \
        --border-label='  ✦  Neovim Recent Files  ' \
        --border-label-pos=0 \
        --margin=1 \
        --padding='1,2' \
        --no-info \
        --no-scrollbar \
        --pointer='▌' \
        --marker='✓' \
        --prompt='  › ' \
        --preview='bat -n --color=always --line-range=:500 {} 2>/dev/null || echo "Error previewing file"' \
        --preview-window='right,55%,border-left' \
        --color="\
fg:${on_surface},\
bg:${surface},\
fg+:${on_primary_container},\
bg+:${primary_container},\
hl:${primary},\
hl+:${primary},\
prompt:${primary},\
pointer:${primary},\
marker:${primary},\
spinner:${primary},\
header:${on_surface_variant},\
info:${on_surface_variant},\
border:${outline},\
label:${primary},\
gutter:${surface},\
scrollbar:${outline_variant}"
  )

  # --------------------------------------------------------
  # Open selected files in Neovim
  # --------------------------------------------------------

  if [[ ${#files[@]} -gt 0 ]]; then
    first_dir="$(dirname -- "${files[0]}")"

    cd -- "$first_dir" || {
      printf 'Failed to cd to %s\n' "$first_dir" >&2
      return 1
    }

    nvim "${files[@]}"
  fi
}

list_oldfiles "$@"
