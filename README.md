Client-side SSL Certificate Authority
=====================================

In cases where an application makes use of microservices that are exposed to the public Internet, it is wise to secure access to those microservices. 

Using SSL Client Certificates is a great way to restrict access to only authenticated clients. See this excelent post for a discussion and nginx setup information:

https://www.curry-software.com/en/blog/authenticate_and_encrypt_microservice_communication/

This repo provides scripts to initialise a simple certificate authority, with root and intermediate certificates; and another to sign a supplied key. Each script has a short configuration section at the top, that you will want to change to suit your needs.

The scripts make use of OpenSSL and have been tested on Ubuntu 176.04 only. They were developed using the commands described here:

https://jamielinux.com/docs/openssl-certificate-authority/

This repo will NOT implement any kind of best practices for public CAs, and you should only use it at your own risk.

