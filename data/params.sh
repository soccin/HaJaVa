##
## Pipeline Parameters/Constants
##

##
## Adapters
##


ADAPTER_SET=MinCommon

case $ADAPTER_SET in

    MinCommon)
        # TrueSeq Full
        ADAPTER_1=AGATCGGAAGAGC
        ADAPTER_2=AGATCGGAAGAGC
        ;;

    TrueSeqFull)
        # TrueSeq Full
        ADAPTER_1=AGATCGGAAGAGCACACGTCTGAAGTCCAGTCAC
        ADAPTER_2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA
        ;;

    Dilution)
        # TrueSeq (MIT Dilution)
        ADAPTER_1=AGATCGGAAGAGCACACGTCT
        ADATPER_2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGTA
        ;;

    MIT_782)
        # The adapters for the earlier MIT-782 set are (DM1010 etc):
        ADAPTER_1=AGATCGGAAGAGCGGTTCAGCAGGAATGCCGAGACCG
        ADAPTER_2=AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT
        ;;

    *)
    echo "Invalid Adapter Set"
    echo $ADAPTER_SET
    exit

esac

echo "ADAPTERS"
echo $ADAPTER_SET
echo $ADAPTER_1
echo $ADAPTER_2
