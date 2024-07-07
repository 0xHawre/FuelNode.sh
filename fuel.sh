#!/bin/bash

print_ascii() {
    echo "  ___       _    _                         "
    echo " / _ \     | |  | |                        "
    echo "| | | |_  _| |__| | __ ___      ___ __ ___ "
    echo "| | | \ \/ /  __  |/ _\` \ \ /\ / / '__/ _ \\"
    echo "| |_| |>  <| |  | | (_| |\ V  V /| | |  __/"
    echo " \___//_/\_\_|  |_|\__,_| \_/\_/ |_|  \___|"
    echo "                                           "
}
echo "===================================="
print_ascii
echo "Welcome to the Fuel Core Setup Script"
echo "===================================="

# Update package lists and upgrade all installed packages
sudo apt-get update -y && sudo apt-get upgrade -y
echo "install necessary tools........"


# install git 
check_git(){
  if command -v git &> /dev/null; then
    git_version=$(git --version | head -n 1)
    echo "git is installed: $git_version"
    else "git is not installed"
      install_git
  fi
}
install_git() {
  echo "installing git......."
  sudo apt-get install git 
}
check_git

# install wget 
check_wget() {
  if command -v wget &> /dev/null; then
    wget_version=$(wget --version | head -n 1 )
    echo "wget is installed: $wget_version"
  else 
    "wget is  not install"
    install_wget
  fi
}
install_wget() {
  echo "installing wget..."
  sudo  apt-get install wget -y
}
check_wget

# install curl 
check_curl() {
  if command -v curl &> /dev/null; then 
    curl_version=$(curl --version | head -n 1 )
  else 
    "curl is not installed"
    install_curl 
  fi 
}
install_curl() {
  echo "installing curl..."
  sudo apt-get install curl -y
}
check_curl

# install rust 
check_rustc() {
  if command -v rustc &> /dev/null; then
    rustc_version=$(rustc --version | head -n 1)
    echo "rustc is installed: $rustc_version"
  else
    echo "rustc is not installed."
    install_rustc
  fi
}
install_rustc() {
  echo "installing rusrc...."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs/ | sh -s -- -y
  PATH=#PATH:./cargo/bin
}
check_rustc

# install tmux 
check_tmux() {
  if command -v tmux &> /dev/null; then
    tmux_version=$(tmux --version | head -n 1)
    echo "tmux version is ${tmux_version}"
  else
    "tmux is not installes"
    install_tmux 
  fi 
}
install_tmux() {
  echo "installing tmux....."
  sudo apt-get install tmux
}
check_tmux

# install fuel 
curl https://install.fuel.network | sh
source /root/.bashrc
export PATH="/root/.fuelup/bin:$PATH"

fuelup toolchain install latest
fuelup self update 
fuelup toolchain install nightly
fuelup default nightly
fuelup show
fuelup default

git clone https://github.com/FuelLabs/chain-configuration chain-configuration
mkdir .fuel-sepolia-testnet 
cp -r chain-configuration/ignition/* ~/.fuel-sepolia-testnet/

fuelup toolchain install testnet
fuelup default testnet

echo "Now we're going to generate a new Peering Key. Make sure to save them."
fuel-core-keygen new --key-type peering >> secret.txt
cat secret.txt 
echo "Your keys have been saved to secret.txt."
echo "Please save them securely and press Enter after you have done so."
read -p "If you saved you're secret key Press Enter to continue..." enter_key


read -p "Enter node name: " nodeName
read -p "Enter secret key pair: " sec
echo
read -p "Enter relayer RPC: " RPC


cat <<EOT > /tmp/fuel_core_command.sh
#!/bin/bash
fuel-core run \
      --service-name=$nodeName \
      --keypair= $sec \
      --relayer= $RPC \
      --ip=0.0.0.0 --port=5333 --peering-port=40453 \
      --db-path=~/.fuel-sepolia-testnet \
      --snapshot ~/.fuel-sepolia-testnet \
      --utxo-validation --poa-instant=false --enable-p2p \
      --reserved-nodes=/dns4/p2p-testnet.fuel.network/tcp/30333/p2p/16Uiu2HAmDxoChB7AheKNvCVpD4PHJwuDGn8rifMBEHmEynGHvHrf \
      --sync-header-batch-size=100 \
      --enable-relayer \
      --relayer-v2-listening-contracts=0x01855B78C1f8868DE70e84507ec735983bf262dA \
      --relayer-da-deploy-height=5827607 \
      --relayer-log-page-size=500 \
      --sync-block-stream-buffer-size=30
EOT

chmod +x /tmp/fuel_core_command.sh

SESSION_NAME="my_tmux_session"
tmux new-session -d -s $SESSION_NAME
tmux send-keys -t $SESSION_NAME "/tmp/fuel_core_command.sh" C-m
tmux attach -t $SESSION_NAME

