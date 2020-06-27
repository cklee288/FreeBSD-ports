#!/bin/bash

# default declaration
username="default"
newpassword="password"

vlanid="500"
configfile=/home/super/config.xml
logfile=/home/super/autopppradius.log
tempconfig=/home/super/tempconfig.xml
tempconfig1=/home/super/tempconfig1.xml
telco="autopppoe"

changemake=0

if [[ ! -z $1 ]]; then
    username="$1"
fi

if [[ ! -z $2 ]]; then
    newpassword="$2"
fi

if [[ ! -z $3 ]]; then
     vlanid="$3"
fi

if [[ ! -z $4 ]]; then
     telco="$4"
fi


if [[ ! -z $5 ]]; then
    configfile=$5
fi

if [[ ! -z $6 ]]; then
    logfile=$6
fi

cp $configfile $tempconfig

b64newpassword=$(echo -n "$newpassword" | openssl base64)

echo " username = $username; password = $newpassword ; vlan = $vlanid; configfile = $configfile"

interface="0.$vlanid"
echo "base64 password = $b64newpassword"

startautopppoe=$(grep -n "<autopppoepw>" $configfile | sed -E 's/^(.*)\:(.*)/\1 /' )
endautopppoe=$(grep -n "</autopppoepw>" $configfile | sed -E 's/^(.*)\:(.*)/\1 /')
echo "start = ${startautopppoe} stop = ${endautopppoe}"
autopppoeline=$(sed -n "${startautopppoe},${endautopppoe}p" $configfile | grep -n "<vlanid>${vlanid}<\/vlanid>" | sed -E 's/^(.*)\:(.*)/\1 /' )
echo "${autopppoeline}"
if [[ -z ${autopppoeline} ]]; then

     NOW=$(date +"%Y%m%dT%H%M%SZ")
     echo "$NOW can't find username password on this vlanid $vlanid. append username " >> $logfile
     backfile=/home/super/backup/config-radius-add-$NOW.xml
## start clear varenable on ##
     sed -E "s/^(.*)(<varenable>).*(<\/varenable>)/\1\2\3/" $tempconfig > $tempconfig1
     cp $tempconfig1 $tempconfig
## end clear varenable on ##
     sed  "/<autopppoepw>/ a\\
                      <config>\\
                              <varenable>on</varenable>\\
                              <telco>$telco$NOW</telco>\\
                              <vlanid>$vlanid</vlanid>\\
                              <username>$username</username>\\
                              <password>$b64newpassword</password>\\
                      </config>\\
     " $tempconfig> $tempconfig1
     cp $tempconfig1 $tempconfig
     changemake=1
else
     NOW=$(date +"%Y%m%dT%H%M%SZ")
     echo "$NOW found username on vlan $vlanid with PPPoE" >> $logfile

     i=0
     for rfeachline in ${autopppoeline}
     do
	## enasure only 1st one with this vlanid edited.	
         if [[ ${i} == 0 ]]; then
             pppoeuserline=$(($startautopppoe+$rfeachline))
             pppoepassline=$(($pppoeuserline+1))
             pppoetelcoline=$((pppoeuserline-2))
	     pppoevarenableline=$((pppoeuserline-3))
             oripppuser=$(sed -E "$pppoeuserline s/^(.*)(<username>)(.*)(<\/username>)/\3/" $configfile | sed -n "${pppoeuserline}p")
             orippppassword=$(sed -E "$pppoepassline s/^(.*)(<password>)(.*)(<\/password>)/\3/" $configfile | sed -n "${pppoepassline}p")

             echo "$NOW $interface original username = $oripppuser; password = $orippppassword" >> $logfile

                if  [[ "$username" != "$oripppuser" ]]; then
                    NOW=$(date +"%Y%m%dT%H%M%SZ")
                    echo "$NOW username not found; replace username/password" >> $logfile
                    # backfile=/home/super/backup/config-pppoe-add$NOW.xml
		    ## start clear varenable on ##
     		    sed -E "s/^(.*)(<varenable>).*(<\/varenable>)/\1\2\3/" $tempconfig > $tempconfig1
     		    cp $tempconfig1 $tempconfig
		    ## end clear varenable on ##

                    sed -E "$pppoeuserline s/^(.*)(<username>).*(<\/username>)/\1\2$username\3/" $tempconfig > $tempconfig1
                    sed -E "$pppoepassline s/^(.*)(<password>).*(<\/password>)/\1\2$b64newpassword\3/" $tempconfig1 > $tempconfig
                    sed -E "$pppoetelcoline s/^(.*)(<telco>).*(<\/telco>)/\1\2$telco$NOW\3/" $tempconfig > $tempconfig1
                    sed -E "$pppoevarenableline s/^(.*)(<varenable>).*(<\/varenable>)/\1\2on\3/" $tempconfig1 > $tempconfig
                    changemake=1

              elif [[ "$username" == "$oripppuser" && "$b64newpassword" != "$orippppassword" ]]; then

                   NOW=$(date +"%Y%m%dT%H%M%SZ")
                   echo "$NOW username found, password incorrect : update password " >> $logfile
                   #backfile=/home/super/backup/config-pppoe-update$NOW.xml
		   ## start clear varenable on ##
     		   sed -E "s/^(.*)(<varenable>).*(<\/varenable>)/\1\2\3/" $tempconfig > $tempconfig1
     		   cp $tempconfig1 $tempconfig
		   ## end clear varenable on ##
                   sed -E "$pppoepassline s/^(.*)(<password>).*(<\/password>)/\1\2$b64newpassword\3/" $tempconfig > $tempconfig1
                   sed -E "$pppoetelcoline s/^(.*)(<telco>).*(<\/telco>)/\1\2$telco$NOW\3/" $tempconfig1 > $tempconfig
                   sed -E "$pppoevarenableline s/^(.*)(<varenable>).*(<\/varenable>)/\1\2on\3/" $tempconfig > $tempconfig1
		   cp $tempconfig1 $tempconfig
                   changemake=1

              else
                   NOW=$(date +"%Y%m%dT%H%M%SZ")
                   echo "$NOW same pppoe username/password, skip update config" >> $logfile
             fi
         fi
         (( i=i+1))
    done
fi
if [[ $changemake == 1 ]]; then
      echo "$NOW autopppoe copy tempconfig to copyconfig" >> $logfile
      cp $tempconfig $configfile
fi
