#!/usr/bin/env bash

readonly nginx_dir="/etc/nginx/"
readonly htpasswd_file="portofino.htpasswd"

htpasswd -bc ${nginx_dir}${htpasswd_file} $HTPASSWD_USER $HTPASSWD_PASS

readonly ssl_cert_dir="/etc/ssl/certs/"
readonly ssl_priv_dir="/etc/ssl/private/"
readonly ssl_file="portofino"

readonly ssl_subj=\
"/C="${SSL_COUNTRY}\
"/ST="${SSL_STATE}\
"/L="${SSL_LOCATION}\
"/O="${SSL_ORGANISATION}\
"/OU="${SSL_ORGANISATION_UNIT}\
"/CN="${SSL_COMMON_NAME}

openssl req -newkey rsa:4096 -nodes -keyout ${ssl_priv_dir}${ssl_file}.key \
        -x509 -days 9999 -out ${ssl_cert_dir}${ssl_file}.crt \
        -subj ${ssl_subj}

nginx -g "daemon off;"
