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
# Functions {{{1
def s:OldGitVersion() #{{{2
    if !exists('g:enhanced_diff_old_git')
        silent let git_version = matchlist(system("git --version"),'\vgit version (\d+)\.(\d+)\.(\d+)')
        let major = git_version[1]
        let middle = git_version[2]
        let minor = git_version[3]
        let g:enhanced_diff_old_git = (major < 1) || (major == 1 && (middle < 8 || (middle == 8 && minor < 2)))
    endif
    return g:enhanced_diff_old_git
enddef
function s:CustomDiffAlgComplete(A,L,P) #{{{2
    if s:OldGitVersion()
        return "myers\ndefault\npatience"
    else
        return "myers\nminimal\ndefault\npatience\nhistogram"
    endif
endfunc
function s:CustomIgnorePat(bang, ...) #{{{2
    if a:bang
        if a:bang && a:0  && a:1 == '-buffer'
            let b:enhanced_diff_ignore_pat=[]
        else
            let g:enhanced_diff_ignore_pat=[]
        endif
    endif
    if !exists("g:enhanced_diff_ignore_pat")
        let g:enhanced_diff_ignore_pat=[]
    endif

    if a:0
        local = 0
        replace  = 'XXX'
        if a:0 == 3 && a:1 == '-buffer'
            let local=1
            if !exists("b:enhanced_diff_ignore_pat"))
                let b:enhanced_diff_ignore_pat=[]
            endif
        endif
        let pat = local ? a:2 : a:1
        if a:0 == 2
            let replace = local ? a:3 : a:2
        endif
        if local
            call add(b:enhanced_diff_ignore_pat, [pat, replace])
        else
            call add(g:enhanced_diff_ignore_pat, [pat, replace])
        endif
    endif
endfunc
def s:EnhancedDiffExpr(algo: string)
    return printf('EnhancedDiff#Diff("git diff","%s")',
                \ s:OldGitVersion()
                \ ? (a:algo == "patience" ? "--patience":"")
                \ : "--diff-algorithm=".a:algo)
enddef
# public interface {{{1
com! -nargs=1 -complete=custom,s:CustomDiffAlgComplete EnhancedDiff : &diffexpr=s:EnhancedDiffExpr("<args>") | :diffupdate
com! PatienceDiff :EnhancedDiff patience
com! EnhancedDiffDisable  :set diffexpr=
com! -nargs=* -bang EnhancedDiffIgnorePat call s:CustomIgnorePat(<bang>0, <f-args>)
# vim: set ft=vim ff=dos fdm=marker ts=4 :expandtab:
