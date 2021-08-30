# utility

Scripts to simplify common CLI actions (in development).

- `backup`: Backup the filesystem to an external location.
- `record`: Record the display and desktop or microphone audio.
- `scot`: Capture the display to clipboard or file.
- `ydl`: Download video or audio media from the internet.

## Status

- `backup` is a work-in-progress; MacOS testing is required.
- `record` desktop audio option recently broke for unknown reasons.

Scripts are designed for GNU/Linux with *nix portability in mind as per the
table below.

| Script      | GNU/Linux | MacOS |
| ----------- | :-------: | :---: |
| backup      | ✓         | -     |
| ydl-plus    | ✓         | ✓     |
| record      | ✓         | x     |
| scot        | ✓         | x     |

## License

Subject to the MIT license. See `LICENSE.txt` for more information.
