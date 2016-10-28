#!/bin/bash

VER=v2.0.0
MOD_AUTH_OPENIDC=mod_auth_openidc-2.0.0-1.el7.centos.x86_64.rpm
CJOSE=cjose-0.4.1-1.el7.centos.x86_64.rpm

function install_mod_auth_openidc {
    wget https://github.com/pingidentity/mod_auth_openidc/releases/download/${VER}/${MOD_AUTH_OPENIDC}
    wget https://github.com/pingidentity/mod_auth_openidc/releases/download/${VER}/${CJOSE}
    sudo yum localinstall ${MOD_AUTH_OPENIDC}
    sudo yum install mod_ssl
    # sudo yum localinstall ${CJOSE}
    rm ${MOD_AUTH_OPENIDC}
    rm ${CJOSE}

}

if [ "$1" == "-y" ]; then
    install=Y
    updatehttpdconf=Y
else
    read -p "Install mod_auth_openidc?" installmod
    read -p "Update httpd.conf" updatehttpdconf
    read -p "Update ssl.conf" updatesslconf
fi

read -p "Dataporten Client ID" dpclientid
read -p "Dataporten Client Secret" dpclientsecret

case ${installmod} in
    [Yy]* ) 
        install_mod_auth_openidc
    ;;
esac

case ${updatehttpdconf} in
    [Yy]* ) 
        sed -i.orig-$(date "+%y-%m-%d") -E '/Supplemental configuration/r 01.httpd.conf' /etc/httpd/conf/httpd.conf
    ;;
esac

case ${updatesslconf} in
    [Yy]* )
        echo "Adds DP info from 01.ssl.conf"
        sed "s/DPCLIENTID/${dpclientid}/" 01.ssl.conf > tmp.01.ssl.conf
        sed -i "s/DPCLIENTSECRET/${dpclientsecret}/" tmp.01.ssl.conf
        sed -i "s/HOSTNAME/${HOSTNAME}/" tmp.01.ssl.conf
        sudo sed -i.orig-$(date "+%y-%m-%d") -E '1 r tmp.01.ssl.conf' /etc/httpd/conf.d/ssl.conf
        rm tmp.01.ssl.conf

        echo "Adds galaxy proxy info"
        sudo sed -i -E '/VirtualHost _default_:443/r tmp.01.ssl.conf' /etc/httpd/conf.d/ssl.conf

        echo "copies users-script to /usr/local/galaxyemailusers.py"
        sudo cp users.py /usr/local/galaxyemailusers.py
        ;;
esac


