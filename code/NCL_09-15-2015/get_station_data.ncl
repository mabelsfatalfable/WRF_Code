; Clint Aegerter
; Gets WRF output from closest grid point to given lat/lon

;  LOAD FUNCTIONS AND PROCEDURES
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

; Basic resources
res = True
res@MainTitle = "UNL Real-Time WRF"
res@Footer = False
mpres = True
pltres = True

; WRF output directory (COMMENT OUT FOR REAL-TIME RUN, UNCOMMENT FOR TEST)
;dir       = "/work/jwang7/caegerter/wrfout/"
;filelist  = "14081312_list"

str       = "string"
filename  = asciiread(dir + filelist, -1, str)
nfile     = dimsizes(filename)

; Station arrays
stationName = (/"KGRI", "KODX", "KPHG", "farmer1", "farmer2", "farmer3", "farmer4", "farmer5"/)
stationLat = (/40. + 58./60., 41. + 37./60., 39. + 44./60., 40.985253, 41.480408, 40.8859, 41.465981, 39.825078/)
stationLon = (/-98. - 19./60., -98. - 57./60., -99. - 19./60., -98.415272, -98.9693, -98.300598, -98.703112, -99.107234/)
nstation = dimsizes(stationName)

T2 = new((/3, 24/), float)
TD = new((/3, 24/), float)
precip = new((/3, 24/), float)

; Do loop to read and plot each file
do j = 0, nstation-1
 do i = 0, nfile-1
 
 a = addfile(dir + filename(i) + ".nc", "r")
 time = charactertostring(a->Times(0, :))
 res@TimeLabel = time
 fileTime = str_sub_str(time, ":", "_")
 lat  = a->XLAT(0,:,:)
 lon  = a->XLONG(0,:,:)
 closest = getind_latlon2d(lat, lon, stationLat(j), stationLon(j))
 initTime = a@SIMULATION_START_DATE
 strInitTime = str_sub_str(initTime, ":", "")
 strInitTime = str_sub_str(strInitTime, "-", "")
 strInitTime = str_sub_str(strInitTime, "_", "")

  if (i .ne. 0) then
   ; Temperature
   tc2  = wrf_user_getvar(a, "T2", 0)  ; T2 in Kelvin
   tc2  = tc2-273.16                   ; T2 in C
   tf2  = 1.8*tc2+32.0                 ; convert to Fahrenheit
    tf2@lat2d = a->XLAT(0,:,:)
    tf2@lon2d = a->XLONG(0,:,:)
   if (i .ge. 1 .and. i .le. 24) then
    T2(0, i-1) = tf2(closest(0,0), closest(0,1))
   else if (i .ge. 25 .and. i .le. 48) then
    T2(1, i-1-24) = tf2(closest(0,0), closest(0,1))
   else if (i .ge. 49 .and. i .le. 72) then
    T2(2, i-1-48) = tf2(closest(0,0), closest(0,1))
   end if
   end if
   end if
   
   ; Dewpoint temperature
   td2  = wrf_user_getvar(a, "td2", 0)
   tdf2 = 1.8*td2+32.0
    tdf2@lat2d = a->XLAT(0,:,:)
    tdf2@lon2d = a->XLONG(0,:,:)
   if (i .ge. 1 .and. i .le. 24) then
    TD(0, i-1) = tdf2(closest(0,0), closest(0,1))
   else if (i .ge. 25 .and. i .le. 48) then
    TD(1, i-1-24) = tdf2(closest(0,0), closest(0,1))
   else if (i .ge. 49 .and. i .le. 72) then
    TD(2, i-1-48) = tdf2(closest(0,0), closest(0,1))
   end if
   end if
   end if

   ; Precip
   rain_exp = wrf_user_getvar(a, "RAINNC", 0)
   rain_con = wrf_user_getvar(a, "RAINC", 0)
   rain_tot = rain_exp + rain_con
   rain_tot = rain_tot * 0.0393701 ; convert to inches
   if (i .ge. 1 .and. i .le. 24) then
    precip(0, i-1) = rain_tot(closest(0,0), closest(0,1))
   else if (i .ge. 25 .and. i .le. 48) then
    precip(1, i-1-24) = rain_tot(closest(0,0), closest(0,1))
   else if (i .ge. 49 .and. i .le. 72) then
    precip(2, i-1-48) = rain_tot(closest(0,0), closest(0,1))
   end if
   end if
   end if

  end if
 end do

; Output to txt files
opt = True

; Temperature file
opt@fout = dir + "stations/" + stationName(j) + "_" + strInitTime + "_T.txt"
write_matrix(T2, "24(F8.5, 3X)", opt)

; Dewpoint file
opt@fout = dir + "stations/" + stationName(j) + "_" + strInitTime + "_Td.txt"
write_matrix(TD, "24(F8.5, 3X)", opt)

; Precip file
opt@fout = dir + "stations/" + stationName(j) + "_" + strInitTime + "_precip.txt"
write_matrix(precip, "24(F8.5, 3X)", opt)

end do

end
