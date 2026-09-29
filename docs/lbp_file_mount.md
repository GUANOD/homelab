# Mounting a VM Disk in Proxmox

## Map the Partitions

Use the following command to map the partitions:

```
kpartx -av /dev/pve/vm-102-disk-1
```

**Note:** If your VM ID isn't 102, adjust the number accordingly. If unsure of the disk name, run `ls /dev/pve/` to list available disks.

## Mount the Disk

Examine the output from the previous command. It will display a partition name such as `pve-vm--102--disk--1p1`.

Mount the partition with:

```
mount /dev/mapper/pve-vm--102--disk--1p1 /mnt/xp_disk
```

## Copy Your Files

Transfer files using SCP:

```
scp -r *file* user@proxmox:/mnt/xp_disk/
```

## Clean Up (Very Important!)

Failure to unmount and unmap may cause the VM to fail to start or result in disk corruption.

```
umount /mnt/xp_disk
kpartx -d /dev/pve/vm-102-disk-1
```