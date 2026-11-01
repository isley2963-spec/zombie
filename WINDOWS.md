# Getting Zombie OS running in a VM from Windows

You do not need Linux on your PC. GitHub builds the ISO for you.

## 1. Build the ISO on GitHub (about 1 to 2 hours, free)

1. Create a free account at github.com and make a **new repository** (private is fine).
2. Upload everything in this folder to it, including the hidden `.github` folder.
   Easiest way: on the repository page choose **Add file > Upload files** and drag the whole unzipped folder in.
   If `.github` does not upload through the browser, install GitHub Desktop and use that instead.
3. Open the **Actions** tab, choose **Build Zombie OS ISO** on the left, then **Run workflow**.
4. Wait for the run to finish. Open it and download **zombie-os-iso** from the Artifacts section at the bottom.
   Unzip it to get `zombie-os-43-x86_64.iso` and its `.sha256` file.
5. Optional: check the file in PowerShell with `Get-FileHash .\zombie-os-43-x86_64.iso -Algorithm SHA256` and compare it with the `.sha256` file.

If the run fails, open the failed step and send me the last 40 lines of the log. The first build often needs a small package-name fix.

The artifact is kept for 7 days.

## 2. Create the VM

Use VirtualBox, VMware Workstation Player, or Hyper-V.

| Setting | Value |
| --- | --- |
| Type / version | Linux, Fedora (64-bit) |
| Memory | **2048 MB** to boot the live ISO and run the installer. After installing, lower it to **1024 MB**. |
| CPUs | 2 |
| Disk | 20 GB or more |
| Display memory | Maximum |
| Graphics controller (VirtualBox) | VMSVGA, with 3D acceleration on |
| Firmware | Enable EFI |
| Optical drive | Select the Zombie OS ISO |

## 3. Install and choose a desktop

1. Boot the VM and run the installer from the live session.
2. After installing, remove the ISO and reboot.
3. At the login screen, use the session picker to choose GNOME, Plasma or Hyprland.
   On 1 GB, choose **Hyprland**. If it will not start in your VM, turn 3D acceleration on, or use Plasma.
