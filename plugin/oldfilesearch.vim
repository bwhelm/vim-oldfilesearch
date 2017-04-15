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

" Define command
command! Oldfiles call oldfilesearch#MRUList()

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
