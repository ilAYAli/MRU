if exists('g:mru_loaded')
    finish
endif

let g:mru_loaded = 1

" let g:mru_use_fzf = get(g:, 'mru_use_fz', 0)

" race?
let g:mru_use_fzf = 0
if g:loaded_fzf
    let g:mru_use_fzf = 1
endif


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

function! s:mru_add()
    lua mru_main({"--add", vim.fn.expand('%:p')})
endfunction

augroup mru_autocmd
    autocmd!
    " automatically update MRU when switching buffer:
    autocmd BufEnter * silent! call <SID>mru_add() | mode
    "autocmd BufEnter * call <SID>mru_add() | mode
augroup END

"---[ FZF ]-----------------------------------------------
if g:mru_use_fzf == 1
    function! s:fzf_edit_path(item)
        execute 'e' a:item
    endfunction

    let $FZF_DEFAULT_OPTS = ""
    function! s:open_fzf_mru(...)
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

    command! -nargs=? MRU call <SID>open_fzf_mru(<f-args>)
else
"---[ location list ]-------------------------------------
    function! s:update_ll(...)
        let l:source = <SID>mru_buflist(a:000)
        if len(l:source) == 0
            return
        endif

        silent! call setloclist(0, map(l:source, 
                    \ {_, p -> {'filename': p}}))
    endfunction

    function! s:open_ll_mru(...)
        silent! call <SID>update_ll()
        silent! lopen
    endfunction

    function! s:close_ll_mru()
        silent! call <SID>update_ll()
        silent! lclose
    endfunction

    augroup mru_ll_au
        autocmd FileType qf nnoremap <silent><buffer> <CR>
                    \ <CR> :silent! call <SID>close_ll_mru()<CR>
    augroup END

    command! -nargs=? MRU call <SID>open_ll_mru(<f-args>)
endif

