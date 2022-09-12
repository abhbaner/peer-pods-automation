#!/bin/bash
sudo apt update -y
echo "Installing make >> "
sudo apt-get -y install ubuntu-make
echo "Installing gcc >>"
sudo apt -y install build-essential
echo "Installing unzip>>"
sudo apt-get -y install unzip
echo "Installing Go>>>"
curl -LO https://go.dev/dl/go1.18.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.18.5.linux-amd64.tar.gz
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
source ~/.bashrc
go version
echo "Installing Rust>>>"
curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.58.1
source $HOME/.cargo/env 
rustup target add x86_64-unknown-linux-musl
echo "Installing Ansible"
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt -y install ansible 
echo "building Cloud api adaptor binary >>>"
export BUILD_DIR=$HOME/remote-hyp
mkdir -p $BUILD_DIR && cd $BUILD_DIR
git clone -b CCv0-peerpod https://github.com/yoheiueda/kata-containers.git
git clone https://github.com/confidential-containers/cloud-api-adaptor.git
cd cloud-api-adaptor
export CLOUD_PROVIDER=aws
make
echo "building kata-containers binary >>>"
pwd
wget -c https://github.com/protocolbuffers/protobuf/releases/download/v3.11.4/protoc-3.11.4-linux-x86_64.zip
sudo unzip protoc-3.11.4-linux-x86_64.zip -d /usr/local
cd $BUILD_DIR/kata-containers/src/runtime
make