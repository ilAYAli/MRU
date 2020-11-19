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


### Configuration:
Use FZF:

    vim.g.mru_use_fzf = true

To disable default command- and autocommands:

    vim.g.mru_disable_default_commands = true

