FROM debian:9

ARG version

RUN set -x && \
    mkdir -p /usr/local/src/nginx && \
    mkdir -p /usr/local/src/modsecurity && \
    mkdir -p /etc/nginx/conf.d && \
    mkdir -p /etc/modsecurity

ADD provision/src-sources.list /etc/apt/sources.list.d/src-sources.list

RUN set -x && \
    cd /usr/local/src/nginx && \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y apache2-dev libxml2-dev curl build-essential libpcre3-dev libghc-zlib-dev libssl-dev && \
    apt-get source -y nginx && \
    cd /usr/local/src/modsecurity && \
    curl  -L https://github.com/SpiderLabs/ModSecurity/releases/download/v$version/modsecurity-$version.tar.gz > modsecurity.tar.gz 2> /dev/null  && \
    tar xzf modsecurity.tar.gz && \
    rm modsecurity.tar.gz && \
    cd /usr/local/src/modsecurity/modsecurity-$version && \
    ./configure --enable-standalone-module --disable-mlogc && \
    make && \
    cd /usr/local/src/nginx && \
    cd "$(ls -l | grep -E '^d' | awk '{print $9}')" && \
    ./configure --prefix=/usr/local/nginx \
        --sbin-path=/usr/local/bin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/lock/nginx.lock \
        --with-http_stub_status_module \
        --without-http_ssi_module \
        --without-http_userid_module \
        --without-http_access_module \
        --without-http_auth_basic_module \
        --without-http_autoindex_module \
        --without-http_geo_module \
        --without-http_map_module \
        --without-http_split_clients_module \
        --without-http_referer_module \
        --without-http_rewrite_module \
        --without-http_fastcgi_module \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --without-http_memcached_module \
        --without-http_empty_gif_module \
        --without-http_browser_module \
        --with-ipv6 \
        --add-module=/usr/local/src/modsecurity/modsecurity-$version/nginx/modsecurity && \
    make && \
    make install && \
    rm -rf /usr/local/src && \
    apt-get autoremove -y && \
    apt-get install libapr1 && \
    apt-get clean -y && \
    apt-get autoclean -y

ADD provision/nginx.conf /etc/nginx/nginx.conf
ADD provision/proxy_params /etc/nginx/proxy_params
ADD provision/index.html /var/www/index.html

ADD provision/modsecurity.conf /etc/modsecurity/modsecurity.conf
ADD provision/unicode.mapping /etc/modsecurity/unicode.mapping

EXPOSE 80

CMD ["/usr/local/bin/nginx"]
