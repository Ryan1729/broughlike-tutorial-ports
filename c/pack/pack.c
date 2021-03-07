#include "stdio.h"

int main(void) {
    FILE* output = fopen("../spritesheet.c", "wb");

    if (!output) {
        return 1;
    }

    int image_length = 1;

    fprintf(output, "static const unsigned char SPRITESHEET_BYTES[%d] = {0};\n", image_length);
    fprintf(output, "static const int SPRITESHEET_LENGTH = %d;\n", image_length);

    return 0;
}
