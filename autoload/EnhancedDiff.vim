vim9script

# EnhancedDiff.vim - Enhanced Diff functions for Vim
# -------------------------------------------------------------
# Version: 0.3
## SubMaintainer:  NiVa
## SubLast Change: Fri, 14 Jan 2022
# Maintainer:  Christian Brabandt <cb@256bit.org>
# Last Change: Thu, 05 Mar 2015 08:11:46 +0100
# Script: http://www.vim.org/scripts/script.php?script_id=5121
# Copyright:   (c) 2009-2015 by Christian Brabandt
#          The VIM LICENSE applies to EnhancedDifff.vim
#          (see |copyright|) except use "EnhancedDiff.vim"
#          instead of "Vim".
#          No warranty, express or implied.
#    *** ***   Use At-Your-Own-Risk!   *** ***
# GetLatestVimScripts: 5121 3 :AutoInstall: EnhancedDiff.vim
function s:DiffInit(...) #{{{2
  let s:diffcmd=exists("a:1") ? a:1 : 'diff'
  let s:diffargs=[]
  let diffopt=split(&diffopt, ',')
  let special_args = {'icase': '-i', 'iwhite': '-b'}
  let git_default = get(g:, 'enhanced_diff_default_git',
    \ '--no-index --no-color --no-ext-diff')
  let default_args = (exists("a:2") ? a:2 : ''). ' '.
    \ get(g:, 'enhanced_diff_default_args', '-U0') 
  let diff_cmd = split(s:diffcmd)[0]
  if exists("g:enhanced_diff_default_{diff_cmd}")
    let {diff_cmd}_default = g:enhanced_diff_default_{diff_cmd}
  endif
  # need to get first word of the diff command

  if !executable(diff_cmd)
    throw "no executable"
  endif
  let s:diffargs += split(default_args)
  if exists("{diff_cmd}_default")
    let s:diffargs += split({diff_cmd}_default)
  endif

  for [i,j] in items(special_args)
    if match(diffopt, '\m\C'.i) > -1
      if diff_cmd is# 'git' && i is# 'icase'
        # git diff does not support -i option!
        call s:Warn("git does not support -i/icase option")
        continue
      endif
      call add(s:diffargs, j)
    endif
  endfor

  # Add file arguments, should be last!
  call add(s:diffargs, s:ModifyPathAndCD(v:fname_in))
  call add(s:diffargs, s:ModifyPathAndCD(v:fname_new))
  # v:fname_out will be written later
endfunction
def s:ModifyDiffFiles(): void #{{{2
  # replace provided pattern by 'XXX' so it will be ignored when diffing
  for expr in get(g:, 'enhanced_diff_ignore_pat', []) + get(b:, 'enhanced_diff_ignore_pat', [])
    if !exists("cnt1")
      var cnt1: string = readfile(v:fname_in)
      var cnt2: string = readfile(v:fname_new)
    endif
    # do not modify the test diff, that always comes
    # before the actual diff is evaluated
    if cnt1 ==# ['line1'] && cnt2 ==# ['line2']
      return
    endif
    call map(cnt1, "substitute(v:val, expr[0], expr[1], 'g')")
    call map(cnt2, "substitute(v:val, expr[0], expr[1], 'g')")
  endfor
  if exists("cnt1")
    call writefile(cnt1, v:fname_in)
    call writefile(cnt2, v:fname_new)
  endif
enddef
def s:Warn( msg: string )
  echohl WarningMsg ' unsilent echomsg  "EnhancedDiff: ' .. msg
  echohl Normal
enddef
def s:ModifyPathAndCD(file: string): string #{{{2
  if has("win32") || has("win64")
    # avoid a problem with Windows and cygwins path (issue #3)
    if file is# '-'
      # cd back into the previous directory
      cd -
      return ''
    endif
    var path = fnamemodify(file, ':p:h')
    if getcwd() isnot# path
      exe 'sil :cd' fnameescape(path)
    endif
    return fnameescape(fnamemodify(file, ':p:.'))
  endif
  return fnameescape(file)
enddef
def EnhancedDiff#ConvertToNormalDiff(list: list<string>) #{{{2
  # Convert unified diff into normal diff
  var result=[]
  var start=1
  var hunk_start = '^@@ -\(\d\+\)\%(,\(\d\+\)\)\? +\(\d\+\)\%(,\(\d\+\)\)\? @@.*$'
  var last = ''
  for line in list
    if start && line !~# '^@@'
      continue
    else
      var start=0
    endif
    if line =~? '^+'
      if last is# 'old'
        call add(result, '---')
        var last='new'
      endif
      call add(result, substitute(line, '^+', '> ', ''))
    elseif line =~? '^-'
      var last='old'
      call add(result, substitute(line, '^-', '< ', ''))
    elseif line =~? '^ ' " skip context lines
      continue
    elseif line =~? hunk_start
      var list = matchlist(line, hunk_start)
      var old_start = list[1] + 0
      var old_len   = list[2] + 0
      var new_start = list[3] + 0
      var new_len   = list[4] + 0
      var action    = 'c'
      var before_end= ''
      var after_end = ''
      var last = ''

      if list[2] is# '0'
        var action = 'a'
      elseif list[4] is# '0'
        var action = 'd'
      endif

      if (old_len)
        var before_end = printf(',%s', old_start + old_len - 1)
      endif
      if (new_len)
        var after_end  = printf(',%s', new_start + new_len - 1)
      endif
      call add(result, old_start.before_end.action.new_start.after_end)
    endif
  endfor
  return result
