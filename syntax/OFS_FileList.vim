" ============================================================================
" OldFileSearch syntax definitions
" ============================================================================

syntax clear
syntax match OFS_FileName /^.\{-}\ze ||/
syntax match OFS_FilePath /^.\{-} || \zs.*/
syntax match OFS_FileDivider / || /
highlight link OFS_FileName Identifier
highlight link OFS_FilePath Comment
highlight link OFS_FileDivider Structure
