#!/usr/bin/env bash

dir_exists() { if [ -d $1 ]; then echo true; else echo false; fi }

file_count() { echo $(ls -1 $@ 2> /dev/null | wc -l); }

echo "Creating htpasswd file..."

readonly nginx_dir="/etc/nginx/"
readonly htpasswd_file="portofino.htpasswd"

htpasswd -bc ${nginx_dir}${htpasswd_file} $HTPASSWD_USER $HTPASSWD_PASS

echo "SSL certificate..."

readonly nginx_cert_dir="/etc/ssl/certs"
readonly nginx_priv_dir="/etc/ssl/private"
readonly ssl_file="portofino"
readonly ssl_bits="4096"

if [ -z $SSL_CERTS_DIR ]; then
  echo "Warning, \$SSL_CERTS_DIR not set. Using default value.";
  readonly SSL_CERTS_DIR="/etc/portofino/certs"
fi

if $(dir_exists ${SSL_CERTS_DIR}); then
  if [ $(file_count ${SSL_CERTS_DIR}/{*.crt,*.key}) -gt 2 ]; then
    echo "Ambiguous files in ${SSL_CERTS_DIR}. Aborting."; exit 1;
  fi
else
  echo "Warning, ${SSL_CERTS_DIR} does not exist. Creating empty directory.";
  mkdir -p ${SSL_CERTS_DIR}
fi

if [ $(file_count ${SSL_CERTS_DIR}/{*.crt,*.key}) == 2 ]; then
  echo "Using existing SSL certificate $(ls -1 ${SSL_CERTS_DIR}/*.crt)."
else
  echo "Creating self-signed SSL certificate..."

  readonly ssl_subj=\
"/C="${SSL_COUNTRY}\
"/ST="${SSL_STATE}\
"/L="${SSL_LOCATION}\
"/O="${SSL_ORGANISATION}\
"/OU="${SSL_ORGANISATION_UNIT}\
"/CN="${SSL_COMMON_NAME}

  openssl req -newkey rsa:${ssl_bits} -nodes -keyout ${SSL_CERTS_DIR}/${ssl_file}.key \
          -x509 -days ${SSL_EXPIRY} -out ${SSL_CERTS_DIR}/${ssl_file}.crt \
          -subj ${ssl_subj}

  touch ${SSL_CERTS_DIR}/GENERATED_PORTOFINO_FILES
fi

echo "Copying certificate and private key to nginx directory..."
cp ${SSL_CERTS_DIR}/*.crt ${nginx_cert_dir}/${ssl_file}.crt
cp ${SSL_CERTS_DIR}/*.key ${nginx_priv_dir}/${ssl_file}.key

echo "Starting nginx..."

nginx -g "daemon off;"
