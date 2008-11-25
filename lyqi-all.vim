" lyqi.vim
" @Author:      Eyolf Østrem (mailto:eyolf curlie oestrem small com)
" @Website:     http://oestrem.com
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     14-May-2008.
" @Last Change: Mon Nov 17 20:32:32 CET 2008
" @Revision:    0.0.1
" TODO:  {{{1
    " macros for \ficta, \fermata, " \times, etc
    " maps/plugin architecture
    " customizable, user-defined layout and macros
    " templates
    " fix the spacing bugs that are still left (why won't pitch() enter a
    " space before the note when the cursor is on the end of the line?)
    
"======================================================================
" USAGE: {{{1
"======================================================================
" The script simplifies note entry for lilypond files. Three different
" kinds of tasks are performed with single or just-a-few key presses: 
" - entry of a new note; 
" - modification of an existing note (wrt duration, accidentals, octave,
"   dots, cautionary accidentals, and articulation signs); 
" - certain special signs, such as fermata, musica ficta, \times x/y {}, etc.
"
" The keyboard is completely remapped: the left hand enters the pitches, in
" the sequence of a piano keyboard, and the right hand 'plays' the rhythms,
" which are laid out 'ergonomically' from the \breve (B) to the 32nd note (P):
" 64th and 128th notes re-use the O and P keys in shifted position, and
" \longa and \maxima are placed on <S-l> and <S-m>. 
" Flats and sharps are added with 'c' and 'v', octaves are modified with
" 'i' (up) and 'm' (down), and cautionary accidentals  are entered with '!'
" and '?'. A \fermata is added with '.'
"
" -------------------------------------------------------------------------  
" |  s  |  g  |  a  |  b  |times|     |     |  '  |16/64|32/128     |     |
" |  Q  |  W  |  E  |  R  |  T  |  Y  |  U  |  I  |  O  |  P  |     |     |
" ---------------------------------------------------------------------------  
"   |  c  |  d  |  e  |  f  | r/R |  1  |  2  |  4  |  8  |     |     |     |
"   |  A  |  S  |  D  |  F  |  G  |  H  |  J  |  K  |  L  |     |     |     |
"   ------------------------------------------------------------------------- 
"     |undo | del |flat |sharp|breve| dot |  ,  |     |     |     |     |
"     |  Z  |  X  |  C  |  V  |  B  |  N  |  M  |     |     |     |     |
"     -------------------------------------------------------------------
"
" The home row is used for the most common elements. 
" The layout ensures that values that are likely to be close together
" (stepwise motion and leaps of fourths; 'f' + 'sharp', 'e' + 'flat';
" adjacent rhythm values, etc.) are close together also on the keyboard. 
"
" Any of the "pitch keys" (asdfwer, plus qgG for s, r, and R) enters a
" single note name. Accidental modifications are rememebered, so one
" doesn't have to change every 'f' to 'fis' in g major. Modifications of
" the simple note is done subsequently. E.g., to turn  
"
"                  f     into      fisis!,\breve..
" 
" one would type the keys 'vv!mbnn' in any order.
" 
"The mode is initialized on startup, or with the vim command Lyqi_init(). To
"enter music, run the function Lyqi_key(), which is an infinite loop (exit
"with <C-c>). 

"The arrow keys navigate between the note strings, and 'z' is mapped to
"'undo'.

"======================================================================
"   Initialization {{{1
"======================================================================
if exists("g:loaded_Lyqi")
    delfun Lyqi_init
    "delfun Lyqi_tonality
    delfun Lyqi_key
    delfun Get_current_note
endif

let g:loaded_Lyqi = 1 " your version number



fun! Lyqi_init()
    " initializes the values that are used throughout. All are immutable
    " and are supposed to be so, except pitchmap, which will change
    " according to the use of accidentals in the course of a piece.
py << EOF
import re 
import math
import vim

