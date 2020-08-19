#!/usr/bin/env bash

APPNAME="$(basename $0)"
USER="${SUDO_USER:-${USER}}"
HOME="${USER_HOME:-${HOME}}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# @Author          : Jason
# @Contact         : casjaysdev@casjay.net
# @File            : install
# @Created         : Wed, Aug 09, 2020, 02:00 EST
# @License         : WTFPL
# @Copyright       : Copyright (c) CasjaysDev
# @Description     : installer script for dotfiles-personal
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Options

PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/core_perl/cpan"
#Modify and set if using the auth token
AUTHTOKEN="${GITHUB_ACCESS_TOKEN:-AUTH_TOKEN_HERE}"
# either http https or git
GITPROTO="https://"
#Your git repo
GITREPO="${MYPERSONALGITREPO:-github.com/dfmgr/personal}"
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

SCRIPTSFUNCTURL="${SCRIPTSFUNCTURL:-https://github.com/dfmgr/installer/raw/master/functions}"
SCRIPTSFUNCTDIR="${SCRIPTSFUNCTDIR:-/usr/local/share/CasjaysDev/scripts}"
SCRIPTSFUNCTFILE="${SCRIPTSFUNCTFILE:-system-installer.bash}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -f "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$SCRIPTSFUNCTDIR/functions/$SCRIPTSFUNCTFILE"
elif [ -f "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE" ]; then
  . "$HOME/.local/share/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
else
  mkdir -p "/tmp/CasjaysDev/functions"
  curl -LSs "$SCRIPTSFUNCTURL/$SCRIPTSFUNCTFILE" -o "/tmp/CasjaysDev/functions/$SCRIPTSFUNCTFILE" || exit 1
  . "/tmp/CasjaysDev/functions/$SCRIPTSFUNCTFILE"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

install_all() {
  dotfiles install --all
  exit
}
install_server() {
  dotfiles install bash git tmux vifm vim
  exit
}
install_desktop() {
  dotfiles install awesome bspwm i3 openbox qtile xfce4 xmonad
  exit
}

##################################################################################################

if [ -z "$AUTHTOKEN" ] || [ "$AUTHTOKEN" == "YOUR_AUTH_TOKEN" ]; then
  printf_red "AUTH Token is not set"
  exit 1
fi
if [ ! -f "$(which sudo 2>/dev/null)" ] && [[ $EUID -ne 0 ]]; then
  printf_red "\t\tSudo is needed, however its not installed installed\n"
  exit 1
fi

##################################################################################################

clear
sleep 1
printf_green "Initializing the installer please wait"
sleep 2

##################################################################################################

if [ ! -d "$DOTFILES"/.git ]; then rm -Rf "$DOTFILES"; fi
rm -Rf "$DOTTEMP" >/dev/null 2>&1

if ! cmd_exists dotfiles; then
  if (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' >/dev/null; then
    sudo bash -c "$(curl -LSs https://github.com/dfmgr/installer/raw/master/install.sh)"
    sudo bash -c "$(curl -LSs https://github.com/dfmgr/installer/raw/master/install.sh)"
  else
    printf_red 'please run sudo bash -c "$(curl -LSs https://github.com/dfmgr/installer/raw/master/install.sh)"'
    exit 1
  fi
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if cmd_exists "sudoers"; then
  sudoers nopass
fi

##################################################################################################

printf_blue "Setting up the git repo"
printf_blue "$GITREPO"

##################################################################################################

find "$HOME/" -xtype l -delete >/dev/null 2>&1
mkdir -p "$HOME"/.ssh "$HOME"/.gnupg >/dev/null 2>&1

##################################################################################################

if [ -d "$DOTFILES"/.git ]; then
  cd "$DOTFILES"
  git pull -fq >/dev/null 2>&1
  getexitcode "repo update successfull"
else
  git clone -q --depth=1 "$GITURL" "$DOTFILES" >/dev/null 2>&1
  getexitcode "git clone successfull"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -d "$DOTFILES" ]; then cp -Rf "$DOTFILES" "$DOTTEMP" >/dev/null 2>&1; fi

##################################################################################################
printf_blue "The installer is updating the scripts"
##################################################################################################

for sudoconf in binaries samba ssl ssh postfix cron tor; do
  sudo bash -c "$(curl -LSs https://github.com/systemmgr/$sudoconf/raw/master/install.sh)"
done

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ "$1" = "--all" ]; then
  install_all
elif [ "$1" = "--server" ]; then
  install_server
elif [ "$1" = "--desktop" ]; then
  install_desktop
elif [ "$1" = "" ]; then
  dotfiles install bash dircolors git vim tmux screen
fi

##################################################################################################
printf_blue "Installing your personal files"
##################################################################################################

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

cp -Rfa "$DOTTEMP"/etc/skel/. "$HOME"/

export GPG_TTY="$(tty)"

if (sudo -vn && sudo -ln) 2>&1 | grep -v 'may not' >/dev/null; then
  mv -f "$DOTTEMP"/etc/skel "$DOTTEMP"/tmp/skel >/dev/null 2>&1
  sudo cp -Rf "$DOTTEMP"/etc/* /etc/ >/dev/null 2>&1
  mv -f "$DOTTEMP"/tmp/skel "$DOTTEMP"/etc/skel >/dev/null 2>&1
fi

# Import gpg keys
gpg --import "$DOTTEMP"/tmp/*.gpg 2>/dev/null
gpg --import "$DOTTEMP"/tmp/*.sec 2>/dev/null
gpg --import-ownertrust "$DOTTEMP"/tmp/ownertrust.gpg 2>/dev/null

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

#if [[ $EUID -eq 0 ]]; then
# rm -Rf --preserve-root /var/lib/tor/*
# rm -Rf --preserve-root /var/lib/tor/.bash*
#fi

rm -Rf "$HOME/.local/share/mail/*/.keep" >/dev/null 2>&1
rm -Rf "$TMP_FILE"

mkdir -p "$HOME"/{Projects,Music,Videos,Downloads,Pictures,Documents}

##################################################################################################
printf_green "Installing your personal files completed" "\n\n"
##################################################################################################

if [ "$DOTTEMP" != "$DOTFILES" ]; then
  if [ -d "$DOTTEMP" ]; then rm -Rf "$DOTTEMP" >/dev/null 2>&1; fi
fi

if [ "$MIN" = "no" ]; then
  unset __colors DOTTEMP MIN UPDATE DESKTOP
  exit 0
fi

if [ -z "$MIN" ] || [ "$MIN" = "yes" ]; then
  sleep 5
  bash -c "$(curl -LsS https://raw.githubusercontent.com/casjay-dotfiles/minimal/master/install.sh)"
  unset __colors DOTTEMP MIN UPDATE DESKTOP
  exit 0
fi

if [ ! -z "$UPDATE" ]; then
  sleep 5
  bash -c "$(curl -LsS https://raw.githubusercontent.com/casjay-dotfiles/minimal/master/update.sh)"
  unset __colors DOTTEMP MIN UPDATE DESKTOP
  exit 0
fi

if [ ! -z "$DESKTOP" ]; then
  sleep 5
  bash -c "$(curl -LsS https://github.com/casjay-dotfiles/desktops/raw/master/src/os/setup.sh)"
  unset __colors DOTTEMP MIN UPDATE DESKTOP
  exit 0
fi
