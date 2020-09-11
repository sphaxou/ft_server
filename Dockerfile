FROM debian:buster

# Install
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y nginx
RUN apt-get install -y php php-fpm php-gd php-mysql  php-cli php-curl php-json php-cgi php-mbstring
RUN apt-get install -y curl mariadb-server wget vim

# Copy
COPY ./srcs/nginx.conf ./
COPY ./srcs/wp-config.php ./
COPY ./srcs/wordpress.sql ./

# Nginx
RUN rm -rf /etc/nginx/sites-enabled/*
RUN mv nginx.conf /etc/nginx/sites-available/
RUN ln -s /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/

# SSL
RUN wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.1/mkcert-v1.4.1-linux-amd64
RUN mv mkcert-v1.4.1-linux-amd64 mkcert && chmod +x mkcert
RUN cp mkcert /usr/local/bin
RUN mkcert -install
RUN mkcert -key-file key.pem -cert-file cert.pem 127.0.0.1 localhost ::1
RUN mv key.pem /etc/ssl/private/key.pem
RUN mv cert.pem /etc/ssl/certs/cert.pem

# MySQL
RUN service mysql start && mysql -u root -e "CREATE DATABASE wordpress;" && mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'admin'@'localhost' IDENTIFIED BY 'password';" && mysql -u root -e "FLUSH PRIVILEGES;" && mysql -u root -e "USE wordpress; SOURCE wordpress.sql;"

# PhpMyAdmin
RUN wget -q https://files.phpmyadmin.net/phpMyAdmin/5.0.2/phpMyAdmin-5.0.2-all-languages.tar.gz
RUN tar xzf phpMyAdmin-5.0.2-all-languages.tar.gz -C /var/www/html/
RUN mv /var/www/html/phpMyAdmin-5.0.2-all-languages /var/www/html/phpmyadmin
RUN sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$(openssl rand -base64 32)'|" /var/www/html/phpmyadmin/config.sample.inc.php > /var/www/html/phpmyadmin/config.inc.php

# Wordpress
RUN wget https://fr.wordpress.org/latest-fr_FR.tar.gz
RUN tar -xzf latest-fr_FR.tar.gz
RUN cp -r wordpress /var/www/html
RUN cp -r wp-config.php /var/www/html/wordpress

# Access
RUN chown -R www-data:www-data /var/www/html/*
RUN chmod -R 755 /var/www/html/*

CMD service mysql start && service nginx start && service php7.3-fpm start && bash
