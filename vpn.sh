#!/bin/sh

# Install pptpd
yum -y install epel-release
rpm -Uvh http://linux.mirrors.es.net/fedora-epel//epel-release-latest-7.noarch.rpm
yum -y install ppp pptpd

# pptpd settings
echo 'option /etc/ppp/options.pptpd' >> /etc/pptpd.conf
echo 'localip 10.10.0.1' >> /etc/pptpd.conf
echo 'remoteip 10.10.0.2-199' >> /etc/pptpd.conf
echo 'ms-dns 8.8.8.8' >> /etc/ppp/options.pptpd
echo 'ms-dns 8.8.4.4' >> /etc/ppp/options.pptpd
echo 'Proxyarp' >> /etc/ppp/options.pptpd
echo 'name pptpd' >> /etc/ppp/options.pptpd
echo 'lock' >> /etc/ppp/options.pptpd
echo 'nobsdcomp' >> /etc/ppp/options.pptpd
echo 'novj' >> /etc/ppp/options.pptpd
echo 'novjccomp' >> /etc/ppp/options.pptpd
echo 'require-mppe-128' >> /etc/ppp/options.pptpd
echo 'require-mschap-v2' >> /etc/ppp/options.pptpd
echo 'Logfile /var/log/pptpd.log' >> /etc/ppp/options.pptpd
echo 'sample pptpd 123456 *' >> /etc/ppp/chap-secrets
# echo 'sample pptpd 123456 *' >> /etc/ppp/chap-secrets // is a username and password for client vpn and server ip is server address in client 



# system ipv4 forward
sysctl_file=/etc/sysctl.conf
if grep -xq 'net.ipv4.ip_forward' $sysctl_file; then
  sed -i.bak -r -e "s/^.*net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/" $sysctl_file
else
  echo 'net.ipv4.ip_forward = 1' >> $sysctl_file
fi
sysctl -p

# firewalld
zone=public
firewall-cmd --permanent --new-service=pptp
cat >/etc/firewalld/services/pptp.xml<<EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <port protocol="tcp" port="1723"/>
</service>
EOF
firewall-cmd --permanent --zone=$zone --add-service=pptp
firewall-cmd --permanent --zone=$zone --add-masquerade
firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -p gre -j ACCEPT
firewall-cmd --permanent --direct --add-rule ipv6 filter INPUT 0 -p gre -j ACCEPT
firewall-cmd --reload

# starte service pptpd
systemctl start pptpd.service
systemctl enable pptpd.service
