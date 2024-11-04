#!/bin/bash

#!/bin/bash
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")
echo $SCRIPTPATH

source $SCRIPTPATH/marketcheck.sh

if [ "$(containsE "$1" "${targets[@]}")" == "0" ]
then
    echo "Invalid Target Market"
    echo "Options are: ${targets[@]}"
    exit 1
fi

python ${SCRIPTPATH}/generate.py "$@"
rc=$?
if [[ $rc == 0 ]]; then
  tput setaf 10 && echo Success && tput sgr0
else
  tput setaf 1 && echo Failed && tput sgr0
fi
exit $rc
