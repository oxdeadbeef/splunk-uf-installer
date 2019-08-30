#!/bin/bash
#
#

PROGNAME=${0##*/}
BASEDIR=$(cd $(dirname $0)/..; pwd)
SELF="$(cd $(dirname $0); pwd)/$PROGNAME"

usage () {
cat <<EOF
Usage: $PROGNAME [OPTIONS]

  -h, --help            This message
  -x, --debug           Enable script debugging
  -V, --version         Splunkforwarder Version
  -H, --hash            Splunkforwarder Hash
  -d, --target          Target directory 
EOF
        exit 1
}

SPLUNK_UF_FILE=splunkforwarder.tar.gz
DOWNLOADDIR=download
SPLUNK_UF_VERSION=
SPLUNK_UF_HASH=

while [[ $# -gt 0 ]]
do
        case "$1" in
        -x|--debug) set -x; shift;;
        -h|--help) usage;;
        -V|--version) [[ $# -gt 1 ]] || usage; SPLUNK_UF_VERSION="$2"; shift 2;;
        -H|--hash) [[ $# -gt 1 ]] || usage; SPLUNK_UF_HASH="$2"; shift 2;;
	-d|--target) [[ $# -gt 1 ]] || usage; DOWNLOADDIR="$2"; shift 2;;
        *) usage;;
        esac
done

if [ -z "${SPLUNK_UF_VERSION}" ]; then
	echo "ERROR: Splunk Version not specified" >&2
	exit 1
fi

if [ -z "${SPLUNK_UF_HASH}" ]; then
	echo "ERROR: Splunk Hash not specified" >&2
	exit 1
fi

WGET_CMD="`command -v wget 2>/dev/null`"
CURL_CMD="`command -v curl 2>/dev/null`"

if [ ! -d "${DOWNLOADDIR}" ]; then
	mkdir -p "${DOWNLOADDIR}" || exit 1
fi

FILENAME="splunkforwarder-${SPLUNK_UF_VERSION}-${SPLUNK_UF_HASH}-Linux-x86_64.tgz"
UF_URL="http://download.splunk.com/products/universalforwarder/releases/${SPLUNK_UF_VERSION}/linux/${FILENAME}"

MD5_URL="${UF_URL}.md5"

#http://download.splunk.com/products/universalforwarder/releases/7.3.1/linux/splunkforwarder-7.3.1-bd63e13aa157-Linux-x86_64.tgz.md5

for cmd in skipme $WGET_CMD $CURL_CMD
do
	case "$cmd" in skipme*) continue;; esac
	case "$cmd" in
	*wget)  GET_UF="$cmd ${UF_URL} -O ${DOWNLOADDIR}/${FILENAME} "
		GET_MD5="$cmd ${MD5_URL} -O ${DOWNLOADDIR}/${FILENAME}.md5"
		;;
	*curl)  GET_UF="$cmd ${UF_URL} -o  ${DOWNLOADDIR}/${FILENAME} "
		GET_MD5="$cmd ${MD5_URL} -o ${DOWNLOADDIR}/${FILENAME}.md5"
		;;
	*) echo "ERROR: No download program found" >&2; exit 1;;
	esac
done

$GET_UF

if [ $? -ne 0 ]; then
	echo "ERROR: Download of the UF failed" >&2
	exit 1
fi

$GET_MD5

if [ $? -ne 0 ]; then
	echo "ERROR: Download of the UF MD5 failed" >&2
	exit 1
fi

set -x
(
	cd ${DOWNLOADDIR}/
	ln -sf ${FILENAME} splunkforwarder.tgz
	ln -sf ${FILENAME}.md5 splunkforwarder.tgz.md5
)

exit 0
