### Docker-compose
```
services:
  web:
    image: ghcr.io/sky22333/epay
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
      MYSQL_ROOT_PASSWORD: epay7890    # 数据库root密码
      MYSQL_DATABASE: epay             # 数据库名称
      MYSQL_USER: epay                 # 数据库用户名
      MYSQL_PASSWORD: epay7890         # 数据库用户密码
    volumes:
      - ./data/epay:/var/lib/mysql
```

```
docker compose up -d
```



---
> 版本：`includes/common.php`： `'VERSION', '3096'`

