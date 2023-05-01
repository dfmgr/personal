#!/usr/bin/env bash
# shellcheck shell=bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202304292252-git
# @@Author           :  Jason Hempstead
# @@Contact          :  jason@casjaysdev.com
# @@License          :  LICENSE.md
# @@ReadME           :  install.sh --help
# @@Copyright        :  Copyright: (c) 2023 Jason Hempstead, Casjays Developments
# @@Created          :  Monday, May 01, 2023 11:05 EDT
# @@File             :  install.sh
# @@Description      :  Install personal dotfiles
# @@Changelog        :  New script
# @@TODO             :  Better documentation
# @@Other            :
# @@Resource         :
# @@Terminal App     :  no
# @@sudo/root        :  no
# @@Template         :  installers/personal
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shell check options
# shellcheck disable=SC2317
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
APPNAME="$(basename "$0" 2>/dev/null)"
VERSION="202304292252-git"
REPO_BRANCH="${GIT_REPO_BRANCH:-main}"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"
SCRIPT_SRC_DIR="${BASH_SOURCE%/*}"
export SCRIPTS_PREFIX="dfmgr"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#set opts
trap 'retVal=$?;trap_exit' ERR EXIT SIGINT
#if [ ! -t 0 ] && { [ "$1" = --term ] || [ $# = 0 ]; }; then { [ "$1" = --term ] && shift 1 || true; } && TERMINAL_APP="TRUE" myterminal -e "$APPNAME $*" && exit || exit 1; fi
[ "$1" = "--debug" ] && set -x && export SCRIPT_OPTS="--debug" && export _DEBUG="on"
[ "$1" = "--raw" ] && export SHOW_RAW="true"
set -o pipefail
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Import functions
CASJAYSDEVDIR="${CASJAYSDEVDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTDIR="${CASJAYSDEVDIR:-/usr/local/share/CasjaysDev/scripts}/functions"
SCRIPTSFUNCTFILE="${SCRIPTSAPPFUNCTFILE:-mgr-installers.bash}"
SCRIPTSFUNCTURL="${SCRIPTSAPPFUNCTURL:-https://github.com/dfmgr/installer/raw/main/functions}"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
if [ -f "$PWD/$SCRIPTSFUNCTFILE" ]; then
  . "$PWD/$SCRIPTSFUNCTFILE"
