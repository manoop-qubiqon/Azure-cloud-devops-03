# Storage and Disk Management in Linux (Ubuntu)
 
A practical guide to inspecting, partitioning, formatting, mounting, and managing storage on Ubuntu. Every section includes commands you can copy and run on a real system.
 
> **Heads up:** Disk commands can destroy data. Always double-check device names (e.g., `/dev/sdb` vs `/dev/sda`) before running write operations. Practice on a spare disk, USB stick, or VM.
 
---
 
## 1. Understanding Linux Storage Basics
 
In Linux, every storage device is treated as a file under `/dev`.
 
| Device pattern | Meaning |
|---|---|
| `/dev/sda`, `/dev/sdb` | SATA / SCSI / USB disks |
| `/dev/sda1`, `/dev/sda2` | Partitions on `/dev/sda` |
| `/dev/nvme0n1` | NVMe SSD |
| `/dev/nvme0n1p1` | First partition on NVMe disk |
| `/dev/mapper/...` | LVM logical volumes or LUKS-encrypted devices |
| `/dev/loop0` | Loopback device (e.g., a mounted ISO) |
 
The typical layout is: **physical disk → partition → filesystem → mount point**.
 
---
 
## 2. Viewing Disks and Partitions
 
### `lsblk` — list block devices (the everyday command)
 
```bash
lsblk
```
 
Example output:
 
```
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0   500G  0 disk
├─sda1   8:1    0   512M  0 part /boot/efi
├─sda2   8:2    0     1G  0 part /boot
└─sda3   8:3    0 498.5G  0 part /
sdb      8:16   1    32G  0 disk
└─sdb1   8:17   1    32G  0 part /media/usb
```
 
Useful flags:
 
```bash
lsblk -f          # show filesystem type, UUID, and label
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID
```
 
### `df` — show mounted filesystem usage
 
```bash
df -h             # human-readable sizes
df -hT            # also show filesystem type
df -i             # show inode usage (useful when "disk full" but space looks free)
```
 
### `du` — show how much space files/directories consume
 
```bash
du -sh /var/log              # total size of one directory
du -h --max-depth=1 /home    # one-level breakdown
du -ah /var | sort -rh | head -20   # top 20 biggest items
```
 
### `fdisk` and `parted` — show partition tables
 
```bash
sudo fdisk -l                # list all disks and partitions
sudo parted -l               # similar, friendlier for GPT disks
```
 
### `blkid` — show UUIDs and filesystem types
 
```bash
sudo blkid
# /dev/sda3: UUID="3f2a..." TYPE="ext4" PARTUUID="..."
```
 
UUIDs are what you should put in `/etc/fstab` instead of `/dev/sdaX` (device names can change between boots).
 
---
 
## 3. Partitioning a Disk
 
Two common partition table formats:
 
- **MBR (msdos)** — older, max 2 TB, max 4 primary partitions.
- **GPT** — modern standard, supports huge disks and many partitions. Required for UEFI boot.
### Using `fdisk` (interactive)
 
Assume you added a new disk at `/dev/sdb`:
 
```bash
sudo fdisk /dev/sdb
```
 
Inside the prompt:
 
```
g       # create a new empty GPT partition table
n       # new partition (accept defaults for full disk)
p       # print the table to verify
w       # write changes and exit
```
 
After writing, refresh the kernel's view:
 
```bash
sudo partprobe /dev/sdb
lsblk /dev/sdb
```
 
### Using `parted` (scriptable)
 
Create a GPT disk with one partition spanning the whole drive:
 
```bash
sudo parted /dev/sdb --script mklabel gpt
sudo parted /dev/sdb --script mkpart primary ext4 0% 100%
sudo parted /dev/sdb print
```
 
---
 
## 4. Creating Filesystems (Formatting)
 
After partitioning, you need a filesystem. Common choices on Ubuntu: **ext4** (default), **xfs**, **btrfs**, **vfat** (USB sticks), **exfat** (cross-platform large drives).
 
