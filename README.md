# truenas_core_nextcloud
Script to deploy SSL on nextcloud jail on TrueNAS CORE 13 or higher.

Installation

  Login to jail via SSH: iocage console "Jail Name"
	
  Download bash script:

  curl -LJO  https://raw.githubusercontent.com/nn0x96a/truenas_core_nextcloud/main/deploy-ssl-nextcloud.sh
  
	Set execute permission: chmod 755 deploy-ssl-nextcloud.sh
  
	Execute the script: ./deploy-ssl-nextcloud.sh
  
	Follow the the steps on main menu.
	
Usage
	
Prerequisites 
	
	DNS API variables: https://github.com/acmesh-official/acme.sh/wiki/dnsapi
	
	TrueNAS API Key: https://sysadmin102.com/2023/05/how-to-generate-api-keys-on-truenas

  
