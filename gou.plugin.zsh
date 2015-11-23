#!/usr/bin/env zsh

-gou-rm() {
  -gou-rm-usage() {
    cat <<'EOT'
Usage: gou rm [-f] [-h]

  -h     Print this help
  -f     Force remove repo(s)
EOT
  }

  # Sanitize args
  shift

  local esc="$(printf "\033")"
  local fg_blue=34
  local fg_red=31
  local _m="m"
  local default="[${_DEFAULT}${_m}"
  local force=false

  local OPTARG OPTIND args
  while getopts ':fh' args; do
    case "$args" in
      f)
        force=true
        ;;
      h)
        -gou-rm-usage
        return 0
        ;;
      *)
        -gou-rm-usage 1>&2
        return 1
        ;;
    esac
  done

  -gou-rm-ask-yes-no() {
    local msg="$1"
    local yes_no

    # FIXME: read -p not work?
    printf "$msg"
    read yes_no
    case "$yes_no" in
      yes)
        return 0
        ;;
      no)
        return 1
        ;;
      *)
        return 1
        ;;
    esac
  }

  -gou-rm-test-is-repo-changed() {
    local msg
    # list changed file(s)
    msg=$(git -c status.color=always status --short 2>&1)

    if [[ $? -eq 0 && -z "$msg" ]]; then
      return 0
    else
      printf "${esc}[${fg_red}${_m}The repository is dirty:${esc}${default}\n"
      echo
      sed 's/^/  /' <<< "$msg"
      echo
      return 1
    fi
  }

  -gou-rm-test-is-unpushed-commit-found() {
    # BUG? looks like initializing variable must be necessary
    local msg
    # list unpushed commit(s)
    msg=$(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline --color=always 2>&1)

    if [[ $? -eq 0 && -z "$msg" ]]; then
      return 0
    else
      printf "${esc}[${fg_red}${_m}There are unpushed commits:${esc}${default}\n"
      echo
      sed 's/^/  /' <<< "$msg"
      echo
      return 1
    fi
  }

  -gou-rm-each-repo() {
    local fd="$1"
    local repo_path

    while read -u "$fd" -r repo_path; do
      printf "\n> ${esc}[${fg_blue}${_m}${repo_path}${esc}${default}\n"
      (
        cd "$repo_path"

        -gou-rm-test-is-repo-changed
        -gou-rm-test-is-unpushed-commit-found

        if [[ "$force" == true ]]; then
          rm -rf "$repo_path"
        else
          -gou-rm-ask-yes-no "Are you sure you want to remove it? [yes/no] " \
          && rm -rf "$repo_path"
        fi
      )
    done
  }

  -gou-rm-each-repo 3 3< <(ls -1d ${GOPATH}/src/*/*/* | peco)
}

-gou-mk() {
  -gou-mk-usage() {
    cat <<'EOT'
Usage: gou mk [-u <user>] [-g <hostname>] <repository> [-h]

  -h                  Print this help
  -u <user>           Specify your git user name (default local user name)
  -s <hostname>       Specify git server name (default github.com)
EOT
  }

  # Sanitize args
  shift

  local user_name="$(whoami)"
  local host_name="github.com"

  local OPTARG OPTIND args
  while getopts ':u:s:h' args; do
    case "$args" in
      u)
        user_name="$OPTARG"
        ;;
      s)
        host_name="$OPTARG"
        ;;
      h)
        -gou-mk-usage
        return 0
        ;;
      *)
        -gou-mk-usage
        return 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  if (( $# != 1 )); then
    -gou-mk-usage 1>&2
    return 1
  fi

  local repository="$1"
  if [[ -z "$repository" ]]; then
    -gou-mk-usage
    return 1
  fi

  local gou_path="${GOPATH}/src/${host_name}/${user_name}/${repository}"
  if [[ -d "$gou_path" ]]; then
    echo "${gou_path}: already exists." 1>&2
    return 1
  else
    mkdir -p "$gou_path" \
    && cd "$gou_path"    \
    && git init
  fi
}

gou() {
  -gou-usage() {
    cat <<'EOT'
Usage: gou [-h] COMMAND [<args>]

gou utility

Commands:

  rm    Remove repo(s) on GOPATH with peco style selecting
  mk    Create repository on GOPATH

Run 'gou COMMAND -h' for more information on a command.
EOT
  }

  local cmd
  for cmd in "go" "peco"; do
    if ! type "$cmd" &>/dev/null; then
      echo "$cmd command not found in your \$PATH." 1>&2
      return 1
    fi
  done

  if [[ -z "$GOPATH" ]]; then
    echo "\$GOPATH is not defined." 1>&2
    return 1
  fi

  cmd="$1"
  if functions -- -gou-${cmd} &>/dev/null; then
    -gou-${cmd} "$@"
  else
    if [[ "$@" =~ "-h" ]]; then
      -gou-usage
      return 0
    else
      -gou-usage 1>&2
      return 1
    fi
  fi
}

_gou() {
  local -a _1st_arguments
  _1st_arguments=(
    'rm:Remove repo(s) on GOPATH with peco style selecting'
    'mk:Create repository on GOPATH and git init'
  )

  __rm() {
    _arguments \
      '-f[Force remove repo(s)]' \
      '-h[Print help message]'
  }

  __mk() {
    _arguments \
      '-u[(local user) User name]' \
      '-s[(github.com) Server hostname]' \
      '-h[Print help message]'
  }

  _arguments '*:: :->command'

  if (( CURRENT == 1 )); then
    _describe -t commands "gou command" _1st_arguments
    return
  fi

  local -a _command_args
  case "$words[1]" in
    rm)
      __rm
      ;;
    mk)
      __mk
      ;;
  esac
}

compdef _gou gou

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
