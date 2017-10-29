FROM debian:9

ARG mod_version
ARG rules_version

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
    apt-get install -y rename apache2-dev libxml2-dev curl build-essential libpcre3-dev libghc-zlib-dev libssl-dev && \
    apt-get source -y nginx && \
    cd /usr/local/src/modsecurity && \
    curl  -L https://github.com/SpiderLabs/ModSecurity/releases/download/v$mod_version/modsecurity-$mod_version.tar.gz > modsecurity.tar.gz 2> /dev/null  && \
    tar xzf modsecurity.tar.gz && \
    rm modsecurity.tar.gz && \
    cd /usr/local/src/modsecurity/modsecurity-$mod_version && \
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
        --add-module=/usr/local/src/modsecurity/modsecurity-$mod_version/nginx/modsecurity && \
    make && \
    make install && \
    rm -rf /usr/local/src && \
    apt-get purge -y \
            apache2-dev libxml2-dev build-essential libpcre3-dev libghc-zlib-dev libssl-dev \
            autoconf automake autopoint autotools-dev binutils cpp \
            cpp-6 debhelper dh-autoreconf dh-strip-nondeterminism dpkg-dev \
            g++ g++-6 gcc gcc-6 icu-devtools \
            intltool-debian \
            libbsd-dev libc-dev-bin libc6-dev \
            libdpkg-perl libexpat1-dev libffi-dev \
            libgcc-6-dev libgmp-dev \
            libicu-dev libldap2-dev libltdl-dev \
            libncurses5-dev libsctp-dev libssl-doc libstdc++-6-dev libtinfo-dev \
            linux-libc-dev man-db manpages-dev po-debconf \
            sgml-base uuid-dev zlib1g-dev && \
    apt-get clean -y && \
    apt-get autoclean -y

RUN set -x && \
    mkdir -p /tmp/rules && \
    cd /tmp/rules && \
    curl  -L https://github.com/SpiderLabs/owasp-modsecurity-crs/archive/v$rules_version.tar.gz > rules.tar.gz 2> /dev/null  && \
    tar xzf rules.tar.gz && \
    cp -r owasp-modsecurity-crs-$rules_version/rules /etc/modsecurity/rules && \
    rm -rf /tmp/rules && \
    cd /etc/modsecurity/rules && \
    find . -name '*.example' | prename 's/\.example//'

ADD provision/nginx.conf /etc/nginx/nginx.conf
ADD provision/proxy_params /etc/nginx/proxy_params
ADD provision/index.html /var/www/index.html

ADD provision/crs-setup.conf /etc/modsecurity/crs-setup.conf
ADD provision/modsecurity.conf /etc/modsecurity/modsecurity.conf
ADD provision/unicode.mapping /etc/modsecurity/unicode.mapping

RUN set -x && \
    ln -s /dev/stdout /var/log/nginx/access.log && \
    ln -s /dev/stderr /var/log/nginx/error.log

RUN set -x && \
    mkdir -p /var/asl/data/audit && \
    chown nobody /var/asl/data/audit

EXPOSE 80

CMD ["/usr/local/bin/nginx"]
