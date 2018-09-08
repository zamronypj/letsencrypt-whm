#!/bin/bash

#------------------------------------------------------------------------------
# Run certbot-auto to renew Let's Encrypt SSL installed certificate
# and install new certificate into WHM-based Linux server
#
# Example usage:
#
# ./letsencrypt.whm.renew.sh
#
# @author Zamrony P. Juhara <zamronypj@yahoo.com>
#------------------------------------------------------------------------------

if [[ -z "${CERTBOT_EXEC}" ]]; then
    CERTBOT_BIN="certbot-auto"
else
    CERTBOT_BIN="${CERTBOT_EXEC}"
fi

if [[ -z "${WHMAPI_EXEC}" ]]; then
    WHMAPI_BIN="whmapi1"
else
    WHMAPI_BIN="${WHMAPI_EXEC}"
fi

BASE_LETSENCRYPT_CERT_DIR=/etc/letsencrypt/live
BASE_CERT_MD5_DIR=/etc/letsencrypt-whm

if [ ! -d "$BASE_CERT_MD5_DIR" ]; then
    #dir not exists, create one
    mkdir "$BASE_CERT_MD5_DIR"
fi

install_cert() {
    DOMAIN_NAME=$1
    LETSENCRYPT_CERT_DIR=$BASE_LETSENCRYPT_CERT_DIR/$DOMAIN_NAME
    CERT_FILE=$LETSENCRYPT_CERT_DIR/cert.pem
    CA_FILE=$LETSENCRYPT_CERT_DIR/chain.pem
    PRIV_KEY_FILE=$LETSENCRYPT_CERT_DIR/privkey.pem

    BASE_CERT_MD5_DOMAIN_DIR=$BASE_CERT_MD5_DIR/$DOMAIN_NAME
    CERT_MD5_DIR=$BASE_CERT_MD5_DOMAIN_DIR/md5
    CERT_MD5_FILE=$CERT_MD5_DIR/cert

    URLENCODE_CA=$(cat $CA_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
    URLENCODE_CERT=$(cat $CERT_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")
    URLENCODE_PRIVKEY=$(cat $PRIV_KEY_FILE | php -r "echo urlencode(file_get_contents('php://stdin'));")


    if [ ! -d "$BASE_CERT_MD5_DOMAIN_DIR" ]; then
        #dir not exists, create one
        mkdir "$BASE_CERT_MD5_DOMAIN_DIR"
    fi

    if [ ! -d "$CERT_MD5_DIR" ]; then
        #dir not exists, create one
        mkdir "$CERT_MD5_DIR"
    fi

    if [ ! -f "$CERT_MD5_FILE" ]; then
        #md5 file not exists, create one
        touch "$CERT_MD5_FILE"
    fi

    ORIGINAL_HASH_VALUE=$(cat "$CERT_MD5_FILE")
    HASH_VALUE=$(md5sum "$CERT_FILE")
    if [ "$ORIGINAL_HASH_VALUE" != "$HASH_VALUE" ]; then
        echo "Install certificate for $DOMAIN_NAME"
        # install certificate
        whm_output=$($WHMAPI_BIN installssl \
                --output=json \
                domain=$DOMAIN_NAME \
                crt=$URLENCODE_CERT \
                key=$URLENCODE_PRIVKEY \
                cab=$URLENCODE_CA \
                enable_sni_for_mail=1)
        echo "$whm_output" | php -r "echo json_decode(file_get_contents('php://stdin'))->result[0]->statusmsg;"

        #update md5 file with new md5 checksum value
        echo "$HASH_VALUE" > $CERT_MD5_FILE
    fi
}


$CERTBOT_BIN renew

for f in "$BASE_LETSENCRYPT_CERT_DIR"/*; do
    if [[ -d "$f" && ! -L "$f" ]]; then
        domain_name=$(basename "$f")
        # domain_name is a directory and it is domain name
        install_cert $domain_name
    fi
done
