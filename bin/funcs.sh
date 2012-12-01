function checkFile {
    FILE=$1
    MD5=$(md5sum $FILE)
    echo "MD5.0=" $FILE ";" $MD5 ";" `date`
    while [ -z "$MD5" ]; do
        sleep 30
        MD5=$(md5sum $FILE)
        echo "MD5.n=" $FILE ";" $MD5 ";" `date`
    done
}
