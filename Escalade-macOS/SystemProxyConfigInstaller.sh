#!/bin/sh

#  SystemProxyConfigInstaller.sh
#  Escalade
#
#  Created by Samuel Zhang on 2/10/17.
#

DIR="/Library/Application Support/Escalade/"
FILE="${DIR}SystemProxyConfig"

cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "${DIR}"
sudo cp SystemProxyConfig "${DIR}"
sudo chown root:admin "${FILE}"
sudo chmod +s "${FILE}"

echo done
