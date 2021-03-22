#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <set>

using namespace std;

string ts_to_srt(double ts) {
	int ts_i, h, m, s, ms;

	ts_i = ts;
	ms = static_cast<int>((ts - ts_i) * 1000);
	s = ts_i % 60;
	m = ts_i / 60;
	h = ts_i / 3600;

	ostringstream oss;
	oss << setfill('0')
	    << setw(2) << h << ":"
	    << setw(2) << m << ":"
	    << setw(2) << s << ","
	    << setw(3) << ms;

	return oss.str();
}

int main(int argc, char ** argv) {
	//<timestamp, <show/hide, text> >
	multimap<double, pair<bool, string> > dialog;
	multimap<double, pair<bool, string> >::iterator it, look_ahead;

	//Other variables
	set<string> display_str;
	set<string>::iterator sit;
	unsigned long long srt_i;
	int i;
	ifstream fp;
	ofstream op;
	double start, end;
	string text;
	bool in_dialog;

	//Argument check
	if (argc < 2) {
		cerr << "usage: "
		     << argv[0]
		     << " file.txt [file2.txt [file3.txt [...]]]\n";

		return 1;
	}

	//Read subtitles from files.
	for (i = 1; i < argc; i++) {
		fp.open(argv[i]);

		while (fp >> start >> end) {
			fp.get();
			getline(fp, text);

			dialog.insert(make_pair(start, make_pair(true , text)));
			dialog.insert(make_pair(end  , make_pair(false, text)));
		}

		fp.close();
	}

	//Generate SRT
	in_dialog = false;
	srt_i = 1;

	for (it = dialog.begin(); it != dialog.end(); it++) {
		//Grab everything
		const double &ts   = it->first;
		      bool   &stat = it->second.first;
		      string &text = it->second.second;

		//Make the look_ahead variable literally look ahead.
		look_ahead = it;
		look_ahead++;

		//Handle whatever.
		if (stat)
			display_str.insert(text);
		else
			display_str.erase(text);

		//Skip if nothing to show or another event exists simultaneously
		if (display_str.empty() || look_ahead->first == ts)
			continue;

		//Subtitle number
		cout << (srt_i++) << endl;

		//Timestamp range
		if (display_str.size() == 1 && look_ahead->second.first == false)
			cout << ts_to_srt(ts) << " --> "
			     << ts_to_srt(look_ahead->first) << endl;
		else
			cout << ts_to_srt(ts) << " --> "
			     << ts_to_srt(look_ahead->first - 0.001) << endl;

		//Text
		for (sit = display_str.begin(); sit != display_str.end(); sit++)
			cout << *sit << endl;

		cout << endl;
	}

	//Save the world
	return 0;
}
