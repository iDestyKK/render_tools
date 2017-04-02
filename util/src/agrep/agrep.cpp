#include <iostream>
#include <fstream>
#include <string>

using namespace std;

int main(int argc, char* argv[]) {
	if (argc != 2) {
		cerr << "Usage: " << argv[0] << " filename" << endl;
		return 1;
	}

	string sample;
	double dB = 0;
	ifstream fp(argv[1]);
	while (fp >> sample) {
		if (sample == "max_volume:") {
			fp >> sample;
			dB = strtod(sample.c_str(), NULL);
			dB *= -1.0;
			cout << dB << endl;
		}
	}
	fp.close();
}