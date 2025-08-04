#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
CC=gcc

if [ $# -lt 1 ]; then
    echo "Using default directory ${OUTDIR} for output"
else
    OUTDIR=$1
    echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}
if [ -d "${OUTDIR}" ]; then
    echo "${OUTDIR} created"
else
    exit 1
fi

cd "${OUTDIR}"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
    echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
    git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
    make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} Image
    make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
fi

echo "Adding the Image in outdir"
cp -u ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image "${OUTDIR}/"

echo "Checking already existing staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm -rf ${OUTDIR}/rootfs
fi

echo "Creating the staging directory for the root filesystem"
mkdir -p ${OUTDIR}/rootfs
if [ -d "${OUTDIR}/rootfs" ]; then
    echo "${OUTDIR}/rootfs created"
else
    exit 1
fi

cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr/bin usr/lib usr/sbin var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]; then
    git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
else
    cd busybox
fi

make distclean
make defconfig
make -j"$(nproc)" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a busybox | grep "Shared library"

SYSROOT=$("${CROSS_COMPILE}${CC}" using -print-sysroot)
cp -a "${SYSROOT}/lib/ld-linux-aarch64.so.1" "${OUTDIR}/rootfs/lib/"
for lib in libc.so.6 libm.so.6 libresolv.so.2; do
    cp -a "${SYSROOT}/lib64/${lib}" "${OUTDIR}/rootfs/lib64/"
done

sudo mknod -m 666 "${OUTDIR}/rootfs/dev/null" c 1 3
sudo mknod -m 600 "${OUTDIR}/rootfs/dev/console" c 5 1

echo "Building writer"
WRITER_SRC="${FINDER_APP_DIR}/writer.c"
WRITER_BIN="${OUTDIR}/rootfs/home/writer"
${CROSS_COMPILE}gcc -Wall -Werror -static -o "${WRITER_BIN}" "${WRITER_SRC}"

cp "${FINDER_APP_DIR}/finder.sh" "$OUTDIR/rootfs/home"
cp "${FINDER_APP_DIR}/finder-test.sh" "$OUTDIR/rootfs/home"
cp "${FINDER_APP_DIR}/autorun-qemu.sh" "${OUTDIR}/rootfs/home/"
cp -Lr "${FINDER_APP_DIR}/conf" "$OUTDIR/rootfs/home"
sed -i 's#../conf#conf#' "${OUTDIR}/rootfs/home/finder-test.sh"

sudo chown -R root:root "${OUTDIR}/rootfs"

echo "Creating initramfs.cpio.gz"
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root >${OUTDIR}/initramfs.cpio
cd "$OUTDIR"
gzip -f initramfs.cpio
