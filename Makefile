build/playground:
	@zmake --folder raykit --static-library
	@zmake --folder playground

build/raykit:
	@zmake --folder raykit --static-library

build/zmake:
	@cd zmake && zig build

build/zlog:
	@cd zlog && zig build

build/ztemporal:
	@cd ztemporal && zig build

run/zlog:
	@cd zlog && zig build run
	
run/ztemporal:
	@cd ztemporal && zig build run

clean/playground:
	@zmake --folder playground --clean

clean/raykit:
	@zmake --folder raykit --clean