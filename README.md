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

#### Configuration

Create a file `portofino.cfg` next to the script:

    HTPASSWD_USER="docker"
    HTPASSWD_PASS="secret"
    SSL_COUNTRY="DE"
    SSL_STATE="Berlin"
    SSL_LOCATION="Berlin"
    SSL_ORGANISATION="Portofino"
    SSL_ORGANISATION_UNIT="Portofino"
    SSL_COMMON_NAME="localhost"

If you leave out any of the above variables, portofino.sh will prompt you for them.
