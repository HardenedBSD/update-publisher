#!/usr/local/bin/zsh

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
