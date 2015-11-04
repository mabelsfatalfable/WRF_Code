; Clint Aegerter
; Add variables to netCDF files

;  LOAD FUNCTIONS AND PROCEDURES
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
pi = 3.14159265359
dtor = pi / 180.

; Basic resources
res = True

; WRF output directory (COMMENT OUT FOR REAL-TIME RUN)
;dir       = "/work/jwang7/caegerter/test/14081312/"
;filelist  = "14081312_list"

str       = "string"
filename  = asciiread(dir + filelist, -1, str)
nfile     = dimsizes(filename)

; Do loop to read and plot each file
do i = 0, nfile-1
 a = addfile(dir + filename(i) + ".nc", "w")
 time = charactertostring(a->Times(0, :))
 a@START_DATE = a@SIMULATION_START_DATE
 a@START_DATE = str_sub_str(a@START_DATE, "_", " ")
 a@START_DATE = a@START_DATE + " UTC"
 timeLabel = str_sub_str(time, "_", " ")
 res@TimeLabel = timeLabel + " UTC"
 fileTime = str_sub_str(time, ":", "_")
 lat  = a->XLAT
 lon  = a->XLONG
  
 ; Dewpoint temperature
 td2  = wrf_user_getvar(a, "td2", 0)
 a->TD2 = td2 

 ; Wind
 u10 = wrf_user_getvar(a, "U10", 0)
 v10 = wrf_user_getvar(a, "V10", 0)
 wdir = wind_direction(u10, v10, 0)
; print(u10+"  "+v10+"  "+wdir)
 wspd = u10 ; preserve metadata
 wspd = sqrt((u10) ^ 2. + (v10) ^ 2.)
 wspd@description = "Wind Speed at 10 M"

; wdir = u10
; dsize = dimsizes(wdir)
; do k = 0, dsize(0) - 1
;   do m = 0, dsize(1) - 1

    ; Wind is from south and west (dir > 0, dir < 90)
;    if (u10(k, m) .gt. 0 .and. v10(k, m) .gt. 0) then
;     wdir(k, m) = atan(abs(v10(k, m)) / abs(u10(k, m)))

    ; Wind is from north and west (dir > 270, dir < 360)
;    else if (u10(k, m) .gt. 0 .and. v10(k, m) .lt. 0) then
;     wdir(k, m) = 360. * dtor - atan(abs(v10(k, m)) / abs(u10(k, m)))

    ; Wind is from south and east (dir > 90, dir < 180)
;    else if (u10(k, m) .gt. 0 .and. v10(k, m) .gt. 0) then
;     wdir(k, m) = 180. * dtor - atan(abs(v10(k, m)) / abs(u10(k, m)))

    ; Wind is from north and east
;    else if (u10(k, m) .lt. 0 .and. v10(k, m) .gt. 0) then
;     wdir(k, m) = 180. * dtor + atan(abs(v10(k, m)) / abs(u10(k, m)))

    ; Wind is from south
;    else if (u10(k, m) .eq. 0 .and. v10(k, m) .gt. 0) then
;     wdir(k, m) = 90. * dtor

    ; Wind is from north
;    else if (u10(k, m) .eq. 0 .and. v10(k, m) .gt. 0) then
;     wdir(k, m) = 270. * dtor

    ; Wind is from west
;    else if (u10(k, m) .gt. 0 .and. v10(k, m) .eq. 0) then
;     wdir(k, m) = 0. * dtor

    ; Wind is from east
;    else if (u10(k, m) .lt. 0 .and. v10(k, m) .eq. 0) then
;     wdir(k, m) = 180. * dtor

;    end if
;    end if
;    end if
;    end if
;    end if
;    end if
;    end if
;    end if

;   end do
; end do
a->WSPD = wspd
a->WDIR = wdir

end do

end