global pitches, pitch_keys, pitchmap
pitches = ( "c", "d", "e", "f", "g", "a", "b", "s", "r", "R" )
pitch_keys = ( "a", "s", "d", "f", "w", "e", "r", "q", "g", "G" ) 
pitchmap = dict(zip(pitch_keys, pitches))
accs = ( -1, 1 )
acc_keys = ( "c", "v" )
accmap = dict(zip(acc_keys, accs))
cauts = ( "!", "?" )
caut_keys = ( "!", "?" )
cautmap = dict(zip(caut_keys, cauts))
octs = ( -1, 1 )
oct_keys = ( "m", "i" )
octmap = dict(zip(oct_keys, octs))
durs = ( "128", "64", "32", "16", "8", "4", "2", "1", "\\breve", "\\longa", "\\maxima" )
dur_keys = ( "P", "O", "p", "o", "l", "k", "j", "h", "b", "L", "M" )
durmap = dict(zip(dur_keys, durs))
dots = ( "." )
dot_keys = ( "n" )
valid_note = ("pitch", "acc", "caut", "oct", "dur", "dot", "art", "add")
current = { "pitch": "c", "acc": "", "caut": "", "oct": "", "dur": "", "dot": "" , "art": "", "add": "" }
new_note = ""
vim_note = ""
notestring = r"""^(?P<pitch>[a-grsR])
(?P<acc>(((ses)|(s))|((es){1,2})|((is){1,2}))?)
(?P<caut>[?!]*)
(?P<oct>[,']*)
(?P<dur>((16)|1|2|4|8|(32)|(64)|(\\breve)|(\\longa)|(\\maxima))?)
(?P<dot>[.]*)
(?P<art>([-_^\\].*)*)
(?P<add>.*)$"""
parsed_note = re.compile(notestring,  re.VERBOSE) 

# here begins the python code which does all the string processing and --
# eventually -- the midi output.
# Contains: 
# - a wrapper function, process_key(), which decides which function to call
#   depending on the input key, 
# - specialized functions for each of the note-string elemenst (pitch, acc,
#   caut, oct, dur, dot, art (for articulation signs etc.) and add
#   (whatever is left over...)
# - make_note(), which generates the new note string.
#
# TODO: add functions for art and add
#

# Python functions {{{1


#======================================================================
                                 #set_tonality {{{2
#======================================================================
def set_tonality():
    tonality = vim.eval('b:tonality')
    if tonality == 'c\major' or 'd\dorian' or 'e\phrygian' or 'f\lydian' or 'g\mixolydian' or 'a\minor':
        pitches = ( "c", "d", "e", "f", "g", "a", "b", "s", "r", "R" )
    elif tonality == 'g\major' or 'a\dorian' or 'b\phrygian' or 'c\lydian' or 'd\mixolydian' or 'e\minor':
        pitches = ( "c", "d", "e", "fis", "g", "a", "b", "s", "r", "R" )
    elif tonality == 'd\major' or 'e\dorian' or 'fis\phrygian' or 'g\lydian' or 'a\mixolydian' or 'b\minor':
        pitches = ( "cis", "d", "e", "fis", "g", "a", "b", "s", "r", "R" )
    elif tonality == 'a\major' or 'b\dorian' or 'cis\phrygian' or 'd\lydian' or 'e\mixolydian' or 'fis\minor':
        pitches = ( "cis", "d", "e", "fis", "gis", "a", "b", "s", "r", "R" )
    elif tonality == 'e\major' or 'fis\dorian' or 'gis\phrygian' or 'a\lydian' or 'b\mixolydian' or 'cis\minor':
        pitches = ( "cis", "dis", "e", "fis", "gis", "a", "b", "s", "r", "R" )
    elif tonality == 'b\major' or 'cis\dorian' or 'dis\phrygian' or 'e\lydian' or 'fis\mixolydian' or 'gis\minor':
        pitches = ( "cis", "dis", "e", "fis", "gis", "ais", "b", "s", "r", "R" )
    elif tonality == 'fis' or 'gis\dorian' or 'ais\phrygian' or 'b\lydian' or 'cis\mixolydian' or 'dis\minor':
        pitches = ( "cis", "dis", "eis", "fis", "gis", "ais", "b", "s", "r", "R" )
    elif tonality == 'ges\major' or 'aes\dorian' or 'bes\phrygian' or 'ces\lydian' or 'des\mixolydian' or 'es\minor':
        pitches = ( "ces", "des", "ees", "f", "ges", "aes", "bes", "s", "r", "R" )
    elif tonality == 'des\major' or 'ees\dorian' or 'f\phrygian' or 'ges\lydian' or 'aes\mixolydian' or 'bes\minor':
        pitches = ( "c", "des", "ees", "f", "ges", "aes", "bes", "s", "r", "R" )
    elif tonality == 'aes\major' or 'bes\dorian' or 'c\phrygian' or 'des\lydian' or 'ees\mixolydian' or 'f\minor':
        pitches = ( "c", "des", "ees", "f", "g", "aes", "bes", "s", "r", "R" )
    elif tonality == 'ees\major' or 'f\dorian' or 'g\phrygian' or 'aes\lydian' or 'bes\mixolydian' or 'c\minor':
        pitches = ( "c", "d", "ees", "f", "g", "aes", "bes", "s", "r", "R" )
    elif tonality == 'bes\major' or 'c\dorian' or 'd\phrygian' or 'ees\lydian' or 'f\mixolydian' or 'g\minor':
        pitches = ( "c", "d", "ees", "f", "g", "a", "bes", "s", "r", "R" )
    elif tonality == 'f\major' or 'g\dorian' or 'a\phrygian' or 'bes\lydian' or 'c\mixolydian' or 'd\minor':
        pitches = ( "c", "d", "ees", "f", "g", "a", "bes", "s", "r", "R" )
    else:
        pitches = ( "c", "d", "e", "f", "g", "a", "b", "s", "r", "R" )

    pitchmap = dict(zip(pitch_keys, pitches))


