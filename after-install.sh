USR_SHELL=$(grep $(id -u) /etc/passwd | grep -E '[a-z]*sh' -o)
sudo pacman -Sy pciutils
if [[ $(lspci -d 106B: | wc -l) -gt 0 ]]; then # 106b is vendor id of apple, lspci is pretty much everywhere so let's just use that idk
  echo 'found apple'
  echo '[arch-mact2] \
  #Server = https://mirror.funami.tech/arch-mact2/os/x86_64 \
  Server = https://github.com/NoaHimesaka1873/arch-mact2-mirror/releases/download/release \
  SigLevel = Never ' | sudo tee -a /etc/pacman.conf &&
    sudo pacman -Syu linux-t2 linux-t2-headers apple-t2-audio-config apple-bcm-firmware linux-firmware iwd efibootmgr t2fanrd
else
  echo 'no apple'
fi
WD=$(pwd)
PARU_PATH=$HOME/paru
sudo pacman -Syu --needed git base-devel --noconfirm
cd $HOME
rm -rf $PARU_PATH
git clone https://aur.archlinux.org/paru
cd $PARU_PATH
makepkg -si
rm -rf $PARU_PATH
cd $WD
paru -Syu parui gnome gnome-tweaks ranger firefox tmux neovim kitty bat devtools fzf refind --noconfirm
sudo refind-install
if [[ $(ps -ax | grep gdm | wc -l) -gt 6 ]]; then
  sudo systemctl enable --now gdm
fi
git clone https://github.com/LazyVim/starter $HOME/.config/nvim

if [[ $USR_SHELL -eq "bash" ]]; then
  echo 'eval "$(fzf --bash)"' >>~/.bashrc

elif [[ $USR_SHELL -eq "zsh" ]]; then
  echo 'eval "$(fzf --zsh)"' >>~/.zshrc
fi
