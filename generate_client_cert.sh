#!/bin/bash
set -e

# This script will create a client SSL certificate signing request
# Using the supplied private key file.
# Create the private key using the following command:
#
#    openssl genrsa -aes256 -out client.key.pem 2048
#    chmod 400 client.key.pem
#
# It follows the excellent instructions laid out here:
#
#    https://jamielinux.com/docs/openssl-certificate-authority/
# 
####################################################################
set -e
set -o errexit
#set -o nounset
#set -o pipefail
set -o xtrace # Uncomment this line for debugging purposes

# Configuration
#
# Change any item in this section, but really only
# the ORGANISATION_DOMAIN is mandatory
#
ORGANISATION_DOMAIN=${ORGANISATION_DOMAIN:-client.example.com}
OUTPUT_DIR="${OUTPUT_DIR:-$PWD}"

# These values are used to calculate the certificate subjects
COUNTRY_CODE=${COUNTRY_CODE:-AU}                            # Country Name (2 letter code)
STATE_NAME="${STATE_NAME:-}"                                # State or Province Name
LOCALITY_NAME="${LOCALITY_NAME:-}"                          # Locality Name
ORGANISATION_NAME="$ORGANISATION_DOMAIN"                    # Organization Name
ORGANISATION_UNIT="${ORGANISATION_UNIT:-}"                  # Organizational Unit Name
COMMON_NAME="${COMMON_NAME:-$ORGANISATION_DOMAIN}"          # Common Name
EMAIL_ADDRESS="${EMAIL_ADDRESS:-root@$ORGANISATION_DOMAIN}" # Email Address

PRIVATE_KEY="$1"                          # Filename passed via the command line
RECREATE="$2"

if [ ! -z "$INTERMEDIATE_KEY_PASSWORD" ]; then
      echo "Passphrase for intermediate key supplied"
      INTERMEDIATE_PASSIN="-passin env:INTERMEDIATE_KEY_PASSWORD"
fi
if [ ! -z "$CLIENT_KEY_PASSWORD" ]; then
      echo "Passphrase for client key supplied"
      CLIENT_PASSIN="-passin env:CLIENT_KEY_PASSWORD"
fi

####################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

####################################################################

. $SCRIPT_DIR/lib/build_subject.sh

####################################################################

# Check the supplied key
if [ -z "$PRIVATE_KEY" ]; then
	echo "Private key file must be supplied"
	exit 1
fi
if [ ! -f "$PRIVATE_KEY" ]; then
	echo "Private key file $PRIVATE_KEY could not be found"
	exit 1
fi
openssl rsa -in "$PRIVATE_KEY" -check

# Does the output directory exist?
if [ ! -d "$OUTPUT_DIR" ]; then
      echo "Output directory $OUTPUT_DIR does not exist"
      exit 1
fi

# Does the output directory contain an initialised CA?
if [ ! -d "$OUTPUT_DIR/ca/root" ]; then
      echo "Output directory $OUTPUT_DIR/ca/root does not exist"
      exit 1
fi
if [ ! -d "$OUTPUT_DIR/ca/intermediate" ]; then
      echo "Output directory $OUTPUT_DIR/ca/intermediate does not exist"
      exit 1
fi

# Has the cert been issued before?
EXISTS=`grep "CN=$COMMON_NAME" $OUTPUT_DIR/ca/intermediate/index.txt | grep '^V'`||true
if [ ! -z "$EXISTS" ]; then
      if [ "$RECREATE" != "true" ]; then
            echo "Certificate has already been issued with that common name, you may need to revoke that first"
            exit 1
      else
            echo "Certificate has already been issued with that common name, revoking automatically"
            INDEX=`grep "CN=$COMMON_NAME" $OUTPUT_DIR/ca/intermediate/index.txt | grep '^V' | tr -s '\t\t' '\t' | cut -f 3`
            echo $SCRIPT_DIR/revoke_client_cert.sh $OUTPUT_DIR/ca/intermediate/newcerts/$INDEX.pem
            $SCRIPT_DIR/revoke_client_cert.sh $OUTPUT_DIR/ca/intermediate/newcerts/$INDEX.pem
      fi
fi

# Generate the CSR
DATE=$( date -u +%Y%m%d%H%M%S )
CSR_FILENAME="$OUTPUT_DIR/ca/intermediate/csrs/$ORGANISATION_DOMAIN-$DATE.csr.pem"
CERT_SUBJECT=$( build_subject "$COUNTRY_CODE" "$STATE_NAME" "$LOCALITY_NAME" "$ORGANISATION_NAME" "$ORGANISATION_UNIT" "$COMMON_NAME" "$EMAIL_ADDRESS" )
openssl req -config $OUTPUT_DIR/ca/intermediate/openssl.conf \
      -key "$PRIVATE_KEY" \
      -subj "$CERT_SUBJECT" \
      -new -sha256 \
      $CLIENT_PASSIN \
      -out "$CSR_FILENAME"

# Sign the cert with the intermediate CA
CERT_FILENAME="$OUTPUT_DIR/ca/intermediate/newcerts/$ORGANISATION_DOMAIN-$DATE.cert.pem"
yes | openssl ca -config $OUTPUT_DIR/ca/intermediate/openssl.conf \
      -extensions usr_cert -notext -md sha256 \
      -in "$CSR_FILENAME" \
      $INTERMEDIATE_PASSIN \
      -out "$CERT_FILENAME" # || rm -f "$CERT_FILENAME"
chmod 644 "$CERT_FILENAME"

# Verify the certificate
openssl x509 -noout -text -in "$CERT_FILENAME"

echo "Success, your certificate can be found at $CERT_FILENAME"