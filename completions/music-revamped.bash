# shellcheck shell=bash
# shellcheck disable=SC2207

_music_revamped() {
  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD - 1]}"

  case "${prev}" in
  --theme)
    COMPREPLY=($(compgen -W "kodougu catppuccin-mocha catppuccin-latte dracula nord gruvbox tokyo-night mono" -- "${cur}"))
    return
    ;;
  --auto-hide)
    COMPREPLY=($(compgen -W "0 1" -- "${cur}"))
    return
    ;;
  --render)
    COMPREPLY=($(compgen -W "jobs options" -- "${cur}"))
    return
    ;;
  --menu-key | --playpause-key | --next-key | --prev-key | --interval | --format | --max-len | --before | --after | --playing-icon | --paused-icon | --stopped-icon | --unknown-icon | --progress-width | --progress-full | --progress-empty | --time-format)
    return
    ;;
  *) ;;
  esac

  COMPREPLY=($(compgen -W "apply list status refresh play-pause next prev daemon doctor version help --json --theme --menu-key --playpause-key --next-key --prev-key --interval --format --max-len --before --after --auto-hide --playing-icon --paused-icon --stopped-icon --unknown-icon --progress-width --progress-full --progress-empty --time-format --render" -- "${cur}"))
}

complete -F _music_revamped music-revamped
