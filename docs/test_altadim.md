# How to test Altadim in a virtual machine

This section explains how to set up a virtual machine to test Altadim
using VirtualBox and Vagrant.

- Vagrant lets you specify & manage virtual Linux distributions.
- VirtualBox lets you run virtual machines.

## Prepare your setup

- First, update your system packages: `sudo apt update && sudo apt upgrade`
- Install VirtualBox: Download from [https://www.virtualbox.org/](https://www.virtualbox.org/)
- Install Vagrant: `sudo apt install vagrant`

## Run Altadim in your Virtual Machine (VM)

- Create a directory for your VM & initialise git:
  `mkdir ~/vm-altadim && cd ~/vm-altadim && git init`
- Create a `Vagrantfile` with Ubuntu 24.04:
  `vagrant init bento/ubuntu-24.04 --box-version 202502.21.0`
- Files in the project directory (the same directory where the `Vagrantfile` sits)
  are automatically accessible in the VM at `/vagrant`.
  - Copy Altadim's install script to the project directory:
    `wget https://raw.githubusercontent.com/khaldoun-xyz/altadim/main/install_altadim.sh`
- Start your VM with `vagrant up` (you may need to run this as `sudo`)
- Connect to your VM: `vagrant ssh` (you may need to run this as `sudo`)
- Navigate to the `/vagrant` directory: `cd /vagrant`
- Run the install script: `sudo bash install_altadim.sh`
