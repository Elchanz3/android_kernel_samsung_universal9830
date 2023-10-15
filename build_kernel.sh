#!/bin/bash

make mrproper

mkdir out

DTB_DIR=$(pwd)/out/arch/arm64/boot/dts
mkdir ${DTB_DIR}/exynos

export PLATFORM_VERSION=11

export SEC_BUILD_CONF_VENDOR_BUILD_OS=13

BUILD_CROSS_COMPILE=/home/chanz22/Vídeos/aarch64-zyc-linux-gnu-14/bin/aarch64-zyc-linux-gnu-
KERNEL_LLVM_BIN=/home/chanz22/Vídeos/Clang-18.0.0-20231014/bin/clang
CLANG_TRIPLE=/home/chanz22/Vídeos/aarch64-zyc-linux-gnu-14/bin/aarch64-zyc-linux-gnu-
KERNEL_MAKE_ENV="CONFIG_BUILD_ARM64_DT_OVERLAY=y"

make O=out ARCH=arm64 CC=$KERNEL_LLVM_BIN exynos9830-c1sxxx_defconfig
make O=out ARCH=arm64 \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN \
	CLANG_TRIPLE=$CLANG_TRIPLE -j12
	
$(pwd)/tools/mkdtimg cfg_create $(pwd)/out/dtb.img dt.configs/exynos9830.cfg -d ${DTB_DIR}/exynos

IMAGE="out/arch/arm64/boot/Image"
if [[ -f "$IMAGE" ]]; then
	rm AnyKernel3/zImage > /dev/null 2>&1
	rm AnyKernel3/dtb > /dev/null 2>&1
	rm AnyKernel3/*.zip > /dev/null 2>&1
	mv out/dtb.img AnyKernel3/dtb
	mv $IMAGE AnyKernel3/zImage
	cd AnyKernel3
	zip -r9 Kernel-N981B2.zip .
fi
