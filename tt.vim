" FIXME: use vim's filetype detection
let g:tags_interested_types = '\.\(asm\|c\|cpp\|cc\|h\|\java\|py\|sh\|vim\)$'
let s:tags_ctags_cmd = "ctags --fields=+ailS --c-kinds=+p --c++-kinds=+p --sort=no --extra=+q"
let s:tags_cscope_cmd = "cscope -bq"

" find project root
function! FindPrj()
    if exists('b:project_root')     " cache
        "echo "cached b:project_root: [" . b:project_root . "]"
        return b:project_root
    endif

    exe "lcd " . expand("%:p:h")
    let id = findfile("cscope.files", ".;")
    if (empty(id))
        let b:project_root = ''
    else 
        let b:project_root = fnamemodify(id, ":p:h")
    endif
    "echo "b:project_root: [" . b:project_root . "]"
    lcd -
    return b:project_root
endfunction


" load tags and cscope db
function! LoadTags()
    if expand("%:p") =~? g:tags_interested_types 
        let root = FindPrj()
        if (empty(root))
            return
        endif

        exe "lcd " . root
        if (filereadable("tags"))                                   " load ctags
            exe "set tags=" . root . "/tags"
        endif
        if (filereadable("cscope.out"))                             " load cscope db
            set nocscopeverbose
            exe "cs add " . root . "/cscope.out " . root
            set cscopeverbose
        endif
        lcd -
    endif

endfunction

" create tags and cscope db
function! CreateTags()
    let root = input("project root: ", expand("%:p:h"))             " project root
    exe "lcd " . root
    let files = glob("**", v:false, v:true)
    call filter(files, 'filereadable(v:val)')                       " filter out directory
    call filter(files, 'v:val =~? g:tags_interested_types')          " only interested files
    call writefile(files, "cscope.files")                           " save list
    exe "silent !" . s:tags_ctags_cmd . " -L cscope.files"
    exe "silent !" . s:tags_cscope_cmd . " -i cscope.files"
    lcd -
    call LoadTags()
endfunction

" update tags and cscope db if loaded
function! UpdateTags()
    let root = FindPrj()
    if (empty(root))
        return
    endif

    exe "lcd " . root
    let file = fnamemodify(expand("%:p"), ":.")                     " path related to project root
    if file =~? g:tags_interested_types 
        let files = readfile("cscope.files")
        if match(files, file) < 0
            files+=file
            call writefile(files, "cscope.files")
        endif

        if (filewritable("tags"))                               " update ctags
            exe "silent !" . s:tags_ctags_cmd . " -L cscope.files"
            " no need to reload
        endif
        if (filewritable("cscope.out"))                         " update cscope db and reload
            exe "silent !" . s:tags_cscope_cmd . " -i cscope.files"
            exe "silent cs reset"
        endif
    endif
    lcd -
endfunction

augroup tagsmngr
    au!
    " load tags on BufEnter
    au BufEnter * call LoadTags()
    " update tags on :w
    au BufWritePost * call UpdateTags()
augroup END
