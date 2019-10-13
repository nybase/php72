ver=7.2.23
wget -c http://www.php.net/distributions/php-$ver.tar.xz

docker build -t nybase/php72 .
