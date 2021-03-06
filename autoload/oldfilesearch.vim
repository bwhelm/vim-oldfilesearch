scriptencoding utf-8
" vim: set fdm=marker:
" ----------------------------------------------------------------------------

function! s:CreateWindow(firstList, secondList) abort  "{{{1
    tabedit
    setlocal buftype=nofile
           \ filetype=ofs_filelist
           \ noswapfile
           \ nowrap
           \ nospell
           \ nocursorline
    " Break undo sequence
    execute "normal! i\<C-G>u\<Esc>"
    " Add text
    call append(0, a:firstList)
    " Break undo sequence
    execute "normal! i\<C-G>u\<Esc>"
    " Remove blank lines
    call setline(1, a:secondList)
    try
        silent execute len(a:secondList) + 1 . ',$delete_'
    catch /E493/
    endtry
    silent global/^$/delete_
    setlocal nomodifiable
    1
endfunction
"}}}
function! s:OpenFile(command, winNum, tabNum) abort  "{{{1
    " Opens a file in the list of most-recently edited files generated by
    " oldfilesearch#MRUList().
    if a:command =~# 'iolddocs'
        let l:line = line('.')
        bwipeout
        execute a:command l:line
        if a:winNum == 1
            call oldfilesearch#IOld()
        endif
        return
    endif
    let l:file = getline('.')
    " TODO: What do the next 3 lines do?
    " if len(tabpagebuflist()) > 1
    "     bwipeout
    " endif
    try
        let [l:filename, l:filepath] = split(l:file, ' || ')
        " Quit the special buffer, switch back to original tab and window
        bwipeout
        execute a:tabNum . 'tab'
        execute a:winNum . 'wincmd w'
        " Execute the new command from that window
        execute a:command fnamemodify(fnameescape(l:filepath . '/' . l:filename),
                    \ ':p')
        " Change local dir to document directory ... or git directory.
        lcd %:p:h
        if g:system !=# 'ios'
            try  " Get top-level git directory
                execute 'lcd' system('git rev-parse --show-toplevel')
            catch /E344/  " Not in git directory
            endtry
        endif
    catch /E687/  " We're in buffer list, not old file list
        let [l:filename, l:filepath, l:location] = split(l:file, ' || ')
        let [l:buffer, l:line] = split(l:location, ',')
        " Quit the special buffer, switch back to original tab and window
        bwipeout
        execute a:tabNum . 'tab'
        execute a:winNum . 'wincmd w'
        " Execute the new command from that window
        execute a:command l:buffer
        execute ':' . l:line
    catch /E688/  " No file under cursor
        " Quit the special buffer, switch back to original tab and window
        bwipeout
        execute a:tabNum . 'tab'
        execute a:winNum . 'wincmd w'
        echohl Error
        redraw | echo "No file selected! Hit 'q' to quit or 'u' to undo last search."
        echohl None
        return
    endtry
    setlocal nocursorline
endfunction
"}}}
function! s:FilterFileList() abort  "{{{1
    let l:saveSearch = @/
    let l:saveHLS = &hlsearch
    let @/ = ''
    setlocal hlsearch
    let l:text = getline(1, '$')
    let l:queryText = ''
    setlocal modifiable
    " Make a change to start the undoable change
    execute "normal! i \<BS>"
    while 1
        redraw | echo 'search>' . l:queryText
        let l:char = getchar()
        if l:char == 27         " <ESC>
            undojoin | call setline(1, l:text)
            setlocal nomodifiable
            redraw
            break
        elseif l:char ==? "\<BS>"
            let l:queryText = l:queryText[:-2]
        elseif l:char == 13         " <CR>
            setlocal nomodifiable
            redraw
            break
        else
            let l:queryText .= nr2char(l:char)
        endif
        let l:filteredText = deepcopy(l:text)
        let l:queryList = split(l:queryText, ' ')
        for s:query in l:queryList
            try
                let l:filteredText = filter(l:filteredText, 'v:val =~ s:query')
            endtry
        endfor
        undojoin | 0,$delete_ | call setline(1, l:filteredText)
        let l:strippedQuery = substitute(l:queryText, ' $', '', '')  " strip trailing space
        let @/ = substitute(l:strippedQuery, ' ', '\\|', 'g')
    endwhile
    let @/ = l:saveSearch
    let &hlsearch = l:saveHLS
    redraw
