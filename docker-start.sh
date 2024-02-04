#!/bin/bash
mkdir -p /home/docker_apps/mysql/
tee /home/docker_apps/mysql/docker-compose.yml <<-'EOF'
version: "3.7"
services:
  c_mysql:
    image: registry.cn-shenzhen.aliyuncs.com/6699/mysql:5.7
    ports:
      - "3307:3306"
    volumes:
      - /home/docker_apps/mysql/data:/var/lib/mysql
    network_mode: "docker_networks"
    restart: always
    privileged: true # 提升mysql至root权限
    container_name: mysql5
    command:
      - --default-authentication-plugin=mysql_native_password
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_general_ci
      - --explicit_defaults_for_timestamp=true
      - --lower_case_table_names=1
      - --default-time-zone=+8:00
    environment:
      MYSQL_ROOT_PASSWORD: 18523543030
EOF
cd /home/docker_apps/mysql/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/wow/
tee /home/docker_apps/wow/docker-compose.yml <<-'EOF'
version: "3.7" 
services: 
   wow: 
    restart: always 
    #image: debian #2：运行debian容器后，容器内，更换下载源
    image: registry.cn-shenzhen.aliyuncs.com/6699/wow_start #1：拉取该镜像
    container_name: wow #3：依赖下载安装完成，添加运行权限，直接修改配置文件，重启容器，即可运行游戏
    tty: true #4：从第四步开始操作
    ports: 
      - "8085:8085" 
      - "3724:3724" 
    environment:
      - TZ=Asia/Shanghai
    volumes: 
      - /home/docker_apps/wow/azeroth-server:/root/azeroth-server #只需要映射编译生成的目录
    network_mode: "docker_networks" 
EOF
cd /home/docker_apps/wow/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/qbittorrent
tee /home/docker_apps/qbittorrent/docker-compose.yml <<-'EOF'
version: '2'
services:
  qbittorrent:
    image: registry.cn-shenzhen.aliyuncs.com/6699/qbittorrent
    container_name: qb
    network_mode: host
    environment:
      - PUID=99
      - PGID=100
      - TZ=Asia/Shanghai
      - UMASK_SET=022
      - WEBUI_PORT=8080
    volumes:
      - /home/docker_apps/qbittorrent/config/:/config
      - /mnt/:/downloads
    ports:
      - 6881:6881 
      - 6881:6881/udp
      - 8080:8080
    restart: always
EOF
cd /home/docker_apps/qbittorrent/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/v2raya/
tee /home/docker_apps/v2raya/docker-compose.yml <<-'EOF'
version: '3'
services:
  v2raya:
    container_name: v2
    image: mzz2017/v2raya
    network_mode: docker_networks
    volumes:
      - /home/docker_apps/v2raya/:/etc/v2raya
    restart: always
    privileged: true
    environment:
      - TZ=Asia/Shanghai
    ports:
      - 20170-20172:20170-20172
      - 2017:2017
EOF
cd /home/docker_apps/v2raya/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/jellyfin
tee /home/docker_apps/jellyfin/docker-compose.yml <<-'EOF'
version: '3'
services:
  jellyfin:
    image: registry.cn-shenzhen.aliyuncs.com/6699/jellyfin
    container_name: jf
    network_mode: host
    environment:
      - TZ=Asia/Shanghai
      - ALL_PROXY=http://192.168.1.88:20172
      - NO_PROXY=http://192.168.1.88:20172
      - HTTP_PROXY=http://192.168.1.88:20172
      - JELLYFIN_PublishedServerUrl=192.168.1.88 #optional
    volumes:
      - /home/docker_apps/jellyfin/config:/config
      - /home/docker_apps/jellyfin/cache:/cache
      - /mnt/:/video
    privileged: true
    restart: always
    devices:
      - /dev/dri:/dev/dri
