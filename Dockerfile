FROM ubuntu:18.04

ENV TZ=Asia/Shanghai LANG=C.UTF-8 DEBIAN_FRONTEND=noninteractive php=php-7.2 ver=7.2.23

RUN sed -i -e 's@ .*.ubuntu.com@ http://mirrors.aliyun.com@g' -e 's@ .*.debian.org@ http://mirrors.aliyun.com@g' /etc/apt/sources.list ;\
    apt-get update ; apt-get install -y --no-install-recommends ca-certificates curl wget apt-transport-https tzdata \
    dumb-init iproute2 iputils-ping iputils-arping telnet less vim-tiny unzip gosu fonts-dejavu-core tcpdump \
    net-tools socat netcat traceroute jq mtr-tiny dnsutils psmisc \
    cron logrotate runit rsyslog-kafka gosu bsdiff libtcnative-1 libjemalloc-dev ; \
    groupmod -g 99 nogroup && groupadd -o -g 99 nobody  && usermod -u 99 -g 99 nobody && useradd -u 8080 -s /bin/bash -o java ; \
    mkdir -p ~/.pip && echo [global] > ~/.pip/pip.conf && echo "index-url = https://pypi.tuna.tsinghua.edu.cn/simple" >> ~/.pip/pip.conf ;  \
    echo registry=http://npmreg.mirrors.ustc.edu.cn/ > ~/.npmrc ; \
    sed -i -e 's@ .*.ubuntu.com@ http://mirrors.aliyun.com@g' -e 's@ .*.debian.org@ http://mirrors.aliyun.com@g' /etc/apt/sources.list ;\
    sed -i '/session    required     pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/cron ;\
    sed -i 's/^module(load="imklog"/#module(load="imklog"/g' /etc/rsyslog.conf ;\
    mkdir -p /etc/service/cron /etc/service/syslog ;\
    bash -c 'echo -e "#!/bin/bash\nexec /usr/sbin/rsyslogd -n" > /etc/service/syslog/run' ;\
    bash -c 'echo -e "#!/bin/bash\nexec /usr/sbin/cron -f" > /etc/service/cron/run' ;\
    chmod 755 /etc/service/cron/run /etc/service/syslog/run 
 
ADD . /opt/

WORKDIR /opt

RUN apt-get install -y libargon2-0-dev libnghttp2-dev build-essential cmake xz-utils perl-base libmagickwand-dev \
       imagemagick librabbitmq-dev libxml2-dev libc6-dev autoconf  libevent-dev libsodium-dev libssl-dev \
       libmcrypt-dev libcurl4-openssl-dev libmemcached-dev re2c libpcre3-dev libwebp-dev mysql-client libpq-dev libpqxx-dev ;\
     test -f php-$ver.tar.xz && tar Jtf php-$ver.tar.xz || wget -c http://www.php.net/distributions/php-$ver.tar.xz  ;\
     tar Jxf php-$ver.tar.xz  && cd php-$ver ;\
     configure="./configure --prefix=/app/$php --enable-sockets --enable-soap --enable-zip \
     --enable-zend-signals --enable-mysqlnd --with-mysqli --enable-opcache --enable-pcntl \
     --enable-embedded-mysqli --enable-mbstring --enable-intl --enable-exif \
     --enable-calendar --enable-bcmath  --enable-fpm \
     --with-fpm-user=nobody --with-fpm-group=nobody \
     --with-mcrypt --enable-re2c-cgoto \
     --disable-short-tags --enable-ftp --with-mysql --with-mysqli --with-pdo-mysql \
     --with-zlib --with-gd --with-freetype-dir=/usr --enable-shmop --enable-sysvsem --with-mhash \
     --with-xmlrpc  --with-jpeg-dir  --with-png-dir --with-webp-dir \
     --enable-phpdbg=no \
     --with-pdo-pgsql --with-pgsql \
     --with-config-file-path=/app/$php/etc --with-config-file-scan-dir=/app/$php/etc/conf.d \
     --with-password-argon2 --with-curl --with-openssl --with-iconv" ;\
    eval $configure ;\
    make -j8 && make install && cp php.ini-production /app/$php/etc/php.ini ;\
    test -d /app/php || ln -s /app/$php /app/php ;\
    mkdir -p /etc/service/php ; \
    bash -c 'echo -e "#!/bin/bash\nexec /app/php/sbin/php-fpm --nodaemonize --fpm-config /app/php/etc/php-fpm.conf" > /etc/service/php/run' ; \
    chmod 755 /etc/service/php/run ;\
    echo -e '\n\n\n\n\n\n\n\n\n' | /app/php/bin/pecl install -f amqp imagick mcrypt memcached mongodb redis; \
    mkdir -p /etc/service/php /run/php ; \
    sed -i -e 's?^error_log =.*?error_log = /dev/stderr?g' /app/$php/etc/php-fpm.conf.default ;\
    grep -v '^;' /app/php-72/etc/php-fpm.conf.default | grep -v '^$' > /app/$php/etc/php-fpm.conf ;\
    sed -i -e 's/^listen =.*/listen = 0.0.0.0:9000/g' -e 's/www-data/nobody/g' /app/$php/etc/php-fpm.d/www.conf.default ;\
    grep -v '^;' /app/$php/etc/php-fpm.d/www.conf.default| grep -v '^$'  > /app/$php/etc/php-fpm.d/www.conf ;\
    bash -c 'echo -e "extension=amqp.so\nextension=imagick.so\nextension=mcrypt.so\nextension=memcached.so\nextension=mongodb.so\nextension=redis.so\n" >> /app/$php/etc/conf.d/99-php.ini' ;\
    bash -c 'echo -e "expose_php=Off\n;upload_max_filesize=80M\npost_max_size=80M\ndate.timezone=Asia/Shanghai" >> /app/$php/etc/conf.d/99-php.ini' ;\
    apt-get clean  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /opt/*


 
 CMD ["runsvdir", "/etc/service"]
