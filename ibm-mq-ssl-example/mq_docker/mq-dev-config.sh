#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2017
#
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

configure_os_user()
{
  # The group ID of the user to configure
  local -r GROUP_NAME=$1
  # Name of environment variable containing the user name
  local -r USER_VAR=$2
  # Name of environment variable containing the password
  local -r PASSWORD=$3
  # Home directory for the user
  local -r HOME=$4
  # Determine the login name of the user (assuming it exists already)

  # if user does not exist
  if ! id ${!USER_VAR} 2>1 > /dev/null; then
    # create
    useradd --gid ${GROUP_NAME} --home ${HOME} ${!USER_VAR}
  fi
  # Change the user's password (if set)
  if [ ! "${!PASSWORD}" == "" ]; then
    echo ${!USER_VAR}:${!PASSWORD} | chpasswd
  fi
}

configure_tls()
{
   local -r PASSPHRASE=${MQ_SSL_PASS:-"passw0rd"}
   echo "LOG mq-dev-config.sh : PASSPHRASE = ${PASSPHRASE}"

   local -r CIPH=${MQ_SSL_CIPH:-"RC4_MD5_US"}
   echo "LOG mq-dev-config.sh : CIPH = ${CIPH}"

  echo "LOG mq-dev-config.sh : configure TLS"
  # Create keystore
  if [ ! -e "/tmp/tlsTemp/key.kdb" ]; then
    # Keystore does not exist
    echo "LOG mq-dev-config.sh :  Start keys CREATE"
    echo "LOG mq-dev-config.sh : creating 'kdb' keys"
	runmqakm -keydb -create -db /tmp/tlsTemp/key.kdb -type cms -pw ${PASSPHRASE} -stash
	  # Create stash file
	if [ ! -e "/tmp/tlsTemp/key.sth" ]; then
    echo "No stash file, so create it"
	 
    	runmqakm -keydb -stashpw -db /tmp/tlsTemp/key.kdb -pw ${PASSPHRASE}
	fi
	
runmqckm -cert -create -db /tmp/tlsTemp/key.kdb -pw ${PASSPHRASE} -label ibmwebspheremq${MQ_QMGR_NAME} -dn "CN=00CA0001CCFcf99usr,O=Savings Bank of the Russian Federation,C=RU" -size 2048
	runmqckm -cert -extract -db /tmp/tlsTemp/key.kdb -pw ${PASSPHRASE} -label ibmwebspheremq${MQ_QMGR_NAME} -target /tmp/tlsTemp/cfmq.arm

	
    echo "LOG mq-dev-config.sh : creating keystore"
	runmqckm -keydb -create -db /tmp/tlsTemp/cfkeystore.jks -type jks -pw ${PASSPHRASE} -stash
	runmqckm -cert -create -db /tmp/tlsTemp/cfkeystore.jks -pw ${PASSPHRASE} -label cfkeystore -dn "CN=00CA0001CCFcf99usr,OU=00CA,O=Savings Bank of the Russian Federation,C=RU" -size 2048
	runmqckm -cert -extract -db /tmp/tlsTemp/cfkeystore.jks -pw ${PASSPHRASE} -label cfkeystore -target /tmp/tlsTemp/cfkeystore.arm
	runmqckm -cert -add -db /tmp/tlsTemp/cfkeystore.jks -pw ${PASSPHRASE} -label sbmq_signer -file /tmp/tlsTemp/cfmq.arm

	runmqckm -cert -list personal -db /tmp/tlsTemp/cfkeystore.jks -pw ${PASSPHRASE}
	runmqckm -cert -list ca -db /tmp/tlsTemp/cfkeystore.jks -pw ${PASSPHRASE}
	
    echo "LOG mq-dev-config.sh : import key to keystore by use keytool"
	/opt/mqm/java/jre64/jre/bin/keytool -importcert -trustcacerts -noprompt -file /tmp/tlsTemp/cfmq.arm  -keystore /tmp/tlsTemp/cfkeystore.jks -storepass ${PASSPHRASE}

    echo "LOG mq-dev-config.sh :  CREATE KEYS DONE!"

  fi


  # Now copy the key files
  echo "LOG mq-dev-config.sh: COPY KEYS START!"
  chown mqm:mqm /tmp/tlsTemp/*.*
  chmod 640 /tmp/tlsTemp/*.*

  su -c "cp -PTv /tmp/tlsTemp/key.kdb ${DATA_PATH}/qmgrs/${MQ_QMGR_NAME}/ssl/key.kdb" -l mqm
  su -c "cp -PTv /tmp/tlsTemp/key.sth ${DATA_PATH}/qmgrs/${MQ_QMGR_NAME}/ssl/key.sth" -l mqm
  su -c "cp -PTv /tmp/tlsTemp/key.rdb ${DATA_PATH}/qmgrs/${MQ_QMGR_NAME}/ssl/key.rdb" -l mqm
  su -c "cp -PTv /tmp/tlsTemp/cfmq.arm ${DATA_PATH}/qmgrs/${MQ_QMGR_NAME}/ssl/cfmq.arm" -l mqm
  su -c "cp -PTv /tmp/tlsTemp/cfmq.arm ${DATA_PATH}/keystore/cfmq.arm" -l mqm
  su -c "cp -PTv /tmp/tlsTemp/cfkeystore.jks ${DATA_PATH}/keystore/cfkeystore.jks" -l mqm
  echo "LOG mq-dev-config.sh: COPY KEYS END!"

}


echo "LOG mq-dev-config.sh : start config}"
echo "LOG mq-dev-config.sh : INIT params:"
# Set default unless it is set
MQ_DEV=${MQ_DEV:-"true"}
echo "LOG mq-dev-config.sh : MQ_DEV = ${MQ_DEV}"

MQ_SSL=${MQ_SSL:-"false"}
echo "LOG mq-dev-config.sh : USE_SSL = ${MQ_SSL}"

# Set needed variables to point to various MQ directories
DATA_PATH=`dspmqver -b -f 4096`
INSTALLATION=`dspmqver -b -f 512`


MQ_APP_NAME="app"
MQ_APP_PASSWORD=${MQ_APP_PASSWORD:-""}

echo "LOG mq-dev-config.sh : Configuring app user"
if ! getent group mqclient; then
  # Group doesn't exist already
  groupadd mqclient
fi

configure_os_user mqclient MQ_APP_NAME MQ_APP_PASSWORD /home/app

# Set authorities to give access to qmgr, queues and topic
su -l mqm -c "setmqaut -m ${MQ_QMGR_NAME} -t qmgr -g mqclient +connect +inq"
su -l mqm -c "setmqaut -m ${MQ_QMGR_NAME} -n \"ESB.**\" -t queue -g mqclient +put +get +browse"


if [ "${MQ_SSL}" == "true" ]; then
    echo "LOG mq-dev-config.sh : Start configuring TLS for queue manager ${MQ_QMGR_NAME}"
    if [ ! -e "${DATA_PATH}/qmgrs/${MQ_QMGR_NAME}/ssl/key.kdb" ]; then
        echo "LOG mq-dev-config.sh : New configuring TLS for queue manager ${MQ_QMGR_NAME}"
        mkdir -p /tmp/tlsTemp
        mkdir -p ${DATA_PATH}/keystore
        chown mqm:mqm ${DATA_PATH}/keystore
        chown mqm:mqm /tmp/tlsTemp
        configure_tls
    else
        echo "LOG mq-dev-config.sh : A key store already exists at '${DATA_PATH}/qmgrs/${MQ_QMGR_NAME}/ssl/key.kdb'"
    fi
fi

if [ "${MQ_DEV}" == "true" ]; then
  echo "LOG mq-dev-config.sh : Configuring default objects for queue manager: ${MQ_QMGR_NAME}"
  set +e
  runmqsc ${MQ_QMGR_NAME} < /etc/mqm/mq-dev-config
  set -e
fi