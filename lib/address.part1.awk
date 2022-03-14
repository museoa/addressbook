#!/usr/bin/gawk -f
BEGIN {FS=";"; OFS=" "

# Definitions of all fields (will be read from .fmt in a later version)
# starting with 1 (not 0)
firstname=1
lastname=2
addon=3
street=4
country=5
zip=6
city=7
birthday=8
phonepriv=9
phonework=10
fax=11
email=12
www=13
category=14
remark=15

# Definitions from .addressbook.config (will be read in automatically in a later version)
mycountry="D"
myareacode="089"
dialoutdistance=""
dialoutlocal=""
intl_dialout="00"
