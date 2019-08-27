" Pets. Snippets like regexp-based abbrevations.
" LICENSE: GPLv3 or later
" AUTHOR: zsugabubus
if exists('g:loaded_pets')
	finish
end

let s:save_cpo = &cpo
set cpo&vim

" Replace <Tab> with this key.
if !has_key(g:, 'pets_joker')
	let g:pets_joker = "<Tab>"
endif

let s:skipsc = 'synIDattr(synID(line("."), col("."), 0), "name") =~? "\vstring|comment"'
function! g:PetsUnclosedBrackets(lookbehind) abort
	let winview = winsaveview()
	let brackets = ''
	let roundpos = [0, 0]
	let prev_roundpos = [0, 0]
	let squarepos = [0, 0]
	let prev_squarepos = [0, 0]

	while 1
		if prev_squarepos ==# squarepos
			let squarepos = searchpairpos('\V[', '', '\V]', 'nb', s:skipsc, line('.') - a:lookbehind, 30)
		endif
		if prev_roundpos ==# roundpos
			let roundpos = searchpairpos('\V(', '', '\V)', 'nb', s:skipsc, line('.') - a:lookbehind, 30)
		endif
		if prev_squarepos ==# squarepos && prev_roundpos ==# roundpos || (squarepos ==# [0, 0] && roundpos ==# [0, 0])
			break
		endif

		if squarepos[0] ># roundpos[0] || (squarepos[0] ==# roundpos[0] && squarepos[1] ># roundpos[1])
			let brackets .= ']'
			call cursor(squarepos)
			let prev_squarepos = squarepos
		else
			let brackets .= ')'
			call cursor(roundpos)
			let prev_roundpos = roundpos
		endif
	endwhile

	call winrestview(winview)
	return brackets
endfunction

function! g:PetsCFormatPreprocessorDirective(pd)
	return matchstr(repeat(' ', searchpair('\v\C^#\s*<ifn?%(def)?>', '\v\C^#\s*<%(elif|else)>', '\v\C^#\s*<endif>', 'nWrm', s:skipsc)).a:pd, '\v\C^\s?\zs.*$')
endfunction

