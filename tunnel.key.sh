#!/bin/bash

HOST=$1

echo "add tunnel user to host..."

KEY=$(cat ./key/id_rsa.pub)

ssh root@"$HOST" 'useradd -m tunnel'

echo "add public key to host..."

ssh root@"$HOST" 'mkdir /home/tunnel/.ssh -p && echo '"$KEY"' > /home/tunnel/.ssh/authorized_keys'

echo "specific key permissions..."

ssh root@"$HOST" 'chown -R tunnel:tunnel /home/tunnel/.ssh && chmod 0700 /home/tunnel/.ssh && chmod 0600 /home/tunnel/.ssh/authorized_keys'

ssh root@"$HOST" 'chown root:tunnel -R /etc/docker/certs.d && chmod 775 /etc/docker/certs.d -R'

echo "all done..."
