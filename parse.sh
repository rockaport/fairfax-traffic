find . -name "*.pdf" | xargs -n1 pdftotext -layout
sed -s -i '/ \+[[:digit:]]\+ \+2019/!d' *.txt
sed -s -i 's/Forward Vehicle/1/g; s/Reverse Vehicle/-1/g; s/Unclassified Vehicle/0/g' *.txt
sed -s -i 's/,//g; s/MPH//g; s/FT//g' *.txt
sed -s -i 's/ \+/ /g; s/^ //g' *.txt
sed -s -i 's/ /,/g' *.txt
