/*
 * label2srt
 *
 * Description:
 *     Very basic Audacity label TXT file to SRT conversion... in C++.
 *
 *     Upon reading an invalid line, the program will terminate early, printing
 *     out all lines up until the error occurred.
 *
 * Synopsis:
 *     ./label2srt < in_txt > out_srt
 *
 * Author:
 *     Clara Nguyen (@iDestyKK)
 */

#include <iostream>
#include <sstream>
#include <string>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

using namespace std;

string ts_to_str(const double& ts) {
	/* 
	 * some stupidly over-engineered stuff just because i want to use C
	 * functions lol...
	 */

	int ds, hh, mm, ss, dms, tmp, buf_len;
	double ms;
	char *buffer;
	string ret;

	//Get appropriate time units
	ds  = (int) ts;
	hh  = ds / 3600;
	mm  = ds / 60;
	ss  = ds % 60;
	ms  = ts - ds;
	dms = (int)(ms * 1000); //Truncate to first 3 digits of milliseconds

	//Get number of digits needed to encode "hh"
	buf_len = 10; //":MM:SS,sss".length = 10

	//math lol
	if (hh != 0)
		buf_len += ((int) log10(hh)) + 1;

	//btw it has to be at least 12 characters
	if (buf_len < 12)
		buf_len = 12;

	//Write to buffer
	buffer = (char *) malloc(sizeof(char) * (buf_len + 1));
	buffer[buf_len] = 0;

	sprintf(buffer, "%02d:%02d:%02d,%03d", hh, mm, ss, dms);
	ret = string(buffer);

	//Clean up and return
	free(buffer);
	return ret;
}

int main() {
	string line, txt;
	double start, end;
	int i;

	for (i = 1; getline(cin, line); i++) {
		istringstream tmp;

		//Populate
		tmp.clear();
		tmp.str(line);

		//Start and end timestamps
		if (!(tmp >> start >> end))
			break;

		//Rest of the line... recycle "line"
		tmp.get();
		getline(tmp, line);

		//Ok, print that subtitle out
		printf(
			"\n%d\n%s --> %s\n%s\n",
			i,
			ts_to_str(start).c_str(), ts_to_str(end).c_str(),
			line.c_str()
		);
	}
}