augroup vim_pets_snippets
	autocmd!
	autocmd BufNew,BufCreate,BufAdd,BufReadPost,FileType,BufWinEnter *
		\ if !exists('b:pets_snippets')|
		\   let b:pets_snippets = []|
		\ endif

	autocmd FileType lex,yacc let b:pets_snippets += [
		\  ["\\%{", "{\<CR>%}\<C-o>O"],
		\]

	autocmd FileType * let b:pets_snippets += [
		\  ["([([{'\"]+)\<CR>", {m-> "\<CR>".join(reverse(split(substitute(m[1], '.', {n-> get({'(': ')', '[': ']', '{': '}'}, n[0], n[0])}, 'g'), '\zs')), '')."\<C-o>O"}],
		\]

	autocmd FileType c,cpp let b:pets_snippets += [
		\  ["^#@!.*<%(if|for|case|while)> ", " ("],
		\  ["^#@!.*<%(if|for|case|while)>.{-}\\)\\ze ", {m-> empty(g:PetsUnclosedBrackets(winline())) ? " {\<CR>}\<C-O>O" : " "}],
		\  ["%(\\}(\\s*))\\ze<(e%[ls])> ", 'else if ('],
		\  ["%(\\}(\\s*))\\ze<(e%[ls])>(", 'else if('],
		\  ["<for>[^;]+;(\\s?)[^;]+;", {m-> ";".m[1]}],
		\  ["<for>\\s*\\((\\k+) ", ' = '],
		\  ["<for>\\s*\\([^;]*;(\\s*)(\\k+)\\s*([<>])\\s*[^; \t]+\<Tab>", {m-> ';'.m[1].(m[3] == '<' ? '++' : '--').m[2].')'}],
		\  ["<for>(\\s*)\\((\\k+)(\\s*)\\=\\s*(\\d+)\<Tab>", {m-> ';'.m[1][:0].m[2].m[3]."<>"[m[4] >=# 1].m[3]}],
		\  ["\\ze#ifnh (\\k+)\<CR>", {m-> "#ifndef ".m[1]."\<CR>#define ".m[1]."\<CR>\<CR>\<CR>\<CR>#endif /* !".m[1]." */\<Up>\<Up>"}],
		\  ["^#(\\s*)if.*\<CR>", "\<CR>#\\1endif\<C-O>O"],
		\  ["^#(\\s*)endif.*\<CR>", "\<C-O>O#\\1e"],
		\  ["^\\ze(\\s*)#(\\s*)%[include]<",  "\\1#\\2include <>\<Left>"],
		\  ["^\\ze(\\s*)#(\\s*)%[include]\"", "\\1#\\2include \"\"\<Left>"],
		\  ["^\\ze#\\s*<(p%[ragma]|i%[fdef]|i%[fndef]|e%[lif]|e%[ndif]|u%[ndef]|d%[efine]|i%[nclude]|i%[mport]|e%[rro])> ", {m-> '#'.PetsCFormatPreprocessorDirective(matchstr('# pragma # if # ifdef # ifndef #elif #else # undef # define # include # import # error # endif ', '\v\C#\zs ?\V'.m[1].'\v.{-} '))}],
		\  ["^\\ze#\\s*<(e%[lse])>\<CR>", {m-> '#'.PetsCFormatPreprocessorDirective('else')."\<CR>"}],
		\  ["^#(\\s*)<ifn?%(def)?>\\s*\\S*\<CR>", "\<CR>#\\1endif\<C-O>O"],
		\  ["^#@!.*%(\\}\\s*)@!\\ze<(e%[ls])> ", 'else '],
		\  ["^#@!.*\\ze<else>  ", 'else if ('],
		\  ["^#@!.*\\ze<e%[lse]> ?(", 'else if('],
		\  ["^#@!.{-}%[}(\\s*)]\\ze<(e%[lse])>{", {m-> "else".m[1]."{\<CR>}\<C-O>O"}],
		\  ["^#@!.*\\ze<(e%[lse])>\<CR>", "else\<CR>"],
		\  ["^%(.{-}<for>.*)@!\\ze;", {m-> substitute(g:PetsUnclosedBrackets(winline()), '\m^$', ';', '')}],
		\  ["^%(.{-}<for>.*)@!;\\ze;", "\<CR>"],
		\  ["^\\s*\\zes%[truct]\\s+(\\k+) ", "struct \\1 {\<CR>};\<C-O>O"],
		\  ["^\\s*\\zes%[truct]\\s+(\\k+)\<CR>", "struct \\1\<CR>{\<CR>};\<C-O>O"],
		\  ["^\\s*\\zes%[truct]\\s+(\\k+);", "struct \\1;\<C-O>o"],
		\]

	autocmd FileType c,cpp,rust let b:pets_snippets += [
		\  ["%(^|\\s){", "{\<CR>}\<C-O>O"],
		\  ["\\{\<CR>", "\<CR>}\<C-O>O"],
		\  ["\\{ ", "  }\<Left>\<Left>"],
		\  ["\\)\\s*{", "{\<CR>}\<C-O>O"],
		\  ["^\\s*<(b%[rea]|c%[ontinu])>;", {m-> matchstr('break;continue;', '\V\<'.m[1].'\v\zs.{-};')}],
		\]

	autocmd FileType rust let b:pets_snippets += [
		\  ["^\\s*<%(fun|trait|struct|for|loop|match|%(<else> )?if)>.{-}[^{]\\zs\\s*\<CR>", "\<CR>{\<CR>}\<C-O>O"],
		\  ["^\\s*<%(fun|trait|struct|for|loop|match|%(<else> )?if)>.{-}[^{]\\zs\\s*{", " {\<CR>}\<C-O>O"],
		\  ["^.*<let>.*=", "= "],
		\  ["=>", "> "],
		\  ["\\ze<e%[lse]>{", "else {\<CR>}\<C-O>O"],
		\  ["\\ze<e%[lse]>\<CR>", "else\<CR>{\<CR>}\<C-O>O"],
		\]

	autocmd FileType sh,zsh let b:pets_snippets += [
		\  ["^\\s*<case>%(\\s+\\S+|.{-}\\ze\\s+<in>)\<CR>", " in\<CR>esac\<C-O>O"],
		\  ["<then>\<CR>", "\<CR>fi\<C-O>O"],
		\  ["<do>\<CR>", "\<CR>done\<C-O>O"],
		\  ["<for>\\s+\\w+ ", " in "],
		\  ["^\\s*<%(for|while|until)>.*;", "; do\<CR>done\<C-O>O"],
		\  ["^\\s*<%(for|while|until)>.*\<CR>", "\<CR>do\<CR>done\<C-O>O"],
		\  ["\\<\\<(\"?)(\\w+)\\ze\"?\<CR>", "\\1\<CR>\\2\<C-O>O"],
		\  ["\\<\\<(\"?)\<CR>", "EOF\\1\<CR>EOF\<C-O>O"],
		\]

	autocmd FileType vim let b:pets_snippets += [
		\  ["^\\s*<(fu%[nction]|for|wh%[ile]|try|if)>.*\<CR>", "\<CR>end\\1\<C-O>O"],
		\  ["^\\s*<(aug%[roup]>(\\s+<END>)@!)>.*\<CR>", "\<CR>\\1 END\<C-O>O"],
		\]

	autocmd FileType lua let b:pets_snippets += [
		\  ["<%(else)?if>.{-}\\ze\\s*%(.*<then>.*)@<!\<CR>", {-> g:PetsUnclosedBrackets(1)." then\<CR>end\<C-O>O"}],
		\  ["<%(else)?if>.*<then>.*\\S+.{-}\\ze\s*%(<end>)@<!\<CR>", " end\<CR>"],
		\  ["<%(do|then)>%(.*<end>.*)@<!\<CR>", "\<CR>end\<C-O>O"],
		\  ["\\ze<%(f%[unction])>(.{-})%(<end>)@<!\<CR>", {m-> 'function'.m[1].g:PetsUnclosedBrackets(1)."\<CR>end\<C-O>O"}],
		\  ["^\\s*\\ze<e%[ls]>\<CR>", "else\<CR>"],
		\  ["^\\s*\\ze<e%(%[lsif]|%[lseif])> ", "elseif "],
		\]

	autocmd FileType *tex let b:pets_snippets += [
		\  ["^\\\\begin\\{([^}]+)\\}.*\<CR>", "\<CR>\\\\end{\\1}\<C-O>O"],
		\]

augroup END

augroup vim_pets_cmds
	autocmd!
	autocmd BufEnter *
		\ for [pat, Sub] in get(b:, 'pets_snippets', [])|
		\   let key = pat[-1:-1]|
		\   let key = get({"\<Space>": '<Space>', "\<Tab>": g:pets_joker}, key, key)|
		\   if !empty(key)|
		\     execute 'inoremap <expr><nowait><buffer><script><silent> '.key.' <SID>pets("'.(key ==# '"' ? '\"' : key).'")'|
		\   endif|
		\ endfor
augroup END

function! s:pets(key) abort
	let llen = col('$')
	if col('.') ==# llen
		let lnum = line('.')
		let line = getline(lnum)
		let key = a:key !=# g:pets_joker ? a:key : "\<Tab>"

		for [pat, Sub] in get(b:, 'pets_snippets', [])
			if pat[-1:-1] !=# a:key
				continue
			endif

			let pat = '\v\C'.(pat[0] ==# '^' ? '\_' : '^.{-}').pat[:-2].'$'
			try
				let m = matchend(line, pat)
				if m !=# -1
					let dellen = len(substitute(strpart(line, m), '\m.', '.', 'g'))
					return (dellen >=# 2 ? "\<C-O>".(dellen - 1). 'X' : '') .
							 \ (dellen >=# 1 ? "\<C-O>x" : '') .
							 \ substitute(line, pat.'\m\ze', Sub, 'I')
				endif
			catch
				throw 'pets: regexp: '.pat.': '.v:exception
			endtry
		endfor
	endif

	return a:key
endfunction

let g:loaded_pets=1

let &cpo = s:save_cpo
unlet s:save_cpo
