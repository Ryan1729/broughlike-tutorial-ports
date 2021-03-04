libs='-L lib-linux/ -lraylib -lGL -lm -lpthread -ldl -lrt -lX11'

ignored='-Wno-nullability-extension'

test -n "$1" && got_argument=true || got_argument=false

# Show errors until I'm sure I like the default format
$got_argument && clang-format *.c --style='{IndentWidth: 4}' --Werror --verbose -n
format_error_code=$?
echo "formatter error code: $format_error_code"
test "$format_error_code" -ne 0 && exit "$format_error_code"

$got_argument && everything='-Weverything' || everything=''
$got_argument && asan='-fsanitize=address -fno-omit-frame-pointer' || asan=''
$got_argument && ubsan='-fsanitize=nullability-arg -fsanitize=nullability-assign -fsanitize=nullability-return' || ubsan=''

echo "$everything $asan $ubsan"

name='broughlike-tutorial'

clang $name.c -fcolor-diagnostics -g -std=c18 -I include/ -Wall -Wextra $everything -Werror $asan $ubsan $libs $ignored -o $name

compile_error_code=$?

echo "compiler error code: $compile_error_code"

test "$compile_error_code" -ne 0 && exit "$compile_error_code"

./$name

