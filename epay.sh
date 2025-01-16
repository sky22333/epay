#!/bin/bash
# 一键部署epay脚本

# 检查是否已经安装 epay
if [ -d "/var/www/html/epay" ]; then
    echo -e "\033[32m检测到 epay 已经安装。\033[0m"
    echo -e "\033[33m如需重新安装，请删除站点文件：/var/www/html/epay 并做好相关备份。\033[0m"
    exit 0
fi

while true; do
    echo -e "\033[33m请输入您的域名(确保已经解析到本机): \033[0m"
    read DOMAIN
    
    echo -e "\033[32m您输入的域名是: $DOMAIN\033[0m"
    echo -e "\033[33m请确认这个域名是否正确 (yes/no, 默认回车确认): \033[0m"
    read CONFIRM
    
    # 如果用户按回车，则默认为确认
    if [[ -z "${CONFIRM// }" ]]; then
        CONFIRM="yes"
    fi
    
    if [[ "${CONFIRM,,}" == "yes" || "${CONFIRM,,}" == "y" ]]; then
        echo -e "\033[32m域名确认成功: $DOMAIN\033[0m"
        break
    else
        echo -e "\033[31m请重新输入域名。\033[0m"
    fi
done

echo -e "\033[32m更新系统包...首次更新可能较慢...请耐心等待。。。\033[0m"
sudo apt-get update -yq

echo -e "\033[32m安装必要的软件包...首次安装可能较慢...请耐心等待。。。\033[0m"
sudo apt-get install -y -q mariadb-server php php-mysql php-fpm php-curl php-json php-cgi php-mbstring php-xml php-gd php-xmlrpc php-soap php-intl php-zip git

sudo systemctl start mariadb
sudo systemctl enable mariadb

sudo mysql_secure_installation <<EOF

y
y
y
y
y
EOF

# 创建epay数据库和用户
DB_NAME="skyepay"
DB_USER="skyeuser"
DB_PASSWORD=$(openssl rand -base64 12)

sudo mysql -u root -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';"
sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# 下载并配置epay
mkdir -p /var/www/html
cd /var/www/html
git clone https://github.com/sky22333/epay.git
rm epay/epay.sh epay/epay.zip epay/README.md

sudo chown -R www-data:www-data /var/www/html/epay
sudo find /var/www/html/epay/ -type d -exec chmod 755 {} \;
sudo find /var/www/html/epay/ -type f -exec chmod 640 {} \;

if [ ! -d /etc/apt/sources.list.d/ ]; then
    sudo mkdir -p /etc/apt/sources.list.d/
fi
sudo apt install -y -q debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update -yq
sudo apt install -y -q caddy

PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')


# 重启PHP-FPM服务
sudo systemctl restart php${PHP_VERSION}-fpm

if systemctl is-active --quiet apache2; then
    sudo systemctl stop apache2
    sudo systemctl disable apache2
else
    echo -e "当前环境是正常状态。"
fi

sudo bash -c "cat > /etc/caddy/Caddyfile" <<EOF
$DOMAIN {
    root * /var/www/html/epay
    encode zstd gzip
    php_fastcgi unix//run/php/php${PHP_VERSION}-fpm.sock
    file_server

    @rewriteHtml {
        not file
        path_regexp html ^/(.[a-zA-Z0-9_-]+)\.html$
    }
    rewrite @rewriteHtml /index.php?mod={http.regexp.html.1}

    @rewritePay {
        path_regexp pay ^/pay/(.*)$
    }
    rewrite @rewritePay /pay.php?s={http.regexp.pay.1}

    # 禁止访问 /plugins 和 /includes 目录
    @blockPlugins {
        path /plugins*
    }
    respond @blockPlugins 403

    @blockIncludes {
        path /includes*
    }
    respond @blockIncludes 403
}
EOF

sudo systemctl restart caddy

echo -e "\033[32m============================================================\033[0m"
echo -e "\033[32m                  数据库信息: \033[0m"
echo -e "\033[32m============================================================\033[0m"
echo -e "\033[33m数据库名:     \033[36m${DB_NAME}\033[0m"
echo -e "\033[33m用户名:       \033[36m${DB_USER}\033[0m"
echo -e "\033[33m密码:         \033[36m${DB_PASSWORD}\033[0m"
echo -e "\033[32m============================================================\033[0m"
echo -e "\033[32m站点域名:     \033[36m${DOMAIN}\033[0m"
echo -e "\033[32m相关信息:     \033[36m首次安装路径：/install 后台路径是：/admin\033[0m"
echo -e "\033[32m您的易支付已经部署完成，请记录好相关信息。\033[0m"
echo -e "\033[32m============================================================\033[0m"
