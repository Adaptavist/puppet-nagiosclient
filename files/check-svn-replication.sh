#!/bin/bash
#set -x
# script to check SVN replication status
# written by Olivier Palanque
# modified by Matthew Hope


PROGNAME=${0##*/} 
VERSION="1.1"
# Binaire
SVN=/usr/bin/svn
CUT=/usr/bin/cut
HEAD=/usr/bin/head
TAIL=/usr/bin/tail

# Variables
MASTER_SVN=""
MASTER_USER=""
MASTER_PASS=""
MIRROR_SVN=""
MIRROR_USER=""
MIRROR_PASS=""
MASTER_REV=""
MIRROR_REV=""
WARN_THRESHOLD="5"
ERROR_THRESHOLD="10"

# Code retour NAGIOS
OK="0"
WARNING="1"
CRITICAL="2"
UNKNOWN="3"

SHORTOPTS="U:u:P:p:S:s:E:W:HhVv"
LONGOPTS="user-source:,user-sync:,password-source:,password-sync:,url-source:,url-sync:,warn-threshold:,error-threshold:help,version"

usage(){
  echo " Usage: $PROGNAME [options]"
  echo " Options:"
  echo "   -h -H --help             :  Displays Help"
  echo "   -U <ARG>                 :  Specifies the user of the source repository"
  echo "    --user-source=<ARG>     :  Equivalent of -U"
  echo "   -P <ARG>                 :  Specifies the password for the source user"
  echo "   --password-source=<ARG>  :  Equivalent of -P"
  echo "   -S <ARG>                 :  Specifies the url of the source repository"
  echo "   --url-source=<ARG>       :  Equivalent of -S"
  echo "   -u <ARG>                 :  Specifies the user of the mirror repository"
  echo "   --user-sync=<ARG         :  Equivalent of -u"
  echo "   -p <ARG>                 :  Specifies the password for the mirror user"
  echo "   --password-sync=<ARG>    :  Equivalent of -p"
  echo "   -s <ARG>                 :  Specifies the url of the mirror repository"
  echo "   --url-sync=<ARG>         :  Equivalent of -s"
  echo "   -W <ARG>                 :  Specifies the difference threshold for warnings, default 5"
  echo "   --warn-threshold=<ARG>   :  Equivalent of -W"
  echo "   -E <ARG>                 :  Specifies the difference threshold for errors default 10"
  echo "   --error-threshold=<ARG>  :  Equivalent of -E"
  echo "   -v -V --version          :  Displays the script version"
} 


ARGS=$(getopt -s bash -q --options $SHORTOPTS  --longoptions $LONGOPTS --name "$PROGNAME" -- "$@") 
if [ $? != 0 ]; then
  echo "Error in the parameters"
  usage
  exit ${UNKNOWN}
fi


eval set -- "$ARGS" 
while true; do
   case $1 in
      -h|-H|--help)
         usage
         exit ${UNKNOWN}
         ;;
      -v|-V|--version)
         echo "Version du script $PROGNAME : v$VERSION"
	 exit ${UNKNOWN}
         ;;
      -U|--user-source)
         MASTER_USER="$2"
 	 shift 1
         ;;
      -P|--password-source)
         MASTER_PASS="$2"
         shift 1
	 ;; 
      -S|--url-source)
         MASTER_SVN="$2"
         shift 1
         ;;
      -u|--user-sync)
         MIRROR_USER="$2"
	 shift 1
         ;;
      -p|--password-sync)
         MIRROR_PASS="$2"
	 shift 1
         ;;
      -s|--url-sync)
	 MIRROR_SVN="$2"
	 shift 1
         ;;
      -W|--warn-threshold)
        WARN_THRESHOLD="$2"
        shift 1
        ;;  
      -E|--error-threshold)
        ERROR_THRESHOLD="$2" 
        shift 1
        ;;
      --)
         shift
         break
         ;;
      *)
         usage
         break
         ;;
   esac
   shift 
done 

# check to enure at least master and mirror repo url's are set
if [ -z "${MASTER_SVN:-}" ] || [ -z "${MIRROR_SVN:-}" ]; then
  echo "ERROR: At a mimimum the master repo (-S) and mirror repo (-s) URL's need to be supplied as arguments" 
  usage
  exit ${UNKNOWN}
fi

# construct the command to get master
MASTER_COMMAND="$SVN info $MASTER_SVN "

if [ ! -z "${MASTER_USER:-}" ]; then
  MASTER_COMMAND="${MASTER_COMMAND} --username=$MASTER_USER"
fi
   
if [ ! -z "${MASTER_PASS:-}" ]; then
  MASTER_COMMAND="${MASTER_COMMAND} --password=$MASTER_PASS"
fi

MASTER_COMMAND="${MASTER_COMMAND} --no-auth-cache --non-interactive --trust-server-cert"

MASTER_REV=$(${MASTER_COMMAND} | ${TAIL} -n 6)

if [ $? != 0 ]; then
  echo "Error in MASTER settings"
  usage
  exit ${UNKNOWN}
fi

MASTER_REV=$(echo "$MASTER_REV" | $HEAD -n 1 | $CUT -f2 -d ' ')

# construct the command to get mirror
MIRROR_COMMAND="$SVN info $MIRROR_SVN "

if [ ! -z "${MIRROR_USER:-}" ]; then
    MIRROR_COMMAND="${MIRROR_COMMAND} --username=$MIRROR_USER"
fi

if [ ! -z "${MIRROR_PASS:-}" ]; then
    MIRROR_COMMAND="${MIRROR_COMMAND} --password=$MIRROR_PASS"
fi

MIRROR_COMMAND="${MIRROR_COMMAND} --no-auth-cache --non-interactive --trust-server-cert"

MIRROR_REV=$(${MIRROR_COMMAND} | ${TAIL} -n 6)
if [ $? != 0 ]; then
  echo "Error in MIRROR parameters"
  usage
  exit ${UNKNOWN}
fi
MIRROR_REV=$(echo "$MIRROR_REV" | $HEAD -n 1 | $CUT -f2 -d ' ')

DIFF=$((MASTER_REV - MIRROR_REV))

if [ "$?" != "0" ]; then
  echo "Error in returning revision"
  exit ${UNKNOWN}
fi


#now lets see if there are any problems
if [ "$DIFF" -eq "0" ]; then 
  echo "Sync OK | Master=$MASTER_REV ,Mirror=$MIRROR_REV"
  exit ${OK}
fi

if [ "$DIFF" -ge "${WARN_THRESHOLD}" ] && [ "$DIFF" -lt "${ERROR_THRESHOLD}" ]; then
  echo "WARNING - Replicaiton is behind by $DIFF Revisions | Master=$MASTER_REV , Mirror=$MIRROR_REV"
  exit ${WARNING}
fi

if [ "$DIFF" -ge "${ERROR_THRESHOLD}" ]; then
  echo "CRITICAL - Replicaiton is behind by $DIFF Revisions | Master=$MASTER_REV , Mirror=$MIRROR_REV"
  exit ${CRITICAL}
fi

