# Personal  
personal files  
Howto install  

clone this repo to your system and copy all personal files from your HOME to the skel dir  
    
If you have GPG key then copy them to the tmp dir and  
the installer will automatically install them ensure a .gpg  
ending for public and for your private keys add a .sec ending  

Change all instances of casjay-dotfiles/personal with your repo name     
Create a private repo and then create a private token replace all instances  
of AUTH_TOKEN_HERE with the private token you have Quick way is find to run the followng commands  
the MY_GIT_REPO_URL does not include the https:// ( IE: github.com/MyUserName/personal )  

```bash
git clone https://github.com/dfmgr/personal "$HOME/.local/dotfiles/personal"
for i in $(find "$HOME/.local/dotfiles/personal/etc" -name "*.sample"); do mv -fv "$i" "${i%.sample}" ; done
"$HOME/.local/dotfiles/personal/etc" -type f -exec sed -i "s#GITHUBAUTH_TOKEN_HERE#TokenYouCreated#g" {} \; >/dev/null 2>&1
"$HOME/.local/dotfiles/personal/etc" -type f -exec sed -i "s#MY_GIT_REPO_URL#YourGitRepoG#g" {} \; >/dev/null 2>&1
```
    
Modify install.sh and edit this README to your liking  
then push this to your git repo  
  
#### All Unix and Linux

### Automated Install
```bash
bash -c "$(curl -LsS -H 'Authorization: token GITHUBAUTH_TOKEN_HERE' https://raw.githubusercontent.com/dfmgr/personal/master/install.sh)"
```
### To exclude minimal dotfiles
```bash
MIN=no bash -c "$(curl -LsS -H 'Authorization: token GITHUBAUTH_TOKEN_HERE' https://raw.githubusercontent.com/dfmgr/personal/master/install.sh)"
```
### Update
```bash
UPDATE=yes bash -c "$(curl -LsS -H 'Authorization: token GITHUBAUTH_TOKEN_HERE' https://raw.githubusercontent.com/dfmgr/personal/master/install.sh)"
```
### Windows install   
```shell
GITHUB_ACCESS_TOKEN=GITHUBAUTH_TOKEN_HERE
git clone -q https://$GITHUB_ACCESS_TOKEN:x-oauth-basic@github.com/dfmgr/personal.git /tmp/dotfiles
cp -Rfva /tmp/dotfiles/etc/skel/. ~/
gpg --import /tmp/dotfiles/tmp/*.gpg
rm -Rf /tmp/dotfiles
```
