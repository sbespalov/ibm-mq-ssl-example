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

if [ -z ${MQ_QMGR_NAME+x} ]; then
  # no ${MQ_QMGR_NAME} supplied so set Queue Manager name as the hostname
  # However make sure we remove any characters that are not valid.
  echo "LOG mq-parameter-check.sh: Hostname is: $(hostname)"
  MQ_QMGR_NAME=`echo $(hostname) | sed 's/[^a-zA-Z0-9._%/]//g'`
  echo "LOG mq-parameter-check.sh: Setting Queue Manager name to ${MQ_QMGR_NAME}"
fi

if [ -z ${MQ_SSL+x} ]; then
  echo "LOG mq-parameter-check.sh: Use SSL ${MQ_SSL}"
fi

if [ -z ${MQ_SSL_PASS+x} ]; then
  echo "LOG mq-parameter-check.sh: SSL passphrase ${MQ_SSL_PASS}"
fi
if [ -z ${MQ_SSL_CIPH+x} ]; then
  echo "LOG mq-parameter-check.sh: Select SSLCIPH ${MQ_SSL_CIPH}"
fi

