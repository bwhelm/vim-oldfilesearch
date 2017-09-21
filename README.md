# vim-oldfilesearch

This plugin provides a method for easily listing, filtering, and opening
entries in the old file list.

CONTENTS

    1. Using OldFileSearch ............................. |using-oldfilesearch|
    2. Configuring OldFileSearch ................. |configuring-oldfilesearch|

USING OLDFILESEARCH                                      *using-oldfilesearch*

OldFileSearch defines one command: |:Oldfiles|. This command will read in the
'v:oldfile' list, filter out some types of files (configurable as defined
below), and display them as:
    filename.ext || ~/path/to/file
Select a file by putting the cursor anywhere on its line, and open it by
hitting:
    <CR>: open in current window
    s:    open in new horizontal split (below)
    t:    open in new tab
    v:    open in new vertical split (right)
In addition, the old file list can be closed by hitting `q`.

The old file list can be searched by hitting `/`. This brings up a `search>`
prompt in the command line, and lines in the old file list will be filtered in
real time as you type. Standard Vim regex can be used, and words separated by
spaces must all occur in the same line (either filename or path), in any
order. While searching, hitting <CR> will end the search, keeping the filtered
list, whereas hitting <ESC> will end, restoring the previous, unfiltered list.

Note that filtering is preserved in the undo list. This includes filtering for
filetypes as defined below. Hence, hitting `u` will undo these filtering
steps.

CONFIGURING OLDFILESEARCH                        *configuring-oldfilesearch*

|g:OldFileSearch_netrw| = 1                          *g:OldFileSearch_netrw*
Sets whether netrw buffers are filtered out.

|g:OldFileSearch_fugitive| = 1                    *g:OldFileSearch_fugitive*
Sets whether fugitive buffers are filtered out.

|g:OldFileSearch_dotfiles| = 1                    *g:OldFileSearch_dotfiles*
Sets whether dot-file buffers are filtered out.

|g:OldFileSearch_helpfiles| = 1                  *g:OldFileSearch_helpfiles*
Sets whether help buffers are filtered out.

|g:OldFileSearch_remotefiles| = 1              *g:OldFileSearch_remotefiles*
Sets whether remote buffers are filtered out.

|g:OldFileSearch_openMRU| = '<Leader>of'           *g:OldFileSearch_openMRU*
Defines the mapping for the |:Oldfiles| command.
