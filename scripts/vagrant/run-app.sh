#!/bin/bash
set -e

cd /vagrant

foreman run scripts/runDev --mayday --bare-server --install
exit 0
