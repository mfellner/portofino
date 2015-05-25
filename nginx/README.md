# Portofino-proxy
NGINX proxy for Portofino private Docker registry

Based on:
* [https://docs.docker.com/registry/deploying]()
* [https://github.com/docker/distribution/tree/master/contrib/compose/nginx]()

## Usage

#### Build and run Docker container

    docker build -t portofino-proxy .

    docker run -d \
               -e HTPASSWD_USER=docker \
               -e HTPASSWD_PASS=secret \
               -e SSL_COUNTRY=DE \
               -e SSL_STATE=Berlin \
               -e SSL_LOCATION=Berlin \
               -e SSL_ORGANISATION=Portofino \
               -e SSL_ORGANISATION_UNIT=Portofino \
               -e SSL_COMMON_NAME=localhost \
               -e SSL_EXPIRY=9999 \
               -p 5000:5000 \
               --link portofino:registry-alias \
               --name portofino-proxy \
               portofino-proxy:latest

Explanation of environment variabes:

* `HTPASSWD_USER` is the username for HTTP basic authentication.
* `HTPASSWD_PASS` is the password for HTTP basic authentication.
* `SSL_*` are the fields for the self-signed SSL certificate.
* `SSL_COMMON_NAME` must be the domain-name of your server.

Explanation of `--link` parameter:

* `portofino` is the name of the Portofino private Docker registry container.
* `registry-alias` is the internally used alias for the registry container.

Test if you can reach your private Docker registry through the Nginx proxy:

    curl -u docker:secret https://localhost:8080/v2/

    docker login https://localhost:8080

* `docker:secret` is the username and password set in the `htpasswd` file.
* `localhost` is the address of the server that your Nginx proxy is running on.

## Provide your own files (not yet implemented)

#### Generate basic authentication htpasswd file

    htpasswd -c docker-registry.htpasswd docker

* Creates a `htpasswd` file for the user `docker`

#### Generate certificate

    openssl req -newkey rsa:4096 -nodes -keyout certs/portofino.key \
    -x509 -days 9999 -out certs/portofino.crt

* Creates a self-signed SSL certificate.

#### GitHub issues

* https://github.com/docker/distribution/issues/452
* https://github.com/docker/distribution/issues/397
