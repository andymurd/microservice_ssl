# Client-side SSL Certificate Authority

In cases where an application makes use of microservices that are exposed to the public Internet, it is wise to secure access to those microservices. 

Using SSL Client Certificates is a great way to restrict access to only authenticated clients. See this excelent post for a discussion and nginx setup information:

https://www.curry-software.com/en/blog/authenticate_and_encrypt_microservice_communication/

This repo provides scripts to initialise a simple certificate authority, with root and intermediate certificates; and another to sign a supplied key. Each script has a short configuration section at the top, that you will want to change to suit your needs.

The scripts make use of OpenSSL and have been tested on Ubuntu 176.04 only. They were developed using the commands described here:

https://jamielinux.com/docs/openssl-certificate-authority/

This repo will NOT implement any kind of best practices for public CAs, and you should only use it at your own risk.

## Usage - Initialise Your CA

First, set up your CA by executing `build.sh`. Follow the prompts and after a
successful run, you will have a directory named `ca` with a root and intermediate
keys and certificates.

You may override the following variables to customise your CA:

* `ORGANISATION_DOMAIN` The domain name of your organisation, e.g. `example.com`
* `OUTPUT_DIR` The directory in which the `ca` output directory will be created
* `COUNTRY_CODE` The two-letter country code in which your orrganisation resides, e.g. `US`
* `STATE_NAME` The name of the state in which your orrganisation resides, e.g. `WA`
* `LOCALITY_NAME` The name of the city in which your orrganisation resides, e.g. `Perth`
* `EMAIL_ADDRESS` The email address that should be used to contact you with questions about your CA
* `ROOT_KEY_PASSWORD` You can set this instead of entering the passphrase every time your root key is used
* `INTERMEDIATE_KEY_PASSWORD` You can set this instead of entering the passphrase every time your intermediate key is used

## Usage - Generate a Certificate

Generate a key:

```
openssl genrsa -aes256 -out client.key.pem 2048
```

You might want to remove the passphrase from this key, or alternatively you can supply the passphrase via `CLIENT_KEY_PASSWORD` environment variable. This command will remove the passphrase from your key:

```
openssl rsa -in ./client.key.pem -out ./client-nopass.key.pem
```

Generate the certificate by executing `generate_client_cert.sh`. Pass your key filename as parameter.

You may override the following variables to customise your certificate:

* `ORGANISATION_DOMAIN` The domain name of your organisation, e.g. `example.com`
* `OUTPUT_DIR` The directory in which the `ca` output directory will be created
* `COUNTRY_CODE` The two-letter country code in which your orrganisation resides, e.g. `US`
* `STATE_NAME` The name of the state in which your orrganisation resides, e.g. `WA`
* `LOCALITY_NAME` The name of the city in which your orrganisation resides, e.g. `Perth`
* `EMAIL_ADDRESS` The email address that should be used to contact you with questions about your certificate
* `COMMON_NAME` Allows you to customise the commmon name of the certificate
* `CLIENT_KEY_PASSWORD` You can set this instead of entering the passphrase every time your key is used
* `INTERMEDIATE_KEY_PASSWORD` You can set this instead of entering the passphrase every time your intermediate key is used

The generated certificate can be found in the `ca/intermediate/newcerts/` directory.

## Usage - Revoke a Certificate

Revoke a certificate by executing `generate_client_cert.sh`. Pass your key filename as parameter.

You may override the following variables to customise your certificate:

* `OUTPUT_DIR` The directory in which the `ca` output directory will be created
* `INTERMEDIATE_KEY_PASSWORD` You can set this instead of entering the passphrase every time your intermediate key is used
