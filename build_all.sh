# create phoenix release
MIX_ENV=prod mix release

# build macos app
cd frontend/macos
./build.sh
