" Vim indent file Language:		JavaScript
" Author: 		Preston Koprivica (pkopriv2@gmail.com)	
" URL:
" Last Change: 	April 30, 2010

" 0. Standard Stuff
" =================

" Only load one indent script per buffer
if exists('b:did_indent')
  finish
endif

let b:did_indent = 1

setlocal indentexpr=GetJsIndent(v:lnum)
setlocal indentkeys=


setlocal cindent
setlocal autoindent


" 1. Variables
" ============

" Inline comments (for anchoring other statements)
let s:js_mid_line_comment = '\s*\(\/\*.*\*\/\)*\s*'
let s:js_end_line_comment = s:js_mid_line_comment . '\s*\(//.*\)*'
let s:js_line_comment = s:js_end_line_comment

" Comment/String Syntax Key
let s:syn_comment = '\(LineComment\|String\|Regexp\)'


" 2. Aux. Functions
" =================

" = Method: IsInComment
"
" Determines whether the specified position is contained in a comment. "Note:
" This depends on a 
function! s:IsInComment(lnum, cnum)
	return synIDattr(synID(a:lnum, a:cnum, 1), 'name') =~? s:syn_comment
endfunction


" = Method: IsComment
" 
" Determines whether a line is a comment or not.
function! s:IsComment(lnum)
	let line = getline(a:lnum)

	return s:IsInComment(a:lnum, 1) && s:IsInComment(a:lnum, strlen(line)) "Doesn't absolutely work.  Only Probably!
endfunction


" = Method: GetNonCommentLine
"
" Grabs the nearest non-commented line
function! s:GetNonCommentLine(lnum)
	let lnum = prevnonblank(a:lnum)

	while lnum > 0
		if s:IsComment(lnum)
			let lnum = prevnonblank(lnum - 1)
		else
			return lnum
		endif
	endwhile

	return lnum
endfunction

" = Method: SearchForPair
"
" Returns the beginning tag of a given pair starting from the given line.
function! s:SearchForPair(lnum, beg, end)
	" Save the cursor position.
	let curpos = getpos(".")

	" Set the cursor position to the beginning of the line (default
	" behavior when using ==)
	call cursor(a:lnum, 1)

	" Search for the opening tag
	let mnum = searchpair(a:beg, '', a:end, 'bW', 
				\ 'synIDattr(synID(line("."), col("."), 0), "name") =~? s:syn_comment' )

	"Restore the cursor position
	call cursor(curpos)
	
	" Finally, return the matched line number
	return mnum
endfunction


" Object Helpers
" ==============
let s:object_beg = '{[^}]*' . s:js_end_line_comment . '$'
let s:object_end = '^' . s:js_mid_line_comment . '}[;,]\='


function! s:IsObjectBeg(line)
	return a:line =~ s:object_beg
endfunction

function! s:IsObjectEnd(line)
	return a:line =~ s:object_end
endfunction 

function! s:GetObjectBeg(lnum)
	return s:SearchForPair(a:lnum, '{', '}')
endfunction


" Array Helpers
" ==============
let s:array_beg = '\[[^\]]*' . s:js_end_line_comment . '$'
let s:array_end = '^' . s:js_mid_line_comment . '[^\[]*\][;,]*' . s:js_end_line_comment . '$'


function! s:IsArrayBeg(line)
	return a:line =~ s:array_beg
endfunction

function! s:IsArrayEnd(line)
	return a:line =~ s:array_end
endfunction 

function! s:GetArrayBeg(lnum)
	return s:SearchForPair(a:lnum, '\[', '\]')
endfunction


" MultiLine Declaration/Invocation Helpers
" ========================================
let s:paren_beg = '([^)]*' . s:js_end_line_comment . '$'
let s:paren_end = '^' . s:js_mid_line_comment . '[^(]*)[;,]*'

function! s:IsParenBeg(line)
	return a:line =~ s:paren_beg
endfunction

function! s:IsParenEnd(line)
	return a:line =~ s:paren_end
endfunction 

function! s:GetParenBeg(lnum)
	return s:SearchForPair(a:lnum, '(', ')')
endfunction



" Continuation Helpers
" ====================
let s:continuation = '\(+\|\\\)\{1}' . s:js_line_comment . '$' 

function! s:IsContinuationLine(line)
	return a:line =~ s:continuation
endfunction

function! s:GetContinuationBegin(lnum) 
	let cur = a:lnum
	
	while s:IsContinuationLine(getline(cur)) 
		let cur -= 1
	endwhile
	
	return cur + 1
endfunction 


" Switch Helpers
" ==============
let s:switch_beg_next_line = 'switch\s*(.*)\s*' . s:js_mid_line_comment . s:js_end_line_comment . '$'
let s:switch_beg_same_line = 'switch\s*(.*)\s*' . s:js_mid_line_comment . '{\s*' . s:js_line_comment . '$'
let s:switch_mid = '^.*\(case.*\|default\)\s*:\s*' 

function! s:IsSwitchBeginNextLine(line) 
	return a:line =~ s:switch_beg_next_line 
endfunction

function! s:IsSwitchBeginSameLine(line) 
	return a:line =~ s:switch_beg_same_line 
endfunction

function! s:IsSwitchMid(line)
	return a:line =~ s:switch_mid
endfunction 


" Control Helpers
" ===============
let s:cntrl_beg_keys = '\(\(\(if\|for\|with\|while\)\s*(.*)\)\|\(try\|do\)\)\s*'
let s:cntrl_mid_keys = '\(\(\(else\s*if\|catch\)\s*(.*)\)\|\(finally\|else\)\)\s*'

let s:cntrl_beg = s:cntrl_beg_keys . s:js_end_line_comment . '$' 
let s:cntrl_mid = s:cntrl_mid_keys . s:js_end_line_comment . '$' 

let s:cntrl_end = '\(while\s*(.*)\)\s*;\=\s*' . s:js_end_line_comment . '$'

function! s:IsControlBeg(line)
	return a:line =~ s:cntrl_beg
endfunction

function! s:IsControlMid(line)
	return a:line =~ s:cntrl_mid
endfunction

function! s:IsControlMidStrict(line)
	return a:line =~ s:cntrl_mid
endfunction

function! s:IsControlEnd(line)
	return a:line =~ s:cntrl_end
endfunction

" 3. Indenter
" ===========
function! GetJsIndent(lnum)
	" Grab the first non-comment line prior to this line
	let pnum = s:GetNonCommentLine(a:lnum-1)

	" First line, start at indent = 0
	if pnum == 0
		return 0
	endif

	" Grab the second non-comment line prior to this line
	let ppnum = s:GetNonCommentLine(pnum-1)

	" Determine the current level of indentation
	let ind = indent(pnum)

	" Grab the lines themselves.
	let pline = getline(pnum)

	" Fix the conflict with NeoSnippet plugin
	" Without it indentation for snippet
	" ```
	"   /**
	"    *
	"    */
	" ```
	" is broken
	if pline =~ '\/\*\*'
		return ind + 1
	endif

	let line = getline(a:lnum)
	let ppline = getline(ppnum)

	" Handle: Object Closers (ie }) 
	" =============================
	if s:IsObjectEnd(line) && !s:IsComment(a:lnum)
		let obeg = s:GetObjectBeg(a:lnum)
		let oind = indent(obeg)
		return oind
	endif

	if s:IsObjectBeg(pline) 
		return ind + &sw 
	endif


	" Handle: Array Closer (ie ])
	" ============================
	if s:IsArrayEnd(line) && !s:IsComment(a:lnum)
		let abeg = s:GetArrayBeg(a:lnum)
		let aind = indent(abeg)
		return aind
	endif

	if s:IsArrayBeg(pline) 
		return ind + &sw 
	endif

	" Handle: Parens
	" ==============
	if s:IsParenEnd(line) && !s:IsComment(a:lnum)
		let abeg = s:GetParenBeg(a:lnum)
		let aind = indent(abeg)
		return aind
	endif

	if s:IsParenBeg(pline) 
		return ind + &sw 
	endif


	" Handle: Continuation Lines. 
	" ========================================================
	if s:IsContinuationLine(pline) 
		let cbeg = s:GetContinuationBegin(pnum)
		let cind = indent(cbeg)
		return cind + &sw
	endif

	if s:IsContinuationLine(ppline)
		return ind - &sw
	endif

	" Handle: Switch Control Blocks
	" =============================
	if s:IsSwitchMid(pline) 
		if s:IsSwitchMid(line) || s:IsObjectEnd(line)
			return ind
		else
			return ind + &sw
		endif 
	endif

	if s:IsSwitchMid(line)
		return ind - &sw
	endif

	
	" Handle: Single Line Control Blocks
	" ==================================
	if s:IsControlBeg(pline)
		if s:IsControlMid(line)
			return ind
		elseif line =~ '^\s*{\s*$'
			return ind
		else
			return ind + &sw
		endif
		
	endif

	if s:IsControlMid(pline)
		if s:IsControlMid(line)
			return ind
		elseif s:IsObjectBeg(line)
			return ind
		else
			return ind + &sw
		endif
	endif

	if s:IsControlMid(line)
		if s:IsControlEnd(pline) || s:IsObjectEnd(pline)
			return ind
		else
			return ind - &sw
		endif
	endif

	if ( s:IsControlBeg(ppline) || s:IsControlMid(ppline) ) &&
			\ !s:IsObjectBeg(pline) && !s:IsObjectEnd(pline)
		return ind - &sw
	endif

	" Handle: No matches
	" ==================
	return ind
endfunction
