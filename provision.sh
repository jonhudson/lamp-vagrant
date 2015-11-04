#!/bin/bash

### CHECK THESE DEFAULTS!

MYSQL_ROOT_PW="root"
DOC_ROOT="/var/www/public"

SYSTEM_PACKAGES=(git curl vim)

ADDITIONAL_PHP_PACKAGES=(php5-mcrypt php5-curl)

PATH_TO_VHOST="/etc/apache2/sites-available/000-default.conf"

echo "================================="
echo "        BEGIN PROVISIONING       "
echo "================================="

sudo apt-get update
sudo apt-get -y install ${SYSTEM_PACKAGES[@]}

echo "###### INSTALLING APACHE ########"

sudo apt-get -y install apache2 libapache2-mod-php5
sudo a2enmod rewrite

if ! [ -L /var/www ]
then
    rm -rf /var/www
    ln -sf /vagrant /var/www
fi

sudo sed -i 's|/var/www/html|'"${DOC_ROOT}"'|' "${PATH_TO_VHOST}"

sudo service apache2 restart

echo "###### INSTALLING MYSQL ########"

sudo debconf-set-selections <<< "mysql-server \
 mysql-server/root_password password ${MYSQL_ROOT_PW}"

sudo debconf-set-selections <<< "mysql-server \
 mysql-server/root_password_again password ${MYSQL_ROOT_PW}"

sudo apt-get -y install mysql-server php5-mysql
sudo service mysql restart

echo "###### INSTALLING PHP ########"

sudo apt-get -y install php5 php5-cli
sudo apt-get -y install ${ADDITIONAL_PHP_PACKAGES[@]}
sudo apt-get -y install php-pear php5-dev

for ini in $(sudo find /etc -name "php.ini")
do
    errRep=$(grep "^error_reporting = " "${ini}")
    sed -i "s/${errRep}/error_reporting = E_ALL/" ${ini}

    dispErr=$(grep "^display_errors = " "${ini}")
    sed -i "s/${dispErr}/display_errors = On/" ${ini}

    dispStrtErr=$(grep "^display_startup_errors = " "${ini}")
    sed -i "s/${dispStrtErr}/display_startup_errors = On/" ${ini}
done

echo "###### INSTALLING XDEBUG ########"

sudo pecl install xdebug
xdbg_path=$(find / -name 'xdebug.so' 2> /dev/null)

if ! [ -d /etc/php5/conf.d ] && ! [ -e /etc/php5/conf.d ]
then
    sudo mkdir /etc/php5/conf.d
fi

sudo echo "zend_extension=${xdbg_path}" > /etc/php5/conf.d/xdebug.ini
sudo service apache2 restart

echo "###### INSTALLING COMPOSER ########"

curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

echo "###### FINISHED ########"
