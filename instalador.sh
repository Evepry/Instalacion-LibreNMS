#!/bin/bash

#Preparacion para instalar LibreNMS
#Instalacion realizada en Ubuntu LTS 22.04
#PASO 1
#Paquetes requeridos para instalacion
#(acl,git,graphviz,mariadb,php,nginx,json,snmp, unzip,pyton,imagemagick,mtr-tiny)

apt install acl curl fping git graphviz imagemagick mariadb-client mariadb-server mtr-tiny nginx-full nmap php-cli php-curl php-fpm php-gd php-gmp php-json php-mbstring php-mysql php-snmp php-xml php-zip rrdtool snmp snmpd whois unzip python3-pymysql python3-dotenv python3-redis python3-setuptools python3-systemd python3-pip

#PASO 2
#Agregamos el usuario librenms

useradd librenms -d /opt/librenms -M -r -s "$(which bash)"

#PASO 3
#Descargamos LibreNMS desde el repositorio

cd /opt
git clone https://github.com/librenms/librenms.git

#PASO 4
#Agregamos permisos al usuario y carpetas LibreNMS

chown -R librenms:librenms /opt/librenms
chmod 771 /opt/librenms
setfacl -d -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/
setfacl -R -m g::rwx /opt/librenms/rrd /opt/librenms/logs /opt/librenms/bootstrap/cache/ /opt/librenms/storage/

#PASO 5
#Insatalamos dependencias de PHP
#Ingresamos al modo superusurio del usuario Librenms

su - librenms

./scripts/composer_wrapper.php install --no-dev

exit

#Si el escript falla, realizarlo manualmente

wget https://getcomposer.org/composer-stable.phar
mv composer-stable.phar /usr/bin/composer
chmod +x /usr/bin/composer

#PASO 6
#Cambiamos Zona horaria
#See https://php.net/manual/en/timezones.php for a list of supported timezones. Valid examples are: "America/New_York", "Australia/Brisbane", "Etc/UTC". Ensure date.timezone is set in php.ini to your preferred time zone.

nano /etc/php/8.1/fpm/php.ini
nano /etc/php/8.1/cli/php.ini

timedatectl

#PASO 7
#Configuramos la base de datos MariaDB

nano /etc/mysql/mariadb.conf.d/50-server.cnf

#Within the [mysqld] section add:
#innodb_file_per_table=1
#lower_case_table_names=0

systemctl enable mariadb
systemctl restart mariadb

mysql -u root

#Cambiar 'password' a contraseña a utilizar

CREATE DATABASE librenms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'librenms'@'localhost' IDENTIFIED BY '1234';
GRANT ALL PRIVILEGES ON librenms.* TO 'librenms'@'localhost';
FLUSH PRIVILEGES;

exit

#PASO 8
#Configuramos PHP-FPM

cp /etc/php/8.1/fpm/pool.d/www.conf /etc/php/8.1/fpm/pool.d/librenms.conf
nano /etc/php/8.1/fpm/pool.d/librenms.conf

#Change [www] to [librenms]:
#[librenms]
#Change user and group to "librenms":
#user = librenms
#group = librenms
#Change listen to a unique name:
#listen = /run/php-fpm-librenms.sock

#PASO 9
#Configuramos el servidor web NGINX

nano /etc/nginx/conf.d/librenms.conf

#Agregamos el siguiente codigo en html

#server {
# listen      80;
# server_name librenms.example.com;
# root        /opt/librenms/html;
# index       index.php;
#
# charset utf-8;
# gzip on;
# gzip_types text/css application/javascript text/javascript application/x-javascript image/svg+xml text/plain text/xsd text/xsl text/xml image/x-icon;
# location / {
#  try_files $uri $uri/ /index.php?$query_string;
# }
# location ~ [^/]\.php(/|$) {
#  fastcgi_pass unix:/run/php-fpm-librenms.sock;
#  fastcgi_split_path_info ^(.+\.php)(/.+)$;
#  include fastcgi.conf;
# }
# location ~ /\.(?!well-known).* {
#  deny all;
# }
#}

rm /etc/nginx/sites-enabled/default

systemctl restart nginx
systemctl restart php8.1-fpm

#PASO 10
#Completamos los comandos habilitados de lnms

ln -s /opt/librenms/lnms /usr/bin/lnms
cp /opt/librenms/misc/lnms-completion.bash /etc/bash_completion.d/

#PASO 11
#Configuramos el snmpd

cp /opt/librenms/snmpd.conf.example /etc/snmp/snmpd.conf

nano /etc/snmp/snmpd.conf

#Cambiamos RANDOMSTRINGGOESHERE por el nombre de comunidad

curl -o /usr/bin/distro https://raw.githubusercontent.com/librenms/librenms-agent/master/snmp/distro
chmod +x /usr/bin/distro

systemctl enable snmpd
systemctl restart snmpd

#PASO 12
#Trabajamos Cron

cp /opt/librenms/librenms.nonroot.cron /etc/cron.d/librenms

#PASO 13
#Copiamos la configuracion logrotate

cp /opt/librenms/misc/librenms.logrotate /etc/logrotate.d/librenms

#PASO 14
#Instalacion web
#ingresamos a la pagina

http://librenms.example.com/install

chown librenms:librenms /opt/librenms/config.php

#PASO 15
#Solucion de problemas

sudo su - librenms

./validate.php

echo "TODO INSTALADO CORRECTAMENTE"

exit
