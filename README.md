# MRU

MRU, most recently used files
Per _git repo_ database. Common database for all other files.

### Installation
    luarocks --local --lua-version=5.1 install md5
    luarocks --local --lua-version=5.1 install lunajson
    luarocks --local --lua-version=5.1 install argparse

    put the following in ~/.profile, ~/.zshrc or similar:
    eval "$(luarocks --lua-version=5.1 path)"

* https://github.com/junegunn/fzf.vim (for vim integration)

### Configuration
to use fzf, specify:
let g:mru_msu_fzf = 1

### Neo/Vim options
    MRU                             print MRU
    MRU --add /path/to/file         delete entry from MRU
    MRU --del /path/to/file         add entry to MRU

