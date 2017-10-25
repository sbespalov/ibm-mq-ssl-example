#!/bin/bash
# -*- mode: sh -*-
# © Copyright IBM Corporation 2015, 2017
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
echo "---------------LICENSE SCRIPT RUN-------------------------"
mq-license-check.sh
echo "----------CHECK PARAMETERS SCRIPT RUN---------------------"
source mq-parameter-check.sh
echo "-----------SETUP VAR SCRIPT RUN--------------------------"
setup-var-mqm.sh
echo "--------------SETUP WEB------------------------"
which strmqweb && source setup-mqm-web.sh
echo "-----------PRE CREATE SCRIPT RUN-------------------------"
mq-pre-create-setup.sh
echo "------------CREATE QMGR SCRIPT RUN------------------------"
source mq-create-qmgr.sh
echo "------------START QMGR SCRIPT RUN------------------------"
source mq-start-qmgr.sh
#echo "--------------RUN QMGR SCRIPT RUN------------------------"
#source mq-configure-qmgr.sh

echo "#########################################################"
echo "----------CONFIG QMGR SCRIPT RUN (MOST IMPORTANT!)-------"
echo "#########################################################"
source mq-dev-config.sh
echo "#########################################################"
echo "--------------CONFIG QMGR SCRIPT DONE--------------------"
echo "#########################################################"

#echo "------------RESTART QMGR-------------------"
#source mq-stop-container.sh
#source mq-start-qmgr.sh

echo "------------MQ MONITOR QMGR SCRIPT RUN-------------------"
exec mq-monitor-qmgr.sh ${MQ_QMGR_NAME}
echo "-------------ALL SCRIPTS DONE. CONFIG FINISH!------------"

