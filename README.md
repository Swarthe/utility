# utility

Scripts to simplify common CLI actions (in development).

- `backup`  : Backup the filesystem to an external location.
- `record`  : Record the display and desktop or microphone audio.
- `scot`    : Capture the display to clipboard or file.
- `ydl`     : Download video or audio media from the internet with metadata.
- `vimg`    : Display images with optional interactivity.
- `bat`     : Show and control battery status.

## Installation

```
git clone https://github.com/Swarthe/utility
cd utility
sudo make install
```

To update:

```
git pull origin
sudo make install
```

To uninstall:

```
sudo make uninstall
```

## Usage

Manuals for every script can be displayed with the `-h` command-line option.

## Status

- `backup` is a work-in-progress; much testing is required.

Scripts are designed for GNU/Linux with \*nix portability in mind as per the
table below.

| Script      | GNU/Linux | Darwin/MacOS |
| ----------- | :-------: | :----------: |
| backup      | ✓         | -            |
| ydl-plus    | ✓         | ✓            |
| record      | ✓         | x            |
| scot        | ✓         | x            |
| vimg        | ✓         | -            |
| bat         | ✓         | x            |

More testing is needed for other systems, but all dependencies should be
installed or available on GNU/Linux distributions.

## License

Copyright (C) 2024 Emil Overbeck `<emil.a.overbeck at gmail dot com>`.

Subject to the MIT license. See `LICENSE.txt` for more information.
