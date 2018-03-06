#!/bin/sh
env=${TIDEWAYS_ENV:-development}
extra="--hostname=tideways-${env}"
extra="${extra} --env=${env}"
extra="${extra} --debug"
extra="${extra} --log /dev/stdout"
extra="${extra} --log-outgoing"
extra="${extra} --address=0.0.0.0:${TIDEWAYS_PORT_TCP}"
extra="${extra} --udp=0.0.0.0:${TIDEWAYS_PORT_UDP}"
echo "starting tideways-daemon, with: ${extra}"
/usr/bin/tideways-daemon $extra
