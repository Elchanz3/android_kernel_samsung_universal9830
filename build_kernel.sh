#!/bin/bash

mkdir out

export PLATFORM_VERSION=11

export SEC_BUILD_CONF_VENDOR_BUILD_OS=13

BUILD_CROSS_COMPILE=/home/chanz22/Documentos/toolchians/gcc-7.4.1/linaro/bin/aarch64-linux-gnu-
KERNEL_LLVM_BIN=/home/chanz22/Documentos/toolchians/clang-r377782d/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="CONFIG_BUILD_ARM64_DT_OVERLAY=y"

make O=out ARCH=arm64 CC=$KERNEL_LLVM_BIN exynos9830-c1sxxx_defconfig
make O=out ARCH=arm64 \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN \
	CLANG_TRIPLE=$CLANG_TRIPLE -j12

IMAGE="out/arch/arm64/boot/Image"
if [[ -f "$IMAGE" ]]; then
	rm AnyKernel3/zImage > /dev/null 2>&1
	rm AnyKernel3/*.zip > /dev/null 2>&1
	cp $IMAGE AnyKernel3/zImage
	cd AnyKernel3
	zip -r9 Kernel-N981B2.zip .
fi
