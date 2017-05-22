scriptencoding utf-8
" vim: set fdm=marker foldlevel=0:

function! s:CreateWindow(firstList, secondList)  "{{{1
	if bufname('%') ==# '' && getbufvar('%', '&mod') == 0
		" if unnamed buffer that's not modified
		new
		only
		let l:oneWindow = 1
	else
		belowright new
		let l:oneWindow = 0
	endif
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
	return l:oneWindow
endfunction
"}}}
function! s:OpenFile(command) abort  "{{{1
	" Opens a file in the list of most-recently edited files generated by
	" s:NoFile().
    let l:file = getline('.')
	if len(tabpagebuflist()) > 1
		quit
	endif
	try
		let [l:filename, l:filepath] = split(l:file, ' || ')
		execute a:command fnamemodify(fnameescape(l:filepath . '/' . l:filename),
					\ ':p')
	catch /E687/  " We're in buffer list, not old file list
		let [l:filename, l:filepath, l:location] = split(l:file, ' || ')
		let [l:buffer, l:line] = split(l:location, ',')
		execute a:command l:buffer
		execute ':' . l:line
	catch /E688/  " No file under cursor
		echohl Error
		echo "No file selected! Hit 'q' to quit or 'u' to undo last search."
		echohl None
		return
	endtry
	set nocursorline
endfunction
"}}}
function! s:FilterFileList() abort  "{{{1
	let l:saveSearch = @/
	let l:saveHLS = &hlsearch
	let @/ = ''
	set hlsearch
	let l:text = getline(1, '$')
	let l:queryText = ''
	setlocal modifiable
	" Make a change to start the undoable change
	execute "normal! i \<BS>"
	while 1
		redraw
		echo 'search>' . l:queryText
		let l:char = getchar()
		if l:char == 27                 " <ESC>
			undojoin | call setline(1, l:text)
			setlocal nomodifiable
			redraw
			break
		elseif l:char ==? "\<BS>"
			let l:queryText = l:queryText[:-2]
		elseif l:char == 13             " <CR>
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
		undojoin | 0,$delete_
		undojoin | call setline(1, l:filteredText)
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
		try
			execute '%s/^> ' . l:file . '\(\n[^>]*\)*//g'
		endtry
		wq
		setlocal modifiable
		delete_
		setlocal nomodifiable
	endif
endfunction
"}}}
function! s:UndoFileListChange() abort  "{{{1
	setlocal modifiable
	undo
	setlocal nomodifiable
endfunction
"}}}
function! s:RedoFileListChange() abort  "{{{1
	setlocal modifiable
	redo
	setlocal nomodifiable
endfunction
"}}}
function! oldfilesearch#MRUList() abort  "{{{1
	" Creates list of most recently edited files in new window
	let l:lineList = v:oldfiles
	" Remove netrw and fugitive files
	call filter(l:lineList, 'v:val !~ "\\/runtime\\/doc"')
	if g:OldFileSearch_netrw == 1
		call filter(l:lineList, 'v:val !~ "\\[BufExplorer\\]"')
	endif
	if g:OldFileSearch_fugitive == 1
		call filter(l:lineList, 'v:val !~ "fugitive:\\/\\/"')
	endif
	" Throw out files that aren't readable
	call filter(l:lineList, 'filereadable(fnamemodify(v:val, ":p"))')
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
		call filter(l:firstList, 'v:val !~ "\\/\\."')
		call filter(l:firstList, 'v:val !~ "^\\."')
	endif
	if g:OldFileSearch_helpfiles == 1
		" help files ... (Note: these are covered by dot files....)
		call filter(l:firstList, 'v:val !~ "\\/doc$.*\S*\\.txt"')
	endif
	if g:OldFileSearch_remotefiles == 1
		" remote files ...
		call filter(l:firstList, 'v:val !~ "scp:\\/\\/"')
	endif
	let l:oneWindow = <SID>CreateWindow(l:secondList, l:firstList)
	if l:oneWindow
		" Move to top
		0
	else
		" Move to top and move window to top
		0
		wincmd K
	endif
	nnoremap <silent> <buffer> <CR> :call <SID>OpenFile('edit')<CR>
    nnoremap <silent> <buffer> s :call <SID>OpenFile('split')<CR>
    nnoremap <silent> <buffer> t :call <SID>OpenFile('tabedit')<CR>
	nnoremap <silent> <buffer> v :call <SID>OpenFile('belowright vsplit')<CR>
	nnoremap <silent> <buffer> q ZQ
	nnoremap <silent> <buffer> <Esc> ZQ
	nnoremap <buffer> / :call <SID>FilterFileList()<CR>
	nnoremap <buffer> D :call <SID>MRUDelete()<CR>
	nnoremap <buffer> u :call <SID>UndoFileListChange()<CR>
	nnoremap <buffer> <C-R> :call <SID>RedoFileListChange()<CR>
endfunction
"}}}
function! oldfilesearch#BufferList() abort  "{{{1
	" Creates list of current buffers in new window
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
		" Create window first with hidden list, then with unhidden list
		call <SID>CreateWindow(l:hiddenLineList, l:bufferLineList)
		" Make sure top line is visible (`:0` doesn't seem to work.)
		normal! gg
		" Move to current buffer line
		execute ':' . l:line
		" Move window to top
		wincmd K
	else
		echohl Error
		echo 'No other buffers!'
		echohl None
		return
	endif
	nnoremap <silent><buffer> <CR> :call <SID>OpenFile('buffer')<CR>
	nnoremap <silent><buffer> s :call <SID>OpenFile('sbuffer')<CR>
	nnoremap <silent><buffer> a :quit \| ball<CR>
	nnoremap <silent><buffer> q ZQ<CR>
	nnoremap <silent><buffer> <Esc> ZQ<CR>
	nnoremap <buffer> / :call <SID>FilterFileList()<CR>
	nnoremap <buffer> u :call <SID>UndoFileListChange()<CR>
	nnoremap <buffer> <C-R> :call <SID>RedoFileListChange()<CR>
	nnoremap <silent><buffer> t :call <SID>OpenFile("tabedit \<Bar> buffer")<CR>
	nnoremap <silent><buffer> v
				\ :call <SID>OpenFile("belowright vsplit \<Bar> buffer")<CR>
endfunction
"}}}
function! oldfilesearch#ExploreAtFilename() abort  " {{{1
" Open netrw at the filename of the current buffer
	" Note: The messing around with &shortmess is to ensure that the 'Press
	" <Enter> or type command to continue' message does not show up.
	let l:winID = win_getid()
	if getbufvar('%', '&mod')
		echohl WarningMsg
		echo 'Save buffer first!'
		echohl None
		return
	endif
	let l:myFilename = fnamemodify(expand('%'), ':t')
    let l:myPath = fnamemodify(expand('%'), ':p:h')
	let l:shortmess = &shortmess
	set shortmess+=s
	execute 'silent edit ' . fnameescape(l:myPath) . '/'
	call win_gotoid(l:winID)
	if l:myFilename !=# ''
		execute '/' . l:myFilename
	endif
	execute 'set shortmess=' . l:shortmess
endfunction
"}}}
