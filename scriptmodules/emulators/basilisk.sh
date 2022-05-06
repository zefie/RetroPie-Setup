#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="basilisk"
rp_module_desc="Macintosh emulator"
rp_module_help="ROM Extensions: .img .rom\n\nCopy your Macintosh roms to $biosdir/classicmac.rom and classic_disk.img to $romdir/macintosh"
rp_module_licence="GPL2 https://raw.githubusercontent.com/kanjitalk755/macemu/master/BasiliskII/COPYING"
rp_module_repo="git https://github.com/kanjitalk755/macemu.git master"
rp_module_section="opt"
rp_module_flags="sdl2 !mali"

function depends_basilisk() {
    local depends=(libsdl2-dev autoconf automake oss-compat)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
    getDepends "${depends[@]}"
}

function sources_basilisk() {
    gitPullOrClone
}

function build_basilisk() {
    cd BasiliskII/src/Unix
    local params=(--enable-sdl-video --enable-sdl-audio --disable-vosf --without-mon --without-esd --with-bincue --enable-standalone-gui)
    ! isPlatform "x86" && params+=(--disable-jit-compiler)
    ! isPlatform "x11" && params+=(--without-x --without-gtk)
    isPlatform "aarch64" && params+=(--build=arm)
    ./autogen.sh --prefix="$md_inst" "${params[@]}"
    make clean
    make
    md_ret_require="$md_build/BasiliskII/src/Unix/BasiliskII"
}

function install_basilisk() {
    cd "BasiliskII/src/Unix"
    make install
}

function configure_basilisk() {
    local params=()
    isPlatform "kms" && params+=("--screen win/%XRES%/%YRES%")

    mkRomDir "macintosh"
    touch "$romdir/macintosh/Start.txt"

    mkUserDir "$md_conf_root/macintosh"

    # set prefs file to RetroPie path
    if [ -e "/home/$user/.basilisk_ii_prefs" ]; then
	rm "/home/$user/.basilisk_ii_prefs"
    fi
    ln -s "$md_conf_root/macintosh/basilisk.cfg" "/home/$user/.basilisk_ii_prefs"

    if [ ! -f "$md_conf_root/macintosh/basilisk.cfg" ]; then
	touch "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # update BIOS ROM path
    if [ $(grep "^rom " "$md_conf_root/macintosh/basilisk.cfg" -c) -gt 0 ]; then
        sed -i "s|^rom.*|rom $biosdir/classicmac.rom|" "$md_conf_root/macintosh/basilisk.cfg"
    else
        echo "rom $biosdir/classicmac.rom" > "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default RAM to 64MB if not already set
    if [ $(grep "^ramsize " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "ramsize 16777216" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default disk to classic_disk.img if not set
    if [ $(grep "^disk " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "disk $romdir/macintosh/classoc_disk.img" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default modelid to 14 if not already set
    if [ $(grep "^modelid " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "modelid 14" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default cpu to 4 if not already set
    if [ $(grep "^cpu " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "cpu 4" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default fpu to true if not set
    if [ $(grep "^fpu " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "fpu true" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default screen to win/640/480 if not set
    if [ $(grep "^screen " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "screen win/640/480" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # default frameskip to 1 if not set
    if [ $(grep "^frameskip " "$md_conf_root/macintosh/basilisk.cfg" -c) -eq 0 ]; then
        echo "frameskip 1" >> "$md_conf_root/macintosh/basilisk.cfg"
    fi

    # Set user to own config
    chown "$user:$user" "$md_conf_root/macintosh/basilisk.cfg"


    addEmulator 1 "$md_id" "macintosh" "$md_inst/bin/BasiliskII --rom $biosdir/classicmac.rom --disk $romdir/macintosh/classic_disk.img --extfs $romdir/macintosh --config $md_conf_root/macintosh/basiliskii.cfg ${params[*]}"
    addSystem "macintosh"
}
