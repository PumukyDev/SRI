#!/bin/bash -x
#
# USAGE: ./test.sh <nameserver-ip>
#

# Salir si algún comando falla
set -euo pipefail

function resolver () {
    dig $nameserver +short $@
}

nameserver=@$1

resolver mercurio.sistema.test
resolver venus.sistema.test
resolver tierra.sistema.test
resolver marte.sistema.test

resolver ns1.sistema.test
resolver ns2.sistema.test

resolver sistema.test mx

resolver sistema.test ns

resolver -x 192.168.57.101
resolver -x 192.168.57.102
resolver -x 192.168.57.103
resolver -x 192.168.57.104
