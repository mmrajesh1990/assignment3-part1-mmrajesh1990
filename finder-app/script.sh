#!/bin/bash
# Script to build ARM64 Linux kernel and root filesystem for QEMU
# Assignment 3 Part 2 – AESD

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
FINDER_APP_DIR=$(realpath $(dirname $0))

if [ $# -ge 1 ]; then
    OUTDIR=$(realpath $1)
    echo "Using passed directory ${OUTDIR} for output"
else
    echo "Using default directory ${OUTDIR} for output"
fi

mkdir -p "${OUTDIR}"

#############################
# Build Linux Kernel
#############################
cd "${OUTDIR}"

if [ ! -d linux-stable ]; then
    echo "Cloning Linux kernel ${KERNEL_VERSION}"
    git clone ${KERNEL_REPO} --depth 1 --branch ${KERNEL_VERSION} linux-stable
fi

cd linux-stable

if [ ! -f arch/${ARCH}/boot/Image ]; then
    echo "Building Linux kernel"
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
fi

cp arch/${ARCH}/boot/Image "${OUTDIR}/Image"
echo "Kernel Image copied to ${OUTDIR}/Image"

#############################
# Create Root Filesystem
#############################
cd "${OUTDIR}"
sudo rm -rf rootfs
mkdir -p rootfs

cd rootfs
mkdir -p bin sbin etc proc sys dev lib lib64 home

#############################
# Build BusyBox
#############################
cd "${OUTDIR}"

if [ ! -d busybox ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
else
    cd busybox
fi

make distclean
make defconfig

# Enable static build
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config

make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

#############################
# Library dependencies
#############################
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

cp -a ${SYSROOT}/lib/* "${OUTDIR}/rootfs/lib/" || true
cp -a ${SYSROOT}/lib64/* "${OUTDIR}/rootfs/lib64/" || true

#############################
# Device Nodes
#############################
sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3
sudo mknod -m 600 "${OUTDIR}/rootfs/dev/console" c 5 1

#############################
# Build writer (Assignment 2)
#############################
cd "${FINDER_APP_DIR}"
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
cp writer "${OUTDIR}/rootfs/home/"

#############################
# Copy finder scripts and config
#############################
cd "${OUTDIR}/rootfs/home"

cp "${FINDER_APP_DIR}/finder.sh" .
cp "${FINDER_APP_DIR}/finder-test.sh" .
cp "${FINDER_APP_DIR}/autorun-qemu.sh" .

mkdir -p conf
cp "${FINDER_APP_DIR}/../conf/username.txt" conf/
cp "${FINDER_APP_DIR}/../conf/assignment.txt" conf/

# Fix finder-test.sh path
sed -i 's|../conf/assignment.txt|conf/assignment.txt|' finder-test.sh

chmod +x finder.sh finder-test.sh autorun-qemu.sh

#############################
# Ownership
#############################
cd "${OUTDIR}/rootfs"
sudo chown -R root:root .

#############################
# Create initramfs
#############################
find . | cpio -H newc -ov --owner root:root | gzip > "${OUTDIR}/initramfs.cpio.gz"

echo "----------------------------------------"
echo "Build complete!"
echo "Kernel: ${OUTDIR}/Image"
echo "Initramfs: ${OUTDIR}/initramfs.cpio.gz"
echo "----------------------------------------"

