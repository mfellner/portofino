FROM nginx:1.9.0

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && \
    apt-get install -y apache2-utils

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD conf/nginx.conf    /etc/nginx/nginx.conf
ADD conf/registry.conf /etc/nginx/conf.d/registry.conf

# Default values for HTTP basic auth
ENV HTPASSWD_USER docker
ENV HTPASSWD_PASS secret

# Default values for SSL certificate
ENV SSL_COUNTRY DE
ENV SSL_STATE Berlin
ENV SSL_LOCATION Berlin
ENV SSL_ORGANISATION Portofino
ENV SSL_ORGANISATION_UNIT Portofino
ENV SSL_COMMON_NAME localhost
ENV SSL_EXPIRY 9999

ADD docker-run.sh docker-run.sh
RUN chmod +x docker-run.sh

EXPOSE 5000

ENTRYPOINT ["./docker-run.sh"]
