FROM nginx:1.9.0

# Use Bash as the shell.
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install requirements for the htpasswd command.
RUN apt-get update && \
    apt-get install -y apache2-utils

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add Nginx configuration.
ADD conf/nginx.conf    /etc/nginx/nginx.conf
ADD conf/registry.conf /etc/nginx/conf.d/registry.conf

# Default values for HTTP basic auth.
ENV HTPASSWD_USER docker
ENV HTPASSWD_PASS secret

# Default values for the self-signed SSL certificate.
ENV SSL_COUNTRY DE
ENV SSL_STATE Berlin
ENV SSL_LOCATION Berlin
ENV SSL_ORGANISATION Portofino
ENV SSL_ORGANISATION_UNIT Portofino
ENV SSL_COMMON_NAME localhost
ENV SSL_EXPIRY 9999
ENV SSL_CERTS_DIR /etc/portofino/certs

# Add the run-script.
ADD utils.sh utils.sh
ADD docker-run.sh docker-run.sh
RUN chmod +x docker-run.sh

# Nginx listens on this port.
EXPOSE 5000

ENTRYPOINT ["./docker-run.sh"]
