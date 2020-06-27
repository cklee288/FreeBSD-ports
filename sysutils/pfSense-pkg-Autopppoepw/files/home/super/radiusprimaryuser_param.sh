#!/bin/bash
username="default"
newpassword="password"

configfile=/home/super/config.xml
logfile=/home/super/autopppradius.log

tempconfig=/home/super/tempconfig.xml
tempconfig1=/home/super/tempconfig1.xml

changemake=0

if [[ ! -z $1 ]]; then
    username="$1"
fi

if [[ ! -z $2 ]]; then
    newpassword="$2"
fi

if [[ ! -z $3 ]]; then
   configfile=$3
fi

if [[ ! -z $4 ]]; then
   logfile=$4
fi

cp $configfile $tempconfig

decodepass=$(echo "$newpassword" | openssl base64 -d)

echo "update freeradius username = $username; password = $decodepass ; configfile = $configfile; tempconfig = $tempconfig"

startradius=$(grep -n "<freeradius>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /' )
endradius=$(grep -n "</freeradius>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /')
echo "start = ${startradius} stop = ${endradius}"
userline=$(sed -n "${startradius},${endradius}p" $tempconfig | grep -n "<varusersusername>${username}<\/varusersusername>" | sed -E 's/^(.*)\:(.*)/\1 /' )
echo "userline ${userline}"

if [[ -z ${userline} ]]; then
     NOW=$(date +"%Y%m%dT%H%M%SZ")
#     echo "$NOW can't find username, append new username to radius"
     echo "$NOW can't find username, append new username to radius" >> $logfile
#     backfile=/home/super/backup/config-radius-add-$NOW.xml
#     cp $configfile $backfile
     startappend=$(($startradius+1))
#     echo "startappend = ${startappend}"
     sed  "/<freeradius>/ a\\
                        <config>\\
                                <sortable></sortable>\\
                                <varusersusername>$username</varusersusername>\\
                                <varuserspassword>$decodepass</varuserspassword>\\
                                <varuserspasswordencryption>Cleartext-Password</varuserspasswordencryption>\\
                                <varusersmotpenable></varusersmotpenable>\\
                                <varusersauthmethod>motp</varusersauthmethod>\\
                                <varusersmotpinitsecret></varusersmotpinitsecret>\\
                                <varusersmotppin></varusersmotppin>\\
                                <varusersmotpoffset></varusersmotpoffset>\\
                                <qrcodetext></qrcodetext>\\
                                <varuserswisprredirectionurl></varuserswisprredirectionurl>\\
                                <varuserssimultaneousconnect></varuserssimultaneousconnect>\\
                                <description></description>\\
                                <varusersframedipaddress></varusersframedipaddress>\\
                                <varusersframedipnetmask></varusersframedipnetmask>\\
                                <varusersframedroute></varusersframedroute>\\
                                <varusersframedip6address></varusersframedip6address>\\
                                <varusersframedip6route></varusersframedip6route>\\
                                <varusersvlanid></varusersvlanid>\\
                                <varusersexpiration></varusersexpiration>\\
                                <varuserssessiontimeout></varuserssessiontimeout>\\
                                <varuserslogintime></varuserslogintime>\\
                                <varusersamountoftime></varusersamountoftime>\\
                                <varuserspointoftime>Daily</varuserspointoftime>\\
                                <varusersmaxtotaloctets></varusersmaxtotaloctets>\\
                                <varusersmaxtotaloctetstimerange>daily</varusersmaxtotaloctetstimerange>\\
                                <varusersmaxbandwidthdown></varusersmaxbandwidthdown>\\
                                <varusersmaxbandwidthup></varusersmaxbandwidthup>\\
                                <varusersacctinteriminterval></varusersacctinteriminterval>\\
                                <varuserstopadditionaloptions></varuserstopadditionaloptions>\\
                                <varuserscheckitemsadditionaloptions></varuserscheckitemsadditionaloptions>\\
                                <varusersreplyitemsadditionaloptions></varusersreplyitemsadditionaloptions>\\
                        </config>
     " $tempconfig > $tempconfig1
     

     cp $tempconfig1 $tempconfig
     changemake=1 

else

    radiuspassline=$(($startradius+$userline))
    oriradiuspassword=$(sed -E "$radiusepassline s/^(.*)(<varuserspassword>)(.*)(<\/varuserspassword>)/\3/" $tempconfig | sed -n "${radiuspassline}p")
#    echo "original password = ${oriradiuspassword};new password = ${decodepass};end"

    if [[ "$decodepass" != "$oriradiuspassword" ]]; then

       NOW=$(date +"%Y%m%dT%H%M%SZ")
#       echo "$NOW found username, password incorrect; update new password" 

       echo "$NOW found username, password incorrect; update new password" >> $logfile
#       backfile=/home/super/backup/config-radius-update$NOW.xml
#       cp $configfile $backfile
       passwordline=$(($startradius+$userline))
       sed -E "$passwordline s/^(.*)(<varuserspassword>).*(<\/varuserspassword>)/\1\2$decodepass\3/" $tempconfig > $tempconfig1
       cp $tempconfig1 $tempconfig
       changemake=1

    else

       NOW=$(date +"%Y%m%dT%H%M%SZ")
#       echo "$NOW username & password match, skip update" 
       echo "$NOW username & password match, skip update" >> $logfile
    fi
fi

if [[ $changemake == 1 ]]; then
      echo "$NOW radiusprimaryuser copy tempconfig to copyconfig" >> $logfile      
      cp $tempconfig $configfile
fi 
