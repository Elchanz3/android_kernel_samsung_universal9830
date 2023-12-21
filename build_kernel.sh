#!/bin/bash

# Function to display error messages and exit
function error_exit {
    echo "Error: $1" >&2
    exit 1
}

clear

# Variables
DIR=$(readlink -f .)
PARENT_DIR=$(readlink -f "${DIR}/..")

DEFCONFIG_NAME=chanz_c1s_defconfig
CHIPSET_NAME=universal9830
VARIANT=c1s
ARCH=arm64
VERSION=PuppyKernel_${VARIANT}_v1.2
LOG_FILE=compilation.log
CCACHE=ccache

export PLATFORM_VERSION=13
export ANDROID_MAJOR_VERSION=t
export SEC_BUILD_CONF_VENDOR_BUILD_OS=13

# Check for the existence of output directories
OUT_DIR="out"
DTB_DIR="$OUT_DIR/arch/arm64/boot/dts/exynos"
mkdir -p "$DTB_DIR" || error_exit "Failed to create directory $DTB_DIR"

# Toolchains
BUILD_CROSS_COMPILE="/home/chanz22/tc/aarch64-zyc-linux-gnu-14/bin/aarch64-zyc-linux-gnu-"
KERNEL_LLVM_BIN="/home/chanz22/tc/SDClang-14/bin/clang"
CLANG_TRIPLE="$BUILD_CROSS_COMPILE"

# Cleaning (if -clean flag is provided)
if [[ "$1" == "-clean" ]]; then
    echo "Cleaning before building..."
    make O="$OUT_DIR" ARCH=arm64 clean || error_exit "Error while running 'make clean'"
    make O="$OUT_DIR" ARCH=arm64 mrproper || error_exit "Error while running 'make mrproper'"
fi

# Kernel compilation
DATE_START=$(date +"%s")

make O="$OUT_DIR" ARCH=arm64 CC="$KERNEL_LLVM_BIN" "$DEFCONFIG_NAME" || error_exit "Error configuring the kernel"
make O="$OUT_DIR" ARCH=arm64 CROSS_COMPILE="$BUILD_CROSS_COMPILE" CC="$KERNEL_LLVM_BIN" CLANG_TRIPLE="$CLANG_TRIPLE" -j"$(nproc)" 2>&1 | tee "../$LOG_FILE" || error_exit "Error during kernel compilation"

# Verification and packaging
IMAGE="$OUT_DIR/arch/arm64/boot/Image"

if [[ -f "$IMAGE" ]]; then
    KERNELZIP="$VERSION.zip"
    rm "AnyKernel3/zImage" "AnyKernel3/dtb" "AnyKernel3/"*.zip &>/dev/null

    $(pwd)/tools/mkdtimg cfg_create $(pwd)/"$OUT_DIR/dtb.img" dt.configs/exynos9830.cfg -d "$DTB_DIR"
    mv "$OUT_DIR/dtb.img" "AnyKernel3/dtb"
    mv "$IMAGE" "AnyKernel3/zImage"

    # Create the AnyKernel package
    (cd "AnyKernel3" && zip -r9 "$KERNELZIP" .) || error_exit "Error creating the AnyKernel package"

    DATE_END=$(date +"%s")
    DIFF=$(($DATE_END - $DATE_START))

    echo -e "\nCompilation completed successfully. Elapsed time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.\n"
else
    error_exit "Kernel image file not found. Compilation may have failed."
fi

