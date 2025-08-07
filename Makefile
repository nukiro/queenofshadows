build/playground:
	@zmake --folder raykit --static-library
	@zmake --folder playground

build/raykit:
	@zmake --folder raykit --static-library

build/zmake:
	@cd zmake && zig build

clean/playground:
	@zmake --folder playground --clean

clean/raykit:
	@zmake --folder raykit --clean