elif [ -f "$SCRIPTSFUNCTDIR/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/$SCRIPTSFUNCTFILE"
else
  echo "Can not load the functions file: $SCRIPTSFUNCTDIR/$SCRIPTSFUNCTFILE" 1>&2
  exit 1
fi
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# user system devenv dfmgr dockermgr fontmgr iconmgr pkmgr systemmgr thememgr wallpapermgr
user_installdirs
show_optvars "$@"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Setup functions
__cmd_exists() { type -p "$1" || return 1; }
__download_file() { curl -q -LSsf "$1" -o "$2" || return 1; }
__service_is_active() { systemctl is-enabled $1 | grep -q 'enabled' || return 1; }
__service_is_running() { systemctl is-active $1 | grep -q 'active' || return 1; }
__get_pid() { ps -aux | grep -v 'grep' | grep "$1" | awk -F ' ' '{print $2}' | grep ${2:-[0-9]} || return 1; }
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set path
PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl/cpan"
# Set default dotfile
DOTFILES_TO_INSTALL_USER="misc bash git tmux nano"
# Set default system files
DOTFILES_TO_INSTALL_SYSTEM="cron installer ssh ssl"
# Set primary dir
DOTFILES_HOME="${DOTFILES_PERSONAL:-$HOME/.local/dotfiles/personal}"
# Set the temp directory
DOTFILES_TEMP="${DOTFILES_TEMP:-/tmp/dotfiles-personal-$USER}"
#Modify and set if using the auth token
DOTFILES_GIT_TOKEN="${GITHUB_ACCESS_TOKEN:-YOUR_AUTH_TOKEN}"
# either http https or git
DOTFILES_GIT_PROTO="https://"
#Your git repo
DOTFILES_GIT_REPO="${DOTFILES_PERSONAL_REPO:-github.com/your/repo}"
#scripts repo
SYSTEM_SCRIPTS_REPO="https://github.com/casjay-dotfiles/scripts"
# Git Command - Private Repo
DOTFILES_GIT_URL="$DOTFILES_GIT_PROTO$DOTFILES_GIT_TOKEN:x-oauth-basic@$DOTFILES_GIT_REPO"
#Public Repo
#DOTFILES_GIT_URL="$DOTFILES_GIT_PROTO$DOTFILES_GIT_REPO"
# Default NTP Server
DOTFILES_NTP_SERVER="ntp.casjay.net"
# Set tmpfile
DOTFILES_TEMP_FILE="$(mktemp /tmp/dfmpersonal-XXXXXXXXX)"
# Set Options
INSTALL_OPTIONS="$*"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Export variables

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
rm -Rf "$DOTFILES_TEMP_FILE" /tmp/dfmpersonal-* &>/dev/null
if __cmd_exists sudo; then sudo echo; fi
clear
printf "\n\n\n\n"
_pre_inst() {
  if [ "$DOTFILES_PERSONAL_REPO" = "github.com/your/repo" ]; then
    printf_red "Please set DOTFILES_PERSONAL_REPO to the url of your repo" 1>&2
    exit 1
  fi
  if [ -z "$DOTFILES_GIT_TOKEN" ] || [ "$DOTFILES_GIT_TOKEN" == "YOUR_AUTH_TOKEN" ]; then
    printf_red "AUTH Token is not set" 1>&2
    exit 1
  fi
  if [ ! -f "$(which sudo 2>/dev/null)" ] && [ $EUID -ne 0 ]; then
    printf_red "Sudo is needed, however its not installed installed" 1>&2
    exit 1
  fi
  if [ "$(uname -s)" = "Linux" ]; then
    if ! __cmd_exists systemmgr; then
      if (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' >/dev/null; then
        sudo bash -c "$(curl -q -LSsf "$SYSTEM_SCRIPTS_REPO/raw/main/install.sh")"
        sudo bash -c "$(curl -q -LSsf "$SYSTEM_SCRIPTS_REPO/raw/main/install.sh")"
      else
        # shellcheck disable=SC2016
        printf_red 'Please run sudo bash -c "$(curl -q -LSsf "$SYSTEM_SCRIPTS_REPO/raw/main/install.sh")"' 1>&2
        exit 1
      fi
    fi
  fi
  if __cmd_exists sudoers; then
    sudoers nopass
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
_git_repo_init() {
  if [ -d "$DOTFILES_HOME/.git" ]; then
    git -C "$DOTFILES_HOME" reset --hard &>/dev/null
    git -C "$DOTFILES_HOME" pull -f
    getexitcode "repo update successful" "git pull failed for $DOTFILES_HOME" 1>&2
  else
    git clone "$DOTFILES_GIT_URL" "$DOTFILES_HOME"
    getexitcode "git clone successful" "git clone $DOTFILES_GIT_URL has failed" 1>&2
  fi
  [ -d "$DOTFILES_HOME" ] || printf_exit "Failed to to clone the repo" 1>&2
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
_scripts_init() {
  install_all_dfmgr() { dfmgr install --all || return 1; }
  install_basic_dfmgr() { dfmgr install misc bash git tmux nano || return 1; }
  install_server_dfmgr() { dfmgr install bash git tmux vifm vim || return 1; }
  install_desktopmgr() { desktopmgr install awesome bspwm i3 openbox qtile xfce4 xmonad || return 1; }
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  systemmgr --config &>/dev/null
  dfmgr --config &>/dev/null
  for sudoconf in $DOTFILES_TO_INSTALL_SYSTEM; do
    systemmgr install "$sudoconf"
  done
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  if [ "$(uname -s)" = "Linux" ]; then
    if [ "$1" = "--all" ]; then
      install_all_dfmgr
    elif [ "$1" = "--server" ]; then
      install_server_dfmgr
    elif [ "$1" = "--desktop" ]; then
      install_basic_dfmgr
      install_desktopmgr
    elif [ -n "$DOTFILES_TO_INSTALL_USER" ]; then
      for user_dotfiles in $ $DOTFILES_TO_INSTALL_USER; do
        dfmgr install $user_dotfiles
      done
    else
      install_basic_dfmgr
    fi
  else
    install_basic_dfmgr
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
_root_init() {
  # Copy gpg ssh to root
  if (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' >/dev/null; then
    sudo mkdir -p "/root/.ssh"
    sudo rsync -avhP "$DOTFILES_TEMP/home/.ssh/." "/root/.ssh/"
    sudo chmod -Rf 600 /root/.ssh/
    sudo chmod -f 700 /root/.ssh
    sudo chown -Rf root:root /root
    if [ -d "/personal" ]; then sudo rm -R "/personal"; fi
    # copy docker config
    sudo mkdir -p /root/.docker
    sudo cp -Rfv "$DOTFILES_TEMP/home/.docker/." "/root/.docker"
  fi
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
_files_init() {
  GPG_TTY="$(tty)"
  unalias cp &>/dev/null
  find "$HOME/" -xtype l -delete &>/dev/null
  mkdir -p "$HOME"/.ssh "$HOME"/.gnupg &>/dev/null
  chmod -Rf 755 "$DOTFILES_TEMP"/system/usr/local/bin/* &>/dev/null
  chmod -Rf 755 "$DOTFILES_TEMP"/home/.local/bin/* &>/dev/null
  find "$DOTFILES_TEMP"/home -type f -iname "*.bash" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/home -type f -iname "*.sh" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/home -type f -iname "*.pl" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/home -type f -iname "*.cgi" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/system -type f -iname "*.bash" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/system -type f -iname "*.sh" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/system -type f -iname "*.pl" -exec chmod 755 -Rf {} \; &>/dev/null
  find "$DOTFILES_TEMP"/system -type f -iname "*.cgi" -exec chmod 755 -Rf {} \; &>/dev/null
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # copy files to ~
  rsync -avhP "$DOTFILES_TEMP/home/." "$HOME/"
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # import podcast feeds
  if __cmd_exists castero; then
    if [ -f "$HOME"/.config/castero/podcasts.opml ]; then
      castero --import "$HOME"/.config/castero/podcasts.opml &>/dev/null
    elif [ -f "$DOTFILES_TEMP"/tmp/podcasts.opml ]; then
      castero --import "$DOTFILES_TEMP"/tmp/podcasts.opml &>/dev/null
    fi
  fi
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # import rss feeds
  if __cmd_exists newsboat; then
    if [ -f "$HOME"/.config/newsboat/news.opml ]; then
      newsboat -i "$HOME"/.config/newsboat/news.opml &>/dev/null
    elif [ -f "$DOTFILES_TEMP"/tmp/news.opml ]; then
      newsboat -i "$DOTFILES_TEMP"/tmp/news.opml &>/dev/null
    fi
  fi
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # change permissions
  find "$HOME"/.gnupg "$HOME"/.ssh -type f -exec chmod 600 {} \; &>/dev/null
  find "$HOME"/.gnupg "$HOME"/.ssh -type d -exec chmod 700 {} \; &>/dev/null
  chmod 755 -f "$HOME" &>/dev/null
  mkdir -p "$HOME"/{Projects,Music,Videos,Downloads,Pictures,Documents}
  rm -Rf "$HOME/.local/share/mail/*/.keep" &>/dev/null
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
_gpg_init() {
  GPG_TTY="$(tty)"
  local exitCode=0
  killall gpg-agent &>/dev/null
  # Import gpg keys - user
  gpg --import "$DOTFILES_TEMP"/tmp/*.gpg 2>/dev/null || exitCode=$((exitCode + 1))
  gpg --import "$DOTFILES_TEMP"/tmp/*.sec 2>/dev/null || exitCode=$((exitCode + 1))
  gpg --import "$DOTFILES_TEMP"/tmp/*.asc 2>/dev/null || exitCode=$((exitCode + 1))
  gpg --import-ownertrust "$DOTFILES_TEMP"/tmp/*.trust 2>/dev/null || exitCode=$((exitCode + 1))
  # Import gpg keys - root
  if sudo -n true; then
    sudo killall gpg-agent &>/dev/null
    sudo GPG_TTY="$(tty)" gpg --import "$DOTFILES_TEMP"/tmp/*.gpg 2>/dev/null || exitCode=$((exitCode + 1))
    sudo GPG_TTY="$(tty)" gpg --import "$DOTFILES_TEMP"/tmp/*.sec 2>/dev/null || exitCode=$((exitCode + 1))
    sudo GPG_TTY="$(tty)" gpg --import "$DOTFILES_TEMP"/tmp/*.asc 2>/dev/null || exitCode=$((exitCode + 1))
    sudo GPG_TTY="$(tty)" gpg --import-ownertrust "$DOTFILES_TEMP"/tmp/*.trust 2>/dev/null || exitCode=$((exitCode + 1))
  fi
  return ${exitCode:-0}
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
main() {
  printf_blue "[ 🗄️ ] Initializing the installer ${YELLOW}please wait${NC} [ 🚀 ]"
  [ -d "$DOTFILES_HOME/.git" ] || rm -Rf "$DOTFILES_HOME"
  [ -d "$DOTFILES_HOME" ] && mkdir -p "$DOTFILES_TEMP" &>/dev/null &&
    rsync -avhP "$DOTFILES_HOME/." "$DOTFILES_TEMP" &>/dev/null && sleep 5
  case "$@" in
  git)
    shift 1
    [ -d "$DOTFILES_HOME/.git" ] && [ -d "$DOTFILES_TEMP" ] || printf_exit "[ 😿 ] Repo has not been setup [ 😿 ]" 1>&2
    printf_blue "[ 🗄️ ] Setting up the git repo: $DOTFILES_GIT_REPO [ 🚀 ]"
    am_i_online && execute "_git_repo_init $INSTALL_OPTIONS" "Initializing git repo"
    printf_cyan "[ ✅ ] The installer finished updating the repo [ 📂 ]"
    ;;
  scripts)
    shift 1
    [ -d "$DOTFILES_HOME/.git" ] && [ -d "$DOTFILES_TEMP" ] || printf_exit "[ 😿 ] Repo has not been setup [ 😿 ]" 1>&2
    printf_blue "[ 🗄️ ] The installer is updating the scripts [ 🚀 ]"
    am_i_online && execute "_scripts_init $INSTALL_OPTIONS" "Installing scripts"
    printf_cyan "[ ✅ ] The installer finished updating the scripts [ 📂 ]"
    ;;
  files)
    shift 1
    [ -d "$DOTFILES_HOME/.git" ] && [ -d "$DOTFILES_TEMP" ] || printf_exit "[ 😿 ] Repo has not been setup [ 😿 ]" 1>&2
    printf_blue "[ 🗄️ ] Installing your personal files [ 🚀 ]"
    execute "_files_init $INSTALL_OPTIONS" "Installing files"
    printf_cyan "[ ✅ ] Installing your personal files completed [ 📂 ]"
    ;;
  root)
    shift 1
    [ -d "$DOTFILES_HOME/.git" ] && [ -d "$DOTFILES_TEMP" ] || printf_exit "[ 😿 ] Repo has not been setup [ 😿 ]" 1>&2
    printf_blue "[ 🗄️ ] Installing your personal files for root [ 🚀 ]"
    execute "_root_init $INSTALL_OPTIONS" "Installing files for root"
    printf_cyan "[ ✅ ] Installing your personal files for root completed [ 📂 ]"
    ;;
  gpg)
    shift 1
    [ -d "$DOTFILES_HOME/.git" ] && [ -d "$DOTFILES_TEMP" ] || printf_exit "[ 😿 ] Repo has not been setup [ 😿 ]" 1>&2
    printf_blue "[ 🗄️ ] Installing your gpg keys [ 🚀 ]"
    _gpg_init &&
      printf_cyan "[ ✅ ] Installing your personal gpg keys completed [ 📂 ]" ||
      printf_red "[ 🔴 ] Installing your personal gpg keys has failed [ 🔴 ]"
    ;;
  *)
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    printf_blue "[ 🗄️ ] Configuring up your system [ 🚀 ]"
    am_i_online && _pre_inst "$INSTALL_OPTIONS"
    printf_cyan "[ ✅ ] Initializing has completed [ 📂 ]"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    printf_blue "[ 🗄️ ] Setting up the git repo: $DOTFILES_GIT_REPO [ 🚀 ]"
    am_i_online && execute "_git_repo_init $INSTALL_OPTIONS" "Initializing git repo"
    printf_cyan "[ ✅ ] The installer finished updating the repo [ 📂 ]"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    printf_blue "[ 🗄️ ] The installer is updating the scripts [ 🚀 ]"
    am_i_online && execute "_scripts_init $INSTALL_OPTIONS" "Installing scripts"
    printf_cyan "[ ✅ ] The installer finished updating the scripts [ 📂 ]"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    printf_blue "[ 🗄️ ] Installing your personal files for root [ 🚀 ]"
    execute "_root_init $INSTALL_OPTIONS" "Installing files for root"
    printf_cyan "[ ✅ ] Installing your personal files for root completed [ 📂 ]"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    printf_blue "[ 🗄️ ] Installing your personal files [ 🚀 ]"
    execute "_files_init $INSTALL_OPTIONS" "Installing files"
    printf_cyan "[ ✅ ] Installing your personal files completed [ 📂 ]"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    printf_blue "[ 🗄️ ] Installing your gpg keys [ 🚀 ]"
    _gpg_init &&
      printf_cyan "[ ✅ ] Installing your personal gpg keys completed" ||
      printf_red "[ 🔴 ] Installing your personal gpg keys has failed [ 🔴 ]"
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ;;
  esac
  printf_yellow "[ 📂 ] Cleaning up temporary files [ 📂 ]"
  rm -Rf "$DOTFILES_TEMP_FILE" /tmp/dfmpersonal-*
  printf '\n'
  unset __colors DOTFILES_TEMP MIN UPDATE DESKTOP
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# finally run application
main "$@"
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End application
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# lets exit with code
exit ${EXIT:-${exitCode:-0}}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# ex: ts=2 sw=2 et filetype=sh
