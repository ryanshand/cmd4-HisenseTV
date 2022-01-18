#!/bin/bash

# IP Address of TV (go to TV settings to find this).
ip="192.168.1.32"

# MAC Address of the TV (go to TV settings to find this).
tvMAC="18:30:0C:FC:D1:8B"

# MAC Address of device paired to the TV through the RemoteNOW app.
pairedMAC="3D:81:F2:B6:08:B0"

# File path of saved Hisense Certificate.
certPath="/home/pi/hisense.crt"

# File path of saved RCM Hisense Certificate .CER file.
rcmCer="/home/pi/rcm_certchain_pem.cer"

# File path of saved key Hisense Certificate .PKCs8 file.
rcmKey="/home/pi/rcm_pem_privkey.pkcs8"


if [ "$1" = "Get" ]; then
  case "$3" in

    # Set to 1=CONFIGURED for all inputs added in config.json.
    IsConfigured )
      stdbuf -o0 -e0 echo 1
    ;;

    # Set to 0=SHOWN for inputs configured for all inputs added in config.json. 0=SHOWN, 1=HIDDEN, 2=STOPPED.
    TargetVisibilityState | CurrentVisibilityState )
      stdbuf -o0 -e0 echo 0
    ;;

    # Polls the TV over your network to see if it is still active.
    Active )
      if [ "$(timeout 2 /bin/bash -c "(echo > /dev/tcp/$ip/36669)" > /dev/null 2>&1 && echo 1 || echo 0)"  = '1' ]; then
        stdbuf -o0 -e0 echo 1
      else
        stdbuf -o0 -e0 echo 0
      fi
    ;;

    ActiveIdentifier )
     # ActiveIdentifier is used to return what input source the TV is using.
        if [ "$(timeout 2 /bin/bash -c "(echo > /dev/tcp/$ip/36669)" > /dev/null 2>&1 && echo 1 || echo 0)"  = '1' ]; then


         stateType=$(mosquitto_sub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -W 1 -h $ip -p 36669 -P multimqttservice -u hisenseservice -t /remoteapp/mobile/broadcast/ui_service/state | jq '.statetype')
         case "$stateType" in
	    '"livetv"' )
                      stdbuf -o0 -e0 echo 0
            ;;

            '"sourceswitch"' )
                 sourceID=$(mosquitto_sub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -W 1 -h $ip -p 36669 -P multimqttservice -u hisenseservice -t /remoteapp/mobile/broadcast/ui_service/state | jq '.sourceid')
                 case "$sourceID" in

                    '"HDMI1"' )
                             stdbuf -o0 -e0 echo 1
                    ;;
	            '"HDMI2"' )
                             stdbuf -o0 -e0 echo 2
                    ;;
                    '"HDMI3"' )
                             stdbuf -o0 -e0 echo 3
                    ;;
                    '"HDMI4"' )
                             stdbuf -o0 -e0 echo 4
                    ;;
                    '"AVS"' )
                             stdbuf -o0 -e0 echo 5
                    ;;
                  esac
              ;;

              '"app"' )
                 name=$(mosquitto_sub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -W 1 -h $ip -p 36669 -P multimqttservice -u hisenseservice -t /remoteapp/mobile/broadcast/ui_service/state | jq '.name')
                 case "$name" in

                    '"netflix"' )
                             stdbuf -o0 -e0 echo 6
                    ;;
                    '"amazon"' )
                             stdbuf -o0 -e0 echo 7
                    ;;
                    '"youtube"' )
                             stdbuf -o0 -e0 echo 8
                    ;;
                    '"foxtel"' )
                             stdbuf -o0 -e0 echo 9
                    ;;
                    '"stan"' )
                             stdbuf -o0 -e0 echo 10
                    ;;
                    '"plex"' )
                             stdbuf -o0 -e0 echo 11
                    ;;
                    '"ABC iview"' )
                             stdbuf -o0 -e0 echo 12
                    ;;
                    '"Youtube Kids"' )
                             stdbuf -o0 -e0 echo 13
                    ;;
                    '"SBS ON DEMAND"' )
                             stdbuf -o0 -e0 echo 14
                    ;;
                    '"AppsNow"' )
                             stdbuf -o0 -e0 echo 15
                    ;;
                    '"Kidoodle.TV"' )
                             stdbuf -o0 -e0 echo 16
                    ;;
                    '"Game Center"' )
                             stdbuf -o0 -e0 echo 17
                    ;;
                    '"Toon Goggles"' )
                             stdbuf -o0 -e0 echo 18
                    ;;
                    '"YuppTV"' )
                             stdbuf -o0 -e0 echo 19
                    ;;
                    '"AccuWeather"' )
                             stdbuf -o0 -e0 echo 20
                    ;;
                    '"TV Browser"' )
                             stdbuf -o0 -e0 echo 21
                    ;;
                            
                  esac
              ;;
            esac

        else
          stdbuf -o0 -e0 echo 0
        fi
    ;;

  esac
fi