#======================================================================
                                #Parse {{{2
#======================================================================
def parse(input_string):
    match_obj = parsed_note.search(input_string)
    for i in valid_note:
        current[i] = match_obj.group(i)
    #adjust the inconsistent accidental syntax
    if current['acc'].startswith('s'):
        current['acc'] = 'e' + current['acc']


                                #pitch {{{2
#======================================================================
# - change current['pitch'] 
# - TODO: play a sound according to cur_note['pitch'] and [oct]

def pitch(input_key):
    current['pitch'] = pitchmap[input_key]
    n = current['pitch']
    if vim.eval("col('.')") == 1:
        vim.command("normal i" + n)
    elif vim.eval("col('$')-col('.')") == 1:
        vim.command("exe 'normal a ' . n")
    else:
        n += " " 
        vim.command("normal a" + n)
        #vim.command("normal a ")

#======================================================================

                                #acc {{{2
#======================================================================
def acc(input_key):
    vim.command("call Get_current_note()")
    global note
    note = vim.eval("b:notestring")
    parse(note)
    #calculate the new value for acc -- up or down?
    if 'e' in current['acc']:
        esis = -1
    else:
        esis = 1
    accnum = len(current['acc']) / 2 * esis + accmap[input_key]
    if accnum < -1:
        current['acc'] = 'eses'
    elif accnum == -1:
        current['acc'] = 'es'
    elif accnum == 0:
        current['acc'] = ''
    elif accnum == 1:
        current['acc'] = 'is'
    else:
        current['acc'] = 'isis'
    for k in pitchmap:
        if pitchmap[k][:1] == current['pitch']:
            pitchmap[k] = current['pitch'] + current['acc']
    vim.command("normal i" + make_note())

#======================================================================
                                #dur {{{2
#======================================================================
def dur(input_key):
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    current['dur'] = durmap[input_key]
    current['dot'] = ''
    vim.command("normal i" + make_note())

#======================================================================
                       #cautionary accidentals {{{2
#======================================================================
def caut(input_key):
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    current['caut'] = cautmap[input_key]
    vim.command("normal i" + make_note())

#======================================================================
                            #octave signs {{{2
#======================================================================
def oct(input_key):
    #get current note from vim and parse it into current{}
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    if ',' in current['oct']:
        octdir = -1
        octsign = ','
    elif "'" in current['oct']:
        octdir = 1
        octsign = "'"
    else: 
        octdir = 0
        if octmap[input_key] == -1:
            octsign = ',' 
        else:
            octsign = "'"
    octnum = abs(len(current['oct']) * octdir + octmap[input_key])
    current['oct'] = octnum * octsign
    vim.command("normal i" + make_note())

#======================================================================
                                 #dot {{{2
#======================================================================
# TODO: make function for backwards scanning after rhythm value. In the
# meantime, a default value of 4 will have to do.
def dot():
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    if not current['dur']:
        current['dur'] = '4'
    current['dot'] += '.'
    vim.command("normal i" + make_note())


#dur = siste_dur
def find_prev_dur():
   dur_search = []
   for i in durs:
       dur_search[i] = '\\(' + durs[i] + '\\)'
   dur_str = '\\|'.join(dur_search)
   dur_match = vim.command("search("+search_str+", 'bcpn')")
   current['dur'] = durs[dur_match-1]