endfunction
"}}}
function! s:MRUDelete() abort  "{{{1
    let l:file = getline('.')
    let [l:filename, l:filepath] = split(l:file, ' || ')
    let l:file = fnamemodify(l:filepath . '/' . l:filename, ':~')
    let l:file = substitute(l:file, '/', '\\/', 'g')
    let l:file = substitute(l:file, '\~', '\\\~', 'g')
    let l:file = substitute(l:file, '\.', '\\.', 'g')
    " Now need to search in `~/.viminfo` or `~/.nviminfo` for relevant lines
    " and delete them.
    if has('nvim')
        "split ~/.nviminfo
        echoerr 'Not implemented ...'
        return
    else
        split ~/.viminfo
        execute 'silent! %substitute/^>' l:file . '\(\n[^>]*\)*//g'
        wq
        setlocal modifiable
        delete_
        setlocal nomodifiable
    endif
endfunction
"}}}
function! s:UndoFileListChange() abort  "{{{1
    setlocal modifiable
    let l:save_s = @s
    let l:save_t = @t
    normal! msHmt
    undo
    normal! 'tzt`s
    let @s = l:save_s
    let @t = l:save_t
    setlocal nomodifiable
endfunction
"}}}
function! s:RedoFileListChange() abort  "{{{1
    setlocal modifiable
    let l:save_s = @s
    let l:save_t = @t
    normal! msHmt
    redo
    normal! 'tzt`s
    let @s = l:save_s
    let @t = l:save_t
    setlocal nomodifiable
