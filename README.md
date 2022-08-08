# sketchup-ext-gem

Storage for stand-alone Windows Rubies and gems built for use in SketchUp.

## Stand-alone Ruby Builds

| File              | Version    | RUBY_PLATFORM   | Build System            |  SketchUp  |
|-------------------|------------|-----------------|-------------------------|------------|
| ruby27-x64ms.zip  | 2.7.6p219  | x64-mswin64_140 | VS 2019                 | 2021, 2022 |
| ruby27-x64u.zip   | 2.7.6p219  | x64-mingw-ucrt  | MSYS2 UCRT64 gcc 12.1.0 | 2021, 2022 |


## SketchUp Embedded Ruby Info

| SketchUp | Ruby      | RUBY_PLATFORM   | Build System            |
|----------|-----------|-----------------|-------------------------|
| 2022     | 2.7.2p137 | x64-mswin64_140 | VS 2019                 |
| 2021     | 2.7.2p137 | x64-mswin64_140 | VS 2019                 |
| 2020     | 2.5.5p157 | x64-mingw32     | MSYS2 MINGW64 gcc 8.3.0 |
| 2019     | 2.5.5p157 | x64-mingw32     | MSYS2 MINGW64 gcc 8.3.0 |
| 2018     | 2.2.4p230 | x64-mingw32     | MSYS ?                  |
| 2017     | 2.2.4p230 | x64-mingw32     | MSYS ?                  |
| 2016     | 2.0.0p247 | x64-mingw32     | MSYS ?                  |
| 2015     | 2.0.0p247 | x64-mingw32     | MSYS ?                  |


## Windows Ruby Build Notes

Much of the below refers to publicly available Ruby builds, available at https://rubyinstaller.org/.
Information is also provided about 'mswin' builds.

### Microsoft Visual C++ (MSVC) versions

Ruby CI has always built with MSVC, but for years it was not fully tested.  Today, it is
built and fully tested using versions dating back to VS 2015 along with the most recent releases.

There are essentially two main versions of MSVC, the old version's main file is `msvcrt.dll`,
the new version's file is `VCRUNTIME140.dll`.  Another indication of the newer runtime is
linking to files prefixed by `api-ms-win-crt-`.  SketchUp 2017 changed to the new runtime.
JFYI, it's not quite that simple, but works for Ruby/SketchUp information...

### MINGW gcc compilers

* **Ruby 1.8 to 2.3** - These Rubies were compiled using a MINGW gcc compiler, which was
included with the MSYS system.

* **Ruby 2.4 to 3.0** - These Rubies are also compiled using a MINGW gcc compiler in the new
MSYS2 system, which also provides a package manager (pacman), and many packages.
Note that the MINGW64 tools used the old MSVC runtime.

* **Ruby 3.1 and later** - These Rubies are also compiled using a MSYS2 MINGW compiler, but
using the UCRT64 toolchain, which compiles with the new MSVC runtime.

### Ruby and SketchUp

Starting with SketchUp 2021, the Ruby is a mswin/msvc build, but the main ruby dll file
is named like previous MINGW64 builds.  So, a publicly available Ruby isn't available that
will match the MSVC runtime.  Hence, the two Ruby 2.7 builds available here.

* **ruby27-x64ms.zip** - built with VS 2019, using packages from [Microsoft/vcpkg](https://github.com/Microsoft/vcpkg).  The current vcpkg OpenSSL version is 3.0.x, so one has to grab the build code from
an earlier commit where OpenSSL 1.1.1 is built.

* **ruby27-x64u.zip** - built with MSYS2 UCRT64, which uses the same MSVC runtime as
SketchUp. The first publicly available Ruby version compatible with UCRT64 is Ruby 3.1, but
I backported the changes needed to Ruby 2.7.

One reason for these builds is to allow plugin/extension authors to experiment with
extension gems.  I would suggest first trying to build with `ruby27-x64ms`, as it matches
SketchUp.  Some gems will not compile with MSVC, but will compile with UCRT64 gcc used with
`ruby27-x64u`.  But, since they are different Ruby platforms, the API may vary.

This means that some extension gems compiled with UCRT64 (`ruby27-x64u`) may not load in
SketchUp.  Another way to check them is to try to load them with `ruby27-x64ms`.

### Links

* MSYS2 Installer - https://github.com/msys2/msys2-installer
* Microsoft/vcpkg - https://github.com/Microsoft/vcpkg

### Misc

This repo contains a file `ruby_info.rb`, which outputs info about Ruby builds.  Haven't
tried it with Ruby builds previous to 2.2.  Works with both stand-alone and loaded in
SketchUp.