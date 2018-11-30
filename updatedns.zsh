#!/usr/local/bin/zsh
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

apikey=$(cat ${1})
name=${2}
recordname=${3}
buildver=${4}
recordid=""
zoneid=""
apiurl="https://api.cloudflare.com/client/v4"
tmpfile=$(mktemp)

function get_zoneid() {
	curl -s -X GET "${apiurl}/zones?name=${name}" \
		-H "X-Auth-Email: shawn.webb@hardenedbsd.org" \
		-H "X-Auth-Key: ${apikey}" \
		-H "Content-Type: application/json" \
		-o ${tmpfile}

	zoneid=$(jq -r '.result[0].id' ${tmpfile})
}

function get_recordid() {
	curl -s -X GET "${apiurl}/zones/${zoneid}/dns_records?name=${recordname}" \
		-H "X-Auth-Email: shawn.webb@hardenedbsd.org" \
		-H "X-Auth-Key: ${apikey}" \
		-H "Content-Type: application/json" \
		-o ${tmpfile}

	recordid=$(jq -r '.result[0].id' ${tmpfile})
}

function generate_new_record_data() {
cat<<EOF > ${tmpfile}
{
	"id": "${recordid}",
	"type": "TXT",
	"name": "${recordname}",
	"content": "${buildver}",
	"proxiable": false,
	"proxied": false,
	"ttl": 3600,
	"locked": false,
	"zoneid": "${zoneid}",
	"zone_name": "${name}",
	"data": {}
}
EOF
}

function update_record() {
	echo "[*] Updating DNS to reflect version: ${buildver}" >&2

	generate_new_record_data

	curl -s -X PUT "${apiurl}/zones/${zoneid}/dns_records/${recordid}" \
		-H "X-Auth-Email: shawn.webb@hardenedbsd.org" \
		-H "X-Auth-Key: ${apikey}" \
		-H "Content-Type: application/json" \
		--data "@${tmpfile}" \
		-o ${tmpfile}

}

get_zoneid
get_recordid
update_record
