/*
** $Id: parse.c,v 1.1 1996/04/17 14:03:14 martin Exp $
** 
** $Log: parse.c,v $
** Revision 1.1  1996/04/17 14:03:14  martin
** Initial revision
**
*/

#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "parse.h"

/* Print fatal error and exit */
#define FATAL(MSG) { fprintf (stderr, "%s\n", MSG); exit (1); }

/* Print parse error and exit */
#define PARSE_ERROR(MSG) {fprintf (stderr, "Parser error: %s (pos %d)\n", MSG, fi); exit(1);}

/* Justification */
#define LEFT 1
#define RIGHT 2

#define MAXNUMS 25

/* To make the parser more readable */
#define INCH format[fi]
#define RESET fi=0
#define FWD fi++


static char *format;
static int nums[MAXNUMS];
static int nums_nr;
static int length;
static int just;
static int fi;

/* Local function prototypes */

static void parse_text(void);
static void parse_field(void);
static int parse_num();


/*
 * Function definitions
 */

/* 
 * Prints one entry with the format in format_p
 */
extern void
print_entry(char format_p[], char *entry[], int field_c)
{
	int i;
	char con[1024];
	char fmt[1024];

	format= format_p;
	RESET;
	
	for (;;) {
		if (INCH == 0)
			break;
		if (INCH == '@') {
			parse_field();

			*con=0;
			for (i=0; i< nums_nr; i++) {
				if (nums[i] >= field_c) {
					fprintf (stderr, 
						"Trying to access field %d (of %d)\n",
						nums[i], field_c
					);
					exit (1);
				}
				if (strlen(con) != 0)
					strcat (con, " ");
				strcat (con, entry[nums[i]]);
			}
			if (length != -1) {
				if (strlen(con) > length) {
					con[length-1]= '!';
					con[length]= 0;
				}
			}
			/* Build the format string for current printfield */
			fmt[0]= 0;
			strcat (fmt, "%");
			if (length != -1)
				sprintf (fmt, "%s%d", fmt, length);
			if (just == LEFT)
				strcat (fmt, "-");
			strcat (fmt, "s");

			printf (fmt, con);
		} else {
			parse_text();
		}
	}
}


/* Parse text from the input and put it to stdout */
static void
parse_text(void)
{
	while (INCH != '@' && INCH != 0) {
		putchar (INCH);
		FWD;
	}
}


/* Parses a field definition (@1[...) */
static void
parse_field(void)
{
	FWD;

	length=-1;
	just=LEFT;

	if (!isdigit(INCH))
		PARSE_ERROR ("expected field number");

	nums_nr=0;
	nums[nums_nr++]= parse_num();
	while (INCH=='+') {
		FWD;
		nums[nums_nr++]= parse_num();
	}
	if (INCH != '[')
		return;

	FWD;
	if (isdigit(INCH)) {
		length= parse_num();
	}
	if (INCH=='L') {
		just=LEFT;
		FWD;
	} else if (INCH=='R') {
		just=RIGHT;
		FWD;
	} 
	if (INCH==']') {
		FWD;
		return;
	}
	if (INCH == 0) {
		PARSE_ERROR("unexpected EOF");
		return;
	}
	PARSE_ERROR("unexpected character after length param");
}


/* Parses a number (1 or more digits) */
static int
parse_num()
{
	int num;

	num=INCH-'0';
	FWD;
	while (isdigit (INCH)) {
		num *= 10;
		num += INCH-'0';
		FWD;
	}
	if (INCH==0)
		PARSE_ERROR ("unexpected EOF");
	return (num);
}
