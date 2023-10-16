#!/bin/bash
# CHANZ-KERNEL-BUILD menu

# Variables
menu_version="v2.4.2"
DIR=`readlink -f .`
OUT_DIR=$DIR/out
PARENT_DIR=`readlink -f ${DIR}/..`

DTB_DIR=$(pwd)/out/arch/arm64/boot/dts
mkdir ${DTB_DIR}/exynos

export PLATFORM_VERSION=11

export SEC_BUILD_CONF_VENDOR_BUILD_OS=13

BUILD_CROSS_COMPILE=/home/chanz22/Vídeos/aarch64-zyc-linux-gnu-14/bin/aarch64-zyc-linux-gnu-
KERNEL_LLVM_BIN=/home/chanz22/Documentos/toolchians/clang-r377782d/bin/clang
CLANG_TRIPLE=/home/chanz22/Vídeos/aarch64-zyc-linux-gnu-14/bin/aarch64-zyc-linux-gnu-
ZIPV=v1.1

# LOG FILE NAME
LOG_FILE=compilation-Puppy.log

# Color
ON_BLUE=`echo -e "\033[44m"`	# On Blue
BRED=`echo -e "\033[1;31m"`	# Bold Red
BBLUE=`echo -e "\033[1;34m"`	# Bold Blue
BGREEN=`echo -e "\033[1;32m"`	# Bold Green
UNDER_LINE=`echo -e "\e[4m"`	# Text Under Line
STD=`echo -e "\033[0m"`		# Text Clear
 
# Functions
pause(){
  read -p "${BRED}$2${STD}Press ${BBLUE}[Enter]${STD} key to $1..." fackEnterKey
}

variant(){
  findconfig=""
  findconfig=($(ls arch/arm64/configs/chanz_* 2>/dev/null))
  declare -i i=1
  shift 2
  echo ""
  echo "${ON_BLUE}Variant Selection:${STD}"
  for e in "${findconfig[@]}"; do
    echo " $i. $(basename $e | cut -d'_' -f2)"
    i=i+1
  done
  local choice
  read -p "Enter choice [ 1 - $((i-1)) ] " choice
  i="$choice"
  if [[ $i -gt 0 && $i -le ${#findconfig[@]} ]]; then
    export v="${findconfig[$i-1]}"
    export VARIANT=$(basename $v | cut -d'_' -f2)
    echo ${VARIANT} selected
    pause 'continue'
  else
    pause 'return to Main menu' 'Error E1: Invalid option, '
    . $DIR/build_menu
  fi
}

clean(){
  echo "${BBLUE}***** Cleaning in Progress... *****${STD}"
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE  clean 
  make $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE  mrproper
  [ -d "$OUT_DIR" ] && rm -rf $OUT_DIR
  echo "${BGREEN}***** Cleaning Process Done... *****${STD}"
  pause 'continue'
 }

build_kernel(){
  variant
  echo "${ON_BLUE}***** Compiling kernel just wait... *****${STD}"
  [ ! -d "$OUT_DIR" ] && mkdir $OUT_DIR
  make -j$(nproc) -C $(pwd) O=$(pwd)/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE chanz_${VARIANT}_defconfig
  
  DATE_START=$(date +"%s")
  
  make O=out ARCH=arm64 \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE CC=$KERNEL_LLVM_BIN \
	CLANG_TRIPLE=$CLANG_TRIPLE -j$(nproc) 2>&1 |tee ../$LOG_FILE

  [ -e $OUT_DIR/arch/arm64/boot/Image.gz ] && cp $OUT_DIR/arch/arm64/boot/Image.gz $OUT_DIR/Image.gz
  if [ -e $OUT_DIR/arch/arm64/boot/Image.gz-dtb ]; then
    cp $OUT_DIR/arch/arm64/boot/Image.gz-dtb $OUT_DIR/Image.gz-dtb
    
    DATE_END=$(date +"%s")
    DIFF=$(($DATE_END - $DATE_START))

echo "Time wasted: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."

    echo "${BGREEN}***** Ready to Roar! *****${STD}"
    pause 'continue'
  else
    pause 'return to Main menu' 'Kernel STUCK in BUILD! E2: check if theres an error, '
  fi
}

anykernel3(){

$(pwd)/tools/mkdtimg cfg_create $(pwd)/out/dtb.img dt.configs/exynos9830.cfg -d ${DTB_DIR}/exynos

IMAGE="out/arch/arm64/boot/Image"
if [[ -f "$IMAGE" ]]; then
	rm AnyKernel3/zImage > /dev/null 2>&1
	rm AnyKernel3/dtb > /dev/null 2>&1
	rm AnyKernel3/*.zip > /dev/null 2>&1
	mv out/dtb.img AnyKernel3/dtb
	mv $IMAGE AnyKernel3/zImage
	cd AnyKernel3
	zip -r9 PuppyKernel-$ZIPV-N981B.zip .
fi

    pause 'continue'
  else
    pause 'return to Main menu' 'Build kernel first, '
  fi
}

dependencies(){
echo "auto installing necessary dependencies please wait."

sudo apt-get update && sudo apt-get upgrade && sudo apt-get install git ccache automake lzop bison flex gperf build-essential zip curl zlib1g-dev libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng bc gcc-aarch64-linux-gnu clang -y

}

# Run once
toolchain

# Show menu
show_menus(){
  clear
  echo "${BRED}Chanz22-SDM845-KERNEL-BUILD menu $menu_version${STD}"
  echo " 1. ${UNDER_LINE}B${STD}uild kernel"
  echo " 2. ${UNDER_LINE}C${STD}lean"
  echo " 3. Make ${UNDER_LINE}f${STD}lashable zip"
  echo " 4. install necessary dependencies"
  echo " 5. E${UNDER_LINE}x${STD}it"
}

# Read input
read_options(){
  local choice
  read -p "Enter choice [ 1 - 5 ] " choice
  case $choice in
    1|b|B) build_kernel ;;
    2|c|C) clean ;;
    3|f|F) anykernel3 ;;
    4|d|D) dependencies ;;
    5|x|X) exit 0 ;;
    *) pause 'return to Main menu' 'E1: Invalid option, '
  esac
}

# Trap CTRL+C, CTRL+Z and quit singles
trap '' SIGINT SIGQUIT SIGTSTP
 
# Step # Main logic - infinite loop
while true
do
  show_menus
  read_options
done
