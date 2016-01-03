#!/usr/local/bin/zsh

function usage() {
	cat <<EOF >&2
USAGE: ${1} -c config
EOF

	exit 1
}

function get_topdir() {
	local self
	self=${1}
	echo $(realpath $(dirname ${self}))
}

function main() {
	local self
	local config

	self=${1}

	TOPDIR=$(get_topdir ${self})
	shift
	cd ${TOPDIR}

	source ./lib/builder.zsh

	while getopts 'hc:' opt; do
		case "${opt}" in
			c)
				config="${OPTARG}"
				;;
			*)
				usage ${self}
				;;
		esac
	done

	if [ -z "${config}" ]; then
		usage ${self}
	fi

	if [ ! "$(id -u)" = "0" ]; then
		echo "[-] This tool must be run as root." >&2
		exit 1
	fi

	do_build ${config}
}

main ${0} $*
