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

BASE_CERT_MD5_DIR=/etc/letsencrypt-whm
BASE_CERT_MD5_DOMAIN_DIR=$BASE_CERT_MD5_DIR/$DOMAIN_NAME
CERT_MD5_DIR=$BASE_CERT_MD5_DOMAIN_DIR/md5
CERT_MD5_FILE=$CERT_MD5_DIR/cert

install_cert() {
    URLENCODE_CA=$(cat $CA_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
    URLENCODE_CERT=$(cat $CERT_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
    URLENCODE_PRIVKEY=$(cat $PRIV_KEY_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")

    # install new certificate
    whmapi1 installssl \
            domain=$DOMAIN_NAME \
            crt=$URLENCODE_CERT \
            key=$URLENCODE_PRIVKEY \
            cab=$URLENCODE_CA \
            enable_sni_for_mail=1
    
    #update md5 file with new md5 checksum value
    md5sum "$CERT_FILE" > $CERT_MD5_FILE
}

if [ ! -d "$BASE_CERT_MD5_DIR" ]; then
    #dir not exists, create one
    mkdir "$BASE_CERT_MD5_DIR"
fi

if [ ! -d "$BASE_CERT_MD5_DOMAIN_DIR" ]; then
    #dir not exists, create one
    mkdir "$BASE_CERT_MD5_DOMAIN_DIR"
fi

if [ ! -d "$CERT_MD5_DIR" ]; then
    #dir not exists, create one
    mkdir "$CERT_MD5_DIR"
fi

if [ ! -f "$CERT_MD5_FILE" ]; then
    #no md5 file, so just install ssl certificate
    install_cert
else 
    ORIGINAL_HASH_VALUE=$(cat "$CERT_MD5_FILE")
    HASH_VALUE=$(md5sum "$CERT_FILE")
    if [ "$ORIGINAL_HASH_VALUE" != "$HASH_VALUE" ]; then
        #hash value is changed so install new ssl certificate
        install_cert
    fi
fi
