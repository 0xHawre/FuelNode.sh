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

# Example usage:
print_ascii
echo "Welcome to the Fuel Core Setup Script"
echo "===================================="


sudo apt-get update -y && sudo apt-get upgrade -y

echo "install necessary tools"


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
}

check_rustc

apt-get install git 

curl https://install.fuel.network | sh
source /root/.bashrc

export PATH="/root/.fuelup/bin:$PATH"

fuelup toolchain install latest
Update Fuelup to the latest version
fuelup toolchain install nightly
fuelup default nightly
fuelup show
fuelup default

git clone https://github.com/0xHawre/fuelNode
fuelup toolchain install testnet
fuelup default testnet

echo "Now we're going to generate a new Peering Key. Make sure to save them."
fuel-core-keygen new --key-type peering >> secret.txt

echo "Your keys have been saved to secret.txt."
echo "Please save them securely and press Enter after you have done so."

# Wait for the user to press Enter
read -p "Press Enter to continue..." enter_key

# Continue with the rest of your script here
# For example:
echo "Continuing with the rest of the story..."

apt-get install tmux
tmux new-session -s fuelu 

read -p "Enter the node name: " nodeName
read -p "Enter youre secretkeu" secretK  
read -p "Enter youre ETH_SEPOLIA RPC " RPC
fuel-core run \
  --service-name=$nodeName \
  --keypair $secretK \
  --relayer $RPC  \
  --ip=0.0.0.0 --port=5333 --peering-port=40453 \
  --db-path=~/.fuel-sepolia-testnet \
  --snapshot /root/.forc/git/checkouts/std-9be0d6062747ea7/2f0392ee35a1e4dd80bd8034962d5b4083dfb8b6/.github/workflows/local-testnode \
  --utxo-validation --poa-instant false --enable-p2p \
  --reserved-nodes /dns4/p2p-testnet.fuel.network/tcp/30333/p2p/16Uiu2HAmDxoChB7AheKNvCVpD4PHJwuDGn8rifMBEHmEynGHvHrf \
  --sync-header-batch-size 100 \
  --enable-relayer \
  --relayer-v2-listening-contracts=0x01855B78C1f8868DE70e84507ec735983bf262dA \
  --relayer-da-deploy-height=5827607 \
  --relayer-log-page-size=500 \
  --sync-block-stream-buffer-size 30



