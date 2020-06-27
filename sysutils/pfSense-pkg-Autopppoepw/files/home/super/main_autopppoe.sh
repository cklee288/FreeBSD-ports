#!/bin/bash
#orig="Feb 25 09:10:00 UTC 2020"

logfile=/home/super/autopppradius.log
oriconfig=/cf/conf/backup/config.xml
systemlog=/home/super/testradius.txt
copyconfig=/home/super/config.xml
tempconfig=/home/super/tempconfig.xml

tempuser=/home/super/tempusername
duration=15
echo "checkpoint0"

if [[ ! -z $1 ]]; then
    oriconfig=$1
fi

if [[ ! -z $2 ]]; then
    logfile=$2
fi

if [[ ! -z $3 ]]; then
    systemlog=$3
fi

if [[ ! -z $4 ]]; then
    duration=$4
fi

echo "checkpoint0.5"
cp $oriconfig $copyconfig

NOW=$(date +"%Y%m%dT%H%M%SZ")

GETDNSIP=`dig +short www.google.com @8.8.8.8`
echo "$NOW dig google.com reply : $GETDNSIP " >> $logfile
echo "$NOW oriconfig = $oriconfig ; systemlog = $systemlog  " >> $logfile
echo "checkpoint1"
if [[ "$GETDNSIP" == *'timed out'* ]]; then
     echo "match timeout"
    updateprimarypppoeuser=$(sed -n "/<varupdateprimarypppoeuser>/p" $copyconfig | sed -E "s/^(.*)(<varupdateprimarypppoeuser>)(.*)(<\/varupdateprimarypppoeuser>)/\3/")
    echo "$NOW checkpoint2 updateprimarypppoeuser = $updateprimarypppoeuser" >> $logfile  
    if [[ "$updateprimarypppoeuser" == auto ]]; then
      
          grep "Auth.*Login" $systemlog | tail -1 | sed -E 's/^(...................).*\[(.*)\/(.*)].*vlan(...).*/\1 \2 \3 \4/' > $tempuser
       #   grep "radius.*Login" $systemlog | tail -1 | sed -E 's/^(...............).*\[.*\[(.*)\/(.*)].*vlan([0-9]*) .*/\1 \2 \3 \4/'  > $tempuser
          echo "$NOW gather info: $(cat "$tempuser")" >> $logfile

          declare -a myArray
          myArray=(`cat "$tempuser"`)
          ## ${myArray[0]} mon - sunday 
          ## ${myArray[1]} ${myArray[2]} ${myArray[3]} date
          ## ${myArray[4]}=learnuser ${myArray[5]}=cleartextlearnpass ${myArray[6]}=learnvlan
          b64learnpassword=$(echo -n "${myArray[5]}" | openssl base64)
          echo "b64learnpassword $b64learnpassword"
          echo "checkpoint3"
          if [[ ! -z "${myArray[4]}" ]]; then

               #for (( i = 0 ; i < 9 ; i++))
               #do
               #  echo "Element [$i]: ${myArray[$i]}" >> $logfile 
               #done

               orig="${myArray[1]} ${myArray[2]} ${myArray[3]}"
               #orig="Feb 25 09:10:00"
               epoch=$(date -j -f "%b %d %T %Z %Y" "$orig"  +"%s")
              epochnow=$(date -j -f "%a %b %d %T %Z %Y" "`date`" +"%s")

               epoch_to_date=$(date -r $epoch +%Y%m%d_%H%M%S)    

               #echo "RESULTS:"
               #echo "original = $orig"
               #echo "epoch time now = $epochnow"
               #echo "epoch conv = $epoch"
               #echo "epoch to human readable time stamp = $epoch_to_date"

               different=$(((epochnow - epoch) / 60))
               echo "$NOW current time - $orig = $different mins, duration = $duration" >> $logfile
               echo "checkpoint4"

           #    if [[ $different -lt $duration ]]; then
                if (( $different < $duration )); then
                  echo "checkpoint5"

                   NOW=$(date +"%Y%m%dT%H%M%SZ")
                   echo "$NOW pppoe username MAC process" >> $logfile 
                   bash /home/super/autopppoeprimaryuser_param.sh ${myArray[4]} ${myArray[5]} ${myArray[6]} auto ${copyconfig} ${logfile}
                   bash /home/super/updatepppoeprimaryuser_param.sh ${myArray[4]} ${b64learnpassword} ${myArray[6]} auto ${copyconfig} ${logfile}
               fi
           fi   
    elif [[ "$updateprimarypppoeuser" == manual ]]; then

        startautopppoe=$(grep -n "<autopppoepw>" $copyconfig | sed -E 's/^(.*)\:(.*)/\1 /' )
        endautopppoe=$(grep -n "</autopppoepw>" $copyconfig | sed -E 's/^(.*)\:(.*)/\1 /')
        echo "start = ${startautopppoe} stop = ${endautopppoe}"
        primaryline=$(sed -n "${startautopppoe},${endautopppoe}p" $copyconfig | grep -n "<varenable>on" | sed -E 's/^(.*)\:(.*)/\1 /' )
        echo "${primaryline}"  
        if [[ -z ${primaryline} ]]; then
            NOW=$(date +"%Y%m%dT%H%M%SZ")
            echo "$NOW no primary user found in manual entry" >> $logfile

        else
            NOW=$(date +"%Y%m%dT%H%M%SZ")
            echo "$NOW found primary user in manual entry" >> $logfile

            i=0
            for rfeachline in ${primaryline}
            do  
       	       ## ensure only 1st primary user used.	
               if [[ ${i} == 0 ]]; then
                   primaryuserline=$(($startautopppoe+$rfeachline+2))
                   primarypassline=$(($primaryuserline+1))
                   primarytelcoline=$((primaryuserline-2))
                   primaryvlanidline=$((primaryuserline-1))
                   oriprimaryuser=$(sed -E "$primaryuserline s/^(.*)(<username>)(.*)(<\/username>)/\3/" $copyconfig | sed -n "${primaryuserline}p")
                   oriprimaryencpassword=$(sed -E "$primarypassline s/^(.*)(<password>)(.*)(<\/password>)/\3/" $copyconfig | sed -n "${primarypassline}p")
                   oriprimarytelco=$(sed -E "$primarytelcoline s/^(.*)(<telco>)(.*)(<\/telco>)/\3/" $copyconfig | sed -n "${primarytelcoline}p")
                   oriprimaryvlanid=$(sed -E "$primaryvlanidline s/^(.*)(<vlanid>)(.*)(<\/vlanid>)/\3/" $copyconfig | sed -n "${primaryvlanidline}p")

                   echo "$NOW manual primary username = $oriprimaryuser; password = $oriprimaryencpassword" >> $logfile

                   if  [[ -z "${oriprimaryuser}" ]]; then
                       NOW=$(date +"%Y%m%dT%H%M%SZ")
                       echo "$NOW username empty abort pppoe user update" >> $logfile

                   else

                       bash /home/super/updatepppoeprimaryuser_param.sh ${oriprimaryuser} ${oriprimaryencpassword} ${oriprimaryvlanid} ${oriprimarytelco} ${copyconfig} ${logfile}

                   fi

                fi
                (( i=i+1))
                echo i
            done     
        fi
    fi
   # echo "test001"
    diffout=$(diff "$oriconfig" "$copyconfig")   
    
    if [[ ! -z ${diffout} ]]; then

       NOW=$(date +"%Y%m%dT%H%M%SZ")
       echo "$NOW pppoe username different found. update actual config file and restart WAN interface" >> $logfile
       cp $copyconfig $oriconfig
       rm /tmp/config.cache
       php  -r 'include  "/etc/inc/interfaces.inc"; interface_reconfigure("wan", false);'

    fi
 #  # echo "test1"
else

    NOW=$(date +"%Y%m%dT%H%M%SZ")
    updateprimarypppoeuser=$(sed -n "/<varupdateprimarypppoeuser>/p" $copyconfig | sed -E "s/^(.*)(<varupdateprimarypppoeuser>)(.*)(<\/varupdateprimarypppoeuser>)/\3/")
    echo "checkpointInternetUp"
    if [[ "$updateprimarypppoeuser" == auto ]]; then    

        echo "$NOW Internet up. add or update freeradius user" >> $logfile

        startautopppoe=$(grep -n "<autopppoepw>" $copyconfig | sed -E 's/^(.*)\:(.*)/\1 /' )
        endautopppoe=$(grep -n "</autopppoepw>" $copyconfig | sed -E 's/^(.*)\:(.*)/\1 /')
        echo "start = ${startautopppoe} stop = ${endautopppoe}"
        primaryline=$(sed -n "${startautopppoe},${endautopppoe}p" $copyconfig | grep -n "<varenable>on" | sed -E 's/^(.*)\:(.*)/\1 /' )
        echo "${primaryline}"  
        if [[ -z ${primaryline} ]]; then
            NOW=$(date +"%Y%m%dT%H%M%SZ")
            echo "$NOW no primary user found in entry" >> $logfile

        else
            NOW=$(date +"%Y%m%dT%H%M%SZ")
            echo "$NOW found primary user in entry" >> $logfile

            i=0
            for rfeachline in ${primaryline}
            do  
       	       ## ensure only 1st primary user used.	
               if [[ ${i} == 0 ]]; then
                   primaryuserline=$(($startautopppoe+$rfeachline+2))
                   primarypassline=$(($primaryuserline+1))
                   primarytelcoline=$((primaryuserline-2))
	           primaryvlanidline=$((primaryuserline-1))
                   oriprimaryuser=$(sed -E "$primaryuserline s/^(.*)(<username>)(.*)(<\/username>)/\3/" $copyconfig | sed -n "${primaryuserline}p")
                   oriprimaryencpassword=$(sed -E "$primarypassline s/^(.*)(<password>)(.*)(<\/password>)/\3/" $copyconfig | sed -n "${primarypassline}p")
                   oriprimarytelco=$(sed -E "$primarytelcoline s/^(.*)(<telco>)(.*)(<\/telco>)/\3/" $copyconfig | sed -n "${primarytelcoline}p")
                   oriprimaryvlanid=$(sed -E "$primaryvlanidline s/^(.*)(<vlanid>)(.*)(<\/vlanid>)/\3/" $copyconfig | sed -n "${primaryvlanidline}p")

                   echo "$NOW manual primary username = $oriprimaryuser; password = $oriprimaryencpassword" >> $logfile

                   if  [[ -z "${oriprimaryuser}" ]]; then
                       NOW=$(date +"%Y%m%dT%H%M%SZ")
                       echo "$NOW username empty abort pppoe user update" >> $logfile

                   else

                       bash /home/super/radiusprimaryuser_param.sh ${oriprimaryuser} ${oriprimaryencpassword} ${copyconfig} ${logfile}

                   fi

                fi
                (( i=i+1))
            done

        fi
        ## start disabled varupdateprimarypppoeuser on ##
        NOW=$(date +"%Y%m%dT%H%M%SZ")
        echo "$NOW change varupdateprimarypppoeuser from auto to disabled" >> $logfile
        sed -E "s/^(.*)(<varupdateprimarypppoeuser>).*(<\/varupdateprimarypppoeuser>)/\1\2disabled\3/" $copyconfig > $tempconfig
        cp $tempconfig $copyconfig
        ## end disabled varupdateprimarypppoeuse on ##

    elif  [[ "$updateprimarypppoeuser" == manual ]]; then    
        ## start disabled varupdateprimarypppoeuser on ##
        NOW=$(date +"%Y%m%dT%H%M%SZ")
        echo "$NOW change varupdateprimarypppoeuser from manual to disabled" >> $logfile
        sed -E "s/^(.*)(<varupdateprimarypppoeuser>).*(<\/varupdateprimarypppoeuser>)/\1\2disabled\3/" $copyconfig > $tempconfig
        cp $tempconfig $copyconfig
        ## end disabled varupdateprimarypppoeuse on ##
    fi
   

    diffout=$(diff "$oriconfig" "$copyconfig")
    
    if [[ ! -z ${diffout} ]]; then

       NOW=$(date +"%Y%m%dT%H%M%SZ")
       echo "$NOW disable autopppoe or update freeradius actual config and restart freeradius service" >> $logfile

       cp $copyconfig $oriconfig
       echo " freeradius primary update copied from $copyconfig to $oriconfig"
       rm /tmp/config.cache
       #php  -r 'include  "/etc/inc/pkg-utils.inc"; send_event("service XXX restart");'
       php  -r 'include  "/usr/local/pkg/freeradius.inc"; freeradius_settings_resync(false);'
       php  -r 'include  "/usr/local/pkg/freeradius.inc"; freeradius_users_resync();'
       #php  -r 'include  "/etc/inc/service-utils.inc"; restart_service(radiusd);'
     #  diff $copyconfig $oriconfig

    fi
fi 
