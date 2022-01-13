vim9script
# EnhancedDiffLayout.vim - Enhanced Diff Layout functions for Vim
# -------------------------------------------------------------
# Version: 0.1
# Maintainer:  NiVa
# Last Change: Sat, 04 Dec 2021
# Script: 
# Copyright:   (c) 2021-2022 by NiVa
#          The VIM LICENSE applies to EnhancedDiffLayout.vim
#          (see |copyright|) except use "EnhancedDiffLayout.vim"
#          instead of "Vim".
#          No warranty, express or implied.
#    *** ***   Use At-Your-Own-Risk!   *** ***

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
