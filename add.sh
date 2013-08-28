#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

## Check user permissions ##
if [ $(id -u) != "0" ]; then
	echo "Error: NO PERMISSION! Please login as root to run this script again."
	exit 1
fi

## Start ##
clear
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
echo ""

echo ""
echo " Please enter the main domain name for new virtual host  <"
echo " Example: sec.ht(without www.)"
read -p " Enter: " domain
if [ "$domain" = "" ]; then
	domain="sec.ht"
fi
if [ ! -f "/etc/nginx/host/$domain.conf" ]; then
	echo "" 
	echo -e "\033[41;37m Main domain name: $domain \033[0m"
else
	echo "" 
	echo -e "\033[41;37m Error: $domain already exist! \033[0m"
	echo "" 
	echo " Exiting..."
	echo ""
	exit 1
fi

echo ""
moredomainlist=""
echo " Do you want to add more domain names for new virtual host?  <"
read -p " Choose ( Y/n ): " moredomain_yn
if [ "$moredomain_yn" = "Y" ] || [ "$moredomain_yn" = "y" ]; then
	echo ""
	echo " Please enter more domain names for new virtual host  <"
	echo " Example: bbs.sec.ht forum.sec.ht"
	read -p " Enter: " moredomain
	moredomainlist=" $moredomain"
	echo ""
	echo -e "\033[41;37m More domain names: $moredomain \033[0m"
else
	echo ""
	echo -e "\033[47;30m No more domain names \033[0m"
fi

echo ""
echo " Please enter the directory for new virtual host: $domain  <"
echo " Default: /var/wwwroot/$domain"
read -p " Enter: " virtualhostdir
if [ "$virtualhostdir" = "" ]; then
	virtualhostdir="/var/wwwroot/$domain"
fi
echo ""
echo -e "\033[41;37m Virtual host directory: $virtualhostdir \033[0m"
echo ""

echo ""
echo " Allow access log? This will log all network requests  <"
read -p " Choose ( Y/n ): " log_yn
if [ "$log_yn" = "Y" ] || [ "$log_yn" = "y" ]; then
	echo ""
	echo " > Please enter the access log name for new virtual host  <"
	echo " > Default access log name: $domain"
	read -p " > Enter: " log_name
	if [ "$log_name" = "" ]; then
		log_name="$domain"
	fi
	access_log="access_log  /var/wwwlogs/$log_name.log  access;"
	echo ""
	echo -e "\033[41;37m Access log file: /var/wwwlogs/$log_name.log \033[0m"
else
	echo ""
	access_log="access_log off;"
	echo -e "\033[47;30m Access log not allowed \033[0m"
fi

	echo " Allow Rewrite rule? <"
	read -p " Choose ( Y/n ): "  allow_rewrite

	if [ "$allow_rewrite" == 'n' ]; then
		rewrite="none"
	else
		rewrite="other"
		echo -e "\033[41;37m Please input the rewrite of programme : \033[0m"
		echo -e "\033[41;37m wordpress,discuz,typecho,sablog,dabr rewrite was exist. \033[0m"
		read -p " > Enter: "  rewrite
		if [ "$rewrite" = "" ]; then
			rewrite="other"
		fi
	fi
	echo -e "\033[41;37m You choose rewrite="$rewrite" \033[0m"

echo "Open GZip? <"
	read -p " Choose ( Y/n ): "  gzip

	if [ "$gzip" == 'n' ]; then
		gzip=""
	else
		gzip="gzip on;
		gzip_min_length  1k;
		gzip_buffers     4 16k;
		gzip_http_version 1.0;
		gzip_comp_level 3;
		gzip_types       text/plain application/x-javascript text/css application/xml;
		gzip_vary on;"
	fi

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
echo ""
echo -e "\033[47;30m * Press any key to start creating virtual host...   \033[0m"
echo -e "\033[47;30m * Or press Ctrl + C to cancel the creation and exit \033[0m"
char=`get_char`
echo ""

if [ ! -d /etc/nginx/host ]; then
	mkdir -p /etc/nginx/host
fi
if [ ! -d /etc/nginx/ssl ]; then
	mkdir -p /etc/nginx/ssl
fi

echo ""
echo "Creating virtual host directory..."
mkdir -p $virtualhostdir

echo "Set permissions for virtual host..."
chmod 755 $virtualhostdir
chown -R www-data $virtualhostdir

echo "Creating configuration file for $domain..."
cat >/etc/nginx/host/$domain.conf<<eof
server
	{
		listen 80;
		server_name $domain www.$domain$moredomainlist;
		index index.html index.htm index.shtml default.html index.php;
		root $virtualhostdir;
		include $rewrite.conf;
		$gzip
		location ~* ^(.+\.php)(.*)$ {
				fastcgi_pass  unix:/tmp/php-cgi.sock;
				fastcgi_index index.php;
                                fastcgi_param SCRIPT_FILENAME $virtualhostdir\$fastcgi_script_name;
                                include fastcgi_params;
			}
		location ~ .*\.(gif|png|jpg|jpeg|bmp|ico|swf)$
			{
				expires 15d;
			}
		location ~ .*\.(js|css)?$
			{
				expires 1d;
			}
		$access_log
	}
eof

echo ""
echo "Completed."

echo ""
echo ""
cat >> /etc/php5/fpm/php.ini<<EOF
[HOST=$domain]
open_basedir ="$virtualhostdir:/tmp"
[HOST=www.$domain]
open_basedir ="$virtualhostdir:/tmp"
EOF

/etc/init.d/php5-fpm restart

/etc/init.d/nginx reload

echo ""
echo -e "\033[41;37m **************************************** \033[0m"
echo -e "\033[41;37m *          LNMP Install Shell          * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m *           Nginx+PHP+MySQL            * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m *        Compiled by N.S.Dept.         * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m *          Extension : 8003            * \033[0m"
echo -e "\033[41;37m *                                      * \033[0m"
echo -e "\033[41;37m **************************************** \033[0m"
echo ""
echo " * Main domain name: $domain"
echo ""
echo " * More domain names: www.$domain$moredomainlist"          
if [ "$log_yn" = "Y" ] || [ "$log_yn" = "y" ]; then
	echo ""
	echo " * Access log file: /var/wwwlogs/$log_name.log"
fi
echo ""
echo " * Directory of $domain: $virtualhostdir"
echo ""
echo " * Rewrite Rule: include $rewrite.conf;"
echo ""
echo -e "\033[47;30m * Completed! * \033[0m"
echo ""

## END ##
