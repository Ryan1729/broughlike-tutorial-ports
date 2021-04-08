#include "stdio.h"

int append_var(FILE* output, char* file_name, char* prefix) {
    FILE* input = fopen(file_name, "rb");

    if (!input) {
        return 2;
    }

    if (fseek(input, 0, SEEK_END) != 0) {
        return 3;
    }

    long input_length = ftell(input);
    if (input_length < 0) {
        return 4;
    }

    fseek(input, 0, SEEK_SET);

    fprintf(output, "static const unsigned char ");
    fprintf(output, "%s", prefix);
    fprintf(output, "_BYTES[%ld] = {", input_length);

    char* sep = "";
    int c; // `int`, not char, is required to handle EOF
    while ((c = fgetc(input)) != EOF) {
        fprintf(output, "%s%u", sep, c);
        sep = ",";
    }

    fprintf(output, "};\n");
    fprintf(output, "static const int ");
    fprintf(output, "%s", prefix);
    fprintf(output, "_LENGTH = %ld;\n", input_length);

    return 0;
}

int main(void) {
    FILE* output = fopen("../asset_bytes.c", "wb");

    if (!output) {
        return 1;
    }

    int error;

#define APPEND(file_name, prefix) \
    error = append_var( \
        output, \
        file_name, \
        prefix \
    ); \
\
    if (error) {\
        return error;\
    }\
\

    APPEND("../assets/spritesheet.png", "SPRITESHEET")
    APPEND("../assets/hit1.wav", "HIT_1")
    APPEND("../assets/hit2.wav", "HIT_2")
    APPEND("../assets/newLevel.wav", "NEW_LEVEL")
    APPEND("../assets/spell.wav", "SPELL")
    APPEND("../assets/treasure.wav", "TREASURE")

    return 0;
}
