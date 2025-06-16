# How to test Altadaim in a virtual machine

This section explains how to set up a virtual machine to test Altadaim
using VirtualBox and Vagrant.

- Vagrant lets you specify & manage virtual Linux distributions.
- VirtualBox lets you run virtual machines.

## Prepare your setup

- First, update your system packages: `sudo apt update && sudo apt upgrade`
- Install VirtualBox: `sudo apt install virtualbox`
- Install Vagrant: `sudo apt install vagrant`

## Run Altadaim in your Virtual Machine (VM)

- Create a directory for your VM & initialise git:
  `mkdir ~/vm-altadaim && cd ~/vm-altadaim && git init`
- Create a `Vagrantfile` with Ubuntu 24.04:
  `vagrant init bento/ubuntu-24.04 --box-version 202502.21.0`
- Files in the project directory (the same directory where the `Vagrantfile` sits)
  are automatically accessible in the VM at `/vagrant`.
  - Copy Altadaim's install script to the project directory:
    `wget https://raw.githubusercontent.com/khaldoun-xyz/altadaim/main/install_altadaim.sh`
- Start your VM with `vagrant up` (you may need to run this as `sudo`)
- Connect to your VM: `vagrant ssh` (you may need to run this as `sudo`)
- Navigate to the `/vagrant` directory: `cd /vagrant`
- Run the install script: `sudo bash install_altadaim.sh`

## Error log

- If you encounter errors, you might find help here: [potential errors](/docs/potential_errors.md)
