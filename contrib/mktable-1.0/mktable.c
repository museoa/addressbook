/*
** $Id: mktable.c,v 1.2 1996/04/17 14:07:39 martin Exp $
** 
** $Log: mktable.c,v $
** Revision 1.2  1996/04/17 14:07:39  martin
** Now searching in other directories for the format files as well
** Using the new parser in parse.c
**
** Revision 1.1  1996/04/17 09:24:06  martin
** Initial revision
**
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <sys/param.h>

#include "parse.h"

#define TRUE 1
#define FALSE 0

/* Print a fatal error message and exit */
#define FATAL(MSG) { fprintf (stderr, "%s\n", MSG); exit (1); }

/* formats for the input files */
#define FILEFMT_HEAD "%s/%s.head"
#define FILEFMT_ENTRY "%s/%s.entry"
#define FILEFMT_FOOT "%s/%s.foot"

/* The default directory to search for formats */
#define DEFAULT_FORMAT_PATH "/opt/local/lib/mktable"

/* This env. var. can hold a dir where formats should be searched for */
#define FORMAT_PATH_ENVVAR "MKTABLEFORMATS"

/* Maximum number of fields and lines */
#define MAXFIELDS 25
#define MAXENTRIES 4096

/* The data from the input file */
char *entries[MAXENTRIES][MAXFIELDS];

/* The number of entries in the database (tuples, lines) */
static int entry_c;

/* Fields per tuple */
static int field_c;

/* The delimiter used to seperate the fields. Can be overridden on cmdline */
static int delim=';';

/* The format string is read into this var */
char format[4096];

/* The name pf the format template */
static char formatf[MAXPATHLEN];

/* The name of the input file (if NULL: stdin is read) */
static char inputf[MAXPATHLEN];

/* if TRUE: Only check the input file (don't generate a table) */
static int check_only=FALSE;


/* Local prototypes */

static void eval_arguments(int argc, char *argv[]);
static void read_table(char *fname);
static int read_file(char *fname, char str[]);
static void print_file(char *fname);
static void print_stat(void);
static void usage(void);
static char *new_strtok(char *s1, char sep);
static char * find_format_path(char *formatf);


/*
 * Function definitions
 */
	
extern int
main(int argc, char *argv[])
{
	int i;
	char fname[MAXPATHLEN];
	char *format_path;

	/* Read command line args */
	eval_arguments(argc, argv);

	/* Read the data file into memory */
	read_table(inputf);

	/* Check only ? print statistics and exit */
	if (check_only==TRUE) {
		print_stat();
		exit (0);
	}

	format_path= find_format_path(formatf);

	/* Read the format specs in the .entry file */
	sprintf (fname, FILEFMT_ENTRY, format_path, formatf);
	read_file(fname, format);

	/* Print header */
	sprintf (fname, FILEFMT_HEAD, format_path, formatf);
	print_file(fname);

	/* Print entries */
	for (i=0; i<entry_c; i++) {
		print_entry(format, entries[i], field_c);
	}

	/* Print foot lines */
	sprintf (fname, FILEFMT_FOOT, format_path, formatf);
	print_file(fname);

	exit (0);
}


/*
 * Evaluate command line arguments
 */
static void
eval_arguments(int argc, char *argv[])
{
	extern char *optarg;
	extern int optind;

	int c;

	while ((c=getopt(argc, argv, "d:f:c")) != -1) {
		switch (c) {
		case 'd':
			delim= optarg[0];
			break;
		case 'f':
			strcpy (formatf, optarg);
			break;
		case 'c':
			check_only=TRUE;
			break;
		case '?':
			usage();
		}
	}
	/* Do we have a file name for the data file ? */
	if (optind == argc-1) {
		strcpy (inputf, argv[optind]);
		return;
	}
	/* If there is no filename, we'll read stdin */
	if (optind == argc) {
		*inputf= 0;
		return;
	}

	/* There are arguments left which we cannot parse -> error */
	usage();
}


/*
 * Print usage information 
 */
static void
usage(void)
{
	fprintf (stderr, "usage:    mktable [-d<delim>] -f<format> [datafile]\n");
	fprintf (stderr, "       or mktable [-d<delim>] -c [datafile]\n");
	fprintf (stderr, "\n");
	fprintf (stderr, "Options are:\n");
	fprintf (stderr, "  -d<delim>   field delimiter (one char)\n");
	fprintf (stderr, "  -f<format>  The format name.\n");
	fprintf (stderr, "  -c          Print some stats on the input file and exit.\n");
	fprintf (stderr, "  [datafile]  The table file. If not given, stdin is read.\n");

	exit (1);
}


/* 
 * Read the data file into memory 
 */
