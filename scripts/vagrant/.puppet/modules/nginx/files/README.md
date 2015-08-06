## nginx (/etc/init.d/nginx)

Has been modified since the default do_start hangs.

Where
- start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
    $DAEMON_ARGS

Has been changed to:

- start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
    $DAEMON_ARGS > /dev/null 2>&1 &
