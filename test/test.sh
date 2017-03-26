ansible-playbook run-demo.yml
ssh server01 wget -T 30 -t 1 172.16.1.4
ssh server01 cat index.html
ssh server01 ip route show table 30
