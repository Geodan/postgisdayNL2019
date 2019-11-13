#/bin/bash

open_sem(){
    mkfifo pipe-$$
    exec 3<>pipe-$$
    rm pipe-$$
    local i=$1
    for((;i>0;i--)); do
        printf %s 000 >&3
    done
}
run_with_lock(){
    local x
    read -u 3 -n 3 x && ((0==x)) || exit $x
    (
     ( "$@"; )
    printf '%.3d' $? >&3
    )&
}
task(){
	local file=$1
	echo $file
        DATE=${file:23:8}
        TIME=${file:31:4}
	TIMEST=`date -d "$DATE $TIME" "+%Y-%m-%dT%H:%M"` || TIMEST=0
        run_with_lock nice gdal_translate $file -sds -f XYZ /vsistdout/ -a_srs '+proj=stere +lat_0=90 +lon_0=0 +lat_ts=60 +a=6378.14 +b=6356.75 +x_0=0 y_0=0' | \
             nice awk '($3>0 && $3<65535) {printf("%d,%d,%d,%s\n"), $1, $2, $3, "'$TIMEST'"}' | \
	      nice psql -d postgisday -c "COPY MFBSNL25_05m FROM stdin WITH delimiter AS ',';" || echo Empty input
}

for YEAR in {2018..2018}; do
	NEXTYEAR=$((YEAR+1))
	URL="ftp://data.knmi.nl/download/rad_nl25_rac_mfbs_5min/2.0/0002/$YEAR/12/31/RADNL_CLIM____MFBSNL25_05m_"$YEAR"1231T235500_"$NEXTYEAR"1231T235500_0002.zip"
 	echo $URL
 	wget -q $URL
	unzip -j -q "RADNL_CLIM____MFBSNL25_05m_"$YEAR"1231T235500_"$NEXTYEAR"1231T235500_0002.zip"
	echo Starting parallel load
	N=24
	open_sem $N
	
        for file in *.h5; do
		run_with_lock task $file
	done
	find . -name "*.h5" -delete
done
