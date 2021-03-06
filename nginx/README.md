# Portofino-proxy
NGINX proxy for Portofino private Docker registry

Based on:
* [https://docs.docker.com/registry/deploying]()
* [https://github.com/docker/distribution/tree/master/contrib/compose/nginx]()

## Usage

#### Build and run Docker container

    docker build -t portofino/portofino-proxy .

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
               -v /home/docker/certs:/etc/portofino/certs \
               --link portofino:registry-alias \
               --name portofino-proxy \
               portofino/portofino-proxy:latest

Explanation of environment variables:

* `HTPASSWD_USER` is the username for HTTP basic authentication.
* `HTPASSWD_PASS` is the password for HTTP basic authentication.
* `SSL_*` are the fields for the self-signed SSL certificate.
* `SSL_COMMON_NAME` must be the domain-name of your server.
* `-v /home/docker/certs:`
  * Local directory to persist the SSL certificate and private key (optional).
  * You can provide an existing .crt and .key pair for your domain.
  * Otherwise, Portofino will create a self-signed certificate and place it in the directory.
  * If no `-v` volume is provided, the created certificate will not be persisted.
* `--link`:
  * `portofino` is the name of the Portofino private Docker registry container.
  * `registry-alias` is the internally used alias for the registry container.

Test if you can reach your private Docker registry through the nginx proxy:

    curl -u docker:secret https://localhost:5000/v2/
    docker login https://localhost:5000

* `docker:secret` is the username and password set in the `htpasswd` file.
* `localhost` is the address of the server that your nginx proxy is running on.

## Provide your own htpasswd (not yet supported), certificate and private key

#### Generate basic authentication htpasswd file

    htpasswd -c docker-registry.htpasswd docker

Creates a `htpasswd` file for the user `docker`

#### Generate certificate

    openssl req -newkey rsa:4096 -nodes -keyout ~/certs/portofino.key \
    -x509 -days 9999 -out ~/certs/portofino.crt

Creates a self-signed SSL certificate.

## GitHub issues

* https://github.com/docker/distribution/issues/452
* https://github.com/docker/distribution/issues/397
