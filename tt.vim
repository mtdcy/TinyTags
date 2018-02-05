" FIXME: use vim's filetype detection
let g:tags_supported_types = '\.\(asm\|c\|cpp\|cc\|h\|\java\|py\)$'
let g:tags_ctags_cmd = "ctags --fields=+ailS --c-kinds=+p --c++-kinds=+p --sort=no --extra=+q"
let g:tags_cscope_cmd = "cscope -bkq"

function! Fixed_findfile(filename)
    exe "lcd " . expand("%:p:h")
    let result = findfile(a:filename, ".;")
    lcd -
    return result
endfunction

" auto load tags and cscope db
function! LoadTags()
    let loc = fnamemodify(Fixed_findfile("cscope.files"), ":p:h")
    exe "lcd " . loc
    if (!empty(loc))
        if (filereadable("tags"))
            exe "set tags=" . loc . "/tags" 
        endif
        if (filereadable("cscope.out"))
            set nocscopeverbose
            exe "cs add " . loc . "/cscope.out"
            set cscopeverbose
        endif
    endif
    lcd -
endfunction
au BufEnter * call LoadTags()

" cmd for create tags and cscope db
function! CreateTags() 
    let loc = input("project root: ", expand("%:p:h"))
    exe "lcd " . loc
    let files = systemlist("find . -type f")
    call filter(files, 'v:val =~# g:tags_supported_types')
    " create if not exists; or empty target
    exe "silent !echo -n \"\" > cscope.files"
    call writefile(files, "cscope.files", "a")

    " create cscope db 
    exe "silent !" . g:tags_cscope_cmd . " -i cscope.files"
    exe "silent !" . g:tags_ctags_cmd . " -L cscope.files"
    lcd -
    call LoadTags()
endfunction

" auto update tags and cscope db if loaded
function! UpdateTags() 
    let curfile = fnamemodify(expand("%:p"), ":.")
    let loc = fnamemodify(Fixed_findfile("cscope.files"), ":p:h")
    exe "lcd " . loc
    if match(curfile, g:tags_supported_types) >= 0
        if (!empty(loc))
            let ctags_file = loc . "/tags"
            if (filewritable("tags")) 
                exe "silent !" . g:tags_ctags_cmd . " " . curfile 
                " no need to reload
            endif
            if (filewritable("cscope.out"))
                exe "silent !" . g:tags_cscope_cmd . " " . curfile
                exe "silent cs reset"
            endif
        else
            call CreateTags()
        endif
    endif
    lcd -
endfunction
" update tags on :w
au BufWritePost * call UpdateTags()
