echo "Shell Commands used in OpenVario Project"
echo "-------------------------------------------------------------------------"

echo "Date Time"
echo "========="
echo "reinterpret unix timestamp to date time"
echo "date -u -d @1692282364"
date -u -d @1692282364

echo "currently timestamp"
echo "date +%c"
date +%c
echo "-------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------"

echo "if-Statement"
echo "============"
if 3 && 4; then echo "3 && 4 = true"; else echo "3 && 4 = false"; fi 
if 0 && 4; then echo "0 && 4 = true"; else echo "0 && 4 = false"; fi 
if 3 && 0; then echo "3 && 0 = true"; else echo "3 && 0 = false"; fi 

echo "-------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------"
