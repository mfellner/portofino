# Portofino
Private Docker registry and secure proxy.
[![build status](https://circleci.com/gh/mfellner/portofino.svg?style=svg)](https://circleci.com/gh/mfellner/portofino)

## Description

Portofino is a private Docker registry with a secure NGINX reverse-proxy in front of it.
It was designed to run on CoreOS but also works in other environments.

## Quick start

    export DOCKER_USER=mfellner
    export PORTOFINO_URL=https://raw.githubusercontent.com/mfellner/portofino/master/portofino.sh
    bash <(curl -sSL $PORTOFINO_URL) install start -y

## Build from source

    ./portofino.sh (build|start|stop|install|uninstall)

## Configuration

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
