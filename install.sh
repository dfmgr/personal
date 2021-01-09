#!/usr/bin/env bash
PROGNAME="$(basename $0)"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version     : 010920210141-git
# @Author      : Jason
# @Contact     : casjaysdev@casjay.net
# @File        : install
# @Created     : Mon, Dec 27, 2019, 21:13 EST
# @License     : WTFPL
# @Copyright   : Copyright (c) CasjaysDev
# @Description : installer script for dotfiles-personal
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Options

PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl/cpan"
#Modify and set if using the auth token
AUTHTOKEN="${GITHUB_ACCESS_TOKEN:-$token}"
# either http https or git
GITPROTO="https://"
#Your git repo
GITREPO="${MYPERSONALGITREPO:-github.com/casjay/personal}"
#scripts repo
SCRIPTSREPO="https://github.com/dfmgr/installer"
# Git Command - Private Repo
GITURL="$GITPROTO$AUTHTOKEN:x-oauth-basic@$GITREPO"
#Public Repo
#GITURL="$GITPROTO$GITREPO"
# Default NTP Server
NTPSERVER="ntp.casjay.net"
# Default dotfiles dir
# Set primary dir
DOTFILES="$HOME/.local/dotfiles/personal"
# Set the temp directory
DOTTEMP="/tmp/dotfiles-personal-$USER"
# Set tmpfile
TMP_FILE="$(mktemp /tmp/dfm-XXXXXXXXX)"
MIN=no

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Set functions

