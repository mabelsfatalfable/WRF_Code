#!/bin/sh
hour=`date +%H`
case $hour in
        "00" ) h_update=00 ;; "01" ) h_update=00 ;; "02" ) h_update=00 ;; "03" ) h_update=00 ;;
        "04" ) h_update=00 ;; "05" ) h_update=00 ;; "06" ) h_update=06 ;; "07" ) h_update=06 ;;
        "08" ) h_update=06 ;; "09" ) h_update=06 ;; "10" ) h_update=06 ;; "11" ) h_update=06 ;;
        "12" ) h_update=12 ;; "13" ) h_update=12 ;; "14" ) h_update=12 ;; "15" ) h_update=12 ;;
        "16" ) h_update=12 ;; "17" ) h_update=12 ;; "18" ) h_update=18 ;; "19" ) h_update=18 ;;
        "20" ) h_update=18 ;; "21" ) h_update=18 ;; "22" ) h_update=18 ;; "23" ) h_update=18 ;;
esac

for n in {0..72}; do    ###CHANGE HERE###
URL1="http://www.ftp.ncep.noaa.gov/data/nccf/com/nam/prod/nam.20`date +%y%m%d`/nam.t"$h_update"z.awphys`printf "%02d" $n`.grb2.tm00"
URL2="http://www.ftp.ncep.noaa.gov/data/nccf/com/nam/prod/nam.20`date +%y%m%d`/nam.t"$h_update"z.awphys`printf "%02d" $n`.grb2.tm00.idx"
wget $URL1
wget $URL2
done
