#!/bin/bash

#------------------------------------------------------------------------------
# Install Lets Encrypt SSL certificate into WHM-based Linux server
#
# Note: This script installs existing LetsEncrypt SSl certificate without
# generating new cerfiticate.
#
# Example usage:
#
# ./whm.install.cert.sh [domain name]
#
# @author Zamrony P. Juhara <zamronypj@yahoo.com>
#------------------------------------------------------------------------------


if [[ -z "${WHMAPI_EXEC}" ]]; then
    WHMAPI_BIN="whmapi1"
else
    WHMAPI_BIN="${WHMAPI_EXEC}"
fi

DOMAIN_NAME=$1
LETSENCRYPT_CERT_DIR=/etc/letsencrypt/live/$DOMAIN_NAME
CERT_FILE=$LETSENCRYPT_CERT_DIR/cert.pem
CA_FILE=$LETSENCRYPT_CERT_DIR/chain.pem
PRIV_KEY_FILE=$LETSENCRYPT_CERT_DIR/privkey.pem

URLENCODE_CA=$(cat $CA_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
URLENCODE_CERT=$(cat $CERT_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
URLENCODE_PRIVKEY=$(cat $PRIV_KEY_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")

whm_output=$($WHMAPI_BIN installssl \
        --output=json \
        domain=$DOMAIN_NAME \
        crt=$URLENCODE_CERT \
        key=$URLENCODE_PRIVKEY \
        cab=$URLENCODE_CA \
        enable_sni_for_mail=1)
echo "$whm_output" | php -r "echo json_decode(file_get_contents('php://stdin'))->result[0]->statusmsg;"
