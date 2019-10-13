ver=7.2.23
test -f php-$ver.tar.xz && tar Jtf php-7.2.23.tar.xz || wget -c http://www.php.net/distributions/php-$ver.tar.xz

docker build -t nybase/php72 .
