#!/bin/bash
ANNOTATOR=/home/socci/Work/Varmus/PolitiK/Pipeline/ver13/Annotation

for file in *__UNION.txt; do
    echo $file;
    $ANNOTATOR/addAnnotation.py \
        < $file \
        > ${file%%.txt}__ANNOTE.txt 2> $(basename $file)_MISSING.txt
done

MISSING=$(wc -l *_MISSING.txt | awk '{s+=$1}END{print s}')
echo MISSING=$MISSING
if [ $MISSING != "0" ]; then

    echo
    echo "Need to re-run"
    echo

    cat *_MISSING.txt | sort | uniq >MISSING.txt
    wc -l MISSING.txt
    $ANNOTATOR/doAnnovar.sh MISSING.txt

    $ANNOTATOR/loadAnnovarGeneAnno.py MISSING.txt
else
    rm *____MuTect__UNION.txt_MISSING.txt
fi

