#!/usr/bin/perl
# If this is the second line of the program, the installationprocedure
# went wrong. Then adjust please the following three lines and the path
# to perl in the first line
$HOME=$ENV{HOME};
$CONFIGFILE="/usr/local/lib/addressbook/addressbook.config";
$MYCONFIGFILE="$HOME/.addressbook.config";
$LIBDIR="/usr/local/lib/addressbook";
#
#########################################################################
#                                                                       #
# address - fast textonly search in addressbook database                #
#                                                                       #
# This is part of my adressbuch / addressbook program			#
# Version 0.7, 02.11.1997						#
# Copyright (C) 1995, 1996, 1997 Clemens Durka				#
#									#
# Clemens Durka (clemens@dagobah.de) 					#
# http://home.pages.de/~clemens/					#
#									#
#########################################################################
#									#
# This program is free software; you can redistribute it and/or modify	#
# it under the terms of the GNU General Public License Version 2 as	#
# published by the Free Software Foundation.				#
#									#
# This program is distributed in the hope that it will be useful,	#
# but WITHOUT ANY WARRANTY; without even the implied warranty of	#
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the		#
# GNU General Public License for more details.				#
#									#
# You should have received a copy of the GNU General Public License	#
# along with this program; if not, write to the Free Software		#
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.		#
#									#
#########################################################################

$COUNTRYFILE="$LIBDIR/countries";

if (!@ARGV) {
    print "$0: Fast search in addressbookdatabase\n";
    print "usage: $0 [-hsl] [-f field] [-n fieldnr]\n";
    print "                 [-a addressfile] [-c configfile] [-ld libdir]\n";
    print "                 [-debug level] substring_of_a_name\n";
    print "Try `$0 -h' for more information.\n";
    exit 1;
}

$long=-1;
$adrfile="";
$a=$ENV{ADDRBOOK_ADDRFILE};
if ($a) {
	$adrfile=$a;
}
$MYCONFIGFILE =~ s/~/$HOME/;
$_="$0";
SWITCH: {
    /phone/    && do { $field="special",$action="tel",    last SWITCH; };
    /tel/      && do { $field="special",$action="tel",    last SWITCH; };
    /fax/      && do { $field="special",$action="fax",    last SWITCH; };
    /birthday/ && do { $field="birthday",                 last SWITCH; };
    /email/    && do { $field="email",                    last SWITCH; };
    /letter/   && do { $field="special",$action="letter", last SWITCH; };
}

while (@ARGV) {
    $i=shift @ARGV;
    if (($i eq "-h") || ($i eq "--help")) {
	print "$0: Fast search in addressbookdatabase\n";
	print "This programm looks the addressfile defined in your personal or global\n";
	print "configfile for matching and outputs the corresponding fields depending\n";
	print "on how it was called:\n";
	print "\n";
	print "Possible names for calling it:\n";
	print "phone    prints all known phone numbers of a person\n";
	print "fax      same with all fax numbers \n";
	print "email    prints the email address\n";
	print "birthday prints the birthday\n";
	print "letter   prints the address as you would write it on a letter\n";
	print "address  gives all information without formatting\n";
	print "\n";
	print "You can use the following options:\n";
	print "-l             long form: name, city and the result (default)\n";
	print "-s             short form: only the result of the query\n";
	print "-f field       fieldname for the output (p.ex.: company, www)\n";
	print "-n fieldnr     number of the field for output (faster)\n";
	print "-a addressfile addressfile to search in";
	print "-c configfile  configfile to read\n";
	print "-ld libdir     libdir\n";
	print "-db level      print debugging output (level: 1 - 4)\n";
	exit;
    } elsif ($i eq "-s") {
	$long = 0;
    } elsif ($i eq "-l") {
	$long = 1;
    } elsif ($i eq "-f") {
	$field = shift @ARGV;
    } elsif ($i eq "-n") {
	$fieldnr = shift @ARGV;
    } elsif ($i eq "-a") {
	$adrfile = shift @ARGV;
    } elsif ($i eq "-c") {
	$MYCONFIGFILE=shift @ARGV;
    } elsif ($i eq "-ld") {
	$t = shift @ARGV;
        $COUNTRYFILE="$t/countries";
    } elsif ($i eq "-db") {
	$debug=shift @ARGV;
    } elsif ($i eq "-debug") {
	$debug=shift @ARGV;
    } else {
	$searchterm = $i;
    }
}

if ($debug > 2) {
    print "Long: $long, Field: $field, Fieldnr: $fieldnr, Action: $action\n";
    print "Searchterm: $searchterm\n";
    print "Adrfile: $adrfile\n";
    print "Configfile: $MYCONFIGFILE\n";
    print "Countryfile: $COUNTRYFILE\n";
}

if ($adrfile eq "") {

    # Load configfile

    if (! open (CFG, "<$CONFIGFILE")) {
	;			# warn ("File $CONFIGFILE could not be opened: $!.\n");  
    } else {			
	if ($debug > 0) { print "Reading configfile: $CONFIGFILE\n";}
	while (<CFG>) {		
	    if (/^([^# \n][\S]*)\s*(.*)/) {
		$options{$1}="$2";
	    }	    
	}
    }
    close CFG;
	    
    # Load private configfile
	    
    if (! open (CFG, "<$MYCONFIGFILE")) {
	; # warn ("File $MYCONFIGFILE could not be opened: $!.\n");  
    } else {
	if ($debug > 0) { print "Reading configfile: $MYCONFIGFILE\n";}
	while (<CFG>) {
	    if ( /^([^# \n][\S]*)\s*(.*)/ ) {
		$options{$1}="$2";
	    }
        }
    }
    close CFG;
    
    if ($options{adrfile1} ne "") {
    	$adrfile=$options{adrfile1};
    } else {
    	$adrfile=$options{adrfile};
    }
}
	
$adrfile =~ s/~/$HOME/;

$fields{special} = -1;

#if ($fieldnr eq "") {

    # Load dataformatfile
    $adrfmt="$adrfile" . ".fmt";

    open (FMT, "<$adrfmt") ||
	die ("File $adrfmt could not be opened: $!.\n");  
    if ($debug > 0) { print "Reading formatfile: $adrfmt\n";}
    while (<FMT>) {
	if (/^([^# \n][\S]*)\s*(.*)/) {
	    $fields{$2}="$1";
	    $fields{$1}="$2";
	}
    }
    close FMT;

    if ($field ne "special") {
	if (($field ne "") && ($fields{$field}>=0)) {
	    $fieldnr=$fields{$field};
	} elsif ($fieldnr eq "") {
	    # Default address: give out all info
	    $fieldnr=-1;
	    $field="special";
	    $action="all";
	    $long=0;
	}
    }
    $birthfld=$fields{birthday};
#}

if ($debug > 2) {
    print "Long: $long, Field: $field, Fieldnr: $fieldnr, Action: $action\n";
}

if (($field eq "birthday") || ($action eq "letter")) {
	
    # Load countryfile

    if (! open (COU, "<$COUNTRYFILE")) {
	; # warn ("File $COUNTRYFILE could not be opened: $!.\n");  
    } else {
	if ($debug > 0) { print "Reading countryfile: $COUNTRYFILE\n";}
	while (<COU>) {
	    chop; # deletes LF at the end
	    if (/^[^#]/) {
		@line = split(/;/);
		$intprefix{$line[0]} = $line[2];
		$fullname{$line[0]} = $line[7];
		$format{$line[0]} = $line[5];
	    }
        }
    }
    close COU;
}

# Load addressfile and perform action

open (ADR, "<$adrfile") ||
    die ("File $adrfile could not be opened: $!.\n");  

if ($debug > 0) { print "Reading addressfile: $adrfile\n";}

while (<ADR>) {
    if (/$searchterm/i) {
	@line = split(/$fields{separatorchar}/);
	if ($debug > 3) { print "Read line: @line\n"; }
	if (($line[$fields{firstname}] !~ /$searchterm/i) && ($line[$fields{lastname}] !~ /$searchterm/i)) {next;}

	if (($field eq "birthday") || ($action eq "letter")) {
	    $coun = $line[$fields{country}];
	    if ($coun eq "") { $coun = $options{mycountry} };
	}

	if (($action ne "letter") && ($long != 0)) {
	    print "$line[$fields{firstname}] $line[$fields{lastname}], $line[$fields{city}]:\t";
	}

	if ($field ne "special") {
	    # Normal Action
	    print "$line[$fieldnr]\n";
	} else {
	    # Special Action
	    if ($action eq "tel") {
		if (($fields{phone}>0) && ($line[$fields{phone}] ne "")) {
		    print "$line[$fields{phone}] ";
		}
		if (($fields{phonepriv}>0) && ($line[$fields{phonepriv}] ne "")) {
		    print "$line[$fields{phonepriv}] (private) ";
		}
		if (($fields{phonework}>0) && ($line[$fields{phonework}] ne "")) {
		    print "$line[$fields{phonework}] (work) ";
		}
		if (($fields{phonesecretary}>0) && ($line[$fields{phonesecretary}] ne "")) {
		    print "$line[$fields{phonesecretary}] (secretary) ";
		}
		if (($fields{phonemobile}>0) && ($line[$fields{phonemobile}] ne "")) {
		    print "$line[$fields{phonemobile}] (mobile) ";
		}
		if (($fields{phonepager}>0) && ($line[$fields{phonepager}] ne "")) {
		    print "$line[$fields{phonepager}] (pager) ";
		}
		print "\n";
	    } elsif ($action eq "fax") {
		print "Fax: ";
		if (($fields{fax}>0) && ($line[$fields{fax}] ne "")) {
		    print "$line[$fields{fax}] ";
		}
		if (($fields{faxpriv}>0) && ($line[$fields{faxpriv}] ne "")) {
		    print "$line[$fields{faxpriv}] ";
		}
		if (($fields{faxwork}>0) && ($line[$fields{faxwork}] ne "")) {
		    print "$line[$fields{faxwork}] ";
		}
		if (($fields{faxsecretary}>0) && ($line[$fields{faxsecretary}] ne "")) {
		    print "$line[$fields{faxsecretary}] ";
		}
		if (($fields{faxmobile}>0) && ($line[$fields{faxmobile}] ne "")) {
		    print "$line[$fields{faxmobile}] ";
		}
		print "\n";
	    } elsif ($action eq "letter") {
		&myprint (*line,mrmrs);
		&myprint (*line,title);
		&myprint (*line,firstname,lastname);
		&myprint (*line,institute);
		&myprint (*line,department);
		&myprint (*line,addon);
		&myprint (*line,pobox);
		&myprint (*line,street); 
		if ($format{$coun} eq "us") {
		    &myprint (*line,",",city,state,zip);
		} elsif ($format{$coun} eq "uk") {
		    &myprint (*line,city,state,zip);
		} elsif ($format{$coun} eq "eu") {
		    if ($options{mycountry} ne $coun) {
			&myprint (*line,"-",country,zip,city);
		    } else {
			&myprint (*line,zip,city);
		    }
		}
		if ($options{mycountry} ne $coun) {
		    print "$fullname{$coun}\n"
		    }
		print "\n";
	    } elsif ($action eq "all") {
		$record = join("\n",@line);
		print "=========================\n";
		print "$record";
	    }
	}
    }
}

close(ADR);

sub myprint {
    local(*lne) = shift @_;
    local($nl) = 0;
    local($fld);
    local($space)=" ";
    while (@_) {
	$fld=shift @_;
	if ($fld eq ",") { $space=", "; }
	elsif ($fld eq "-") { $space="-"; }
	elsif (($fields{$fld} ne "") && ($lne[$fields{$fld}] ne "")) {
	    print "$lne[$fields{$fld}]$space";
	    $space=" ";
	    $nl++;
	}
    }
    if ($nl > 0) { print "\n"; }
}
