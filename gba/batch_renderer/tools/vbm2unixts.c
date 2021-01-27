/*
 * VBA-RR VBM Replay File to Unix Timestamp
 *
 * Description:
 *     Simply extracts the unix timestamp component of a VBA-RR replay file
 *     (*.vbm) and outputs it to stdout.
 *
 * Author:
 *     Clara Nguyen (@iDestyKK)
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int main(int argc, char ** argv) {
	FILE *fp;
	uint32_t ts;

	//Argument check
	if (argc != 2) {
		fprintf(stderr, "usage: %s vbm_file\n", argv[0]);
		return 1;
	}

	fp = fopen(argv[1], "rb");

	//Make sure we can read the file
	if (fp == NULL) {
		fprintf(
			stderr,
			"fopen failed. Unable to open file \"%s\" for reading.\n",
			argv[1]
		);

		return 1;
	}

	//Skip to appropriate offset
	fseek(fp, 0x8, SEEK_SET);

	//Make sure we read correctly
	if (fread(&ts, sizeof(uint32_t), 1, fp) != 1) {
		fprintf(
			stderr,
			"fread failed. Unable to read file at position 0x08.\n"
		);

		return 1;
	}

	fclose(fp);

	//Print out the timestamp
	printf("%u\n", ts);

	//We're done here
	return 0;
}
