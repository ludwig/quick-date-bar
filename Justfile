set shell := ["bash", "-eu", "-o", "pipefail", "-c"]

# Build the Release app into build/DerivedData.
build:
    ./build.sh

# Compile and run the DateFormats boundary-date checks (no Xcode test target needed).
test:
    mkdir -p build
    swiftc -O -o build/date-formats-tests SimpleMenuBarApp/DateFormats.swift Tests/DateFormatsTests.swift
    build/date-formats-tests

clean:
    rm -rf build