enddef
def s:SysList(cmd: string): string
  if exists('*systemlist')
    return systemlist(cmd)
  endif
  return split(system(cmd), '\n')
enddef
function EnhancedDiff#Diff(...)
  let cmd = (exists("a:1") ? a:1 : '')
  let arg = (exists("a:2") ? a:2 : '')

  " no-op
  " error occured, reset diffexpr
  try
    call s:DiffInit(cmd, arg)
  catch
    set diffexpr=
    " call s:Warn( cmd . ' not found in path, aborting!' )
    call s:Warn( ' not found in path, aborting ' )
    return
  endtry
  call s:ModifyDiffFiles()
  if get(g:, 'enhanced_diff_debug', 0)
    sil echomsg "Executing diff command: ". s:diffcmd . ' '. join(s:diffargs, ' ')
  endif
  let difflist=s:SysList(s:diffcmd . ' ' . join(s:diffargs, ' '))
  call s:ModifyPathAndCD('-')
  if v:shell_error < 0 || v:shell_error > 1
    " An error occured
    set diffexpr=
    call s:Warn(cmd. ' Error executing "'. s:diffcmd. ' '.join(s:diffargs, ' ').'"')
    call s:Warn(difflist[0])
    return
  endif
  " if unified diff...
  " do some processing here
  if !empty(difflist) && difflist[0] !~# '\m\C^\%(\d\+\)\%(,\d\+\)\?[acd]\%(\d\+\)\%(,\d\+\)\?'
    " transform into normal diff
    let difflist=EnhancedDiff#ConvertToNormalDiff(difflist)
  endif
  call writefile(difflist, v:fname_out)
  if get(g:, 'enhanced_diff_debug', 0)
    " This is needed for the tests.
    call writefile(difflist, 'EnhancedDiff_normal.txt')
    " Also write default diff
    let opt = "-a --binary "
    if &diffopt =~ "icase"
      let opt .= "-i "
    endif
    if &diffopt =~ "iwhite"
      let opt .=  "-b "
    endif
    silent execute "!diff " . opt . v:fname_in . " " . v:fname_new .  " > EnhancedDiff_default.txt"
    redraw!
  endif
endfunction


export def EnhancedDiffLayout() #{{{


  exec 'sleep ' .. g:EnhancedDiffLayout_Options.timemsecbefore .. 'm'

  echomsg 'EnhancedDiffLayout :: autocmd called on CursorHold event.'
  g:EnhancedDirDiffDone = {} # cursor hold event locker to do the job

  if ( &ft == 'dirdiff' ) && exists( 'b:currentDiff' )

    var memo_currentDiff: number = b:currentDiff

    # maximize Vim if not 
    if &columns < 200
      set columns=999 
      set lines=999
    endif

    # minimize dirdiff buffer 
    resize 4

    # don't do the job if already done 
    if has_key(g:EnhancedDirDiffDone, memo_currentDiff)
      if g:EnhancedDirDiffDone[memo_currentDiff]
        return
      endif
    endif


    windo if &diff | setl nofoldenable | endif

  exec ':1,2 windo vertical resize ' .. (&columns / 2)
  exec ':1,2 windo setl nofoldenable'
  exec ':1 windo exec '':3'''
  exec ':1 windo norm ]c'

  g:EnhancedDirDiffDone[memo_currentDiff] = true

endif

enddef #}}}
export def EnhancedDiffLayout_Toggle() #{{{

  g:EnhancedDiffLayout_Options.autocmd_enabled = !g:EnhancedDiffLayout_Options.autocmd_enabled

  if !g:EnhancedDiffLayout_Options.autocmd_enabled

    echomsg "EnhancedDiffLayout_autocmd disabled"

    augroup difflayout
      autocmd!
    augroup END

  else

    echomsg "EnhancedDiffLayout_autocmd enabled"
    augroup difflayout
      au!
      autocmd CursorHold *.tmp call EnhancedDiffLayout()
    augroup END

  endif
enddef #}}}
# vim: set ft=vim ff=dos fdm=marker ts=4 :expandtab:
