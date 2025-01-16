### Docker-compose
```
services:
  web:
    image: ghcr.io/sky22333/epay:latest
    container_name: epay
    restart: always
    ports:
      - "8080:80"
    depends_on:
      - mysql

  mysql:
    image: mysql:5.7
    container_name: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword     # 数据库root密码
      MYSQL_DATABASE: skyepay               # 数据库名称
      MYSQL_USER: skyeuser                  # 数据库用户名
      MYSQL_PASSWORD: skyuserpassword       # 数据库用户密码
    volumes:
      - ./data/epay:/var/lib/mysql         # 持久化数据库数据到本地
```
```
docker compose up -d
```



---
> `'VERSION', '3065'`

> [Epay源码来源](https://github.com/bigsb-scw/epay)




---

- 一键安装脚本

```
bash <(wget -qO- https://github.com/sky22333/epay/raw/main/epay.sh)
```
