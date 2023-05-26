#!/usr/bin/env sh
##########################################################
################### SYSADMIN102™ LLC #####################
##########################################################

# Instructions on how to use this script:
# iocage console <Jail Name>
# git clone https://github.com/nn0x96a/truenas_core_nextcloud
# chmod 755 deploy-ssl-nextcloud.sh
# ./deploy-ssl-nextcloud.sh
# SCRIPT: deploy-ssl-nextcloud.sh
# AUTHOR: NHAN NGUYEN
# PLATFORM: TrueNAS CORE 13.0 or higher Nextcloud Jail
# URL: https://github.com/nn0x96a/truenas_core_nextcloud

##########################################################
################ BEGINNING OF MAIN #######################
##########################################################

#This function will create a backup or restore config.php
menu() {
    while true; do
        echo ""
        echo "#################################################################"
        echo "#### DEPLOY LET'S ENCRYPT CERTS WITH ACME.SH ON TRUENAS CORE ####"
        echo "#################################################################"
        echo ""
        echo "   Press Ctrl + C to terminate the script at any point"
        echo ""
        echo "1. Install acme.sh package"
        echo "2. Backup/Restore (config.php, account.conf, and nginx.conf)"
        echo "3. Edit the 'trusted_domains' setting in config/config.php"
        echo "4. Edit /root/.acme.sh/account.conf"
        echo "5. Deploy Let's Encrypt certificate on Nextcloud"
        echo "6. Deploy Let's Encrypt certificate to TrueNAS CORE"
        echo "7. Exit"
        echo ""
        read -p "Please select the above options: " ANSWER
        echo ""
        case $ANSWER in
            [1]) install_acme;;
            [2]) backup_restore;;
            [3]) edit_config_php;;
            [4]) edit_account_conf;;
            [5]) deploy_cert_nextcloud;;
            [6]) deploy_cert_truenas;;
            [7]) printf "Courtesy of SYSADMIN102 LLC™\n\n"; exit;;
           *)  echo "Invalid option, please select the above options: ";;
        esac
    done
}

# This function will install ACME Client.
install_acme() {
    # Install acme.sh
    pkg install security/acme.sh
    acme.sh --upgrade
    # Check if the installtion was sucessful
    if pkg install security/acme.sh; then
        echo "The acme.sh script was sucessfully installed."
        return 0
    else
        echo "The package failed to installed. $?"
    fi

}

# This function will back up or restore config.php, account.conf, and nginx.conf
backup_restore() {
    while true; do
        echo ""
        echo "####################### BACKUP & RESTORE  #######################"
        echo "1. Backup config.php, account.conf, and nginx.conf"
        echo "2. Restore config.php"
        echo "3. Restore account.conf"
        echo "4. Restore nginx.conf"
        echo "5. Return to main menu"
        read -p "Please select the above options: " ANSWER
        case $ANSWER in
            [1])    cp /usr/local/www/nextcloud/config/config.php /usr/local/www/nextcloud/config/backup_config.php;
                    cp /root/.acme.sh/account.conf /root/.acme.sh/backup_account.conf;
                    cp /usr/local/etc/nginx/nginx.conf /usr/local/etc/nginx/backup_nginx.conf;
                    printf "Backup has been created for config.php, account.conf, and nginx.conf\n";;
            [2])    cp /usr/local/www/nextcloud/config/backup_config.php /usr/local/www/nextcloud/config/config.php;
                    printf "config.php has been restored from backup\n";;
            [3])    cp /root/.acme.sh/backup_account.conf /root/.acme.sh/account.conf;
                    printf "account.conf has been restored from backup\n";;
            [4])    cp /usr/local/etc/nginx/backup_nginx.conf /usr/local/etc/nginx/nginx.conf;
                    printf "nginx.conf has been restored from backup\n";;
            [5])    menu;;
            * )     echo "Invalid option, please select the above options: ";;
        esac
    done
}

# This function will check the "trusted_domains" setting in config/config.php
trusted_domain() {
    while true; do
        read -p "Do you want to add 'trusted_domains'? Y/N: " ANSWER
        case $ANSWER in
            [Yy]* ) edit_config_php; break;;
            [Nn]* ) exit;;
                * ) echo "Please answer Y, or N: ";;
        esac
    done
}

# This function will edit the "trusted_domains" setting in /usr/local/www/nextcloud/config/config.php
edit_config_php() {
    HOSTNAME=$(hostname -f)
    while true; do
        printf "\nYour hostname is %s.\n" "$HOSTNAME"
        read -p  "Please enter your domain (ex: sysadmin102.com): " DOMAIN
        read -p  "Please enter your IPv4 address (ex: 10.13.2.133): " IP_ADDR
        printf "\n\nYour subdomain is: %s\n" "$HOSTNAME.$DOMAIN"
        printf "Your IPv4 address is:  %s\n\n" "$IP_ADDR"
        printf "\nThe following lines will overwrite the original lines in your config.php\n\n"
        printf "'host' => '%s',\n" "$HOSTNAME.$DOMAIN"
        printf "0 => '%s',\n" "$HOSTNAME.$DOMAIN"
        printf "1 => '%s',\n" "$IP_ADDR"
        printf "'overwrite.cli.url' => 'https://%s',\n\n" "$HOSTNAME.$DOMAIN"

        read -p "Yes to write to file, No to corrrect subdomain and IP Address Y/N: " ANSWER

        case $ANSWER in
            [Yy]* ) sed -i '' "s/'host' => 'localhost',/'host' => '$HOSTNAME.$DOMAIN',/" /usr/local/www/nextcloud/config/config.php;
                    sed -i '' "s/0 => 'localhost',/0 => '$HOSTNAME.$DOMAIN',/" /usr/local/www/nextcloud/config/config.php;
                    sed -i '' "s/1 => '.*,/1 => '$IP_ADDR',/" /usr/local/www/nextcloud/config/config.php;
                    sed -i '' "s,http://localhost,https://$HOSTNAME.$DOMAIN," /usr/local/www/nextcloud/config/config.php;
                    printf "\n\n%s and %s added to 'trusted_domains'\n" "$HOSTNAME.$DOMAIN" "$IP_ADDR"; 
                    menu;;
            [Nn]* ) edit_config_php;;
                * ) echo "Please answer Y, or N: ";;
        esac
    done
}

