FROM php:8.1-apache

# 安装必要的库和扩展
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpng-dev \
        libjpeg-dev \
        libfreetype6-dev \
        libzip-dev \
        && docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install gd pdo_mysql \
    && a2enmod rewrite deflate \
    && sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置工作目录并复制代码
WORKDIR /var/www/html
COPY . .

# 设置权限并暴露端口
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]