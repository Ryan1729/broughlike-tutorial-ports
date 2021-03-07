#include "stdio.h"

int main(void) {
    FILE* output = fopen("../spritesheet.c", "wb");

    if (!output) {
        return 1;
    }

    FILE* input = fopen("../assets/spritesheet.png", "rb");

    if (!input) {
        return 2;
    }

    if (fseek(input, 0, SEEK_END) != 0) {
        return 3;
    }

    long image_length = ftell(input);
    if (image_length < 0) {
        return 4;
    }

    fseek(input, 0, SEEK_SET);

    fprintf(output, "static const unsigned char SPRITESHEET_BYTES[%ld] = {", image_length);

    char* sep = "";
    int c; // `int`, not char, is required to handle EOF
    while ((c = fgetc(input)) != EOF) {
        fprintf(output, "%s%u", sep, c);
        sep = ",";
    }

    fprintf(output, "};\n");
    fprintf(output, "static const int SPRITESHEET_LENGTH = %ld;\n", image_length);

    return 0;
}
