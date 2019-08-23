#!/bin/bash
#
#

#SPLUNK_UF_VERSION="7.3.1"
#SPLUNK_UF_HASH="bd63e13aa157"

SPLUNK_UF_VERSION="$1"
SPLUNK_UF_HASH="$2"
WGET_CMD="`command -v wget 2>/dev/null`"
CURL_CMD="`command -v curl 2>/dev/null`"

rm -rf ./dist

if [ ! -d dist ]; then
	mkdir -p dist || exit 1
fi

FILENAME="splunkforwarder-${SPLUNK_UF_VERSION}-${SPLUNK_UF_HASH}-Linux-x86_64.tgz"
UF_URL="http://download.splunk.com/products/universalforwarder/releases/${SPLUNK_UF_VERSION}/linux/${FILENAME}"

MD5_URL="${UF_URL}.md5"

#http://download.splunk.com/products/universalforwarder/releases/7.3.1/linux/splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz.md5

for cmd in skipme $WGET_CMD $CURL_CMD
do
	case "$cmd" in skipme*) continue;; esac
	case "$cmd" in
	*wget) GET_UF="$cmd ${UF_URL} -O dist/${FILENAME} "; GET_MD5="$cmd ${MD5_URL} -O dist/${FILENAME}.md5";;
	*curl) GET_UF="$cmd ${UF_URL} -o dist/${FILENAME} "; GET_MD5="$cmd ${MD5_URL} -o dist/${FILENAME}.md5";;
	esac
done

$GET_UF
$GET_MD5
set -x
(
	cd dist
	ln -sf ${FILENAME} splunkforwarder.tgz
	ln -sf ${FILENAME}.md5 splunkforwarder.tgz.md5
)
