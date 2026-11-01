# Zombie OS

A Red Hat family Linux spin built on **Fedora**. It ships the stock Fedora Linux kernel and three desktops, **GNOME**, **KDE Plasma** and **Hyprland**, with a dark frosted glass look. Pick the desktop at the login screen.

## What is in this folder

| File | What it is |
| --- | --- |
| `zombie-os.ks` | The kickstart: every package, service and setting in the OS |
| `build.sh` | Builds the bootable ISO from the kickstart |
| `site/index.html` | The Zombie OS website (dark frosted glass, one self-contained file) |

## Build the ISO

You need a Fedora machine, a privileged Fedora container, or a Fedora VM, with internet access and about 25 GB of free disk space.

```bash
sudo ./build.sh                  # uses the Fedora release you are running
sudo RELEASEVER=43 ./build.sh    # or pick a release
```

The ISO and its SHA-256 checksum land in `out/`. Write it to a USB stick (replace `/dev/sdX` with your stick, this erases it):

```bash
sudo dd if=out/zombie-os-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## The 1 GB target, plainly

- The **installed** system is tuned for 1 GB: zram swap (zstd), earlyoom, a small volatile journal, no file indexer, no GNOME Software, no CUPS, no ABRT, and Hyprland animations off.
- Run **one desktop session at a time**. All three are installed, none run together.
- Rough order of memory use, lightest first: **Hyprland, KDE Plasma, GNOME**. On 1 GB, Hyprland is the comfortable choice. Plasma works with zram. GNOME will swap a lot.
- The **live ISO** boots into a RAM-backed environment and needs more than 1 GB to be pleasant. Install it to disk for the 1 GB experience.
- Hyprland needs a working GPU driver. It runs in most VMs with 3D acceleration on, and on real hardware.

## ISO size

An ISO's size comes from what is inside it. Three desktops make this one larger than a single-desktop Fedora spin (expect a few GB). It cannot be set to an exact number. If you need a smaller image, delete the packages for a desktop you do not want from the `%packages` section in `zombie-os.ks` and rebuild.

## Notes

- Hyprland is pulled from the `solopasha/hyprland` COPR (the `repo --name=hyprland` line). If your Fedora release already packages Hyprland, you can delete that line.
- SELinux and firewalld stay on. They cost almost no memory and are what you want on any machine you use for real work.
- This project was written but **not built or booted** where it was authored, since building an ISO needs root on a Fedora host. The first build may need small package-name adjustments for your Fedora release; `ksvalidator` and the `livemedia-creator` log will point to them.
- Fedora is a trademark of Red Hat, Inc. Zombie OS is an independent project and is not affiliated with or endorsed by Red Hat or the Fedora Project.