static void
read_table(char *fname)
{
	FILE *in;
	char line[1024+1];
	char *start;
	int cur_field_c;
	int i;

	/* If we have no input file name, we use stdin */
	if (*inputf==0) {
		in= stdin;
	} else {
		in= fopen(fname, "r");
		if (in == NULL)
			FATAL ("Could not open input file");
	}
	
	/* Count entries (tuples) while reading them */
	entry_c=0;
	for (;;) {
		/* EOF ? */
		if (fgets (line, 1024, in) == NULL)
			break;

		/* Ignore empty lines */
		if (strlen (line) == 0)
			continue;

		/* Cut trailing newline */
		line[strlen(line)-1]= 0;

		/* Read all the fields in one line, count fields in cur_field_c */
		cur_field_c= 0;
		start= new_strtok (line, delim);
		while (start != NULL) {
			entries[entry_c][cur_field_c]= strdup(start);
			cur_field_c++;
			start= new_strtok (NULL, delim);
		}

		/* The number of fields in the first entry will be the
		   standard fieldcount.
		*/
		if (entry_c == 0)
			field_c= cur_field_c;

		/* If the current line has less fields than the standard line,
		   fill the missing fields with empty strings.
		   If the current line has MORE fields than the standard line,
		   these fields are ignored. Otherwise we would have to adapt
		   all other entries .. normally all this should not happen,
		   because every line should have the same number of fields ..
		*/
		if (cur_field_c < field_c) {
            for (i=cur_field_c; i<field_c; i++)
                entries[entry_c][i]= strdup ("");
		}
		/* And on to the next entry (line) .. */
		entry_c++;

		/* Check for overflow in the input file */
		if (entry_c > MAXENTRIES) {
			fprintf (stderr, "Max number of entries reached (%d) -- Exit.\n", MAXENTRIES);
			exit (1);
		}
	}
}


/*
 * Prints the contents of a file to stdout.
 * If the file is not existant or it is empty, nothing is printed,
 * this is not an error.
 */
static void
print_file(char *fname)
{
	FILE *in;
	int ch;

	in=fopen(fname, "r");
	if (in == NULL)
		return;

	while ((ch=fgetc (in)) != EOF)
		putchar (ch);

	fclose (in);
}


/*
 * Reads the format specs from the .entry file
 * More generally, the file <fname> is read into the string <str>
 */
static int
read_file(char *fname, char str[])
{
	FILE *in;
	int ch;
	int i;

	/* Open file, if not possible - fatal error */
	if ((in=fopen(fname, "r")) == NULL) {
		fprintf (stderr, "Could not open file <%s>\n", fname);
		exit (1);
	}

	i=0;
	while ((ch=fgetc (in)) != EOF) {
		str[i]= ch;
		i++;
	}
	str[i]=0;

	fclose (in);
	return (i);
}


/*
 * A little different from strtok(). All fields are seperated by
 * exactly one sep. char, and a seperator at the end means an
 * empty field following.
 */
static char *
new_strtok(char *s1, char sep)
{
	static char *el;
	static int last;
	char *hlp;
	char *ret;

	if (s1 != NULL) {
		el= s1;
		last= FALSE;
	}
	if (last == TRUE)
		return (NULL);

	hlp= el;
	while (*hlp != sep && *hlp != 0)
		hlp++;

	if (*hlp == 0)
		last=TRUE;

	*hlp= 0;
	ret= el;
	el= ++hlp;
	return (ret);
}


/*
 * Prints some statistics about the input data file.
 */
static void
print_stat(void)
{
	int i, j;
	int max_len, max_idx;

	/* Show number of entries and fields/entry */
	printf ("Got %d entries, %d fields each\n", entry_c, field_c);

	/* Show, for each field, the length of the longest value */
	printf ("Maximum lengths of field values:\n");
	for (i=0; i<field_c; i++) {
		max_len=0;
		max_idx=0;
		for (j=0; j<entry_c; j++) {
			if (strlen (entries[j][i]) > max_len) {
				max_len= strlen (entries[j][i]);
				max_idx= j;
			}
		}
		printf ("Field %2d: %3d (%s)\n", i, max_len, entries[max_idx][i]);
	}
}


/*
 * Find the path where .entry, .head, ... are to be searched for
 */
static char *
find_format_path(char *formatf)
{
	char fullname[MAXPATHLEN];

	/* The current working dir ? */
	sprintf (fullname, FILEFMT_ENTRY, ".", formatf);
	if (fopen(fullname, "r") != NULL)
		return (".");

	/* .. or in the default format path (can be defined at compile time) */
	sprintf (fullname, FILEFMT_ENTRY, DEFAULT_FORMAT_PATH, formatf);
	if (fopen(fullname, "r") != NULL)
		return (DEFAULT_FORMAT_PATH);

	/* .. or in the dir from an environment variable whose name
	   is stored in FORMAT_PATH_ENVVAR
	 */
	if (getenv(FORMAT_PATH_ENVVAR) != NULL) {
		sprintf (fullname, FILEFMT_ENTRY, getenv(FORMAT_PATH_ENVVAR), formatf);
		if (fopen(fullname, "r") != NULL)
			return (getenv (FORMAT_PATH_ENVVAR));
	}
	
	/* The format was found nowhere .... */
	fprintf (stderr, "Could not find format <%s>\n", formatf);
	exit (1);
}
