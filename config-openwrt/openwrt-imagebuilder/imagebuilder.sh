#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021- https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021- https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Download from: https://downloads.openwrt.org/releases
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./config-openwrt/openwrt-imagebuilder/imagebuilder.sh <branch>
#          ./config-openwrt/openwrt-imagebuilder/imagebuilder.sh 21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_config           : Add custom config
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="openwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config-openwrt/openwrt-imagebuilder/files"
custom_config_file="${make_path}/config-openwrt/openwrt-imagebuilder/config"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Downloading imagebuilder files
    # Download example: https://downloads.openwrt.org/releases/21.02.3/targets/armvirt/64/openwrt-imagebuilder-21.02.3-armvirt-64.Linux-x86_64.tar.xz
    download_file="https://downloads.openwrt.org/releases/${rebuild_branch}/targets/armvirt/64/openwrt-imagebuilder-${rebuild_branch}-armvirt-64.Linux-x86_64.tar.xz"
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf openwrt-imagebuilder-* && sync && rm -f openwrt-imagebuilder-*.tar.xz
    mv -f openwrt-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adjusting .config file settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom packages..."

    # Create a [ packages ] directory
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-amlogic
    amlogic_api="https://api.github.com/repos/ophub/luci-app-amlogic/releases"
    #
    amlogic_file="luci-app-amlogic"
    amlogic_file_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_name}.*.ipk" | head -n 1)"
    wget -q ${amlogic_file_down} -O packages/${amlogic_file_down##*/}
    [[ "${?}" -eq "0" ]] && echo -e "${INFO} The [ ${amlogic_file} ] is downloaded successfully."
    #
    # Download other luci-app-xxx
    # ......

    sync && sleep 3
    echo -e "${INFO} [ packages ] directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom packages, lib, theme, app and i18n, etc.
custom_config() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom config..."

    config_list=""
    if [[ -s "${custom_config_file}" ]]; then
        config_list="$(cat ${custom_config_file} 2>/dev/null | grep -E "^CONFIG_PACKAGE_.*=y" | sed -e 's/CONFIG_PACKAGE_//g' -e 's/=y//g' -e 's/[ ][ ]*//g' | tr '\n' ' ')"
        echo -e "${INFO} Custom config list: \n$(echo "${config_list}" | tr ' ' '\n')"
    else
        echo -e "${INFO} No custom config was added."
    fi
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adding custom files..."

    if [[ -d "${custom_files_path}" ]]; then
        # Copy custom files
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} [ files ] directory status: $(ls files -l 2>/dev/null)"
    else
        echo -e "${INFO} No customized files were added."
    fi
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start building OpenWrt with Image Builder..."

    # Selecting default packages, lib, theme, app and i18n, etc.
    # sorting by https://build.moz.one
    my_packages="\
		btrfs-progs base-files busybox ca-bundle dropbear e2fsprogs firewall fstools ip6tables iptables kmod-ipt-offload  \
		libc libgcc libustream-wolfssl logd mkf2fs netifd odhcp6c odhcpd-ipv6only opkg partx-utils  \
		procd uboot-envtools uci uclient-fetch urandom-seed urngd  \
        zram-swap tar bash curl luci-compat bind-tools coreutils-nohup perlbase-file perlbase-time -dnsmasq dnsmasq-full  \
        -ppp -ppp-mod-pppoe -kmod-ppp  \
        ath9k-htc-firmware hostapd hostapd-utils kmod-ath kmod-ath9k kmod-ath9k-common \
        kmod-ath9k-htc kmod-cfg80211 kmod-crypto-acompress kmod-crypto-crc32c kmod-crypto-hash \
        kmod-fs-btrfs kmod-mac80211 wireless-tools wpa-cli wpa-supplicant \
        \
        luci-app-amlogic \
        \
        ${config_list} \
        "

    # Rebuild firmware
    make image PROFILE="Default" PACKAGES="${my_packages}" FILES="files"

    sync && sleep 3
    echo -e "${INFO} [ openwrt/bin/targets/armvirt/64 ] directory status: $(ls bin/targets/*/* -l 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x ${0} ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ ${0} 21.02.3 ]"
rebuild_branch="${1}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild branch: [ ${rebuild_branch} ]"
echo -e "${INFO} Server space usage before starting to compile: \n$(df -hT ${make_path}) \n"
#
# Perform related operations
download_imagebuilder
adjust_settings
custom_packages
custom_config
custom_files
rebuild_firmware
#
# Show server end information
echo -e "Server space usage after compilation: \n$(df -hT ${make_path}) \n"
# All process completed
wait