endfunction
"}}}
function! oldfilesearch#MRUList() abort  "{{{1
    " Creates list of most recently edited files in new window
    let l:lineList = v:oldfiles
    " Remove netrw and fugitive files
    call filter(l:lineList, 'v:val !~# "\\/runtime\\/doc"')
    if g:OldFileSearch_netrw == 1
        call filter(l:lineList, 'v:val !~# "\\[BufExplorer\\]"')
    endif
    if g:OldFileSearch_fugitive == 1
        call filter(l:lineList, 'v:val !~# "fugitive:\\/\\/"')
    endif
    " Reformat lines for pretty presentation
    let l:firstList = []
    for l:line in l:lineList
        let l:path = fnamemodify(l:line, ':~:h')
        let l:filename = fnamemodify(l:line, ':t')
        call add(l:firstList, l:filename . ' || ' . l:path)
    endfor
    " Copy the list now for setting undo sequence
    let l:secondList = deepcopy(l:firstList)
    " Remove typically unwanted files
    if g:OldFileSearch_dotfiles == 1
        " dot files ...
        call filter(l:firstList, 'v:val !~# "\\/\\."')
        call filter(l:firstList, 'v:val !~# "^\\."')
        if g:system ==# 'ios'
            call filter(l:firstList, 'v:val !~# "vim-folder"')
        endif
    endif
    if g:OldFileSearch_helpfiles == 1
        " help files ... (Note: these are covered by dot files....)
        call filter(l:firstList, 'v:val !~# "\\/doc$.*\S*\\.txt"')
    endif
    if g:OldFileSearch_remotefiles == 1
        " remote files ...
        call filter(l:firstList, 'v:val !~# "scp:\\/\\/"')
    endif
    " Throw out files that aren't readable
    call filter(l:lineList, 'filereadable(fnamemodify(v:val, '':p''))')

    let l:winNum = winnr()
    let l:tabNum = tabpagenr()
    let l:oneWindow = <SID>CreateWindow(l:secondList, l:firstList)
    execute 'nnoremap <silent> <buffer> <CR> :call <SID>OpenFile(''drop'', '
                \ . l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent> <buffer> s :call <SID>OpenFile(''split'', '
                \ . l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent> <buffer> t :call <SID>OpenFile(''tab drop'', '
                \ . l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent> <buffer> v :call <SID>OpenFile(''belowright '
                \ . 'vsplit'',' l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent><buffer> q :bwipeout! <Bar>' l:tabNum
                \ . 'tab <Bar>' l:winNum . 'wincmd w<CR>'
    execute 'nnoremap <silent><buffer> <Esc> :bwipeout! <Bar>' l:tabNum
                \ . 'tab <Bar>' l:winNum . 'wincmd w<CR>'
    execute 'nnoremap <silent><buffer> e :bwipeout! <Bar>' l:tabNum . 'tab <Bar> '
                \ . l:winNum . 'wincmd w <Bar> enew<CR>'
    execute 'nnoremap <silent><buffer> i :bwipeout! <Bar>' l:tabNum . 'tab <Bar> '
                \ . l:winNum . 'wincmd w <Bar> enew<CR>i'
    nnoremap <buffer> / :call <SID>FilterFileList()<CR>
    nnoremap <buffer> D :call <SID>MRUDelete()<CR>
    nnoremap <buffer> u :call <SID>UndoFileListChange()<CR>
    nnoremap <buffer> <C-R> :call <SID>RedoFileListChange()<CR>
endfunction
"}}}
if g:system ==# 'ios'
    function! oldfilesearch#IOld() abort  "{{{1
        " Creates list of most recently edited files in new window
        redir @z
        silent iolddocs
        redir END
        let l:lineList = split(@z, "\n")
        let l:firstList = l:lineList
        " " Copy the list now for setting undo sequence
        let l:secondList = deepcopy(l:firstList)
        for item in range(len(l:firstList))
            let l:firstList[item] = substitute(l:firstList[item], '\/.\{-}\([^\/]*\)$', '\1', '')
        endfor
        let l:oneWindow = <SID>CreateWindow(l:secondList, l:firstList)
        nnoremap <silent> <buffer> <CR> :call <SID>OpenFile('iolddocs', 0, 0)<CR>
        nnoremap <silent> <buffer> D :call <SID>OpenFile('iolddocs!', 1, 0)<CR>
        nnoremap <silent><buffer> q :bwipeout!<CR>
        nnoremap <silent><buffer> <Esc> :bwipeout!<CR>
        nnoremap <buffer> u :call <SID>UndoFileListChange()<CR>
        nnoremap <buffer> <C-R> :call <SID>RedoFileListChange()<CR>
    endfunction
    "}}}
endif
function! s:BufferWipeout() abort  "{{{1
    let l:file = getline('.')
    let [l:filename, l:filepath, l:line] = split(l:file, ' || ')
    let l:file = fnamemodify(l:filepath . l:filename, ':~')
    execute 'bwipeout' l:file
    setlocal modifiable
    delete_
    setlocal nomodifiable
endfunction
function! oldfilesearch#BufferList() abort  "{{{1
    " Creates list of current buffers in new window
    let l:myFilename = fnamemodify(expand('%'), ':t')
    let l:bufNum = bufnr('%')
    let l:oldA = @a
    redir @a
    silent buffers!
    redir END
    let l:lineList = split(@a, '\n')
    let @a = l:oldA
    unlet l:oldA
    let l:bufferLineList = []  " Keep track of normal buffer list ...
    let l:hiddenLineList = []  " ... and list with hidden buffers
    let l:line = 0
    let l:listedCounter = 0
    for l:item in range(len(l:lineList))
        let l:bmatch = matchlist(l:lineList[l:item],
                \ '\s*\(\d\+u\?\)\s\+[^"]*"\(.\+\/\)\?\([^"]*\)"\s*line\s*\(\d\+\)')
        try
            let l:number = str2nr(l:bmatch[1])
            let l:unlisted = l:bmatch[1] =~? 'u'
            let l:thisItem = l:bmatch[3] . ' || ' .
                            \ fnamemodify(l:bmatch[2], ':p:~') . ' || ' .
                            \ l:number . ',' . l:bmatch[4]
            if l:unlisted
                call add(l:hiddenLineList, l:thisItem)
            else
                call add(l:hiddenLineList, l:thisItem)
                call add(l:bufferLineList, l:thisItem)
                let l:listedCounter += 1
            endif
            if l:number == l:bufNum
                let l:line = l:listedCounter
            endif
        catch /E684/  " list index out of range
        endtry
    endfor
    if len(l:hiddenLineList) > 1
        let l:winNum = winnr()
        let l:tabNum = tabpagenr()
        " Create window first with hidden list, then with unhidden list
        call <SID>CreateWindow(l:hiddenLineList, l:bufferLineList)
    else
        echohl Error
        redraw | echo 'No other buffers!'
        echohl None
        return
    endif
    if l:myFilename !=# ''
        silent call search('\C' . l:myFilename)
    endif
    execute 'nnoremap <silent><buffer> <CR> :call <SID>OpenFile(''buffer'', '
                \ . l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent><buffer> s :call <SID>OpenFile(''sbuffer'', '
                \ . l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent><buffer> t :call <SID>OpenFile(''tabedit <Bar>'
                \ . 'buffer'',' l:winNum . ',' l:tabNum . ')<CR>'
    execute 'nnoremap <silent><buffer> v :call <SID>OpenFile(''belowright vsplit'
                \ . '<Bar> buffer'',' l:winNum . ',' l:tabNum . ')<CR>'
    nnoremap <silent><buffer> a :quit \| ball<CR>
    execute 'nnoremap <silent><buffer> q :bwipeout! <Bar>' l:tabNum
                \ . 'tabnext <Bar>' l:winNum . 'wincmd w<CR>'
    execute 'nnoremap <silent><buffer> <Esc> :bwipeout! <Bar>' l:tabNum
                \ . 'tabnext <Bar>' l:winNum . 'wincmd w<CR>'
    execute 'nnoremap <silent><buffer> e :bwipeout! <Bar>' l:tabNum . 'tabnext <Bar> '
                \ . l:winNum . 'wincmd w <Bar> enew<CR>'
    execute 'nnoremap <silent><buffer> i :bwipeout! <Bar>' l:tabNum . 'tabnext <Bar> '
                \ . l:winNum . 'wincmd w <Bar> enew<CR>i'
    nnoremap <silent><buffer> D :call <SID>BufferWipeout()<CR>
    nnoremap <buffer> / :call <SID>FilterFileList()<CR>
    nnoremap <buffer> u :call <SID>UndoFileListChange()<CR>
    nnoremap <buffer> <C-R> :call <SID>RedoFileListChange()<CR>
endfunction
"}}}
function! oldfilesearch#ExploreAtFilename() abort  " {{{1
" Open netrw at the filename of the current buffer
    " Note: The messing around with &shortmess is to ensure that the 'Press
    " <Enter> or type command to continue' message does not show up.
    let l:winID = winnr()
    if getbufvar('%', '&mod')
        echohl WarningMsg
        redraw | echo 'Save buffer first!'
        echohl None
        return
    endif
    let l:myFilename = fnamemodify(expand('%'), ':t')
    let l:myPath = fnamemodify(expand('%'), ':p:h')
    execute 'silent edit' fnameescape(l:myPath) . '/'
    execute l:winID . 'wincmd w'
    if l:myFilename !=# ''
        silent call search('\C' . l:myFilename)
    endif
endfunction
"}}}
