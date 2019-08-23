#!/bin/bash

PROGNAME=${0##*/}
BASEDIR=$(cd $(dirname $0)/..; pwd)
SELF="$(cd $(dirname $0); pwd)/$PROGNAME"

OPENSSL="`command -v openssl 2>/dev/null`"
DS_URL="@@DS_URL@@"
NOSTART=0
ARCHIVE="splunkforwarder.tgz"

if [ "`uname -s`" != "Linux" ]; then
	echo "ERROR: This script is for Linux systems only" >&2
	exit 1
fi

if [ -z "$OPENSSL" ]; then
	echo "ERROR: openssl is required to generate random password" >&2
	exit 1
fi

SEED_PASS=changeme
CHANGE_PASS="`$OPENSSL rand -base64 16`"
USER="`whoami`"
if [ $EUID -eq 0 ]; then
USER=root
fi
WHOAMI="`whoami`"
TARGET=/opt
if [ $EUID -ne 0 ]; then
	TARGET="`pwd`"
fi
LOGFILE=

mk_msg_domain()
{
    MK_MSG_DOMAIN="$1"
}

mk_msg_domain "$PROGNAME"

mk_msg_format() {
        printf "%s %s\n" "[$1]" "$2"
}

mk_msg() {
        mk_log "$@"
        mk_msg_format "$MK_MSG_DOMAIN" "$*" >&2
}

log_info () {
        mk_msg "$@" >&2
}

log_verbose() {
        [[ $verbose -eq 1 ]] && mk_msg "$@" >&2
}

mk_log()
{
        [ -n "${MK_LOG_FD}" ] \
                && mk_msg_format "$MK_MSG_DOMAIN" "$*" >&${MK_LOG_FD}
}

log_error() {
        mk_msg "ERROR: $@" >&2
}

mk_fail() {
        log_error "$@" >&2
        exit 1
}

log_debug() {
        [[ $debug -eq 1 ]] && mk_msg "DEBUG: $@" >&2
}

usage () {
cat <<EOF
Usage: $PROGNAME [OPTIONS]

  -h, --help		This message
  -x, --debug		Enable script debugging
  -D, --url		Deployment Server URL [$DS_URL]
  -d, --target		Directory to install into [$TARGET]
  -P, --pass		Admin password to set [$SEED_PASS]
  -u, --user		Default user to run as [$USER]
  -n, --nostart		Dont start splunk
EOF
	exit 1
}

while [[ $# -gt 0 ]]
do
	case "$1" in
	-x|--debug) set -x; shift;;
	-h|--help) usage;;
	-P|--pass) [[ $# -gt 1 ]] || usage; SEED_PASS="$2"; shift 2;;
	-D|--url) [[ $# -gt 1 ]] || usage; DS_URL="$2"; shift 2 ;;
	-d|--target) [[ $# -gt 1 ]] || usage; TARGET="$2"; shift 2 ;;
	-u|--user) [[ $# -gt 1 ]] || usage; USER="$2"; shift 2 ;;
	-n|--nostart) NOSTART=1; shift ;;
	*) usage;;
	esac
done

TARGETDIR=$TARGET/splunkforwarder

#if [ "$EUID" -ne 0 ]; then
#	mk_fail "ERROR: Please run this as root" 
#fi

if [ -x $TARGETDIR/bin/splunk ]; then
	mk_msg "$TARGETDIR/bin/splunk already exists.. STOPPING" 
	$TARGETDIR/bin/splunk stop 
fi

if [ -d $TARGETDIR ]; then
	mk_msg "$TARGETDIR already exists.. REMOVING" 
	rm -rf "$TARGETDIR" || exit 1
fi

if [ ! -w "$TARGET" ]; then
	mk_msg "Creating $TARGET"
	mkdir -p "$TARGET" || exit 1
fi

if [ "$EUID" -eq 0 ]; then 
	if ! getent group splunk >/dev/null 2>&1; then
		mk_msg "Adding splunk group"
		groupadd splunk || exit 1
	fi

	if ! getent passwd splunk >/dev/null 2>&1; then
		mk_msg "Adding splunk user"
		useradd -c "Splunk User" -d $TARGETDIR -g splunk -s /bin/bash splunk || exit 1
	else
		mk_msg "Adding splunk user"
		usermod -d $TARGETDIR splunk || exit 1
	fi
fi
# unarchive
mk_msg "Installing into $TARGET"

tar -C $TARGET -zxvf $ARCHIVE || mk_fail "Failed to extract $ARCHIVE"

# disable management port
mk_msg "Disabling REST API"
mkdir -p $TARGETDIR/etc/apps/UF-TA-killrest/local || mk_fail "Could not create directory  $TARGETDIR/etc/apps/UF-TA-killrest/local"
cat > $TARGETDIR/etc/apps/UF-TA-killrest/local/server.conf<<EOF
[httpServer]
disableDefaultPort = true
EOF

# create deploymentclient.conf
mk_msg "Configuring deploymentclient.conf"
mkdir -p $TARGETDIR/etc/apps/deployment-client/local || mk_fail "Could not create directory  $TARGETDIR/etc/apps/deployment-client/local"
cat > $TARGETDIR/etc/apps/deployment-client/local/deploymentclient.conf<<EOF
[deployment-client]

[target-broker:deploymentServer]
targetUri = $DS_URL
EOF

# configure splunk
if [ "$EUID" -ne 0 ]; then
	$TARGETDIR/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd $SEED_PASS --auto-ports || exit 1
#	$TARGETDIR/bin/splunk stop 
else
	$TARGETDIR/bin/splunk enable boot-start --accept-license --answer-yes --no-prompt --seed-passwd $SEED_PASS --auto-ports || exit 1
fi

# ensure splunk home is owned by splunk, except for splunk-launch.conf
if [ "$EUID" -eq 0 ]; then
	chown -R splunk:splunk /opt/splunkforwarder
	chown root:splunk $TARGETDIR/etc/splunk-launch.conf
fi
chmod 644 $TARGETDIR/etc/splunk-launch.conf

# enable deploymentclient
#$TARGETDIR/bin/splunk set deploy-poll "$DS_URL" -auth admin:changeme --accept-license --answer-yes --auto-ports --no-prompt || exit 1

# change admin pass
$TARGETDIR/bin/splunk edit user admin -password ${CHANGE_PASS} -auth admin:changeme || exit 1

# start
if [ $NOSTART = 0 ]; then
	mk_msg "RESTARTING..."
	$TARGETDIR/bin/splunk restart --accept-license --answer-yes --auto-ports --no-prompt || exit 1
else
	mk_msg "Done. Not starting splunk.... I'm outta here"
fi
