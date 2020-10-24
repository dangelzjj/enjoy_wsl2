wsl -d Ubuntu-18.04 -u root ip addr add 172.19.110.237/24 broadcast 172.19.110.255 dev eth0 label eth0:1
netsh interface ip add address "vEthernet (WSL)" 172.19.110.1  255.255.255.0