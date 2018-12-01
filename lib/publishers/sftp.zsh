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

function publish_sftp() {
	local publish_user publish_host publish_path tmpfile
	local config=$1 i=$2 j=$3 dnsstr=$4 ver=$5
	tmpfile=$(mktemp)


	publish_user=$(jq -r ".builds[${i}].publish[$j].user" ${config})
	publish_host=$(jq -r ".builds[${i}].publish[$j].host" ${config})
	publish_path=$(jq -r ".builds[${i}].publish[$j].directory" ${config})

	echo ${dnsstr} > ${tmpfile}
	chmod 744 ${tmpfile}


	sudo -u ${publish_user} scp /builds/updater/output/update-${ver}.tar \
	    ${publish_host}:${publish_path}/
	sudo -u ${publish_user} scp ${tmpfile} \
	    ${publish_host}:${publish_path}/update-latest.txt


}
