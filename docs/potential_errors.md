# Potential errors you might encounter

## errors with `vagrant up`

- "Bringing machine 'default' up with 'libvirt' provider...
  Error while connecting to Libvirt: Error making a connection to libvirt URI qemu:///system:
  Call to virConnectOpen failed: Failed to connect socket
  to '/var/run/libvirt/libvirt-sock': No such file or directory":
  - `sudo apt install libvirt-daemon-system libvirt-clients qemu-kvm`
- "Name `vm-altadim_default` of domain about to create is already taken.
  Please try to run `vagrant up` command again."
  - `sudo virsh destroy vm-altadaim_default`
  - `sudo virsh undefine vm-altadaim_default`
- "There was an error while executing `VBoxManage`, a CLI used by Vagrant
  for controlling VirtualBox. The command and stderr is shown below.
  Command: ["startvm", "4517a6b8-bcce-42d6-97b9-9d2bcd71288c", "--type", "headless"]
  Stderr: VBoxManage: error: VirtualBox can't operate in VMX root mode.
  Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_VMX_IN_VMX_ROOT_MODE)
  VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005),
  component ConsoleWrap, interface IConsole"
  - `sudo modprobe -r kvm_intel kvm`

## fixes

- if your wifi is not available, follow these steps:
  <https://askubuntu.com/questions/55868/installing-broadcom-wireless-drivers>
- if your webcam is not available, follow the Debian steps:
  <https://github.com/patjak/facetimehd/wiki/Installation#get-started-on-debian>
