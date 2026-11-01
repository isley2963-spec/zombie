#!/bin/bash
# Build the Zombie OS ISO.
# Run on a Fedora machine (or a privileged Fedora container / VM) with internet access
# and roughly 25 GB of free disk space.
#
#   sudo ./build.sh                 # builds for the Fedora release you are running
#   sudo RELEASEVER=43 ./build.sh   # builds for a specific Fedora release
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run as root: sudo ./build.sh" >&2
    exit 1
fi

cd "$(dirname "$0")"

RELEASEVER="${RELEASEVER:-$(rpm -E %fedora)}"
OUT="$PWD/out"
ISO="zombie-os-${RELEASEVER}-x86_64.iso"

dnf install -y lorax lorax-lmc-novirt pykickstart xorriso squashfs-tools

# Validate the kickstart before the long build
ksvalidator zombie-os.ks

rm -rf "$OUT" /var/tmp/zombie-lmc
mkdir -p /var/tmp/zombie-lmc
livemedia-creator \
    --make-iso \
    --no-virt \
    --ks zombie-os.ks \
    --project "Zombie OS" \
    --releasever "$RELEASEVER" \
    --volid "ZOMBIE_OS_${RELEASEVER}" \
    --iso-only \
    --iso-name "$ISO" \
    --tmp /var/tmp/zombie-lmc \
    --resultdir "$OUT" || {
    rc=$?
    echo "=== livemedia-creator failed (exit $rc). Installer logs follow ==="
    find /var/log /tmp /var/tmp "$OUT" -maxdepth 4 \
        \( -name 'packaging.log' -o -name 'dnf.librepo.log' -o -name 'anaconda.log' \) 2>/dev/null |
        while read -r f; do echo "--- $f (last 60 lines)"; tail -n 60 "$f"; done
    exit "$rc"
}

sha256sum "$OUT/$ISO" | tee "$OUT/$ISO.sha256"
ls -lh "$OUT/$ISO"
echo
echo "Done. ISO: $OUT/$ISO"