# This function will edit the account.conf in /root/.acme.sh/account.conf
edit_account_conf() {
    printf "You will need DNS API credentials and TrueNAS API Key before proceeding.\n\n"
    printf "Visit ACME.SH Wiki Page to get the correct config for your DNS API:\n"
    printf "https://github.com/acmesh-official/acme.sh/wiki/dnsapi\n\n"
    printf "Input DNS API variables or paste it, and Ctrl-D when done\n"
    keyvariable=$(cat)
    printf "\n\nThe following line will be appended to /root/.acme.sh/account.conf:\n"
    echo "$keyvariable"
    echo ""
    while true; do
        read -p "Do you wish to continue? Y/N: " ANSWER
        case $ANSWER in
            [Yy]* ) echo "$keyvariable" >> /root/.acme.sh/account.conf;
                    echo "DNS API variables added to account.conf";
                    echo ""; break;;
            [Nn]* ) echo "Return to main menu"; break;;
                * ) echo "Please answer Y, or N: ";;
        esac
    done
}

# This function will deploy SSL certs on Nextcloud Jail
deploy_cert_nextcloud() {
    printf "Visit ACME.SH Wiki Page to get the correct syntax for your DNS API:\n"
    printf "https://github.com/acmesh-official/acme.sh/wiki/dnsapi\n\n"
    read -p "Enter your DNS API (ex: dns_cloudns): " DNSAPI
    read -p  "Please enter your domain (ex: sysadmin102.com): " DOMAIN
    read -p "Enter your email to be registered with Let's Encrypt Server: " EMAIL
    echo "Change directory to: /root/.acme.sh"
    cd /root/.acme.sh || exit
  
    while true; do
        read -p "Do you wish to continue? Y/N: " ANSWER
        case $ANSWER in
            [Yy]* ) ./acme.sh --register-account -m "$EMAIL";
                    ./acme.sh --issue --dns "$DNSAPI" -d "$DOMAIN" -d "*.$DOMAIN";
                    update_nginx_conf;
                    ./acme.sh --install-cronjob;
                    menu;;
            [Nn]* ) menu;;
                * ) echo "Please answer Y, or N: ";;
        esac
    done
}

# This function will update the path to ACME SSL certs
update_nginx_conf() {
    CERTPATH="ssl_certificate "
    NEWCERTPATH=$(find / -name "$DOMAIN".cer)
    KEYPATH="ssl_certificate_key "
    NEWKEYPATH=$(find / -name "$DOMAIN".key)
    CAPATH="ssl_trusted_certificate "
    NEWCAPATH=$(find / -name ca.cer)
    
    echo "Update the path to ssl_cert in /usr/local/etc/nginx/nginx.conf"
    sed -i '' "s|$CERTPATH.*|ssl_certificate $NEWCERTPATH;|g" /usr/local/etc/nginx/nginx.conf
    sed -i '' "s|$KEYPATH.*|ssl_certificate_key $NEWKEYPATH;|g" /usr/local/etc/nginx/nginx.conf
    sed -i '' "s|$CAPATH.*|ssl_trusted_certificate $NEWCAPATH;|g" /usr/local/etc/nginx/nginx.conf
    service nginx restart
}

# This function will deploy SSL Certs to TrueNAS CORE
deploy_cert_truenas() {
    printf "Visit SYSADMIN102 Blog to get steps by steps instruction on generating API key\n"
    printf "https://sysadmin102.com/2023/05/how-to-generate-api-keys-on-truenas/\n\n"
    
    read -p "Input TrueNAS API key: " APIKEY
    read -p "Please enter your domain (ex: sysadmin102.com): " DOMAIN
    read -p "Input TrueNAS hostname (ex: truenas.sysadmin102.tech): " HOSTNAME
    
    printf "\nThe following line will be appended to /root/.acme.sh/account.conf:\n"
    printf "DEPLOY_TRUENAS_APIKEY='%s'\n" "$APIKEY"
    printf "DEPLOY_TRUENAS_HOSTNAME='%s'\n\n" "$HOSTNAME"
    
    # Add deploy hook to the account.conf in /root/.acme.sh/account.conf
    while true; do
        read -p "Do you wish to continue? Y/N: " ANSWER
        case $ANSWER in
            [Yy]* ) echo "DEPLOY_TRUENAS_APIKEY='""$APIKEY""'" >> /root/.acme.sh/account.conf;
                    echo "DEPLOY_TRUENAS_HOSTNAME='""$HOSTNAME""'" >> /root/.acme.sh/account.conf;
                    echo "";
                    echo "TrueNAS CORE deploy hook added to account.conf"; break;;
            [Nn]* ) menu;;
                * ) echo "Please answer Y, or N: ";;
        esac
    done
    
    echo "Change directory to: /root/.acme.sh"
    cd /root/.acme.sh || exit
    
    echo " Deploying SSL certs to TrueNAS CORE"
    ./acme.sh --insecure --deploy -d "$DOMAIN" --deploy-hook truenas
    
    exit;
}

# Call for function
menu
