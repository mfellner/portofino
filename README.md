# Portofino
Private Docker registry and secure proxy.

## Usage

    ./portofino.sh (install|run|stop)

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
