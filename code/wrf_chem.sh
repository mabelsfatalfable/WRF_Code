#!/bin/sh
cd `dirname ${0}` || exit 1
. /util/opt/lmod/lmod/init/profile
export -f module
echo "Today is `date +%y/%m/%d`"

#Download 1 more file for the 01-24 requirement
#wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --date='3 day' +%Y`/`date --date='3 day' +%Y%m`/flambe_arctas_`date --date='3 day' +%Y%m%d`0000.dat &> /dev/null
#Change 00-23 to 01-24 
#for file in `find ./ -name "*0000*"`; do
#time=`echo $file | cut -d '_' -f 3 | cut -d '.' -f 1 | cut -c 1-8`
#NewName=flambe_arctas_`date -d "$time -1 days" "+%Y%m%d"`2400.dat
#mv $file $NewName
#done

#Download wrf_only files
#Delete old fils if exist | in the current directory
cd /work/swanson/jingchao/wrf/WRF_forecast/WPS/source
files=nam.t00z.awphys*; [[ "${#files[@]}" -gt 0 ]] && rm nam.t00z.awphys* 2> /dev/null
#Fetch Files
for n in {0..72}; do    ###CHANGE HERE###
URL1="http://www.ftp.ncep.noaa.gov/data/nccf/com/nam/prod/nam.20`date +%y%m%d`/nam.t00z.awphys`printf "%02d" $n`.grb2.tm00"
URL2="http://www.ftp.ncep.noaa.gov/data/nccf/com/nam/prod/nam.20`date +%y%m%d`/nam.t00z.awphys`printf "%02d" $n`.grb2.tm00.idx"
wget $URL1 &> /dev/null
wget $URL2 &> /dev/null
done
 
#Run WPS
#STEP 1: Build the links using ./link_grib.csh
cd /work/swanson/jingchao/wrf/WRF_forecast/WPS
grfiles=GRIBFILE*; [[ "${#grfiles[@]}" -gt 0 ]] && rm GRIBFILE* 2> /dev/null
./link_grib.csh source/nam.t00z.awphys*
#STEP 2: Unpack the GRIB data using ./ungrib.exe
sed -i "4s/.*/ start_date = '`date +%Y-%m-%d`_00:00:00'/" namelist.wps				###CHANGE HERE###
sed -i "5s/.*/ end_date = '`date --date='72 hour' +%Y-%m-%d`_00:00:00'/" namelist.wps		###CHANGE HERE###
ugfiles=FILE*; [[ "${#ugfiles[@]}" -gt 0 ]] && rm FILE* 2> /dev/null
id1=`sbatch ungrib.submit | cut -d ' ' -f 4`
#STEP 3: Generate input data for WRFV3
metfiles=met_em*; [[ "${#metfiles[@]}" -gt 0 ]] && rm met_em* 2> /dev/null
id2=`sbatch -d afterok:$id1 metgrid.submit | cut -d ' ' -f 4`

#Download the Fire files
#Create/Change folder and prepare for Fire files download
cd /work/swanson/jingchao/wrf/data/wrf_chem
[[ ! -d "`date +%Y%m%d`" ]] && mkdir `date +%Y%m%d`
cd `date +%Y%m%d` 
flambe=flambe_arctas*; [[ "${#flambe[@]}" -gt 0 ]] && rm flambe_arctas* 2> /dev/null
#Download 72 hours' files
for i in {0..23}; do
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date +%Y`/`date +%Y%m`/flambe_arctas_`date +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --date='1 day' +%Y`/`date --date='1 day' +%Y%m`/flambe_arctas_`date --date='1 day' +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
wget ftp://ftp.nrlmry.navy.mil/pub/receive/hyer/arctas/flambe_arctas_hourly/`date --date='2 day' +%Y`/`date --date='2 day' +%Y%m`/flambe_arctas_`date --date='2 day' +%Y%m%d``printf "%02d" $i`00.dat &> /dev/null
done

