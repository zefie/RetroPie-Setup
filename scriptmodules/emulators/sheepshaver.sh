#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="sheepshaver"
rp_module_desc="PowerPC Macintosh emulator"
rp_module_help="ROM Extensions: .img .rom\n\nCopy your Macintosh rom to $biosdir/powermac.rom and your disk image to $romdir/macintosh/powermac_disk.img"
rp_module_licence="GPL2 https://raw.githubusercontent.com/kanjitalk/macemu/master/basiliskII/COPYING"
rp_module_repo="git https://github.com/kanjitalk755/macemu.git master"
rp_module_section="exp"
rp_module_flags="sdl2 !mali"

function depends_sheepshaver() {
    local depends=(libvdeplug-dev libsdl2-dev autoconf automake oss-compat dkms)
    isPlatform "x11" && depends+=(libgtk2.0-dev)
    getDepends "${depends[@]}"
}

function sources_sheepshaver() {
    gitPullOrClone
}

pkgver() {
  cd "$md_build"
  echo "r$(git rev-list --count HEAD).g$(git rev-parse --short HEAD)"
}

function build_sheepnet() {
    # sheep_net kernel driver
    srcdir="/usr/src/sheepnet-$(pkgver)"
    if [ -d "$srcdir" ]; then
        rm -rf "$srcdir";
    fi
    cp -r "$md_build/BasiliskII/src/Unix/Linux/NetDriver" "$srcdir"
    cat > "$srcdir/dkms.conf" <<-EOF
	PACKAGE_NAME="sheepnet"
	PACKAGE_VERSION="$(pkgver)"
	AUTOINSTALL=yes
	BUILT_MODULE_NAME="sheep_net"
	DEST_MODULE_LOCATION="/kernel/net"
EOF

    echo "ACTION==\"add\", KERNEL==\"sheep_net\", MODE=\"0660\", OWNER=\"$user\", GROUP=\"$user\"" > /etc/udev/rules.d/sheep_net-permissions.rules
    dkms install "sheepnet/$(pkgver)"
    md_ret_require="/lib/modules/$(uname -r)/updates/dkms/sheep_net.ko"
}


function build_sheepshaver() {
    cd SheepShaver/src/Unix

    export CPPFLAGS="$CPPFLAGS -DSTDC_HEADERS=1"
    export CXXFLAGS="$CXXFLAGS -DSTDC_HEADERS=1"
    local params=(--enable-sdl-video --enable-sdl-audio --enable-addressing=real --without-esd --with-bincue --enable-tuntap --with-vdeplug)
    params+=(--enable-standalone-gui)
    ! isPlatform "x86" && params+=(--disable-jit-compiler)
    ! isPlatform "x11" && params+=(--without-x --without-gtk)
    isPlatform "aarch64" && params+=(--build=arm)
    ./autogen.sh --prefix="$md_inst" "${params[@]}"

    # fix GUI with bincue
    sed -i 's|GUI_SRCS = ../prefs.cpp|GUI_SRCS = bincue.cpp ../prefs.cpp|' "$md_build/SheepShaver/src/Unix/Makefile"


    make clean all -j1
    strip SheepShaver
    md_ret_require="$md_build/SheepShaver/src/Unix/SheepShaver"

    build_sheepnet
}

function install_sheepshaver() {
    cd "$md_build/SheepShaver/src/Unix"
    make install

    # use insecure setuid root bit to get around Low Memory permission
    chown root:root "$md_inst/bin/SheepShaver"
    chmod 4755 "$md_inst/bin/SheepShaver"

    # load network module
    modprobe sheep_net
}

function configure_sheepshaver() {
    local params=()
    isPlatform "kms" && params+=("--screen win/%XRES%/%YRES%")

    mkRomDir "macintosh"
    touch "$romdir/macintosh/Start.txt"

    mkUserDir "$md_conf_root/macintosh"

    # set prefs file to RetroPie path
    if [ -e "/home/$user/.sheepshaver_prefs" ]; then
	rm "/home/$user/.sheepshaver_prefs"
    fi
    ln -s "$md_conf_root/macintosh/sheepshaver.cfg" "/home/$user/.sheepshaver_prefs"

    if [ ! -f "$md_conf_root/macintosh/sheepshaver.cfg" ]; then
	touch "$md_conf_root/macintosh/sheepshaver.cfg"
    fi

    # update BIOS ROM path
    if [ $(grep "^rom " "$md_conf_root/macintosh/sheepshaver.cfg" -c) -gt 0 ]; then
        sed -i "s|^rom.*|rom $biosdir/powermac.rom|" "$md_conf_root/macintosh/sheepshaver.cfg"
    else
        echo "rom $biosdir/powermac.rom" > "$md_conf_root/macintosh/sheepshaver.cfg"
    fi

    # default RAM to 64MB if not set
    if [ $(grep "^ramsize " "$md_conf_root/macintosh/sheepshaver.cfg" -c) -eq 0 ]; then
        echo "ramsize 67108864" >> "$md_conf_root/macintosh/sheepshaver.cfg"
    fi

    # default disk to powermac_disk.img if not set
    if [ $(grep "^disk " "$md_conf_root/macintosh/sheepshaver.cfg" -c) -eq 0 ]; then
        echo "disk $romdir/macintosh/powermac_disk.img" >> "$md_conf_root/macintosh/sheepshaver.cfg"
    fi

    # default screen to win/1024/768 if not set
    if [ $(grep "^screen " "$md_conf_root/macintosh/sheepshaver.cfg" -c) -eq 0 ]; then
        echo "screen win/1024/768" >> "$md_conf_root/macintosh/sheepshaver.cfg"
    fi

    # default frameskip to 1 if not set
    if [ $(grep "^frameskip " "$md_conf_root/macintosh/sheepshaver.cfg" -c) -eq 0 ]; then
        echo "frameskip 1" >> "$md_conf_root/macintosh/sheepshaver.cfg"
    fi

    # Set user to own config
    chown "$user:$user" "$md_conf_root/macintosh/sheepshaver.cfg"

    addEmulator 1 "$md_id" "macintosh" "$md_inst/bin/SheepShaver --rom $biosdir/powermac.rom --disk $romdir/macintosh/powermac_disk.img --extfs $romdir/macintosh --config $md_conf_root/macintosh/sheepshaver.cfg ${params[*]}"
    addSystem "macintosh"
}
