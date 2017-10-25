#!/bin/bash
A=$(tput sgr0)
echo -e '\E[32m'" $A"


ID=`/usr/bin/id -u`
echo " your id is $ID "
if [ $ID != 0 ];then
echo -e '\E[32m'" only root user can add new users; you are not allowed $A"
echo -e '\E[32m'" Please login as root and run this script again $A"
echo ""
else


echo -e '\E[32m'"Which zsh_configuration you need ?? $A"
echo ""
echo -e '\E[33m'"------------------------ $A"
echo -e '\E[33m'"| 1 |  Official    zsh | $A"
echo -e '\E[33m'"------------------------ $A"
echo -e '\E[33m'"| 2 |  customized  zsh | $A"
echo -e '\E[33m'"------------------------ $A"
echo ""
echo -e '\E[32m'"Press '1' or '2' $A"
echo ""
read ZSH_OPTION
until [[ $ZSH_OPTION = [1,2] ]];do
echo -e '\E[32m'"WARNING $A"
echo -e '\E[32m'"Press 1 or 2 $A"
read ZSH_OPTION
done
echo ""


echo ""
echo -e '\E[32m'" Please enter the username for your user $A"
read USERZ
LEN_USERZ=$(echo ${#USERZ})
until [[ $LEN_USERZ -gt 1 ]];do
echo -e '\E[33m'"WARNING $A"
echo -e '\E[33m'"enter the proper USER name $A"
read USERZ
LEN_USERZ=$(echo ${#USERZ})
done



if cat /etc/passwd | cut -d ":" -f 1 | grep $USERZ &> /dev/null ; then
echo ""
echo -e '\E[33m'"WARNING $A"
echo -e '\E[33m'"'$USERZ' is already present in this system $A"
echo -e '\E[33m'"Choose any one of the option from below $A"
echo ""
echo ""
echo -e '\E[33m'"--------------------------------------------------------------- $A"
echo -e '\E[33m'"| 1 | Delete the existing user and home folder and create new | $A"
echo -e '\E[33m'"--------------------------------------------------------------- $A"
echo -e '\E[33m'"| 2 | Aborting the task			 	       | $A"
echo -e '\E[33m'"--------------------------------------------------------------- $A"
echo ""
echo -e '\E[32m'"Press '1' or '2' $A"
echo ""
read USERZ_OPTION
until [[ $USERZ_OPTION = [1,2] ]];do
echo -e '\E[32m'"WARNING $A"
echo -e '\E[32m'"Press 1 or 2 $A"
read USERZ_OPTION
done
echo ""


if [[ $USERZ_OPTION = 1 ]];then
echo -e '\E[32m'"WARNING $A"
echo -e '\E[32m'"The Home folder will also delete so you may loose datas if anything inside $USERZ home folder $A"
echo ""
echo -e '\E[32m'"Do you really want to continue ??????????? $A"
echo -e '\E[32m'"Press Y or N $A"
read USERZ_DELETE
echo ""
until [[ $USERZ_DELETE = [Y,N] ]];do
echo -e '\E[32m'"WARNING $A"
echo -e '\E[32m'"Press Y or N $A"
read USERZ_DELETE
done
if [[ $USERZ_DELETE = Y ]];then
echo -e '\E[33m'"Deleting the $USERZ.....$A"
userdel -r $USERZ
else
echo -e '\E[33m'"Aborting.............. $A"
exit 0
fi
else
echo -e '\E[33m'"Aborting.............. $A"
exit 0
fi
fi

echo ""
echo -e '\E[32m'" Please note that your password is same as your username $A"
echo ""
useradd  --password $USERZ --shell /bin/bash --create-home $USERZ
echo "$USERZ:$USERZ" | chpasswd
usermod -aG sudo $USERZ
DEST=$(cat /etc/passwd | grep "$USERZ" | cut -d : -f6)
echo $ZSH_OPTION > $DEST/zsh-option.txt
echo $DEST > $DEST/destination.txt

apt-get update && apt-get install -y sshpass
addgroup installationzz
if cat /etc/sudoers | grep installationzz &> /dev/null ; then
echo "passwordless group is available"
else
echo "%installationzz         ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers
fi
usermod -aG installationzz $USERZ

if cat /etc/sudoers | grep "$USERZ    ALL = (ALL) NOPASSWD: /usr/local/bin/$USERZ" &> /dev/null ; then
echo "passwordless chown command is available"
else
echo "$USERZ    ALL = (ALL) NOPASSWD: /usr/local/bin/$USERZ" >> /etc/sudoers
fi

rm -rf /usr/local/bin/$USERZ
cat <<EOF >> /usr/local/bin/$USERZ
#!/bin/bash
chown -R $USERZ:$USERZ $DEST
EOF
chmod 700 /usr/local/bin/$USERZ


cat <<EOF >> $DEST/kickstart.2.sh
#!/bin/bash
cd $DEST
sudo apt-get install emacs -y
sudo curl -L https://github.com/akhilrajmailbox/prelude/raw/master/utils/installer.sh | sh
#sudo curl -L https://github.com/bbatsov/prelude/raw/master/utils/installer.sh | sh
sudo chsh -s /bin/zsh $USERZ
sudo apt-get install vim-nox w3m zsh -y
sudo chown -R $USERZ:$USERZ $DEST
sudo rm -rf $DEST/.zshrc $DEST/.bashrc

git clone https://github.com/akhilrajmailbox/dotfiles.git
sudo chown -R $USERZ:$USERZ $DEST


if [[ $ZSH_OPTION = 1 ]];then
curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh & wait
mv $DEST/.zshrc $DEST/.zshrc.bak
#mv $DEST/.emacs.d $DEST/.emacs.d.bak
cd $DEST/dotfiles && ./install
sudo chown -R $USERZ:$USERZ $DEST

else
echo ""
echo "customized zsh is configuring....."
echo ""
cd $DEST/dotfiles && ./install
echo ""
fi
EOF

ls /home/$USERZ/

chown -R $USERZ:$USERZ $DEST
chmod 777 $DEST/kickstart.2.sh
sshpass -p $USERZ ssh -o StrictHostKeyChecking=no -t -t $USERZ@localhost "sh -c '$DEST/kickstart.2.sh'" & wait

groupdel installationzz
gpasswd -d $USERZ sudo
sed -i '/%installationzz/d' /etc/sudoers
rm -rf $DEST/zsh-option.txt $DEST/destination.txt


chown -R $USERZ:$USERZ $DEST
echo ""
echo -e '\E[32m'"You need to change the password at the time of first login $A"
chage -d 0 $USERZ
rm -rf $DEST/kickstart.*
fi
