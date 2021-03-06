#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
cur_dir=$(pwd)
source_dir=$cur_dir/source
WEBROOT="/var/www"

echo " Please enter the server domain name, the default is: $hostname  <"
echo " Example: sec.ht"
read -p " --Enter: " hostname
if [ "$hostname" = "" ]; then
	hostname="$servername"
fi
if [ "$hostname" = "" ]; then
	hostname="sec.ht"
fi
echo ""
echo -e "\033[41;37m Server domain name: $hostname \033[0m"
echo ""
hostname $hostname
get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo ""
echo -e "\033[47;30m * Press any key to start installing DNMP...             \033[0m"
echo -e "\033[47;30m * Or press Ctrl + C to cancel the installation and exit \033[0m"
char=`get_char`
echo ""

dpkg -l |grep apache 
dpkg -P apache2 apache2-doc apache2-mpm-prefork apache2-utils apache2.2-common

apt-get update
apt-get remove -y apache2 apache2-doc apache2-utils apache2.2-common apache2.2-bin apache2-mpm-prefork apache2-doc apache2-mpm-worker
wget http://www.dotdeb.org/dotdeb.gpg
apt-key add dotdeb.gpg
cat >> /etc/apt/sources.list<<EOF
deb http://mirror.us.leaseweb.net/dotdeb/ stable all
deb-src http://mirror.us.leaseweb.net/dotdeb/ stable all
deb http://packages.dotdeb.org wheezy all
deb-src http://packages.dotdeb.org wheezy all
EOF

apt-get update
apt-get install -y mysql-server mysql-client 
apt-get install -y nginx elinks unzip curl
apt-get install -y php5-fpm php5-gd php5-mysql php5-curl
#php.ini
/etc/init.d/php5-fpm stop
sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php5/fpm/php.ini
sed -i "s#disable_functions =#disable_functions = pcntl_alarm,pcntl_fork,pcntl_waitpid,pcntl_wait,pcntl_wifexited,pcntl_wifstopped,pcntl_wifsignaled,pcntl_wexitstatus,pcntl_wtermsig,pcntl_wstopsig,pcntl_signal,pcntl_signal_dispatch,pcntl_get_last_error,pcntl_strerror,pcntl_sigprocmask,pcntl_sigwaitinfo,pcntl_sigtimedwait,pcntl_exec,pcntl_getpriority,pcntl_setpriority,dl,exec,passthru,proc_open,proc_close,shell_exec,system#g" /etc/php5/fpm/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/g' /etc/php5/fpm/php.ini
sed -i "s#;open_basedir =#open_basedir = /tmp/:$WEBROOT/:/proc/#g" /etc/php5/fpm/php.ini
sed -i "s#expose_php = On#expose_php = Off#g" /etc/php5/fpm/php.ini
#php-fpm
rm -rf /etc/php5/fpm/pool.d/www.conf
mv conf/www.conf /etc/php5/fpm/pool.d/www.conf
mkdir /var/wwwlogs
mkdir /var/wwwroot
mkdir $WEBROOT
mkdir /var/run/php5
mkdir /etc/nginx/host
mkdir /etc/nginx/host
/etc/init.d/nginx stop
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/nginx.conf
rm -rf /etc/nginx/fastcgi_params
cp conf/nginx.conf /etc/nginx/nginx.conf
cp conf/fastcgi_params /etc/nginx/fastcgi_params
sed -i "s,sec.ht,$hostname,g" /etc/nginx/nginx.conf
#URL Rewrite
mv conf/none.conf /etc/nginx
cp conf/index.html $WEBROOT/index.html
cp conf/prober.php $WEBROOT/p.php
#Get latest phpMyAdmin.zip
if [ ! -s phpMyAdmin-*-all-languages.zip ]; then
	PMA_VERSION=`elinks http://jaist.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/ | awk -F/ '{print $7F}' | sort -n | grep -iv '-' | tail -1`
	PMA_LINK="http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/"
	LATEST_PMA_LINK="${PMA_LINK}${PMA_VERSION}/phpMyAdmin-${PMA_VERSION}-all-languages.zip/download"
	wget -c ${LATEST_PMA_LINK} -O conf/phpMyAdmin.zip
	unzip conf/phpMyAdmin.zip
	mv phpMyAdmin-${PMA_VERSION}-all-languages $WEBROOT/pma
else
	PMA_VERSION=`ls phpMyAdmin-*-all-languages.zip | awk -F- '{print $2}'`
	upzip phpMyAdmin-*-all-languages.zip 
	mv $WEBROOT/phpMyAdmin-*-all-languages $WEBROOT/pma
fi
chown -R www-data $WEBROOT
chown -R www-data /var/wwwroot
#add host
cp conf/add.sh /home/
chmod +x /home/add.sh
#start
usermod -L www-data
#usermod -U www-data  //unlock the user account
/etc/init.d/nginx start
/etc/init.d/php5-fpm start

echo ""
echo -e "\033[41;37m **************************************** \033[0m"
echo -e "\033[41;37m *          DNMP Install Shell          * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m *           Nginx+PHP+MySQL            * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m *        Compiled by N.S.Dept.         * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m *          Extension : 8003            * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m **************************************** \033[0m"
## END ##