#======================================================================
                             #make_note {{{2
#======================================================================
def make_note():
    new_note = ""
    for i in valid_note:
        new_note += current[i]
    return new_note

#======================================================================
                              #process_key(): {{{2
#======================================================================
def process_key():
    key = vim.eval("b:input_key")
    if key in pitch_keys:
        pitch(key)
    elif key in acc_keys:
        acc(key)
    elif key in oct_keys:
        oct(key)
    elif key in caut_keys:
        caut(key)
    elif key in dur_keys:
        dur(key)
    elif key in dot_keys:
        dot()
    else:
        key = " " + key + " "
        vim.command("normal a" + key)
EOF
endfun
" }}}2
call Lyqi_init()

"Vim functions {{{1
"======================================================================
                    "function! Get_current_note() {{{2
"======================================================================
" collects the note-string prior to the cursor position (here only a
" rudimentary check is done: the first string which begins with one of
" the note-characters)
" So far limited to plain strings; chords will have to come at a later
" stage.
function! Get_current_note() 
    call search('\<[a-gRrs]', 'bc')
    "let save_cursor = getpos(".") 
    execute "normal diW" 
    let b:notestring = getreg('"') 
    "call setpos('.', save_cursor) 
endfunction
"======================================================================
                              "Lyqi_key {{{2
"======================================================================
function! Lyqi_key()
    let b:input_key = 1
    while b:input_key !~ 'k2' 
        call search('\_s', 'c')
        call setline('.',  substitute(getline('.'), " \\+", " ", "g"))
        2match Error /\<\S\{-}\%#\S\{-}\>\|^\%#\s*/
        match WarningMsg /\%#/
        "positions the cursor at current or following whitespace. Doesn't
        "capture repeated whitespace, but never mind... can be cleaned up with
        "a general function 
        "call cursor(".", searchpos('\_s', 'ce')[1])
        redraw
        "input key press
        " navigation keys; interpreted directly
        let b:input_key = Getchar()
        if b:input_key =~ "kl"
            call search('\_s', 'b')
            redraw
            "match Error /\<\S\{-}\%#\S\{-}\>\|^\%#\s*/
            continue
        elseif b:input_key == '.'
            exe "normal a\\fermata "
            redraw
            continue
        elseif b:input_key =~ "kr"
            call search('\_s', '')
            redraw
            "match Error /\<\S\{-}\%#\S\{-}\>\|^\%#\s*/
            continue
        elseif b:input_key =~ "kd"
            normal j
            call search('\_s', '')
            redraw
            "match Error /\<\S\{-}\%#\S\{-}\>\|^\%#\s*/
            continue
        elseif b:input_key =~ "ku"
            normal k
            "call search('\_s', '')
            redraw
            "match Error /\<\S\{-}\%#\S\{-}\>\|^\%#\s*/
            continue
        elseif b:input_key == 't'
            exe "normal a\\times " . input("Fraction: ", "2/3") . " { " 
            redraw
            continue
        elseif b:input_key == '~'
            exe "normal a~ "
            redraw
            continue
        elseif b:input_key == '\'
            exe "normal a\\" . input("Escaped sequence: ") . " "
            redraw
            continue
        elseif b:input_key == 'x'
            call Get_current_note()
            let line = getline('.')
            substitute(eval(line), " \+", " ", "g")
            redraw
            continue
        elseif b:input_key == 'z'
            normal u
            redraw
            continue
        elseif b:input_key == 'Z'
            redo
            redraw
            continue
        elseif b:input_key =~ 'k2'
            mat
            break
        else
            python process_key()
            redraw
        endif
        redraw
    endwhile
    match
endfunction 

"======================================================================
"fun! Lyqi_tonality {{{2
"======================================================================

fun! Lyqi_tonality()
    "Search back to previous '\key'
    "search('key *', 'be')
    "normal /[a-g] *\\\S*/
    "let b:tonality = getreg('/') 
    "if  b:tonality == ''
    let b:tonality = input('Key: ')
    "endif
    py set_tonality()
endfun

"======================================================================
"general utility functions {{{1
"======================================================================
fun! Getchar()
  let c = getchar()
  if c != 0
    let c = nr2char(c)
  endif
  return c
endfun

match

command! LyqiMode :call Lyqi_key()
noremap <f2> :LyqiMode<cr>


" vim:fdm=marker
"
