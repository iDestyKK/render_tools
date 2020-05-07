/*
 * FFMPEG HDR Colour Primaries and Display Luminance string generator
 *
 * Description:
 *     Takes "Colour Primaries" and "Display Luminance" from dxdiag.exe and
 *     converts it into a valid x265-param string for specifying HDR
 *     information.
 *
 * Author:
 *     Clara Nguyen (@iDestyKK)
 */

#include <iostream>
#include <string>
#include <stdio.h>
#include <cmath>

using namespace std;

typedef unsigned int   uint;
typedef unsigned short ushort;

#define CPD 0.00002 //Colour Primaries Divisor
#define DLD 0.0001  //Display Luminance Divisor

class HDR_DISPLAY_SPEC {
	public:
		//Set functions
		void set_r (double x, double y) { fset<ushort>(rx, ry, x, y, CPD); }
		void set_g (double x, double y) { fset<ushort>(gx, gy, x, y, CPD); }
		void set_b (double x, double y) { fset<ushort>(bx, by, x, y, CPD); }
		void set_wp(double x, double y) { fset<ushort>(wx, wy, x, y, CPD); }
		void set_l (double x, double y) { fset<uint  >(lx, ly, x, y, DLD); }

		//Dump string out to stdout
		void dump_master_display() {
			printf(
				"G(%hu,%hu)"
				"B(%hu,%hu)"
				"R(%hu,%hu)"
				"WP(%hu,%hu)"
				"L(%u,%u)\n",
				gx, gy, bx, by, rx, ry, wx, wy,
				lx, ly
			);
		}

	private:
		ushort rx, ry, gx, gy, bx, by, wx, wy;
		uint   lx, ly;

		//Setter utility for readability
		template <typename rty>
		inline void fset(rty &x, rty &y, double &sx, double &sy, double d) {
			x = round(sx / d);
			y = round(sy / d);
		}
};

int main() {
	HDR_DISPLAY_SPEC obj;

	//Configure based on dxdiag information
	obj.set_g (0.306641, 0.630859);
	obj.set_b (0.150391, 0.059570);
	obj.set_r (0.651367, 0.332031);
	obj.set_wp(0.313477, 0.329102);
	obj.set_l (1499.00 , 0.01    );

	obj.dump_master_display();
}

