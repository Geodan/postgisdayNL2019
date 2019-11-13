#/bin/bash

URL="https://data.knmi.nl/download/radar_tar_refl_composites/1.0/0001/2018/12/05/RAD25_OPER_R___TARPCP__L2__20181205T000000_20181206T000000_0001.tar"

curl -s $URL | tar xv

for file in *.h5; do
    DATE=${file:16:8}
    TIME=${file:24:4}
    TIMEST=`date -d "$DATE $TIME" "+%Y-%m-%dT%H:%M"`
    echo $TIMEST
    gdal_translate $file -sds -f XYZ /vsistdout/ -a_srs '+proj=stere +lat_0=90 +lon_0=0 +lat_ts=60 +a=6378.14 +b=6356.75 +x_0=0 y_0=0' | \
      awk '($3>0 && $3<255) {printf("%d,%d,%d,%s\n"), $1, $2, $3, "'$TIMEST'"}' | \
      clickhouse-client -d postgisday -q "INSERT INTO radardata FORMAT CSV" --date_time_input_format=best_effort
done

rm RAD*