SCRIPTSFUNCTURL="${SCRIPTSAPPFUNCTURL:-https://github.com/dfmgr/installer/raw/master/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSAPPFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSAPPFUNCTFILE:-app-installer.bash}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -f "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE"
elif [ -f "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
else
  mkdir -p "$HOME/.local/share/CasjaysDev/functions"
  curl -LSs "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE" || exit 1
  . "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

##################################################################################################

clear
sleep 1
printf_green "\t\tInitializing the installer please wait\n"
sleep 2

##################################################################################################

urlverify "$GITURL" || printf_exit "$GITURL is invalid"

##################################################################################################

install_all_dfmgr() { dfmgr install --all || return 1; }
install_basic_dfmgr() { dfmgr install bash git vim || return 1; }
install_server_dfmgr() { dfmgr install bash git tmux vifm vim || return 1; }
install_desktop_dfmr() { dfmgr install awesome bspwm i3 openbox qtile xfce4 xmonad || return 1; }

##################################################################################################

_pre_inst() {
if [ -z "$AUTHTOKEN" ] || [ "$AUTHTOKEN" == "YOUR_AUTH_TOKEN" ]; then
  printf_
  red "\t\tAUTH Token is not set"
  exit 1
fi
if [ ! -f "$(which sudo 2>/dev/null)" ] && [[ $EUID -ne 0 ]]; then
  printf_red "\t\tSudo is needed, however its not installed installed\n"
  exit 1
fi

if [ ! -d "$DOTFILES"/.git ]; then rm -Rf "$DOTFILES"; fi
rm -Rf "$DOTTEMP" >/dev/null 2>&1

if [[ "$OSTYPE" =~ ^linux ]]; then
  if ! cmd_exists systemmgr; then
    if (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' >/dev/null; then
      sudo bash -c "$(curl -LSs https://github.com/systemmgr/installer/raw/master/install.sh)"
      sudo bash -c "$(curl -LSs https://github.com/systemmgr/installer/raw/master/install.sh)"
    else
      printf_red '\t\tplease run sudo bash -c "$(curl -LSs https://github.com/systemmgr/installer/raw/master/install.sh)\n"'
      exit 1
    fi
  fi
fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if cmd_exists "sudoers"; then
  printf_custom "4" "$(sudoers nopass)"
fi

##################################################################################################
printf_blue "\t\tSetting up the git repo\n"
printf_blue "\t\t$GITREPO\n"
##################################################################################################

_git_repo_init() {
if [ -d "$DOTFILES"/.git ]; then
  #git -C "$DOTFILES" pull -f
  git -C "$DOTFILES" pull -f
  getexitcode "repo update successfull"
else
  #git clone "$GITURL" "$DOTFILES"
  git clone "$GITURL" "$DOTFILES"
  getexitcode "git clone successfull"
fi

if [ -d "$DOTFILES" ]; then cp -Rf "$DOTFILES" "$DOTTEMP" >/dev/null 2>&1; fi
}

##################################################################################################
printf_blue "\t\tThe installer is updating the scripts\n"
##################################################################################################

_scripts_init() {
for sudoconf in installer; do
  sudo systemmgr install $sudoconf
done

if [[ "$OSTYPE" =~ ^linux ]]; then
  if [ "$1" = "--all" ]; then
    install_all_dfmgr
  elif [ "$1" = "--server" ]; then
    install_server_dfmgr
  elif [ "$1" = "--desktop" ]; then
    install_desktop_dfmgr
  elif [ "$1" = "" ]; then
    install_basic_dfmgr
  fi
else
  install_basic_dfmgr
fi
}

##################################################################################################
printf_blue "\t\tInstalling your personal files\n"
##################################################################################################

_files_init() {
find "$HOME/" -xtype l -delete >/dev/null 2>&1
mkdir -p "$HOME"/.ssh "$HOME"/.gnupg >/dev/null 2>&1

chmod -Rf 755 "$DOTTEMP"/usr/local/bin/* >/dev/null 2>&1
chmod -Rf 755 "$DOTTEMP"/etc/skel/.local/bin/* >/dev/null 2>&1

find "$DOTTEMP"/etc -type f -iname "*.bash" -exec chmod 755 -Rf {} \; >/dev/null 2>&1
find "$DOTTEMP"/etc -type f -iname "*.sh" -exec chmod 755 -Rf {} \; >/dev/null 2>&1
find "$DOTTEMP"/etc -type f -iname "*.pl" -exec chmod 755 -Rf {} \; >/dev/null 2>&1
find "$DOTTEMP"/etc -type f -iname "*.cgi" -exec chmod 755 -Rf {} \; >/dev/null 2>&1

find "$DOTTEMP"/usr -type f -iname "*.bash" -exec chmod 755 -Rf {} \; >/dev/null 2>&1
find "$DOTTEMP"/usr -type f -iname "*.sh" -exec chmod 755 -Rf {} \; >/dev/null 2>&1
find "$DOTTEMP"/usr -type f -iname "*.pl" -exec chmod 755 -Rf {} \; >/dev/null 2>&1
find "$DOTTEMP"/usr -type f -iname "*.cgi" -exec chmod 755 -Rf {} \; >/dev/null 2>&1

unalias cp 2>/dev/null

rsync -ahqk "$DOTTEMP"/etc/skel/. "$HOME"/

export GPG_TTY="$(tty)"

if (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' >/dev/null; then
  mv -f "$DOTTEMP"/etc/skel "$DOTTEMP"/tmp/skel >/dev/null 2>&1
  sudo rsync -ahq "$DOTTEMP"/etc/* /etc/ >/dev/null 2>&1
  mv -f "$DOTTEMP"/tmp/skel "$DOTTEMP"/etc/skel >/dev/null 2>&1
fi

# Import gpg keys
gpg --import "$DOTTEMP"/tmp/*.gpg 2>/dev/null
gpg --import "$DOTTEMP"/tmp/*.sec 2>/dev/null
gpg --import-ownertrust "$DOTTEMP"/tmp/*.trust 2>/dev/null

# import podcast feeds
if cmd_exists castero; then
  if [[ -f "$HOME"/.config/castero/podcasts.opml ]]; then
    castero --import "$HOME"/.config/castero/podcasts.opml >/dev/null 2>&1
  elif [[ -f "$DOTTEMP"/tmp/podcasts.opml ]]; then
    castero --import "$DOTTEMP"/tmp/podcasts.opml >/dev/null 2>&1
  fi
fi

# import rss feeds
if cmd_exists newsboat; then
  if [[ -f "$HOME"/.config/newsboat/news.opml ]]; then
    newsboat -i "$HOME"/.config/newsboat/news.opml >/dev/null 2>&1
  elif [[ -f "$DOTTEMP"/tmp/news.opml ]]; then
    newsboat -i "$DOTTEMP"/tmp/news.opml >/dev/null 2>&1
  fi
fi

find "$HOME"/.gnupg "$HOME"/.ssh -type f -exec chmod 600 {} \; >/dev/null 2>&1
find "$HOME"/.gnupg "$HOME"/.ssh -type d -exec chmod 700 {} \; >/dev/null 2>&1

chmod 755 -f "$HOME" >/dev/null 2>&1

rm -Rf "$HOME/.local/share/mail/*/.keep" >/dev/null 2>&1
rm -Rf "$TMP_FILE"

mkdir -p "$HOME"/{Projects,Music,Videos,Downloads,Pictures,Documents}
}

##################################################################################################
printf_green "\t\tInstalling your personal files completed\n\n"
##################################################################################################

main() {
if [ "$DOTTEMP" != "$DOTFILES" ]; then
  if [ -d "$DOTTEMP" ]; then rm -Rf "$DOTTEMP" >/dev/null 2>&1; fi
fi
execute "_pre_inst" "Setting up"
execute "_git_repo_init" "Initializing git repo"
execute "_scripts_init" "Installing scripts"
execute "_files_init" "Installing files"
unset __colors DOTTEMP MIN UPDATE DESKTOP
exit "$?"
}

##################################################################################################
# finally run main function
main "$@"

##################################################################################################

# end