EOF
cd /home/docker_apps/jellyfin
sleep 1
docker-compose up -d
#配置1：===================================================  增加网站 增加一个server
mkdir -p /home/docker_apps/nginx/conf.d
tee /home/docker_apps/nginx/conf.d/default.conf <<-'EOF'
server { # xcsm.vvtop.top 所有文件夹需要设置 chomod -R 777
    listen 80; # 监听 80 端口
    server_name xcsm.vvtop.top; # 访问域名
    location / { 
        root /usr/share/nginx/html/xcsm.com; # 设置nginx容器中的网页根目录
        index index.html index.htm index.php;                             
    }
    location ~ \.php$ {                                                   
        root /var/www/html/xcsm.com; # 设置php容器中的网页根目录
        fastcgi_pass php:9000;                                            
        fastcgi_index index.php;                                          
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; 
        include fastcgi_params;                                           
    }
} # 结束 server 块
server { # niit..vvtop.top 报错解决：https://docs.typecho.org/faq
    listen 80; # 监听 80 端口
    server_name niit.vvtop.top;  # 访问域名
    location / { 
        root /usr/share/nginx/html/niit.com; # 设置nginx容器中的网页根目录
        index index.html index.htm index.php;
        
        if (!-e $request_filename)
        {
        rewrite ^(.*)$ /index.php$1 last;
        }                            
    }
    location ~ .*\.php(\/.*)*$ {                                                   
        root /var/www/html/niit.com; # 设置php容器中的网页根目录
        fastcgi_pass php:9000;                                            
        fastcgi_index index.php;                                          
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; 
        include fastcgi_params;
    }
} # 结束 server 块
server { # ty..vvtop.top 报错解决：https://docs.typecho.org/faq
    listen 80; # 监听 80 端口
    server_name ty.vvtop.top;  # 访问域名
    location / { 
        root /usr/share/nginx/html/typecho.com; # 设置nginx容器中的网页根目录
        index index.html index.htm index.php;
        
        if (!-e $request_filename)
        {
        rewrite ^(.*)$ /index.php$1 last;
        }                              
    }
    location ~ .*\.php(\/.*)*$ {                                                   
        root /var/www/html/typecho.com; # 设置php容器中的网页根目录
        fastcgi_pass php:9000;                                            
        fastcgi_index index.php;                                          
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; 
        include fastcgi_params;                                           
    }
} # 结束 server 块
server {
    listen 80 default_server;
    server_name _;  # 捕获所有其他请求
    return 444;  # 拒绝处理这些请求
}
EOF
#配置：2 ===================================================
mkdir -p /home/docker_apps/nginx/conf
tee /home/docker_apps/nginx/conf/nginx.conf <<-'EOF'
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    server_tokens off; #关闭nginx 的版本号

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
EOF
#配置：3 ===================================================
mkdir -p /home/docker_apps/nginx/wwwroot
tee /home/docker_apps/nginx/wwwroot/index.php <<-'EOF'
<?php
phpinfo();
?>
EOF
mkdir -p /home/docker_apps/php
tee /home/docker_apps/php/docker-compose.yml <<-'EOF'
version: "3.7"
services:  
 php:
    restart: always
    image: registry.cn-shenzhen.aliyuncs.com/6699/php:7.4
    #image: php:fpm
    container_name: php
    environment:
      - TZ=Asia/Shanghai
    ports:
      - "9000:9000"
    volumes:
      - /home/docker_apps/nginx/wwwroot:/var/www/html
      - /home/docker_apps/php/fonts:/usr/share/fonts
      - /home/docker_apps/php/wkhtmltopdf:/home
      - /home/docker_apps/php/logs:/var/log/php
    network_mode: docker_networks
EOF
cd /home/docker_apps/php
sleep 1
docker-compose up -d
#执行前，先添加nginx.conf配置
mkdir -p /home/docker_apps/nginx
tee /home/docker_apps/nginx/docker-compose.yml <<-'EOF'
version: "3.7"
services:
  nginx:
    image: nginx:latest
    restart: always
    container_name: nginx
    environment:
      - TZ=Asia/Shanghai
    ports:
      - "30300:80"
      - "30301:443"  
    volumes:
      - /home/docker_apps/nginx/conf.d:/etc/nginx/conf.d
      - /home/docker_apps/nginx/conf/nginx.conf:/etc/nginx/nginx.conf
      - /home/docker_apps/nginx/wwwroot:/usr/share/nginx/html
      - /home/docker_apps/nginx/logs:/var/log/nginx
    network_mode: docker_networks
EOF
cd /home/docker_apps/nginx
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/chfs
tee /home/docker_apps/chfs/docker-compose.yml <<-'EOF'
version: '3'
services:
  chfs-container:
    image: registry.cn-shenzhen.aliyuncs.com/6699/chfs:3.0
    container_name: chfs
    network_mode: docker_networks
    restart: always
    ports:
      - "9999:8080"
    volumes:
      - /home/docker_apps/chfs/chfs_conf:/config
      - /home/docker_apps/chfs/chfs_logs:/var/log/
      - /mnt:/data
EOF
cd /home/docker_apps/chfs/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/ddns
tee /home/docker_apps/ddns/docker-compose.yml <<-'EOF'
version: '3.7'

services:
  ddns-go:
    container_name: ddns
    image: jeessy/ddns-go
    network_mode: "docker_networks"
    privileged: true
    ports:
      - "9876:9876"
    restart: always
    volumes:
      - /home/docker_apps/ddns:/root
EOF
cd /home/docker_apps/ddns/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/alist
tee /home/docker_apps/alist/docker-compose.yml <<-'EOF'
version: '3.7'

services:
  alist:
    image: registry.cn-shenzhen.aliyuncs.com/6699/alist
    container_name: alist
    network_mode: "docker_networks"
    ports:
      - "5244:5244"
    volumes:
      - /home/docker_apps/alist/mdata:/mnt/data
      - /home/docker_apps/alist/odata:/opt/alist/data
    restart: always
    privileged: false
EOF
cd /home/docker_apps/alist/
sleep 1
docker-compose up -d
mkdir -p /home/docker_apps/nas-tools
tee /home/docker_apps/nas-tools/docker-compose.yml <<-'EOF'
version: '3.7'

services:
  nas-tools:
    image: registry.cn-shenzhen.aliyuncs.com/6699/nas-tools
    container_name: nas-tools
    network_mode: "docker_networks"
    ports:
      - "3000:3000"
    environment:
      - PUID=0
      - PGID=0
      - UMASK=000
    volumes:
      - /home/docker_apps/nas-tools/config:/config
      - /home/docker_apps/nas-tools/video:/video
      - /mnt:/mnt
    restart: always
EOF
cd /home/docker_apps/nas-tools/
sleep 1
docker-compose up -d
