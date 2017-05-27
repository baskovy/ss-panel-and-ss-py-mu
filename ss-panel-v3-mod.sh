#!/bin/bash
#Check Root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
install_ss_panel_mod_v3(){
	yum install -y unzip zip
	#wget -c https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/lnmp1.3.zip && unzip lnmp1.3.zip && cd lnmp1.3 && chmod +x install.sh && ./install.sh lnmp
	cd /home/wwwroot/default/
	yum install git -y
	rm -rf index.html
	wget http://home.ustc.edu.cn/~mmmwhy/ss.panel_mod.zip && unzip ss.panel_mod.zip
	chattr -i .user.ini
	mv .user.ini public
	chown -R root:root *
	chmod -R 777 *
	chown -R www:www storage
	chattr +i public/.user.ini
	wget -N -P  /usr/local/nginx/conf/ http://home.ustc.edu.cn/~mmmwhy/nginx.conf 
	service nginx restart
	yum install perl-DBI freeradius freeradius-mysql freeradius-utils -y
	mysql -uroot -proot -e"CREATE USER 'radius'@'%' IDENTIFIED BY 'root';" 
	mysql -uroot -proot -e"GRANT ALL ON *.* TO 'radius'@'%';" 
	mysql -uroot -proot -e"create database radius;" 
	mysql -uroot -proot -e"use radius;" 
	mysql -uroot -proot radius < /home/wwwroot/default/sql/all.sql
	mysql -uroot -proot -e"CREATE USER 'ss-panel-radius'@'%' IDENTIFIED BY 'root';" 
	mysql -uroot -proot -e"GRANT ALL ON *.* TO 'ss-panel-radius'@'%';" 
	mysql -uroot -proot -e"CREATE USER 'sspanel'@'%' IDENTIFIED BY 'root';" 
	mysql -uroot -proot -e"GRANT ALL ON *.* TO 'sspanel'@'%';" 
	mysql -uroot -proot -e"create database sspanel;" 
	mysql -uroot -proot -e"use sspanel;" 
	mysql -uroot -proot sspanel < /home/wwwroot/default/sql/sspanel.sql
	\cp /home/wwwroot/default/sql/sql.conf /etc/raddb/sql.conf
	wget https://github.com/glzjin/Radius-install/raw/master/radiusd.conf -O /etc/raddb/radiusd.conf
	wget https://github.com/glzjin/Radius-install/raw/master/default -O /etc/raddb/sites-enabled/default
	wget https://github.com/glzjin/Radius-install/raw/master/dialup.conf -O /etc/raddb/sql/mysql/dialup.conf
	wget https://github.com/glzjin/Radius-install/raw/master/dictionary -O /etc/raddb/dictionary
	wget https://github.com/glzjin/Radius-install/raw/master/counter.conf -O /etc/raddb/sql/mysql/counter.conf
	service radiusd start && chkconfig radiusd on
	cd /home/wwwroot/default
	php composer.phar install
	yum -y install vixie-cron
	yum -y install crontabs
}
update_cron(){
	crontab –e 30 22 * * * php /home/wwwroot/ss.panel/xcat sendDiaryMail
	crontab –e */1 * * * * php /home/wwwroot/ss.panel/xcat synclogin
	crontab –e */1 * * * * php /home/wwwroot/ss.panel/xcat syncvpn
	crontab –e 0 0 * * * php -n /home/wwwroot/ss.panel/xcat dailyjob
	crontab –e */1 * * * * php /home/wwwroot/ss.panel/xcat checkjob    
	crontab –e */1 * * * * php -n /home/wwwroot/ss.panel/xcat syncnas
}

update_python(){
	yum install openssl openssl-devel zlib-devel gcc -y
	# apt-get install libssl-dev
	# apt-get install openssl openssl-devel
	# 下载源码
	wget http://www.python.org/ftp/python/2.7.12/Python-2.7.12.tgz
	tar -zxvf Python-2.7.12.tgz
	cd Python-2.7.12
	mkdir /usr/local/python2.7.12
	# 开启zlib编译选项
	# sed -i '467c zlib zlibmodule.c -I$(prefix)/include -L$(exec_prefix)/lib -lz' Module/Setup
	sed '467s/^#//g' Module/Setup
	./configure --prefix=/usr/local/python2.7.12 
	make
	make install
	if [ $? -eq 0 ];then
	     echo "Python2.7.12升级完成"
	else
	     echo "Python2.7.12升级失败，查看报错信息手动安装"
	fi
	cd
	mv /usr/bin/python /usr/bin/python2.6.6
	ln -s /usr/local/python2.7.12/bin/python2.7 /usr/bin/python
	sed -i '1s/python/python2.6/g' /usr/bin/yum
	wget --no-check-certificate https://bootstrap.pypa.io/get-pip.py
	python get-pip.py
	if [ $? -eq 0 ];then
	     echo "pip升级完成"
	else
	     echo "pip安装失败，查看报错信息手动安装"
	fi
	rm -rf /usr/bin/pip
	ln -s /usr/local/python2.7.12/bin/pip2.7 /usr/bin/pip
}

