if exists('g:mru_loaded')
    finish
endif
let g:mru_loaded = 1

" define default command- and autocommands
let g:mru_disable_default_commands = get(g:, 'mru_disable_default_commands', 0)

" don't use fzf by default:
let g:mru_use_fzf = get(g:, 'mru_use_fzf', 0)


lua require'mru'

function! s:mru_buflist(...) abort
    " vim list to lua table:
    let l:args = substitute(join(a:000), '[', '{', 'g')
    let l:args = substitute(l:args, ']', '}', 'g')
    let l:args = substitute(l:args, " ", "\', \'", 'g')

    redir => buf
    let l:cmd = "lua mru_main(" . l:args . ")"
    silent! exe l:cmd
    redir END

    " arbitrary min length:
    if len(buf) < 5
        return []
    endif
    let l:mru_list = split(buf, '\n')
    let l:bufname = expand('%:p')

    if len(l:bufname) == 0
        return l:mru_list
    endif

    " single element in the MRU:
    if len(l:mru_list) == 1
        let l:idx = stridx(l:bufname, l:mru_list[0])
        if l:idx >= 0 " substring match:
            let l:relpath = l:bufname[l:idx:]
            if mru_list[0] == l:bufname ||  mru_list[0] == l:relpath
                " the single MRU element matches the current buffer name
                return []
            endif
        endif
    endif

    if len(l:mru_list) > 1 && len(l:bufname)
        let l:removed = remove(l:mru_list, l:bufname)
    endif
    return l:mru_list
endfunction

function! s:mru_add() abort
    lua mru_main({"--add", vim.fn.expand('%:p')})
endfunction


"---[ FZF ]-----------------------------------------------
function! s:fzf_edit_path(item)
    execute 'e' a:item
endfunction

function! s:open_fzf_mru(...) abort
    let $FZF_DEFAULT_OPTS = ""

    let l:fzf_files_options = '--ansi --border --prompt "MRU> "'
    let l:source = <SID>mru_buflist(a:000)
    if len(l:source) == 0
        return
    endif

    "\ 'down':    len(l:source) + 2
    call fzf#run({
    \ 'source':  l:source,
    \ 'sink':    function('s:fzf_edit_path'),
    \ 'options': '-m ' . l:fzf_files_options,
    \ 'down':    len(l:source) + 4
    \ })
endfunction

"---[ location list ]-------------------------------------
function! s:update_ll(...) abort
    let l:source = <SID>mru_buflist(a:000)
    if len(l:source) == 0
        return
    endif

    silent! call setloclist(0, map(l:source, 
                \ {_, p -> {'filename': p}}))
endfunction

function! s:open_ll_mru(...) abort
    silent! call <SID>update_ll()
    silent! lopen
endfunction

function! s:close_ll_mru() abort
    silent! call <SID>update_ll()
    silent! lclose
endfunction

"---------------------------------------------------------
function! MRU_open(...) abort
    echo "args:L " a:000
    if g:mru_use_fzf == 1
        call call("<SID>open_fzf_mru", a:000)
    else
        call call("<SID>open_ll_mru", a:000)
    endif
endfunction

function! MRU_close(...) abort
    if g:mru_use_fzf == 0
        call <SID>close_ll_mru(a:000)
    endif
endfunction

if ! g:mru_disable_default_commands
    command! -nargs=? MRU call MRU_open(<f-args>)
    
    augroup mru_autocmd
        autocmd!
        autocmd BufEnter * silent! call <SID>mru_add() | mode
    
        autocmd FileType qf nnoremap <silent><buffer> <CR>
                    \ <CR> :silent! call MRU_close()<CR>
    augroup END
end

