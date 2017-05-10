" ============================================================================
" OldFileSearch syntax definitions
" ============================================================================

syntax clear
syntax match OFS_FileName /^.\{-}\( || \)\@=/
syntax match OFS_OFSFilePath /\(^.\{-} || \)\@<=.*\( || \d\+,\d\+\)\@<!/
syntax match OFS_BufferFilePath /\(^.\{-} || \)\@<=.*\( || \d\+,\d\+$\)\@=/
syntax match OFS_FileDivider / || \@=/ conceal
syntax match OFS_BL_Lines / || \d\+,\d\+$/ conceal

highlight link OFS_FileName Identifier
highlight link OFS_OFSFilePath Comment
highlight link OFS_BufferFilePath Comment
highlight Conceal cterm=NONE gui=NONE guibg=NONE

setlocal conceallevel=2
setlocal concealcursor=nc
