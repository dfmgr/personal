dotfilespersonal() {
local MIN=no 
local UPDATE=yes
bash -c "$(curl -LSs -H 'Authorization: token $GITHUB_ACCESS_TOKEN' $MYPERSONALGITREPO/raw/master/install.sh)"
}
