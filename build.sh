#!/bin/sh

set -e

go get -d github.com/bosun-monitor/bosun
go run build.go > _config.yml
cat _config.yml

for GOOS in windows linux darwin; do
	EXT=""
	if [ $GOOS = "windows" ]; then
		EXT=".exe"
	fi
	for GOARCH in amd64 386; do
		export GOOS=$GOOS
		export GOARCH=$GOARCH
		echo $GOOS $GOARCH $EXT
		go build -o bosun-$GOOS-$GOARCH$EXT github.com/bosun-monitor/bosun
	done
done