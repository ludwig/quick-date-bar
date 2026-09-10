set shell := ["bash", "-euo", "pipefail", "-c"]

project_root := justfile_directory()
derived_data := project_root / "build/DerivedData"
app_name := "SimpleMenuBarApp"
release_app := derived_data / "Build/Products/Release" / app_name + ".app"
installed_app := "/Applications" / app_name + ".app"

# Release build into build/DerivedData (unsigned; see install).
build:
    ./build.sh

# Build only when a source or project file is newer than the app binary.
build-if-needed:
    #!/usr/bin/env bash
    set -euo pipefail
    binary="{{release_app}}/Contents/MacOS/{{app_name}}"
    if [ -f "$binary" ] && [ -z "$(find "{{project_root}}/{{app_name}}" "{{project_root}}/{{app_name}}.xcodeproj" -newer "$binary" -print -quit)" ]; then
        echo "{{app_name}}.app is up to date"
    else
        just --justfile "{{justfile()}}" build
    fi

# Build if needed, then restart the app from the build directory.
run: build-if-needed
    -pkill -x "{{app_name}}"
    open "{{release_app}}"

# Build if needed, ad-hoc sign, replace /Applications/SimpleMenuBarApp.app, and relaunch it.
install: build-if-needed
    #!/usr/bin/env bash
    set -euo pipefail
    if pgrep -xq "{{app_name}}"; then
        echo "Quitting running {{app_name}}"
        pkill -x "{{app_name}}"
        sleep 1
    fi
    rm -rf "{{installed_app}}"
    ditto "{{release_app}}" "{{installed_app}}"
    codesign --force --sign - "{{installed_app}}"
    echo "installed {{installed_app}}"
    open "{{installed_app}}"

# Compile and run the DateFormats boundary-date checks (no Xcode test target needed).
test:
    mkdir -p build
    swiftc -O -o build/date-formats-tests {{app_name}}/DateFormats.swift Tests/DateFormatsTests.swift
    build/date-formats-tests

clean:
    rm -rf build
