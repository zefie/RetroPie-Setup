#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-pcsx2"
rp_module_desc="PlayStation 2 emu - PCSX2 port for libretro"
rp_module_help="ROM Extensions: .iso .bin\n\nCopy your PlayStation 2 roms to $romdir/ps2"
rp_module_licence="GPL2 https://raw.githubusercontent.com/RetroPie/ppsspp/master/LICENSE.TXT"
rp_module_repo="git https://github.com/libretro/pcsx2.git main"
rp_module_section="exp"
rp_module_flags="!all x86"

function depends_lr-pcsx2() {
    getDepends cmake libglvnd-dev xxd libaio-dev libxml2-dev liblzma-dev libyaml-cpp-dev zlib1g-dev libpng-dev \
    libopengl-dev libpcap-dev jq
}

function sources_lr-pcsx2() {
    echo -n "*** Checking libretro to find latest successfully built commit... "
    local res=$(curl --silent "https://git.libretro.com/libretro/pcsx2/-/pipelines.json?scope=main&page=1" | \
       jq -r '.pipelines[] | select(.details.status.text == "passed").commit.id' | head -n1);

    if [ -z "${res}" ]; then
       echo " unknown, using HEAD"
    else
       echo " found ${res}"
    fi

    gitPullOrClone "${md_build}" "$(rp_resolveRepoParam "$md_repo_url")" "$(rp_resolveRepoParam "$md_repo_branch")" "${res}"
}

function build_lr-pcsx2() {
    # remove ccache
    sed -i '/ccache/d' "$md_build/CMakeLists.txt"

    cmake -B build \
      -DLIBRETRO=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_LINK_WHAT_YOU_USE=TRUE \
      -Wno-dev

    cmake --build build
    md_ret_require="$md_build/build/pcsx2/pcsx2_libretro.so"
}

function install_lr-pcsx2() {
    md_ret_files=(
        'build/pcsx2/pcsx2_libretro.so'
    )
}

function configure_lr-pcsx2() {
    mkRomDir "ps2"
    ensureSystemretroconfig "ps2"

    if [[ "$md_mode" == "install" ]]; then
        mkUserDir "$biosdir/pcsx2"
        mkUserDir "$biosdir/pcsx2/bios"
    fi

    addEmulator 1 "$md_id" "ps2" "$md_inst/pcsx2_libretro.so"
    addSystem "ps2"
}
