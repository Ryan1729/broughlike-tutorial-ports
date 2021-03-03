
echo Setup required Environment
echo -------------------------------------
SET NAME_PART="broughlike-tutorial"
SET COMPILER_PATH=C:\raylib\MinGW\bin
SET "PATH=%COMPILER_PATH%;%PATH%"
SET CC=gcc
SET CFLAGS= -O2 -std=c18 -Wall -I include/
SET LDFLAGS=-L lib-windows/ -lraylib -lopengl32 -lgdi32 -lwinmm
echo Clean latest build
echo ------------------------
cmd /c IF EXIST %NAME_PART%.exe del /F $(NAME_PART).exe
echo Compile program
echo -----------------------
%CC% -o %NAME_PART%.exe %NAME_PART%.c %CFLAGS% %LDFLAGS%
echo Execute program
echo -----------------------
cmd /c IF EXIST %NAME_PART%.exe %NAME_PART%.exe



