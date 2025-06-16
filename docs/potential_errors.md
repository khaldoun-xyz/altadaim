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