if [ "$1" = "Set" ]; then
  case "$3" in

    Active )
      if [ "$4" = "1" ]; then
        #TV can only be turned back on by WOL using MAC ADDRESS
        wakeonlan $tvMAC

      else
        #TV can turn off using MQTT
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey   --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_POWER"
      fi
    ;;

    ActiveIdentifier )
    # ActiveIdentifier is used to set what input source the TV is using.
      case "$4" in
        #TV
        0 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey   --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"sourceid":"0","sourcename":"TV"}'
        ;;

        #HDMI1
        1 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey  --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"sourceid":"4","sourcename":"HDMI1"}'
        ;;

	#HDMI2
        2 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey  --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"sourceid":"5","sourcename":"HDMI2"}'
        ;;

	#HDMI3
        3 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"sourceid":"6","sourcename":"HDMI3"}'
        ;;

	#AV
        5 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"sourceid":"1","sourcename":"AV"}'
        ;;

        #Netflix
        6 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"Netflix","urlType":37,"storeType":0,"url":"netflix"}'
        ;;

        #PrimeVideo
        7 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"Amazon","urlType":37,"storeType":0,"url":"amazon"}'
        ;;

        #YouTube
        8 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"YouTube","urlType":37,"storeType":0,"url":"youtube"}'
        ;;

        #Foxtel
        9 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"Amazon","urlType":37,"storeType":99,"url":"https://foxtel-go-sw.foxtelplayer.foxtel.com.au/foxtel-hisense19-300/"}'
        ;;

        #Stan
        10 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"YouTube","urlType":37,"storeType":0,"url":"https://hisense.stan.app/6886/"}'
        ;;

        #Plex
        11 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"Plex","urlType":37,"storeType":0,"url":"http://plex.tv/web/tv/hisense"}'
        ;;

        #ABC iview
        12 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"name":"ABC iview","urlType":37,"storeType":0,"url":"https://ctv.iview.abc.net.au/?device=hisense"}'
        ;;

        #Youtube Kids
        13 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"name":"Youtube Kids","urlType":37,"storeType":0,"url":"youtube_kids"}'
        ;;

	#SBS ON DEMAND
        14 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"name":"SBS ON DEMAND","urlType":37,"storeType":0,"url":"http://sbsondemandctv.sbs.com.au/hisense/"}'
        ;;

      	#AppsNow
        15 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"name":"AppsNow","urlType":37,"storeType":99,"url":"appstore-hisense"}'
        ;;

      	#Kidoodle.TV
        16 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"name":"Kidoodle.TV","urlType":37,"storeType":0,"url":"https://ctv-vidaa.kidoodle.tv"}'
        ;;

	#Game Center
        17 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/changesource" -m '{"name":"Game Center","urlType":37,"storeType":0,"url":"http://apps.tvgam.es/tv_games/hisense_portal/production/portal/index.html"}'
        ;;

        #Toon Goggles
        18 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"Toon Goggles","urlType":37,"storeType":0,"url":"http://html5.toongoggles.com/"}'
        ;;

        #YuppTV
        19 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/"$pairedMAC"$normal/actions/launchapp" -m '{"name":"YuppTV","urlType":37,"storeType":0,"url":"http://www.yupptv.com/hisense/index.html"}'
        ;;

        #AccuWeather
        20 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_MUTE"
        ;;

        #TV Browser
        21 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_MUTE"
        ;;

        #Channel9
        22 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/3D:81:F2:B6:08:B0$normal/actions/changechannel" -m '{"channel_param" : "90#ch07fa526c-8c83-4547-8726-238b1fee4bf5#sl3d54bfff-ba0d-4f22-9cfd-b2686cd5cc4d#4"}'
	    ;;

        #Channel10
        23 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/3D:81:F2:B6:08:B0$normal/actions/changechannel" -m '{"channel_param" : "1#chf9037e9a-894e-4a08-8b9a-32f686320f23#sl3d54bfff-ba0d-4f22-9cfd-b2686cd5cc4d#4"}'
        ;;

        #Channel7
        24 )
         mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/ui_service/3D:81:F2:B6:08:B0$normal/actions/changechannel" -m '{"channel_param" : "70#chb4f07a10-36ed-47a1-bd55-4803dd664e86#sl3d54bfff-ba0d-4f22-9cfd-b2686cd5cc4d#4"}'
        ;;
		esac
    ;;

    Mute )
      if [ "$4" = "true" ]; then
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_MUTE"
      else
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_MUTE"
      fi
    ;;

    VolumeSelector )
      case "$4" in
        0 )
        # Volume up.
         mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_VOLUMEUP"
        ;;
        1 )
        # Volume down.
         mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_VOLUMEDOWN"
        ;;
      esac
    ;;

    RemoteKey )
    # TV remote control buttons accepted by Apple.
      case "$4" in
        # Rewind.
        0 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_BACKS"
        ;;
        # Fast Forward.
        1 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_FORWARDS"
        ;;
        # Next Track.
        2 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_FORWARDS"
        ;;
        # Previous Track.
        3 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_BACKS"
        ;;
        # Arrow Up.
        4 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_CHANNELUP"
        ;;
        # Arrow Down.
        5 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_CHANNELDOWN"
        ;;
        # Arrow Left.
        6 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_VOLUMEDOWN"
        ;;
        # Arrow Right.
        7 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_VOLUMEUP"
        ;;
        # Select.
        8 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_OK"
        ;;
        # Back.
        9 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_RETURNS"
        ;;
        # Exit.
        10 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_EXIT"
        ;;
        # Play/Pause.
        11 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_PLAY"
        ;;
        # Information.
        15 )
        mosquitto_pub --cafile $certPath --cert $rcmCer --key $rcmKey --insecure -h $ip -p 36669 -P multimqttservice -u hisenseservice -t "/remoteapp/tv/remote_service/"$pairedMAC"$normal/actions/sendkey" -m "KEY_MUTE"
        ;;
	esac
    ;;

esac
fi

exit 0
