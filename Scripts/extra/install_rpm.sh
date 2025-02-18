#!/usr/bin/env bash
#|---/ /+------------------------------+---/ /|#
#|--/ /-| Script to install RPM pkgs   |--/ /-|#
#|-/ /--| Prasanth Rangan              |-/ /--|#
#|/ /---+------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

flg_DryRun=${flg_DryRun:-0}
export log_section="package"

listPkg="${1:-"${scrDir}/pkg_fedora.lst"}"
rpmPkg=()
ofs=$IFS
IFS='|'

while read -r pkg deps; do
    pkg="${pkg// /}"
    if [ -z "${pkg}" ]; then
        continue
    fi

    if [ -n "${deps}" ]; then
        deps="${deps%"${deps##*[![:space:]]}"}"
        while read -r cdep; do
            pass=$(cut -d '#' -f 1 "${listPkg}" | awk -F '|' -v chk="${cdep}" '{if($1 == chk) {print 1;exit}}')
            if [ -z "${pass}" ]; then
                if pkg_installed "${cdep}"; then
                    pass=1
                else
                    break
                fi
            fi
        done < <(xargs -n1 <<<"${deps}")

        if [[ ${pass} -ne 1 ]]; then
            print_log -warn "missing" "dependency [ ${deps} ] for ${pkg}..."
            continue
        fi
    fi

    if pkg_installed "${pkg}"; then
        print_log -y "[skip] " "${pkg}"
    else
        print_log -b "[queue] " -g "rpm" -b "::" "${pkg}"
        rpmPkg+=("${pkg}")
    fi
done < <(cut -d '#' -f 1 "${listPkg}")

IFS=${ofs}

if [ "${flg_DryRun}" -ne 1 ]; then
    if [[ ${#rpmPkg[@]} -gt 0 ]]; then
        print_log -b "[install] " "rpm packages..."
        sudo dnf install -y "${rpmPkg[@]}"
    fi
fi
