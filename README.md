# MRU Most Recently Used Files

MRU with one cache for for git non-tracked files, and individual caches per git repo. 

### Installation
    luarocks --local --lua-version=5.1 install md5
    luarocks --local --lua-version=5.1 install lunajson
    luarocks --local --lua-version=5.1 install argparse

    In order to make luarocks work, ensure that the following is executed before launching neovim, by e.g putting the following in ~/.profile, ~/.zshrc or similar:
    eval "$(luarocks --lua-version=5.1 path)"

optional:
* https://github.com/junegunn/fzf.vim


### Configuration
To utilize fzf, specify the following in ~/.config/nvim/init.vim
    let g:mru_use_fzf = 1

Or set the following in "init.lua":
    lua vim.g.mru_use_fzf = 1

### Neo/Vim options
    MRU                             print MRU
    MRU --add /path/to/file         delete entry from MRU
    MRU --del /path/to/file         add entry to MRU