```bash
sudo mkfs.ext4 /dev/sdb1                # ext4
sudo mkfs.xfs  /dev/sdb1                # xfs
sudo mkfs.vfat -F 32 /dev/sdb1          # FAT32 (USB)
sudo mkfs.exfat /dev/sdb1               # exFAT (install: sudo apt install exfatprogs)
```
 
Add a label while formatting:
 
```bash
sudo mkfs.ext4 -L data /dev/sdb1
```
 
Change a label later:
 
```bash
sudo e2label /dev/sdb1 backups          # ext2/3/4
sudo xfs_admin -L backups /dev/sdb1     # xfs
```
 
---
 
## 5. Mounting and Unmounting
 
### Manual mount
 
```bash
sudo mkdir -p /mnt/data
sudo mount /dev/sdb1 /mnt/data
df -hT /mnt/data
```
 
Unmount:
 
```bash
sudo umount /mnt/data
```
 
If you get `target is busy`, find what's using it:
 
```bash
sudo lsof +D /mnt/data
sudo fuser -vm /mnt/data
```
 
### Persistent mounts via `/etc/fstab`
 
`/etc/fstab` is read at boot. Always use UUIDs.
 
Get the UUID:
 
```bash
sudo blkid /dev/sdb1
# /dev/sdb1: UUID="b3f5c2a1-..." TYPE="ext4"
```
 
Edit the file:
 
```bash
sudo nano /etc/fstab
```
 
Add a line like:
 
```
UUID=b3f5c2a1-...   /mnt/data   ext4   defaults,nofail   0   2
```
 
Field meanings: `device  mount-point  fs-type  options  dump  fsck-order`.
 
Test before rebooting:
 
```bash
sudo mount -a        # mounts everything in fstab; reports errors
findmnt /mnt/data    # verify it's mounted
```
 
> Tip: `nofail` prevents boot from hanging if the disk is missing (great for external/USB drives).
 
---
 
## 6. Swap Space
 
Swap is disk space used as overflow when RAM fills up.
 
### Check current swap
 
```bash
swapon --show
free -h
```
 
### Create a swap file (easiest on Ubuntu)
 
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```
 
Make it persistent — add to `/etc/fstab`:
 
```
/swapfile   none   swap   sw   0   0
```
 
Tune swappiness (lower = use swap less aggressively):
 
```bash
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
 
---
 
## 7. LVM — Logical Volume Manager
 
LVM lets you pool multiple disks/partitions and slice them into resizable logical volumes. The hierarchy is:
 
**Physical Volume (PV) → Volume Group (VG) → Logical Volume (LV)**
 
### Install LVM tools
 
```bash
sudo apt update
sudo apt install lvm2
```
 
### Build a setup from two disks
 
```bash
# 1. Create physical volumes
sudo pvcreate /dev/sdb /dev/sdc
 
# 2. Create a volume group named "datavg"
sudo vgcreate datavg /dev/sdb /dev/sdc
 
# 3. Create a 50 GB logical volume named "media"
sudo lvcreate -L 50G -n media datavg
 
# 4. Format and mount
sudo mkfs.ext4 /dev/datavg/media
sudo mkdir -p /mnt/media
sudo mount /dev/datavg/media /mnt/media
```
 
### Inspect
 
```bash
sudo pvs        # physical volumes
sudo vgs        # volume groups
sudo lvs        # logical volumes
sudo lvdisplay
```
 
### Extend a logical volume online
 
```bash
# Add 20 GB and grow the ext4 filesystem in one go
sudo lvextend -L +20G -r /dev/datavg/media
```
 
For xfs, the filesystem grows with `xfs_growfs /mnt/media` — `-r` handles both automatically.
 
### Shrink (ext4 only — back up first!)
 
```bash
sudo umount /mnt/media
sudo e2fsck -f /dev/datavg/media
sudo resize2fs /dev/datavg/media 30G
sudo lvreduce -L 30G /dev/datavg/media
sudo mount /dev/datavg/media /mnt/media
```
 
---
 
## 8. Disk Encryption with LUKS
 
LUKS is the standard full-disk encryption layer on Linux.
 
