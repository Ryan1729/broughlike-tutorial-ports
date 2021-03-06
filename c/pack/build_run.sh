libs=''

ignored='-Wno-nullability-extension'

test -n "$1" && got_argument=true || got_argument=false

# No clang-format until it supports sensible paren placement,
# if I have anything to say about it.
# https://reviews.llvm.org/D33029

$got_argument && everything='-Weverything' || everything=''
$got_argument && asan='-fsanitize=address -fno-omit-frame-pointer' || asan=''
$got_argument && ubsan='-fsanitize=nullability-arg -fsanitize=nullability-assign -fsanitize=nullability-return' || ubsan=''

echo "$everything $asan $ubsan"

name='pack'

clang $name.c -fcolor-diagnostics -ferror-limit=0 -g -std=c18 -I include/ -Wall -Wextra $everything -Werror $asan $ubsan $libs $ignored -o $name

compile_error_code=$?

echo "compiler error code: $compile_error_code"

test "$compile_error_code" -ne 0 && exit "$compile_error_code"

./$name

