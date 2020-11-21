#!/bin/bash
set -e

# This script will create a root CA and intermediate in a "ca"
# directory below the current.
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
ORGANISATION_DOMAIN=${ORGANISATION_DOMAIN:-example.com}
PKI_NAME="trust.$ORGANISATION_DOMAIN"
ROOT_PKI_NAME=${ROOT_PKI_NAME:-$PKI_NAME}
INTERMEDIATE_PKI_NAME=${INTERMEDIATE_PKI_NAME:-$PKI_NAME}
OUTPUT_DIR=${OUTPUT_DIR:-.}

# These values are used to calculate the certificate subjects
COUNTRY_CODE=${COUNTRY_CODE:-AU}                          # Country Name (2 letter code)
STATE_NAME=${STATE_NAME:-}                                # State or Province Name
LOCALITY_NAME=${LOCALITY_NAME:-}                          # Locality Name
ORGANISATION_NAME="$ORGANISATION_DOMAIN"                  # Organization Name
ROOT_ORGANISATION_UNIT="Trust Root CA"                    # Organizational Unit Name for root cert
INTERMEDIATE_ORGANISATION_UNIT="Trust CA"                 # Organizational Unit Name for intermediate cert
ROOT_COMMON_NAME="root.$ROOT_PKI_NAME"                    # Common Name for root cert
INTERMEDIATE_COMMON_NAME="ca.$INTERMEDIATE_PKI_NAME"      # Common Name for intermediate cert
EMAIL_ADDRESS=${EMAIL_ADDRESS:-root@$ORGANISATION_DOMAIN} # Email Address

# Determines for how long each cert will be valid
ROOT_CA_DAYS=7300                        # 20 years
INTERMEDIATE_CA_DAYS=3650                # 10 years

if [ ! -z "$ROOT_KEY_PASSWORD" ]; then
      echo "Passphrase for root key supplied"
      ROOT_PASSIN="-passin env:ROOT_KEY_PASSWORD"
      ROOT_PASSOUT="-passout env:ROOT_KEY_PASSWORD"
fi
if [ ! -z "$INTERMEDIATE_KEY_PASSWORD" ]; then
      echo "Passphrase for intermediate key supplied"
      INTERMEDIATE_PASSIN="-passin env:INTERMEDIATE_KEY_PASSWORD"
      INTERMEDIATE_PASSOUT="-passout env:INTERMEDIATE_KEY_PASSWORD"
fi

####################################################################

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

####################################################################

. $SCRIPT_DIR/lib/build_subject.sh

####################################################################
# Create the CA directories
mkdir -p $OUTPUT_DIR/ca
mkdir -p $OUTPUT_DIR/ca/root
mkdir -p $OUTPUT_DIR/ca/intermediate

# Create the root CA config file
cat $SCRIPT_DIR/etc/root.openssl.conf $SCRIPT_DIR/etc/base.openssl.conf | sed -e s@__DIR__@$OUTPUT_DIR@ > $OUTPUT_DIR/ca/root/openssl.conf

# Create the intermediate CA config file
cat $SCRIPT_DIR/etc/intermediate.openssl.conf $SCRIPT_DIR/etc/base.openssl.conf | sed -e s@__DIR__@$OUTPUT_DIR@ > $OUTPUT_DIR/ca/intermediate/openssl.conf

cd $OUTPUT_DIR/ca

####################################################################
# CA root

cd root
mkdir -p certs
mkdir -p crl
mkdir -p newcerts
mkdir -p private
chmod 700 private
touch index.txt
echo '01' > serial
echo '01' > crlnumber

# Generate the root key
echo "Generating root CA key..."
openssl genrsa -aes256 \
      $ROOT_PASSOUT \
      -out private/root.key.pem 4096
chmod 400 private/root.key.pem

# Generate the root certificate
echo "Generating root CA certificate..."
ROOT_SUBJECT=$( build_subject "$COUNTRY_CODE" "$STATE_NAME" "$LOCALITY_NAME" "$ORGANISATION_NAME" "$ROOT_ORGANISATION_UNIT" "$ROOT_COMMON_NAME" "$EMAIL_ADDRESS" )
openssl req -config $OUTPUT_DIR/ca/root/openssl.conf \
      -key private/root.key.pem \
      -new -x509 -days $ROOT_CA_DAYS -sha256 -extensions v3_ca \
      -subj "$ROOT_SUBJECT" \
      $ROOT_PASSIN \
      -out certs/root.cert.pem

# Check the generated certificate
echo "Checking root certificate..."
openssl x509 -noout -text -in certs/root.cert.pem

cd ..

####################################################################
# Intermediate CA

cd intermediate
mkdir -p certs
mkdir -p crl
mkdir -p csrs
mkdir -p newcerts
mkdir -p private
chmod 700 private
touch index.txt
echo '1000' > serial
echo '1000' > crlnumber

# Generate intermediate CA key
echo "Generating intermediate key..."
openssl genrsa -aes256 \
      $INTERMEDIATE_PASSOUT \
      -out private/intermediate.key.pem 4096
chmod 400 private/intermediate.key.pem

# Request signing by the root
echo "Request that the intermediate CA key be signed by the root..."
INTERMEDIATE_SUBJECT=$(build_subject "$COUNTRY_CODE" "$STATE_NAME" "$LOCALITY_NAME" "$ORGANISATION_NAME" "$INTERMEDIATE_ORGANISATION_UNIT" "$INTERMEDIATE_COMMON_NAME" "$EMAIL_ADDRESS" )
openssl req -config $OUTPUT_DIR/ca/intermediate/openssl.conf -new -sha256 \
      -key private/intermediate.key.pem \
      -subj "$INTERMEDIATE_SUBJECT" \
      $INTERMEDIATE_PASSIN \
      -out intermediate.csr.pem

cd ..

####################################################################
# Link the intermediate to the root

# Sign the subordinate CA cert
echo "Root CA signing the intermediate certificate..."
yes | openssl ca -config $OUTPUT_DIR/ca/root/openssl.conf -extensions v3_intermediate_ca \
      -days $INTERMEDIATE_CA_DAYS -notext -md sha256 \
      $ROOT_PASSIN \
      -in intermediate/intermediate.csr.pem \
      -out intermediate/certs/intermediate.cert.pem

# Check the generated cert
echo "Checking the intermediate certificate..."
openssl x509 -noout -text -in intermediate/certs/intermediate.cert.pem

# Verify the generated cert
echo "Verifying the intermediate certificate against the root certificate..."
openssl verify -CAfile root/certs/root.cert.pem \
      intermediate/certs/intermediate.cert.pem

# Create the certificate chain
echo "Creating the certificate chain..."
cat intermediate/certs/intermediate.cert.pem \
      root/certs/root.cert.pem > intermediate/certs/intermediate-chain.cert.pem
chmod 444 intermediate/certs/intermediate-chain.cert.pem