```bash
sudo apt install cryptsetup
 
# Encrypt the partition (DESTROYS data on it)
sudo cryptsetup luksFormat /dev/sdb1
 
# Open it — creates /dev/mapper/securedata
sudo cryptsetup open /dev/sdb1 securedata
 
# Create a filesystem inside the encrypted mapping
sudo mkfs.ext4 /dev/mapper/securedata
sudo mount /dev/mapper/securedata /mnt/secure
 
# When done
sudo umount /mnt/secure
sudo cryptsetup close securedata
```
 
---
 
## 9. Disk Health and Monitoring
 
### SMART data (mechanical and SSD health)
 
```bash
sudo apt install smartmontools
 
sudo smartctl -i /dev/sda          # device info
sudo smartctl -H /dev/sda          # overall health summary
sudo smartctl -a /dev/sda          # full attributes
sudo smartctl -t short /dev/sda    # run a short self-test
```
 
### I/O statistics
 
```bash
sudo apt install sysstat
iostat -xz 2          # extended stats every 2 seconds
```
 
### Real-time disk activity
 
```bash
sudo apt install iotop
sudo iotop -o         # only show processes doing I/O
```
 
### Find what's eating space
 
```bash
sudo apt install ncdu
sudo ncdu /            # interactive, sorted disk usage browser
```
 
---
 
## 10. Filesystem Maintenance
 
### Check and repair (must be unmounted!)
 
```bash
sudo umount /dev/sdb1
sudo fsck -y /dev/sdb1          # auto-repair ext filesystems
sudo xfs_repair /dev/sdb1       # for xfs
```
 
### Resize an ext4 filesystem
 
```bash
sudo resize2fs /dev/sdb1            # grow to fill the partition
sudo resize2fs /dev/sdb1 20G        # shrink (umount first, fsck first)
```
 
### Trim SSDs (reclaim deleted blocks)
 
```bash
sudo fstrim -av                     # trim all mounted filesystems
systemctl status fstrim.timer       # Ubuntu runs this weekly by default
```
 
---
 
## 11. Disk Quotas (limit user space)
 
```bash
sudo apt install quota
 
# Add usrquota,grpquota to the mount options in /etc/fstab, e.g.:
# UUID=...   /home   ext4   defaults,usrquota,grpquota   0   2
 
sudo mount -o remount /home
sudo quotacheck -cum /home
sudo quotaon /home
 
# Set limits for user "alice": soft 5G, hard 6G
sudo setquota -u alice 5000000 6000000 0 0 /home
 
# Inspect
sudo repquota -a
quota -u alice
```
 
---
 
## 12. Quick Cheat Sheet
 
| Task | Command |
|---|---|
| List disks/partitions | `lsblk -f` |
| Show free space | `df -hT` |
| Largest directories | `du -h --max-depth=1 /` |
| Get UUID | `sudo blkid` |
| Partition (interactive) | `sudo fdisk /dev/sdX` |
| Format ext4 | `sudo mkfs.ext4 /dev/sdX1` |
| Mount | `sudo mount /dev/sdX1 /mnt/point` |
| Unmount | `sudo umount /mnt/point` |
| Test fstab | `sudo mount -a` |
| Add swap file | `fallocate → mkswap → swapon` |
| Create LVM stack | `pvcreate → vgcreate → lvcreate` |
| Grow LV + FS | `sudo lvextend -L +10G -r /dev/vg/lv` |
| Encrypt | `sudo cryptsetup luksFormat /dev/sdX1` |
| Disk health | `sudo smartctl -H /dev/sda` |
| Live I/O | `sudo iotop -o` |
| Space explorer | `sudo ncdu /` |
 
---
 
## 13. Common Pitfalls
 
- **Editing `/etc/fstab` wrong** can prevent boot. Always run `sudo mount -a` after editing — if it errors, fix it before rebooting.
- **Wrong device name** during `mkfs` or `fdisk` wipes data instantly. Confirm with `lsblk` first.
- **"No space left on device" with free space showing** usually means inodes are exhausted. Check with `df -i`.
- **Removing a USB while mounted** can corrupt the filesystem. Always `sudo umount` (or use the file manager's eject) first.
- **Shrinking xfs is not supported** — only ext4 can be shrunk safely. Plan sizes accordingly.
---