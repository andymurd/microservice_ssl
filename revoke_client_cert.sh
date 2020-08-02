#!/bin/bash
set -e

# This script will revoke a client SSL certificate
# 
####################################################################
# Configuration
#
# Change any item in this section, but really only
# the OUTPUT_DIR is mandatory
#
OUTPUT_DIR=${OUTPUT_DIR:-.}

CERT_FILENAME="$1"     # Filename passed via the command line

if [ ! -z "$INTERMEDIATE_KEY_PASSWORD" ]; then
      echo "Passphrase for intermediate key supplied"
      INTERMEDIATE_PASSIN="-passin env:INTERMEDIATE_KEY_PASSWORD"
fi

####################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

####################################################################

# Check the supplied cert
if [ -z "$CERT_FILENAME" ]; then
	echo "Certificate file must be supplied"
	exit 1
fi
if [ ! -f "$CERT_FILENAME" ]; then
	echo "Certificate file $PRIVATE_KEY could not be found"
	exit 1
fi
openssl verify -verbose -CAfile $OUTPUT_DIR/ca/intermediate/certs/intermediate-chain.cert.pem "$CERT_FILENAME"

# Generate the CSR
openssl ca -revoke $CERT_FILENAME \
      -crl_reason superseded \
      $INTERMEDIATE_PASSIN \
      -config $OUTPUT_DIR/ca/intermediate/openssl.conf

echo "Success, certificate $CERT_FILENAME has been revoked"