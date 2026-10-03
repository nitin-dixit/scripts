#!/bin/bash

# nzo - Search files with fd/fzf + zoxide and open in Neovim
# alias nzo='~/path/to/nzo'

# ------------------------------------------------------------
# Matugen colors
# ------------------------------------------------------------

MATUGEN_COLORS="$HOME/.local/state/quickshell/user/generated/colors.json"

matugen_color() {
  local name="$1"

  if [[ -f "$MATUGEN_COLORS" ]] && command -v jq >/dev/null 2>&1; then
    jq -r --arg name "$name" '
            if (.[$name] | type) == "object" then
                (.[$name].hex // .[$name].value // (.[$name].default | if type == "object" then .hex else . end) // empty)
            elif (.[$name] | type) == "string" then
                .[$name]
            else
                empty
            end
        ' "$MATUGEN_COLORS" 2>/dev/null
  fi
}

# Keep surface pure black (#000000) or use -1 to inherit your terminal transparency
surface="#000000"
surface_container="#111111"
surface_container_high="#181818"

on_surface="$(matugen_color on_surface)"
on_surface_variant="$(matugen_color on_surface_variant)"

primary="$(matugen_color primary)"
primary_container="$(matugen_color primary_container)"
on_primary_container="$(matugen_color on_primary_container)"

outline="$(matugen_color outline)"
outline_variant="$(matugen_color outline_variant)"

# ------------------------------------------------------------
# Fallbacks for dynamic colors
# ------------------------------------------------------------

on_surface="${on_surface:-#e6e1e5}"
on_surface_variant="${on_surface_variant:-#cac4d0}"

primary="${primary:-#d0bcff}"
primary_container="${primary_container:-#4f378b}"
on_primary_container="${on_primary_container:-#eaddff}"

outline="${outline:-#938f99}"
outline_variant="${outline_variant:-#49454f}"

# ------------------------------------------------------------
# Bat preview command
# ------------------------------------------------------------

BAT_CMD="bat"
command -v batcat >/dev/null 2>&1 && BAT_CMD="batcat"

# ------------------------------------------------------------
# FZF theme
# ------------------------------------------------------------

fzf_theme=(
  --ansi
  --height=70%
  --layout=reverse
  --border=rounded
  --border-label='  󰈔  Files  '
  --border-label-pos=0
  --margin=1
  --padding='1,2'
  --no-info
  --no-scrollbar
  --pointer='▌'
  --marker='✓'
  --prompt='  › '
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

# ------------------------------------------------------------
# Bat preview
# ------------------------------------------------------------

fzf_preview=(
  --preview-window='right:60%:border-rounded'
  --preview="
        $BAT_CMD \
            --style=numbers \
            --color=always \
            --line-range=:500 \
            --paging=never \
            -- {} 2>/dev/null ||
        echo 'Unable to preview file'
    "
)

# ------------------------------------------------------------
# Search
# ------------------------------------------------------------

search_with_zoxide() {

  # ========================================================
  # No argument:
  # Search files in current directory
  # ========================================================

  if [[ -z "$1" ]]; then

    file="$(
      fd \
        --type f \
        -I \
        -H \
        -E .git \
        -E .git-crypt \
        -E .cache \
        -E .backup |
        fzf \
          "${fzf_theme[@]}" \
          "${fzf_preview[@]}" \
          --border-label='  󰈔  Files in Current Directory  '
    )"

    if [[ -n "$file" ]]; then
      dir="$(dirname -- "$file")"
      file_name="$(basename -- "$file")"

      cd -- "$dir" || {
        echo "Failed to cd to $dir" >&2
        return 1
      }

      nvim -- "$file_name"
    fi

    return
  fi

  # ========================================================
  # With argument:
  # Search zoxide tracked directories
  # ========================================================

  local lines=""
  local zdir
  local found

  while IFS= read -r zdir; do

    found="$(
      fd \
        --type f \
        -I \
        -H \
        -E .git \
        -E .git-crypt \
        -E .cache \
        -E .backup \
        -E .vscode \
        "$1" \
        "$zdir" \
        2>/dev/null
    )"

    if [[ -n "$found" ]]; then
      lines+="$found"$'\n'
    fi

  done < <(zoxide query -l)

  lines="${lines%$'\n'}"

  # --------------------------------------------------------
  # No results
  # --------------------------------------------------------

  if [[ -z "$lines" ]]; then
    echo "No matches found." >&2
    return 0
  fi

  # --------------------------------------------------------
  # Count results
  # --------------------------------------------------------

  local line_count
  line_count="$(printf '%s\n' "$lines" | wc -l)"

  # --------------------------------------------------------
  # One result = open directly; Multiple = fzf
  # --------------------------------------------------------

  if [[ "$line_count" -eq 1 ]]; then
    file="$lines"
  else
    file="$(
      printf '%s\n' "$lines" |
        fzf \
          "${fzf_theme[@]}" \
          "${fzf_preview[@]}" \
          --query="$1" \
          --no-sort \
          --border-label='  󰈔  Search Zoxide Directories  '
    )"
  fi

  # --------------------------------------------------------
  # Open selected file
  # --------------------------------------------------------

  if [[ -n "$file" ]]; then
    dir="$(dirname -- "$file")"
    file_name="$(basename -- "$file")"

    cd -- "$dir" || {
      echo "Failed to cd to $dir" >&2
      return 1
    }

    nvim -- "$file_name"
  fi
}

search_with_zoxide "$@"
