# tel.awk 2. Teil

# Aufsplitten des Suchargumentes
split(SEARCH, S, " ")
SEARCH1=S[1]
SEARCH2=S[2]
}


# Funktion zur Texkonvertierung
function converttotex (line) {
  result=""
  i=1
  end=length(line)

  while(i <= end) {
    zeichen=substr(line,i,1)
    
    if (zeichen == "#") zeichen = "\\#"
    if (zeichen == "&") zeichen = "\\&"
    if ((zeichen == " ") && (substr(line,i-1,1) == ".")) zeichen = "~"

    result=sprintf("%s%s",result,zeichen)
#    result=zeichen
    i++
  }
  return result
}


# Funktion zur Ausgabe
function output (line) {
  if (ACTION ~ /lettertex/) {
    line=converttotex(line)
  }
  printf "%s\n", line
}

# Funktion zur Konvertierung von Telefonnummern
function prepare_number (line, country) {
    # Nummer extrahieren
    gsub(/[A-Za-z]/,"",line)
    gsub(/[ ()/\-]/,"",line)
#    match(line,"[(]*[0-9)/\-]*")
#    nummer=substr(line,RINDEX,RLENGTH)
    if (country != mycountry) {
      # international call
      tel = dialoutdistance
      tel = tel intl_dialout
      if (index(line,"+" intl_prefix[country]) == 0) {
        # kein +, also landesvorwahl anfuegen
	tel = tel intl_prefix[country]
	if (index(line,intl_leaveout[country]) == 1) { 
          # '0' oder so entfernen
	  line = substr(line,1+length(intl_leaveout[country]))
	}
      }
      tel = tel line
      gsub(/+/,"",tel)
    } else {
      # nationaler call
      if (index(line,"+" intl_prefix[country]) == 1) {
        # + Landesvorwahl entfernen
	line = intl_leaveout[country] substr(line,2+length(intl_prefix[country]))
      }
      if (index(line,myareacode) == 1) {
        # Ortsgespraech Vorwahl entfernen
	tel = dialoutlocal substr(line,1+length(myareacode))
      } else {
        # Ferngespraech
	tel = dialoutdistance line
      }
    }
    return tel
}

# Funktion zum Ausdruck formatieren 
function myprint (line, field) {
    split(line, l, ";")
    if (field == mail) {
# Adresse
	if (l[title] != "") {
	    output(l[title] " " l[firstname] " " l[lastname])
	} else {
 	    output(l[firstname] " " l[lastname])
	}
	if (l[department] != "") output(l[department])
    	if (l[institute] != "") output(l[institute])
	if (l[addon] != "") output(l[addon])
    	if (l[pobox] != "") output(l[pobox])
    	if (l[street] != "") output(l[street])
	if (l[country] == "D") { 
	    output(l[zip] " " l[city])
	} else {
	    if ((l[country] == "USA") ||(l[country] == "MEX")) {
	    	output(l[city] ", " l[zip])
	    } else {
		if ((l[country] == "GB") || (l[country] == "AUS") ||
	    	    (l[country] == "J") || (l[country] == "CDN") ||
		    (l[country] == "SGP") || (l[country] == "IND")) {
		    output(l[city] " " l[zip])
		} else {
	    	    output(l[country] "-" l[zip] " " l[city])
		}
	    }
	}
	if (l[country] != "D") {
	    output(fc[l[country]])
	}
	output("")
    } else {
# Keine Adresse
        anzahl=split(l[field],a,",")
        if (anzahl == 0) {
	  printf "Keine Information hierzu fuer %s %s vorhanden.\n", l[firstname], l[lastname] > "/dev/stderr"
	} else if (anzahl == 1) {
	  if ((field == tel) || (field == fax)) {
	    print(prepare_number(a[1],l[country]))
	  } else {
	    print a[1]
	  }
	} else {
	  for (i=1; i<=anzahl; i++) {
# Fuehrendes Leerzeichen entfernen
	    gsub(/^ /,"",a[i])
	    gsub(/\(H\)/,"(home)",a[i])
	    gsub(/\(O\)/,"(office)",a[i])
	    gsub(/\(W\)/,"(work)",a[i])
	    gsub(/\(S\)/,"(secretary)",a[i])
	    gsub(/\(P\)/,"(pager)",a[i])
	    gsub(/\(M\)/,"(mobile)",a[i])
	    gsub(/\(C\)/,"(cellular)",a[i])
	    printf "%-35s #%4s\n", a[i] ,i > "/dev/stderr"
	  }
	  printf "Mehrere Nummern fuer %s %s vorhanden. Bitte waehlen: ", l[firstname], l[lastname] > "/dev/stderr"
	  getline ans < "/dev/stdin"
	  if ((ans != " ") && (ans != "q") && (ans != "")) {
	    if ((field == tel) || (field == fax)) {
	      print(prepare_number(a[ans],l[country]))
	    } else {
	      print a[ans]
	    }
	  }
 	}
    }
}


# Hauptschleife zum Suchen
{
if (((match($(firstname), SEARCH1)) && (match($(lastname), SEARCH2))) ||
    ((match($(firstname), SEARCH2)) && (match($(lastname), SEARCH1)))) {
	i++
	found[i] = $0
    }

}
    	

# Endbehandlung Ausgabe
END {
# print SEARCH " : " i " Vorkommen "  NUM

if (i == 0) {
    print SEARCH " : nicht gefunden"
    exit 1
}

if (ACTION ~ /tel/) { field=tel }
if (ACTION ~ /fax/) { field=fax }
if (ACTION ~ /email/) { field=email }
if (ACTION ~ /letter/) { field=mail }

if (i == 1) {
# Nur ein Vorkommen
    myprint(found[1],field)
} else {
    if (NUM != "") {
# Mehrere Vorkommen, eins wurde ausgewaehlt
	myprint(found[NUM],field)
    } else {
# Mehrere Vorkommen, alle werden mit Namen angezeigt.
        # print "Mehrere Vorkommen gefunden." > "/dev/stderr"
	for (j=1; j<=i; j++ in found) {
	    split(found[j], f, ";") 
	    printf "%-35s #%4d  %s %s, %s\n", f[field], j,
	    f[firstname],f[lastname],f[city] > "/dev/stderr"
	}
	printf "Bitte passende Nummer eingeben (q oder SPACE = quit): " > "/dev/stderr"
	getline ans < "/dev/stdin"
	if ((ans != " ") && (ans != "q") && (ans != "")) {
	  myprint(found[ans],field)
	}
    }
}

}