#Run WEPS
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/results; rm * 2> /dev/null
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/data/smoke/FLAMBE/
[[ ! -d "`date +%Y`" ]] && mkdir `date +%Y`; cd `date +%Y`
[[ ! -d "`date +%Y%m`" ]] && mkdir `date +%Y%m`; cd `date +%Y%m`
cp /work/swanson/jingchao/wrf/data/wrf_chem/`date +%Y%m%d`/flambe_arctas* ./
cd /work/swanson/jingchao/wrf/WRF_forecast/WEPS_v01/run
sed -i "5s/.*/START_YEAR                   : `date +%Y`       2012       2012/" namelist.weps
sed -i "6s/.*/START_MONTH                  : `date +%m`         09         09/" namelist.weps
sed -i "7s/.*/START_DAY                    : `date +%d`         15         15/" namelist.weps
sed -i "8s/.*/START_HOUR                   : 01         01         01/" namelist.weps
sed -i "9s/.*/END_YEAR                     : `date --date='48 hour' +%Y`       2012       2012/" namelist.weps
sed -i "10s/.*/END_MONTH                    : `date --date='48 hour' +%m`         09         09/" namelist.weps
sed -i "11s/.*/END_DAY                      : `date --date='48 hour' +%d`         29         29/" namelist.weps
sed -i "12s/.*/END_HOUR                     : 24         24         24/" namelist.weps
id3=`sbatch weps.submit | cut -d ' ' -f 4`

#Run WRFV3
#STEP 1: real.exe
cd /work/swanson/jingchao/wrf/WRF_forecast/WRF_chem/test/em_real
#lfiles=met_em*; [[ "${#lfiles[@]}" -gt 0 ]] && rm met_em* && sleep 2
sed -i "3s/.*/ run_hours                           = 72,/" namelist.input						 ###CHANGE HERE###
sed -i "6s/.*/ start_year                          = `date +%Y`,  2012, 2012,/" namelist.input				 ###CHANGE HERE###
sed -i "7s/.*/ start_month                         = `date +%m`,  07,  07,/" namelist.input				 ###CHANGE HERE###
sed -i "8s/.*/ start_day                           = `date +%d`,   25,  25,/" namelist.input				 ###CHANGE HERE###
sed -i "9s/.*/ start_hour                          = 00,   12,   12,/" namelist.input					 ###CHANGE HERE###
sed -i "12s/.*/ end_year                            = `date --date='72 hour' +%Y`,   2012,  2012,/" namelist.input	 ###CHANGE HERE###
sed -i "13s/.*/ end_month                           = `date --date='72 hour' +%m`,  07,  07,/" namelist.input		 ###CHANGE HERE###
sed -i "14s/.*/ end_day                             = `date --date='72 hour' +%d`,    27,   27,/" namelist.input	 ###CHANGE HERE###
sed -i "15s/.*/ end_hour                            = 00,   00,   00,/" namelist.input					 ###CHANGE HERE###
sed -i "33s/.*/ auxinput1_inname                    = \"\.\/met_em.d<domain>.<date>\"/" namelist.input
sed -i "35s/.*/ history_outname                     = \"\.\/wrfout\/wrfout_d<domain>_<date>\"/" namelist.input
sed -i "143s/.*/ chem_opt                            = 0,        11,    11,/" namelist.input
id4=`sbatch -d afterok:$id2:$id3 real.submit | cut -d ' ' -f 4`
sed -i "143s/.*/ chem_opt                            = 2,        11,    11,/" namelist.input
id5=`sbatch -d afterok:$id4 convert.submit | cut -d ' ' -f 4`
id6=`sbatch -d afterany:$id5 real.submit2 | cut -d ' ' -f 4`
#STEP 2: WRF.EXE
id7=`sbatch -d afterok:$id6 wrf.submit | cut -d ' ' -f 4`
#STEP 3: RESULTS TRANSFER
cd /work/swanson/jingchao/wrf/data/wrf_chem
find . -type d -mtime +2 | xargs rm -rf
cd /work/swanson/jingchao/wrf/data/wrf_chem/`date +%Y%m%d`
ndir="`date +%y%m%d%H`"
mkdir $ndir && cd $ndir
cp /work/swanson/jingchao/wrf/WRF_forecast/WPS/dir.submit ./
id8=`sbatch -d afterany:$id7 dir.submit | cut -d ' ' -f 4`

#echo "Submitted batch job $id1(ungrib) --> $id2(metgrid) --> $id3(real) --> $id4(wrf) --> $id5(File_transfer)"
echo "Submitted batch job $id1 (ungrib) --> $id2 (metgrid) --> $id3 (WEPS) --> $id4 (REAL1) --> $id5 (convert) --> $id6 (real2) --> $id7 (wrf) --> $id8 (transfer)"
