#!/bin/bash
# Adding swap temporarily in case of using t3.nano
dd if=/dev/zero of=/var/cache/swapfile bs=1M count=1024;
chmod 600 /var/cache/swapfile;
mkswap /var/cache/swapfile;
swapon /var/cache/swapfile;
free -m > /var/tmp/swap.txt
yum update -y;
yum upgrade -y;
amazon-linux-extras install epel docker -y;
yum upgrade -y;
yum -y install amazon-ecr-credential-helper jq
systemctl enable docker --now
sed -i 's/^#Port 22/Port 2020/g' /etc/ssh/sshd_config;
systemctl restart sshd;
hostnamectl set-hostname ${project_name};
timedatectl set-timezone Europe/London;

echo "{ \"credsStore\": \"ecr-login\" }" > /etc/docker/config.json
systemctl restart docker
/usr/bin/openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=UK/ST=Bobbins/L=GreaterManchester/O=Dis/CN=jupyter.chegwin.org" \
    -keyout /root/jupyter.key  -out /root/jupyter.crt;
wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
chmod a+x /usr/local/bin/docker-compose
cat <<"EOF" > /root/docker-compose.yml
version: '3.2'
services:

  jupyter:
    image: jupyter/scipy-notebook
    container_name: jupyter
    command: start.sh jupyter lab --LabApp.token='${jupyter_passwd}'  --LabApp.allow_remote_access='True' --LabApp.allow_origin='*'
    restart: always
    environment:
      JUPYTER_ENABLE_LAB: "yes"
    networks:
      - skynet
    hostname: jupyter

  nginx:
    image: nginx
    container_name: nginx
    restart: always
    networks:
      - skynet
    ports:
      - 80:80
      - 443:443
    volumes:
      - /root/jupyter.crt:/etc/nginx/self.crt
      - /root/jupyter.key:/etc/nginx/self.key
      - /root/nginx.conf:/etc/nginx/nginx.conf

      
networks:
  skynet:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 192.168.69.0/24
EOF

cat <<"EOF" > /root/nginx.conf
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log warn;
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

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;

    server {
        listen 80 default;
        server_name  _;

        return 301 https://$host$request_uri;
    }

    upstream jupyter {
        server jupyter:8888;
    }

    
    ############## Jupyter ####################
    server {
        listen      0.0.0.0:443 ssl;
        server_name   jupyter.remote.lan
                      www.jupyter.remote.lan;

        ssl_certificate     /etc/nginx/self.crt;
        ssl_certificate_key /etc/nginx/self.key;

        ssl_protocols TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        ssl_ciphers EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA512:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:ECDH+AESGCM:ECDH+AES256:DH+AESGCM:DH+AES256:RSA+AESGCM:!aNULL:!eNULL:!LOW:!RC4:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS;
        ssl_session_cache  builtin:1000  shared:SSL:10m;

        access_log  /var/log/nginx/jupyter.log ;
        error_log  /var/log/nginx/jupyter.error.log debug;

        location / {
          proxy_set_header        Host $host;
          proxy_set_header        X-Real-IP $remote_addr;
          proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header        X-Forwarded-Proto $scheme;
          proxy_pass              http://jupyter;
          proxy_read_timeout      90;
        }

        location ~* /(api/kernels/[^/]+/(channels|iopub|shell|stdin)|terminals/websocket)/? {
           proxy_pass http://jupyter;

           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header Host $host;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           # WebSocket support
           proxy_http_version 1.1;
           proxy_set_header      Upgrade "websocket";
           proxy_set_header      Connection "Upgrade";
           proxy_read_timeout    86400;

        }
    }

}
EOF

#sed -i 's/bobbins/${jupyter_passwd}/g' /root/docker-compose.yml;
$(aws ecr get-login --region eu-west-1 | sed -e 's/-e none//g')
cd root && echo "y" | /usr/local/bin/docker-compose up --detach
if [ ${break_workspace} == 'true' ]
then 
    cd /root;
    yum -y install git;
    git clone https://github.com/datacharmer/test_db.git;
    cd test_db;
    xfs_io -x -c "resblks" /;
    systemctl stop nginx;
    # Horribly obfuscated to stop it being read by a candidate easily.
    # Do not run this unless you know what you are doing!
    $(echo "ZGQgaWY9L2Rldi96ZXJvIG9mPS92YXIvbG9nL3JvZ3VlX2ZpbGUubG9nIGJzPTE2ayBjb3VudD0yMDBrCg==" | base64 -d) || true; sync; sync;
    systemctl start nginx;
else
    echo "Nothing to break"
fi
