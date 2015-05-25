# Portofino [![build status](https://circleci.com/gh/mfellner/portofino.svg?style=svg)](https://circleci.com/gh/mfellner/portofino) [![GitHub license](https://img.shields.io/github/license/mfellner/portofino.svg?style=flat-square)](https://github.com/mfellner/portofino/blob/master/LICENSE)

Portofino is a private Docker registry with a secure NGINX reverse-proxy in front of it.
It was designed to run on CoreOS but also works in other environments.

## Usage

#### Quick start

    DOCKER_USER=mfellner bash <(curl -sSL https://raw.githubusercontent.com/mfellner/portofino/master/portofino.sh) install start -y

#### Commands
  * build: Build the Portofino Docker images from source.
  * start: Starts the Portofino Docker containers.
  * stop: Stops the Portofino Docker containers.
  * install: Pulls the Portofino Docker images from the Docker Hub.
  * uninstall: Removes the Portofino Docker images.
  * `-y`: Skip all prompts with "yes"

#### Configuration

You can set the following environment variables to configure portofino.sh:

* `DOCKER_USER` Used as prefix for the Docker image names (default: "portofino")
* `REGISTRY_NAME` Name of the registry image (default: "portofino")
* `NGINX_NAME` Name of the nginx image (default: "portofino-proxy")
* `NGINX_PORT` Exposed port of the nginx container (default: "5000")
* `LOCAL_CERTS_DIR` Directory for persisting the SSL certificate and private key (default: "./certs")
  ** See nginx/README.md for more details.

Create a file `portofino.cfg` next to the script:

    HTPASSWD_USER="docker"
    HTPASSWD_PASS="secret"
    SSL_COUNTRY="DE"
    SSL_STATE="Berlin"
    SSL_LOCATION="Berlin"
    SSL_ORGANISATION="Portofino"
    SSL_ORGANISATION_UNIT="Portofino"
    SSL_COMMON_NAME="localhost"
    SSL_EXPIRY="365"

If you leave out any of the above variables, portofino.sh will prompt you for them.

#### Notes for boot2docker users

Follow these instructions to add a self-signed certificate to boot2docker's trusted CAs:
https://github.com/boot2docker/boot2docker/issues/347#issuecomment-70950789

#### Notes on self-signed certificates on CoreOS

When using `docker login`, docker will inform the user if a certificate is unknown and suggest
to add the file under a location /etc/docker/certs.d/domain:5000/ca.crt. However upon doing so,
the login command yields the following error message instead:

    FATA[0013] Error response from daemon: Server Error:
    Post https://domain:5000/v1/users/: x509: certificate signed by unknown authority

This suggests that the CA would have to be added to `/etc/ssl/certs/ca-certificates.crt`, which
is not possible on a read-only filesystem. As of today, there seems to be no simple solution to
this problem.
