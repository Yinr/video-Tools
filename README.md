# video-Tools

A bash script to help downloading videos on the web.

## Dependency
[annie](https://github.com/iawia002/annie): get video's info & download videos

ffprobe: get video's resolution

[danmaku2ass](https://github.com/m13253/danmaku2ass): convert xml danmaku to ass

## Usage
> ATTENTION! This readme and help text is not completed, see the source code for more infomations!

```
usage:  ./videoTools.sh SUBCOMMAND [OPTION]...

SUBCOMMAND:
    cookie          - make bilibili cookies
    list [make]     - list or generate download list
    download        - download videos and generate ass
    stat [PREFIX]   - show file list & counts with PREFIX of filename
    ass [PREFIX]    - generate ass from xml with PREFIX of filename
    info            - generate video infomations
    move PREFIX     - move files with PREFIX of filename to ${HOME}/Videos/PREFIX
    help            - show this help text
```

see `./videoTools.sh help` for help.

## License
MIT
