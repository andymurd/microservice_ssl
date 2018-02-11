#!/bin/bash

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
# Configuration
#
# Change any item in this section, but really only
# the ORGANISATION_DOMAIN is mandatory
#
ORGANISATION_DOMAIN="client.example.com"

# These values are used to calculate the certificate subjects
COUNTRY_CODE="AU"                         # Country Name (2 letter code)
STATE_NAME=""                             # State or Province Name
LOCALITY_NAME=""                          # Locality Name
ORGANISATION_NAME="$ORGANISATION_DOMAIN"  # Organization Name
ORGANISATION_UNIT=""                      # Organizational Unit Name
COMMON_NAME="$ORGANISATION_DOMAIN"        # Common Name
EMAIL_ADDRESS=""                          # Email Address

PRIVATE_KEY="$1"                          # Filename passed via the command line

####################################################################

. ./lib/build_subject.sh

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

# Generate the CSR
DATE=$( date -u +%Y%m%d%H%M%S )
CSR_FILENAME="ca/intermediate/csrs/$ORGANISATION_DOMAIN-$DATE.csr.pem"
CERT_SUBJECT=$( build_subject "$COUNTRY_CODE" "$STATE_NAME" "$LOCALITY_NAME" "$ORGANISATION_NAME" "$ORGANISATION_UNIT" "$COMMON_NAME" "$EMAIL_ADDRESS" )
openssl req -config ca/intermediate/openssl.conf \
      -key "$PRIVATE_KEY" \
      -subj "$CERT_SUBJECT" \
      -new -sha256 \
      -out "$CSR_FILENAME"

# Sign the cert with the intermediate CA
CERT_FILENAME="ca/intermediate/newcerts/$ORGANISATION_DOMAIN-$DATE.cert.pem"
openssl ca -config ca/intermediate/openssl.conf \
      -extensions usr_cert -notext -md sha256 \
      -in "$CSR_FILENAME" \
      -out "$CERT_FILENAME"
chmod 444 "$CERT_FILENAME"

# Verify the certificate
openssl x509 -noout -text -in "$CERT_FILENAME"