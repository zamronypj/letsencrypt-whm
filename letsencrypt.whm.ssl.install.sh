#!/bin/bash

#------------------------------------------------------------------------------
# Run certbot-auto to generate Let's Encrypt SSL certificate
# and install generated certificate into WHM-based Linux server
#
# Example usage:
#
# ./letsencrypt.whm.ssl.install.sh /home/username0/public_html example.com
#
# @author Zamrony P. Juhara <zamronypj@yahoo.com>
#------------------------------------------------------------------------------

if [[ -z "${CERTBOT_EXEC}" ]]; then
    CERTBOT_BIN="certbot-auto"
else
  CERTBOT_BIN="${CERTBOT_EXEC}"
fi

WORKING_DIR=$1
DOMAIN_NAME=$2

$CERTBOT_BIN --webroot -w $WORKING_DIR -d $DOMAIN_NAME certonly

LETSENCRYPT_CERT_DIR=/etc/letsencrypt/live/$DOMAIN_NAME
CERT_FILE=$LETSENCRYPT_CERT_DIR/cert.pem
CA_FILE=$LETSENCRYPT_CERT_DIR/chain.pem
PRIV_KEY_FILE=$LETSENCRYPT_CERT_DIR/privkey.pem

URLENCODE_CA=$(cat $CA_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
URLENCODE_CERT=$(cat $CERT_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
URLENCODE_PRIVKEY=$(cat $PRIV_KEY_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")

whmapi1 installssl \
        domain=$DOMAIN_NAME \
        crt=$URLENCODE_CERT \
        key=$URLENCODE_PRIVKEY \
        cab=$URLENCODE_CA \
        enable_sni_for_mail=1
