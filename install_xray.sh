#!/bin/bash
# set val
PORT=${PORT:-8100}
AUUID=${AUUID:-5194845a-cacf-4515-8ea5-fa13a91b1026}
ParameterSSENCYPT=${ParameterSSENCYPT:-chacha20-ietf-poly1305}
CADDYIndexPage=${CADDYIndexPage:-https://github.com/AYJCSGM/mikutap/archive/master.zip}

# template file
cat >> Caddyfile.temp <<EOF
{
        servers {
                protocol {
                        experimental_http3
                }
        }
}
:\$PORT
root * www
file_server browse

route {
        forward_proxy {
                basic_auth xwy fuck_gfw_ccp
                hide_ip
                hide_via
                probe_resistance
        }
        root * www
        file_server browse
}

basicauth /\$AUUID/* {
        \$AUUID \$MYUUID-HASH
}

route /\$AUUID-vmess {
        reverse_proxy 127.0.0.1:7001
}

route /\$AUUID-vless {
        reverse_proxy 127.0.0.1:7002
}

route /\$AUUID-trojan {
        reverse_proxy 127.0.0.1:7003
}

route /\$AUUID-ss {
        reverse_proxy 127.0.0.1:4234
}

route /\$AUUID-socks {
        reverse_proxy 127.0.0.1:5234
}

EOF

cat >> config.json <<EOF
{
    #"log": { "loglevel": "info" },
    "inbounds": 
    [
        {
            "listen": "127.0.0.1","port": 7001,"protocol": "vmess",
            "settings": {"clients": [{"id": "\$AUUID"}]},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/\$AUUID-vmess"}}
        },
        {
            "listen": "127.0.0.1","port": 7002,"protocol": "vless",
            "settings": {"clients": [{"id": "\$AUUID"}],"decryption": "none"},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/\$AUUID-vless"}}
        },
        {
            "listen": "127.0.0.1","port": 7003,"protocol": "trojan",
            "settings": {"clients": [{"password":"\$AUUID"}]},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/\$AUUID-trojan"}}
        },
        {
            "port": 4234,"listen": "127.0.0.1","tag": "onetag","protocol": "dokodemo-door",
            "settings": {"address": "v1.mux.cool","network": "tcp","followRedirect": false},
            "streamSettings": {"security": "none","network": "ws","wsSettings": {"path": "/\$AUUID-ss"}}
        },
        {
            "port": 4324,"listen": "127.0.0.1","protocol": "shadowsocks",
            "settings": {"method": "\$ParameterSSENCYPT","password": "\$AUUID"},
            "streamSettings": {"security": "none","network": "domainsocket","dsSettings": {"path": "apath","abstract": true}}
        },
        {   "port": 5234,"listen": "127.0.0.1","protocol": "socks",
            "settings": {"auth": "password","accounts": [{"user": "\$AUUID","pass": "\$AUUID"}]},
            "streamSettings": {"network": "ws","wsSettings": {"path": "/\$AUUID-socks"}}
        }
    ],
    
    "outbounds": 
    [
        {"protocol": "freedom","tag": "direct","settings": {}},
        {"protocol": "blackhole","tag": "blocked","settings": {}},
        {"protocol": "socks","tag": "sockstor","settings": {"servers": [{"address": "127.0.0.1","port": 9050}]}},
        {"protocol": "freedom","tag": "twotag","streamSettings": {"network": "domainsocket","dsSettings": {"path": "apath","abstract": true}}}    
    ],
    
    "routing": 
    {
        "rules": 
        [
            {"type": "field","inboundTag": ["onetag"],"outboundTag": "twotag"},
            {"type": "field","outboundTag": "sockstor","domain": ["geosite:tor"]},
            {"type": "field","outboundTag": "blocked","domain": ["geosite:category-ads-all"]}
        ]
    }
}

EOF

# download execution
wget "https://github.com/GeminiT369/binary/raw/main/caddy" -O caddy
wget "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" -O xray.zip
unzip -o xray.zip && rm -rf xray.zip
chmod +x caddy xray

# set caddy
mkdir -p www
echo -e "User-agent: *\nDisallow: /" > www/robots.txt
wget $CADDYIndexPage -O www/index.html && unzip -qo www/index.html -d www/ && mv www/*/* www/

# set config file
cat ./Caddyfile.temp | sed -e "s/\$PORT/$PORT/g" -e "s/\$AUUID/$AUUID/g" -e "s/\$MYUUID-HASH/$(./caddy hash-password --plaintext $AUUID)/g" > Caddyfile
cat ./config.json | sed -e "s/\$AUUID/$AUUID/g" -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" > xray.json

# start cmd
killall xray caddy
./xray -config xray.json & ./caddy run --config Caddyfile --adapter caddyfile
