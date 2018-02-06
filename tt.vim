
" FIXME: use vim's filetype detection
let g:tags_supported_types = '\.\(asm\|c\|cpp\|cc\|h\|\java\|py\)$'
let g:tags_ctags_cmd = "ctags --fields=+ailS --c-kinds=+p --c++-kinds=+p --sort=no --extra=+q"
let g:tags_cscope_cmd = "cscope -bkq"

" auto load tags and cscope db
function! LoadTags()
    let cur = expand("%:p:h")                                       " cur file location
    exe "lcd " . cur
    let root = fnamemodify(findfile("cscope.files", ".;"), ":p:h")  " project root
    if (!empty(root))
        if (filereadable("tags"))                                   " load ctags
            exe "set tags=" . root . "/tags" 
        endif
        if (filereadable("cscope.out"))                             " load cscope db
            set nocscopeverbose
            exe "cs add " . root . "/cscope.out " . root 
            set cscopeverbose
        endif
    endif
    lcd -
endfunction
au BufEnter * call LoadTags()

" cmd for create tags and cscope db
function! CreateTags() 
    let root = input("project root: ", expand("%:p:h"))             " project root
    exe "lcd " . root
    let files = systemlist("find . -type f")                        " FIXME: this won't work on windows
    call filter(files, 'v:val =~# g:tags_supported_types')          " only interested files 
    call writefile(files, "cscope.files")                           " save list
    exe "silent !" . g:tags_cscope_cmd . " -i cscope.files"
    exe "silent !" . g:tags_ctags_cmd . " -L cscope.files"
    lcd -
    call LoadTags()
endfunction

" auto update tags and cscope db if loaded
function! UpdateTags() 
    let cur = expand("%:p:h")                                       " current file location
    exe "lcd " . cur
    let root = fnamemodify(findfile("cscope.files", ".;"), ":p:h")  " project root 
    lcd -
    exe "lcd " . root
    let file = fnamemodify(expand("%:p"), ":.")                     " path related to project root
    if match(file, g:tags_supported_types) >= 0
        if (!empty(root))
            if (filewritable("tags"))                               " update ctags
                exe "silent !" . g:tags_ctags_cmd . " " . file
                " no need to reload
            endif
            if (filewritable("cscope.out"))                         " update cscope db and reload
                exe "silent !" . g:tags_cscope_cmd . " " . file 
                exe "silent cs reset"
            endif
        endif
    endif
    lcd -
endfunction
" update tags on :w
au BufWritePost * call UpdateTags()

