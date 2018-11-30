#-
# Copyright (c) 2018 HardenedBSD
# Author: Shawn Webb <shawn.webb@hardenedbsd.org>
#
# This work originally sponsored by G2, Inc
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

function get_number_builds() {
	local config=${1}

	jq -r '.builds | length' ${config}
}

function sanitize_str() {
	local str

	str="${1}"
	str=${str/\%RUNDIR\%/${TOPDIR}}

	echo ${str}
}

function do_build()
{
	local config nbuilds i enabled tmpfile name output res
	local dnsstr publish_user publish_host publish_path ver
	local dnsentry apikey kernels
	config=${1}
	tmpfile=$(mktemp)

	nbuilds=$(get_number_builds ${config})
	for ((i=0; i<${nbuilds}; i++)); do
		enabled=$(jq -r ".builds[${i}].enabled" ${config})
		if [ "${enabled}" = "false" ]; then
			continue
		fi

		name=$(jq -r ".builds[${i}].name" ${config})

		echo "[*] Building ${name}"

		kernels=$(jq -r ".builds[${i}].kernels" ${config})
		if [ "${kernels}" = "null" ]; then
			kernels="HARDENEDBSD"
		fi

		srcconf=$(jq -r ".builds[${i}].src_conf" ${config})
		if [ "${srcconf}" != "null" ]; then
			srcconf=$(sanitize_str ${srcconf})
            if [ ! -f ${srcconf} ]; then
                echo "[-] SRCCONF ${srcconf} does not exist."
                continue
            fi
		else
			srcconf=""
		fi

		devmode=$(jq -r ".builds[${i}].devmode" ${config})
		if [ "${devmode}" = "null" ]; then
			devmode=""
		fi

        target=$(jq -r ".builds[${i}].target" ${config})
        if [ "${target}" = "null" ]; then
            target=$(uname -m)

        fi

        target_arch=$(jq -r ".builds[${i}].target_arch" ${config})
        if [ "${target_arch}" = "null" ]; then
            target_arch=$(uname -p)
        fi

        needs_cross_utils=$(jq -r ".builds[${i}].needs_cross_utils" ${config})
        if [ "${needs_cross_utils}" = "null" ]; then
            needs_cross_utils="1"
        fi

        scriptfile=$(jq -r ".builds[${i}].scriptfile" ${config})
        if [ "${scriptfile}" = "null" ]; then
            scriptfile=""
        fi

		cat<<EOF > ${tmpfile}
REPO=$(jq -r ".builds[${i}].repo" ${config})
BRANCH=$(jq -r ".builds[${i}].branch" ${config})
DEVMODE="${devmode}"
FULLCLEAN="yes"
KERNELS="${kernels}"
SRCCONFPATH="${srcconf}"
TARGET="${target}"
TARGET_ARCH="${target_arch}"
NEED_CROSS_UTILS=${needs_cross_utils}
SCRIPTFILE="${scriptfile}"
EOF
		output=$(hbsd-update-build -c ${tmpfile})
		res=$(echo ${output} | awk '{print $1;}')
		echo "    [+] res: ${output}"

		if [ ! "${res}" = "OK" ]; then
			echo "    [-] ${name} failed"
			continue
		fi

		dnsstr=$(echo ${output} | awk '{print $2;}')
		ver=$(echo ${dnsstr} | sed 's,|, ,g' | awk '{print $2;}')

		echo ${dnsstr} > ${tmpfile}
		chmod 744 ${tmpfile}

		publish_user=$(jq -r ".builds[${i}].publish.user" ${config})
		publish_host=$(jq -r ".builds[${i}].publish.host" ${config})
		publish_path=$(jq -r ".builds[${i}].publish.directory" ${config})
		dnsentry=$(jq -r ".builds[${i}].dns" ${config})
		apikey=$(jq -r ".apikey" ${config})

		sudo -u ${publish_user} scp /builds/updater/output/update-${ver}.tar \
		    ${publish_host}:${publish_path}/
		sudo -u ${publish_user} scp ${tmpfile} \
		    ${publish_host}:${publish_path}/update-latest.txt

		${TOPDIR}/updatedns.zsh ${apikey} hardenedbsd.org ${dnsentry} ${dnsstr}
	done

	rm -f ${tmpfile}
}
