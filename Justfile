set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

build:
    ./build.sh

clean:
    rm -rf build
