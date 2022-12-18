cls
$blgfile = "C:\Processing\*.blg"
$csvfile = (Split-Path -Path $blgfile -Parent) + "\Alfa_20220531.csv"
#relog -f csv $blgfile -cf "C:\Counters.txt"  -o $csvfile # -b 01.07.2021
#relog -f csv $blgfile -cf "C:\Counters.txt"  -o $csvfile # -b 01.07.2021
relog -f CSV $blgfile   -o $csvfile # -b 13.12.2021

#-e "08.07.2020"