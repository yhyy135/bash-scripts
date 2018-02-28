#!/bin/bash
yum install git vim -y
git clone https://github.com/yhyy135/shadowsocksr.git
cp ~/shadowsocksr/shadowsocks /usr/local/shadowsocks -a
server_ip=`/sbin/ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:"`
read -p "Default Setting? [Y/n]: " yn
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport '$server_port' -j ACCEPT
if [ "$yn" == "Y" -o "$yn" == "y" ]; then
    server_port="443"
    password=`date +%s | sha256sum | base64 | head -c 15 ; echo`
    method="none"
    protocol="auth_chain_a"
    obfs="plain"
else
    read -p "Please input server port: (Default port: 8999) " server_port
    [ -z "$server_port" ] && server_port="8999"
    read -p "Please input password: (Default: random password) " password
    [ -z "$password" ] && password=`date +%s | sha256sum | base64 | head -c 15 ; echo`
    echo "The password is $password \n"
    read -p "Please input method: (Default method: aes-256-cfb) " method
    [ -z "$method" ] && method="aes-256-cfb"
    read -p "Please input protocol: (Default protocol: auth_chain_a) " protocol
    [ -z "$protocol" ] && protocol="auth_chain_a"
    read -p "Please input obfs: (Default obfs: tls1.2_ticket_auth) " obfs
    [ -z "$obfs" ] && obfs="tls1.2_ticket_auth"
fi
echo '{
    "server": "'$server_ip'",
    "server_ipv6": "::",
    "server_port": '$server_port',
    "local_address": "127.0.0.1",
    "local_port": 1080,
    "password": "'$password'",
    "method": "'$method'",
    "protocol": "'$protocol'",
    "protocol_param": "",
    "obfs": "'$obfs'",
    "obfs_param": "",
    "speed_limit_per_con": 0,
    "speed_limit_per_user": 0,
    "additional_ports" : {},
    "timeout": 120,
    "udp_timeout": 60,
    "dns_ipv6": false,
    "connect_verbose_info": 0,
    "redirect": "",
    "fast_open": false
}' > ~/user-config.json

$iptstatus=`/etc/init.d/iptables status`
if [ $iptstatus -eq 0 ]; then
    $sspstatus=`iptables -L -n | grep -i ${server_port}`
    if [ $sspstatus -ne 0 ]; then
        iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport ${server_port} -j ACCEPT
        iptables -I INPUT -m state --state NEW -m udp -p udp --dport ${server_port} -j ACCEPT
        /etc/init.d/iptables save
        /etc/init.d/iptables restart
    else
        echo "port ${server_port} has been set up."
    fi
else
    echo -e "[Warning] iptables looks like shutdown or not installed, please manually set it if necessary."
fi

cp ~/user-config.json /usr/local/shadowsocks/user-config.json -f
chmod +x /usr/local/shadowsocks/*.sh
curl https://gist.githubusercontent.com/yhyy135/3abbc00a87f90cd8ff55525a11b00994/raw/93bd8d3a05e223ac82d981364ea68d5afaa82591/SysVinit > /etc/init.d/shadowsocks && chmod 755 /etc/init.d/shadowsocks && chkconfig --add shadowsocks
read -p "Start shadowsocksR-rss now? [Y/n] " yn
echo "alias 'fuckgfw'='service shadowsocks start'" >> ~/.bash_profile && source ~/.bash_profile
[ "$yn" == "Y" -o "$yn" == "y" ] && service shadowsocks start && echo "\n" && echo 'SSR deploy successfully! The config is:
    server_ip: '$server_ip'
    server_port: '$server_port'
    password: '$password'
    method: '$method'
    protocol: '$protocol'
    obfs: '$obfs'
'
[ "$yn" == "N" -o "$yn" == "n" ] && echo "You can use 'fuckgfw' to start shadowsocks."