install_ssr(){
	check_sys(){
		if [[ -f /etc/redhat-release ]]; then
			release="centos"
		elif cat /etc/issue | grep -q -E -i "debian"; then
			release="debian"
		elif cat /etc/issue | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
		elif cat /proc/version | grep -q -E -i "debian"; then
			release="debian"
		elif cat /proc/version | grep -q -E -i "ubuntu"; then
			release="ubuntu"
		elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
			release="centos"
	    fi
		bit=`uname -m`
	}
	install_soft_for_each(){
		    check_sys
		    if [[ ${release} = "centos" ]]; then
			        yum install git -y
			        yum install python-setuptools && easy_install pip -y
			        yum -y groupinstall "Development Tools" -y
			        wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.11.tar.gz
			        tar xf libsodium-1.0.11.tar.gz && cd libsodium-1.0.10
			        ./configure && make -j2 && make install
			        echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
			        ldconfig
		    else
		    apt-get update -y
		    apt-get install supervisor -y
		    apt-get install git -y
		    apt-get install build-essential -y
		    wget https://raw.githubusercontent.com/mmmwhy/ss-panel-and-ss-py-mu/master/libsodium-1.0.11.tar.gz
		    tar xf libsodium-1.0.11.tar.gz && cd libsodium-1.0.11
		    ./configure && make -j2 && make install
		    ldconfig
		    fi
	}
	install_soft_for_each
	#clone shadowsocks
	cd /root
	git clone -b manyuser https://github.com/glzjin/shadowsocks.git "/root/shadowsocks"
	#install devel
	cd /root/shadowsocks
	yum -y install python-devel
	yum -y install libffi-devel
	yum -y install openssl-devel
	pip install -r requirements.txt
	cp apiconfig.py userapiconfig.py
	cp config.json user-config.json
	#iptables
	iptables -I INPUT -p tcp -m tcp --dport 104 -j ACCEPT
	iptables -I INPUT -p tcp -m tcp --dport 1024: -j ACCEPT
	iptables-save
}
supervision(){
	rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm --quiet
	yum install supervisor python-pip -y
	pip install supervisor==3.1
	chkconfig supervisord on
	wget https://github.com/glzjin/ssshell-jar/raw/master/supervisord.conf -O /etc/supervisord.conf
	wget https://github.com/glzjin/ssshell-jar/raw/master/supervisord -O /etc/init.d/supervisord
	sed -i '$a [program:mu]\ncommand=python /root/shadowsocks/server.py\ndirectory=/root/shadowsocks\nautorestart=true\nstartsecs=10\nstartretries=36\nredirect_stderr=true\nuser=root ; setuid to this UNIX account to run the program\nlog_stdout=true ; if true, log program stdout (default true)\nlog_stderr=true ; if true, log program stderr (def false)\nlogfile=/var/log/mu.log ; child log path, use NONE for none; default AUTO\n;logfile_maxbytes=1MB ; max # logfile bytes b4 rotation (default 50MB)\n;logfile_backups=10 ; # of logfile backups (default 10)' /etc/supervisord.conf
}


install_node(){
	clear
	echo
	echo "#############################################################"
	echo "# One click Install Shadowsocks-Python-Manyuser             #"
	echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
	echo "# Author: 91VPS.CLUB                                        #"
	echo "# https://91vps.club/2017/05/27/ss-panel-v3-mod/            #"
	echo "#############################################################"
	echo
	#Check Root
	[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }
	read -p "Please input your domain(like:https://ss.feiyang.li or http://114.114.114.114): " Userdomain
	read -p "Please input your muKey(like:mupass): " Usermukey
	read -p "Please input your Node_ID(like:1): " UserNODE_ID
	update_python
	install_ssr
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	Userdomain=${Userdomain:-"http://gz.feiyang.li"}
	sed -i "s#https://zhaoj.in#${Userdomain}#" /root/shadowsocks/userapiconfig.py
	Usermukey=${Usermukey:-"mupass"}
	sed -i "s#glzjin#${Usermukey}#" /root/shadowsocks/userapiconfig.py
	UserNODE_ID=${UserNODE_ID:-"1"}
	sed -i '2d' /root/shadowsocks/userapiconfig.py
	sed -i "2a\NODE_ID = ${UserNODE_ID}" /root/shadowsocks/userapiconfig.py
	supervision #后台运行
	service supervisord start
}

one_click_all(){
	install_ss_panel_mod_v3
	update_cron
	update_python
	install_ssr
	IPAddress=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	cd /root/shadowsocks
	echo -e "modify Config.py...\n"
	sed -i "s#https://zhaoj.in#${IPAddress}#" /root/shadowsocks/userapiconfig.py
	sed -i "s#glzjin#$mupass#" /root/shadowsocks/userapiconfig.py
	supervision #后台运行
	service supervisord start
}


install_ss_panel(){
	install_ss_panel_mod_v3
	update_cron	
}
echo
echo "#############################################################"
echo "# One click Install SS-panel and Shadowsocks-Py-Mu          #"
echo "# Github: https://github.com/mmmwhy/ss-panel-and-ss-py-mu   #"
echo "# Author: 91VPS.club                                        #"
echo "# https://91vps.club/2017/05/27/ss-panel-v3-mod/            #"
echo "# Please choose the server you want                         #"
echo "# 1  SS-V3_mod_panel + SS-node One click Install            #"
echo "# 2  SS-V3_mod_panel One click Install                      #"
echo "# 3  SS-node One click Install                              #"
echo "#############################################################"
echo
stty erase '^H' && read -p " 请输入数字 [1-3]:" num
case "$num" in
	1)
	one_click_all
	;;
	2)
	install_ss_panel
	;;
	3)
	install_node
	;;
	*)
	echo "请输入正确数字 [1-3]"
	;;
esac
