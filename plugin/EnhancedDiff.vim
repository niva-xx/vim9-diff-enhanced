vim9script
# EnhancedDiffLayout.vim - Enhanced Diff Layout functions for Vim
# -------------------------------------------------------------
# Version: 0.1
# Maintainer:  NiVa
# Last Change: Sat, 13 Jan 2022
# Script: 
# Copyright:   (c) 2021-2022 by NiVa
#          The VIM LICENSE applies to EnhancedDiffLayout.vim
#          (see |copyright|) except use "EnhancedDiffLayout.vim"
#          instead of "Vim".
#          No warranty, express or implied.
#    *** ***   Use At-Your-Own-Risk!   *** ***
#
# import EnhancedDiffLayout        from '../autoload/enhanceddifflayout.vim'
# import EnhancedDiffLayout_Toggle from '../autoload/enhanceddifflayout.vim'
import '../autoload/EnhancedDiff.vim' as DiffEnhancedLayout

g:EnhancedDiffLayout_Options = { 'timemsecbefore': 100, 'autocmd_enabled': true }

silent! echomsg 'EnhancedDiffLayout'

augroup difflayout
  au!
  autocmd CursorHold *.tmp call DiffEnhancedLayout.EnhancedDiffLayout()
augroup END

command! -nargs=0 EnhancedDiffLayoutToggle call DiffEnhancedLayout.EnhancedDiffLayout_Toggle()
# vim: set ft=vim ff=dos fdm=marker ts=4 :expandtab:
