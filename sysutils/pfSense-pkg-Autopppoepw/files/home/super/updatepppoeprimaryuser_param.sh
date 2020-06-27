#!/bin/bash

# default declaration

username="default"
newpassword="password"
vlanid="500"
telco="telco"
configfile=/home/super/config.xml
tempconfig=/home/super/tempconfig.xml
logfile=/home/super/autopppradius.log

tempconfig1=/home/super/tempconfig1.xml

NOW=$(date +"%Y%m%dT%H%M%SZ")

changemake=0

if [[ ! -z $1 ]]; then
    username="$1"
fi

if [[ ! -z $2 ]]; then
    newpassword="$2"
fi

if [[ ! -z $3 ]]; then
     vlanid="$3"
     if ! [[ "$vlanid" =~ ^[0-9]+$ && "$vlanid" -le  4096 ]]; then           
           echo "$NOW vlan $vlanid is not a integer or within 0-4096, Exit error code 1" >> $logfile
           exit 1
     fi
fi

if [[ ! -z $4 ]]; then
    telco=$4
fi


if [[ ! -z $5 ]]; then
    configfile=$5
fi


if [[ ! -z $6 ]]; then
    logfile=$6
fi


cp $configfile $tempconfig 

#b64newpassword=$(echo -n "$newpassword" | openssl base64)

b64newpassword=$newpassword 

echo "base64 password = $b64newpassword"

interfacetype=$(sed -n '/<vlanif>/p' $tempconfig | sed -E 's/^.*(<vlanif>)([A-Za-z]+0)(.*)(<\/vlanif>)/\2/' )

echo $interfacetype
     i=0
     for rfinterfacetype in ${interfacetype}
     do
        echo $rfinterfacetype
          
         anywrongoutput=$(echo $rfinterfacetype | sed -E 's/^.*(vlanif)(.*)/\1/' )
         echo "wrongoutput = ${anywrongoutput} "

        ## ensure only 1st interfacetype taken.
       #  if [[ ${i} == 0 ]]; then # replace with below logic, if still contain vlanif skip, 

         if [[ ${anywrongoutput} != "vlanif" ]]; then  
             interface="${rfinterfacetype}"
             interfacevlan="${rfinterfacetype}.${vlanid}"
             echo "found interfacetype.vlanid = ${interfacevlan} "
         fi
         (( i=i+1))
         echo $i
     done

startvlans=$(grep -n "<vlans>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /' )
endvlans=$(grep -n "</vlans>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /')
echo "vlans start = ${startvlans} stop = ${endvlans}"
vlanintline=$(sed -n "${startvlans},${endvlans}p" $tempconfig | grep -n "<vlanif>${interfacevlan}<\/vlanif>" | sed -E 's/^(.*)\:(.*)/\1 /' )
echo "vlanintline $vlanintline"

if [[ -z ${vlanintline} ]]; then

     NOW=$(date +"%Y%m%dT%H%M%SZ")
     echo "$NOW can't find $interfacevlan in vlans, Append" >> $logfile

     sed  "/<vlans>/ a\\
                <vlan>\\
                        <if>$interface</if>\\
                        <tag>$vlanid</tag>\\
                        <pcp></pcp>\\
                        <descr><![CDATA[$telco PPPoE vlan $vlanid (WAN)]]></descr>\\
                        <vlanif>$interface.$vlanid</vlanif>\\
                </vlan>
     " $tempconfig > $tempconfig1
     cp $tempconfig1 $tempconfig
     changemake=1
fi 

startppps=$(grep -n "<ppps>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /' )
endppps=$(grep -n "</ppps>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /')
echo "ppps start = ${startppps} stop = ${endppps}"
pppintline=$(sed -n "${startppps},${endppps}p" $tempconfig | grep -n "<if>pppoe0</if>" | sed -E 's/^(.*)\:(.*)/\1 /' )
echo "pppintline $pppintline"

if [[ "${startppps}" == "${endppps}" ]]; then
     NOW=$(date +"%Y%m%dT%H%M%SZ")
     echo "$NOW total new PPPoE setup, no even single PPP user, Append"
     echo "$NOW total new PPPoE setup, no even single PPP user, Append" >> $logfile
#     exit 2

     sed  "/<ppps>/ a\\
                <ppp>\\
                        <ptpid>0</ptpid>\\
                        <type>pppoe</type>\\
                        <if>pppoe0</if>\\
                        <ports>$interfacevlan</ports>\\
                        <username>$username</username>\\
                        <password>$b64newpassword</password>\\
                        <descr><![CDATA[${telco}_1stPPPoE]]></descr>\\
                        <provider></provider>\\
                        <bandwidth></bandwidth>\\
                        <mtu></mtu>\\
                        <mru></mru>\\
                        <mrru></mrru>\\
                </ppp>\\
           </ppps>
     " $tempconfig > $tempconfig1

    sed -E "s/<ppps><\/ppps>/<ppps>/" $tempconfig1 > $tempconfig
  #   cp $tempconfig1 $tempconfig
     changemake=1

elif [[ -z ${pppintline} ]]; then
     NOW=$(date +"%Y%m%dT%H%M%SZ")
     echo "$NOW cannot find <if>pppoe0</if> in PPPoE, Append" >> $logfile
#     exit 2

     sed  "/<ppps>/ a\\
               <ppp>\\
                        <ptpid>0</ptpid>\\
                        <type>pppoe</type>\\
                        <if>pppoe0</if>\\
                        <ports>$interfacevlan</ports>\\
                        <username>$username</username>\\
                        <password>$b64newpassword</password>\\
                        <descr><![CDATA[${telco}_1stPPPoE]]></descr>\\
                        <provider></provider>\\
                        <bandwidth></bandwidth>\\
                        <mtu></mtu>\\
                        <mru></mru>\\
                        <mrru></mrru>\\
                </ppp>
     " $tempconfig > $tempconfig1
     cp $tempconfig1 $tempconfig
     changemake=1


else
     NOW=$(date +"%Y%m%dT%H%M%SZ")
     echo "$NOW found <if>pppoe0</if> with PPPoE" >> $logfile
     pppoeportsline=$(($startppps+$pppintline))
     pppoeuserline=$(($startppps+$pppintline+1))     
     pppoepassline=$(($pppoeuserline+1))
     pppoedescline=$(($pppoepassline+1))

     oriports=$(sed -E "$pppoeportsline s/^(.*)(<ports>)(.*)(<\/ports>)/\3/" $tempconfig | sed -n "${pppoeportsline}p")
     oripppuser=$(sed -E "$pppoeuserline s/^(.*)(<username>)(.*)(<\/username>)/\3/" $tempconfig | sed -n "${pppoeuserline}p")
     orippppassword=$(sed -E "$pppoepassline s/^(.*)(<password>)(.*)(<\/password>)/\3/" $tempconfig | sed -n "${pppoepassline}p")

     echo "$NOW $interfacevlan original username = $oripppuser; password = $orippppassword; port = $oriports" >> $logfile
    
     echo "interfacevlan = ${interfacevlan}"
    
      if  [[ "$interfacevlan" != "$oriports" ]]; then
           NOW=$(date +"%Y%m%dT%H%M%SZ")
           echo "$NOW ports mismatch ; replace ports" >> $logfile

#           sed -E "$pppoeportsline s/^(.*)(<ports>).*(<\/ports>)/\1\2$interfacevlan\3/" $tempconfig > $tempconfig1
           sed -E "$pppoeportsline s/^(.*)(<ports>).*(<\/ports>)/\1\2$interfacevlan\3/; $pppoedescline s/^(.*)(<descr>).*(<\/descr>)/\1\2<![CDATA[${telco}_1stPPPoE]]>\3/" $tempconfig > $tempconfig1      

           cp $tempconfig1 $tempconfig
           changemake=1

    fi 

    if  [[ "$username" != "$oripppuser" ]]; then
           NOW=$(date +"%Y%m%dT%H%M%SZ")
           echo "$NOW username not found; replace username/password" >> $logfile

           sed -E "$pppoeuserline s/^(.*)(<username>).*(<\/username>)/\1\2$username\3/" $tempconfig > $tempconfig1
           sed -E "$pppoepassline s/^(.*)(<password>).*(<\/password>)/\1\2$b64newpassword\3/; $pppoedescline s/^(.*)(<descr>).*(<\/descr>)/\1\2<![CDATA[${telco}_1stPPPoE]]>\3/" $tempconfig1 > $tempconfig
           changemake=1

     elif [[ "$username" == "$oripppuser" && "$b64newpassword" != "$orippppassword" ]]; then

           NOW=$(date +"%Y%m%dT%H%M%SZ")
           echo "$NOW username found, password incorrect : update password " >> $logfile

           sed -E "$pppoepassline s/^(.*)(<password>).*(<\/password>)/\1\2$b64newpassword\3/; $pppoedescline s/^(.*)(<descr>).*(<\/descr>)/\1\2<![CDATA[${telco}_1stPPPoE]]>\3/" $tempconfig > $tempconfig1
           cp $tempconfig1 $tempconfig
           changemake=1

     else
           NOW=$(date +"%Y%m%dT%H%M%SZ")
           echo "$NOW same pppoe username/password, futher check whether pppoe0 on WAN interface" >> $logfile

     fi
fi

startinterfaces=$(grep -n "<interfaces>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /' )
endinterfaces=$(grep -n "</interfaces>" $tempconfig | sed -E 's/^(.*)\:(.*)/\1 /')
echo "interfaces start = ${startinterfaces} stop = ${endinterfaces}"
wanstrintline=$(sed -n "${startinterfaces},${endinterfaces}p" $tempconfig | grep -n "<wan>" | sed -E 's/^(.*)\:(.*)/\1 /' )
wanendintline=$(sed -n "${startinterfaces},${endinterfaces}p" $tempconfig | grep -n "</wan>" | sed -E 's/^(.*)\:(.*)/\1 /' )

startwan=$(($startinterfaces+$wanstrintline))
endwan=$(($startinterfaces+$wanendintline))
deletewan1stline=$(($startwan-1))     
deletewanlastline=$(($endwan-1))

pppoe0intline=$(sed -n "${startwan},${endwan}p" $tempconfig | grep -n "<if>pppoe0<\/if>" | sed -E 's/^(.*)\:(.*)/\1 /' )
echo "pppoe0intline $pppoe0intline"



## if found changes, only start to check WAN interface and update configuration or not found pppoe0 line in WAN##

if [[ $changemake == 1 || -z ${pppoe0intline} ]]; then

     if [[ -z ${pppoe0intline} ]]; then
          NOW=$(date +"%Y%m%dT%H%M%SZ")
          echo "$NOW cannot find <if>pppoe0</if> in wan, append" >> $logfile
#         #exit 2
          sed -E "${deletewan1stline},${deletewanlastline}d" $tempconfig > $tempconfig1

          sed  "/<interfaces>/ a\\
                <wan>\\
                        <if>pppoe0</if>\\
                        <descr><![CDATA[${telco}_1stPPPoE]]></descr>\\
                        <spoofmac></spoofmac>\\
                        <enable></enable>\\
                        <ipaddr>pppoe</ipaddr>\\
                        <ipaddrv6>dhcp6</ipaddrv6>\\
                        <dhcp6-duid></dhcp6-duid>\\
                        <dhcp6-ia-pd-len>8</dhcp6-ia-pd-len>\\
                        <dhcp6-ia-pd-send-hint></dhcp6-ia-pd-send-hint>\\
                        <dhcp6usev4iface></dhcp6usev4iface>\\
                        <adv_dhcp6_prefix_selected_interface>wan</adv_dhcp6_prefix_selected_interface>\\
                        <blockbogons></blockbogons>\\
                </wan>
           " $tempconfig1 > $tempconfig
     fi

      echo "$NOW updatepppoe  copy tempconfig to copyconfig" >> $logfile
      cp $tempconfig $configfile
fi
