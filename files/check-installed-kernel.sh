#!/bin/bash

# define functions
function ok () {
   echo "OK - ${1}"
   exit 0
}

function warning() {
   echo "WARNING - ${1}"
   exit 1
}

function critical() {
   echo "CRITICAL - ${1}"
   exit 2
}

function unknown() {
  echo "UNKNOWN - ${1}"
  exit 3
}

# define variables
REDHAT_KERNEL_COMMAND='rpm -q --qf="%{BUILDTIME} %{INSTALLTIME} %{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n" kernel |sort | tail -n 1'
DEBIAN_KERNEL_COMMAND='dpkg --list | grep linux-image-[0-9] | cut -f 3 -d " "| sort -V | tail -n 1'
CRITICAL_SECONDS=86400 # 1 day

# Basic option handling
while (( $# > 0 ))
do
  opt="$1"

  case $opt in
    --critical-seconds|-c)
        CRITICAL_SECONDS="$2"
        shift
        ;;
    -*)
        echo "Unknown option: '$opt'"
        exit 1
        ;;
    *)
       # end of long options
       break
       ;;
  esac
  shift 
done

# check to make sure this is a RedHat based distro
if [[ -f /etc/redhat-release ]]; then
    LATEST=$(eval ${REDHAT_KERNEL_COMMAND} | cut -f 3 -d ' ' | sed -e 's/^kernel-*//')
    INSTALLED=$(eval ${REDHAT_KERNEL_COMMAND} | cut -f 2 -d ' ' )
    RUNNING=$(uname -r)
# if this is not redhat based assume its a debian based one
else
    LATEST=$(eval ${DEBIAN_KERNEL_COMMAND} | sed -e 's/^linux-image-*//')
    RUNNING=$(uname -r)
    if [[ -f /var/lib/dpkg/info/linux-image-${LATEST}.list ]]; then
    	INSTALLED=$(stat --format=%Y /var/lib/dpkg/info/linux-image-${LATEST}.list)
    else
        unknown "Unable to determine kernel installation date"
    fi
fi

if  [[ -z ${INSTALLED} ]] || [[ ${INSTALLED} -eq 0 ]]; then
    unknown "Unable to determine kernel installation date"
fi

if [[ "${RUNNING}" != "${LATEST}" ]]; then
    TIME_NOW=$(date +%s)
    TIME_DIFF=$(($TIME_NOW - $INSTALLED))
    MESSAGE="Latest Installed Kernel NOT in use | Latest installed = ${LATEST}, running = ${RUNNING}"
    if [[ ${TIME_DIFF} -lt ${CRITICAL_SECONDS} ]]; then
        warning "${MESSAGE}"
	else
        critical "${MESSAGE}"
    fi
else
    ok "Latest Installed Kernel in use | kernel = $(uname -r)"
fi
