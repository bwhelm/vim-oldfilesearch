" ============================================================================
" vim-oldfilelist.vim - Vim: improve listing and searching of old file list
" ============================================================================
" Author:        bwhelm
" Version:       0.1
" License:       GPL2 or later

if exists('g:OldFileSearch_loaded') || &compatible
    finish
endif
let g:OldFileSearch_loaded = 1

" Check operating system
if !exists('g:system')
    if has('ios')
        let g:system = 'ios'
    else
        let g:system = 'unknown'
    endif
endif

" Define commands
command! Oldfiles call oldfilesearch#MRUList()
command! BL call oldfilesearch#BufferList()

if g:system ==# 'ios'
    command! IOldDocs call oldfilesearch#IOld()
endif

" Configuration
let g:OldFileSearch_netrw = get(g:, 'OldFileSearch_netrw', 1)
let g:OldFileSearch_fugitive = get(g:, 'OldFileSearch_fugitive', 1)
let g:OldFileSearch_dotfiles = get(g:, 'OldFileSearch_dotfiles', 1)
let g:OldFileSearch_helpfiles = get(g:, 'OldFileSearch_helpfiles', 1)
let g:OldFileSearch_remotefiles = get(g:, 'OldFileSearch_remotefiles', 1)

" Default keymappings
" mnemonic: 'Files-Old' (or 'Files-Open')
let g:OldFileSearch_openMRU = get(g:, 'OldFileSearch_openMRU', '<Leader>fo')
execute 'noremap <unique>' g:OldFileSearch_openMRU ':Oldfiles<CR>'
" mnemonic: 'Buffer List'
let g:OldFileSearch_openBL = get(g:, 'OldFileSearch_openBL', '<Leader>b')
execute 'noremap <unique>' g:OldFileSearch_openBL ':BL<CR>'

if g:system ==# 'ios'
    " mnemonic: 'I Old'
    let g:OldFileSearch_openIO = get(g:, 'OldFileSearch_openIO', '<Leader>io')
    execute 'noremap <unique>' g:OldFileSearch_openIO ':IOldDocs<CR>'
endif

" Open netrw at current file
let g:OldFileSearch_openDir = get(g:, 'OldFileSearch_openDir', '<Leader>d')
execute 'nnoremap <silent>' g:OldFileSearch_openDir ':call oldfilesearch#ExploreAtFilename()<CR>'
