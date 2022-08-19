#!/bin/bash 	 
# Installing awscli 

chmod  +x  /root/Automation_Project/automation.sh
sudo apt update
sudo apt install awscli
sudo su
./root/Automation_Project/automation.sh
sudo apt-get update -y

REQUIRED_PKG="apache2"
ACCESS_LOG_LOCATION="/var/log/apache2/access.log"
ERROR_LOG_LOCATION="/var/log/apache2/error.log"
S3_BUCKET = "upgrad-Anirban"
timestamp=$(date '+%d%m%Y-%H%M%S') )

PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
echo Checking for $REQUIRED_PKG: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
  sudo apt-get --yes install $REQUIRED_PKG 
fi

servstat=$(service REQUIRED_PKG status)

if [[ $servstat == *"active (running)"* ]]; then
  echo "process is running"
else echo "process is not running"
fi

tar -cf Anirban-httpd-accesslog-timestamp.tar ACCESS_LOG_LOCATION
tar -cf Anirban-httpd-errorlog-timestamp.tar ERROR_LOG_LOCATION

cp Anirban-httpd-accesslog-timestamp.tar /tmp/
cp Anirban-httpd-errorlog-timestamp.tar /tmp/

DIR=${1:-"/tmp/*.tar"}
BASES3URI=${2:-"s3://S3_BUCKET/log-bkp"}
DATESTART=$(date +%F)

function log {
  echo "[$(date --rfc-3339=seconds)]: $*"
}

function move_files {

  for f in `find ${DIR} -type f`
  do
    datepart=$(date +%F -r $f)
    filename=$(basename $f)
    s3uri="${BASES3URI}/$datepart/$filename"
    cmd="aws s3 cp ${f} ${s3uri}"

    log "Moving: $f to $s3uri"
    output="$(${cmd} 2>&1)"

    if [ $? -eq 0 ]; then
      log "Deleting: $f"
      rm -f $f
    else
      log "Failed: $output"
    fi

  done
}

function ensure_only_running {
  if [ "$(pgrep -fn $0)" -ne "$(pgrep -fo $0)" ]; then
    log "Detected multiple instances of $0 running, exiting."
    exit 1
  fi
}

log "Starting to move files ($DATESTART)"
ensure_only_running
move_files
echo "Finished."