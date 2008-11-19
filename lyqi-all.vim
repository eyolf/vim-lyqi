" lyqi.vim
" @Author:      Eyolf Østrem (mailto:eyolf curlie oestrem small com)
" @Website:     http://oestrem.com
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     14-May-2008.
" @Last Change: Mon Nov 17 20:32:32 CET 2008
" @Revision:    0.0.1
" TODO:  {{{1
    " Navigation, 
    " error correction (undo), 
    " macros for \ficta, \fermata, " \times, etc
    " maps
"======================================================================
" USAGE: {{{1
"======================================================================
" The script simplifies note entry for lilypond files. Three different
" kinds of tasks are performed with single or just-a-few key presses: 
" - entry of a new note; 
" - modification of an existing note (wrt duration, accidentals, octave,
"   dots, cautionary accidentals, and articulation signs); 
" - certain special signs, such as fermata, musica ficta, \times {}, etc.
"
" The keyboard is completely remapped, the left hand enters the pitches,
" the right hand the rhythms:
"
" -------------------------------------------------------------------------  
" |  s  |  g  |  a  |  b  |times|     |     |  '  |16/64|32/128     |     |
" |  Q  |  W  |  E  |  R  |  T  |  Y  |  U  |  I  |  O  |  P  |     |     |
" ---------------------------------------------------------------------------  
"   |  c  |  d  |  e  |  f  | r/R |  1  |  2  |  4  |  8  |     |     |     |
"   |  A  |  S  |  D  |  F  |  G  |  H  |  J  |  K  |  L  |     |     |     |
"   ------------------------------------------------------------------------- 
"     |undo |     |flat |sharp|breve| dot |  ,  |     |     |     |     |
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
" 
"======================================================================
"
"
"======================================================================
"   Initialization {{{1
"======================================================================
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
EOF
endfun

"======================================================================
"function! Get_current_note() {{{1
"======================================================================
" collects the note-string prior to the cursor position (here only a
" rudimentary check is done: the first string which begins with one of
" the note-characters)
" So far limited to plain strings; chords will have to come at a later
" stage.
function! Get_current_note() 
    call search('\<[a-gRrs]', 'bc')
    "execute "normal ?\<[a-gRrs]?"
    let save_cursor = getpos(".") 
    execute "normal diW" 
    let b:notestring = getreg('"') 
    call setpos('.', save_cursor) 
endfunction
"======================================================================
                              "Lyqi_key {{{1
"======================================================================
function! Lyqi_key()
    let b:input_key = 1
    while b:input_key != "å" 
        "positions the cursor at current or following whitespace. Doesn't
        "capture repeated whitespace, but never mind... can be cleaned up with
        "a general function 
        call cursor(".", searchpos('\_s', 'ce')[1]+1)
        match Error /\<\S\{-}\%#.\{-}\>/
        "input key press
        let b:input_key = nr2char(getchar())
        if b:input_key == 't'
            exe "normal a \\times " . input("Fraction: ", "2/3") . " {" 
            redraw
            continue
            if b:input_key == '}'
                exe "normal a } "
                redraw
                continue
            endif
        elseif b:input_key == '.'
            normal a\fermata
            redraw
            continue
        else
" here begins the python code which does all the string processing and --
" eventually -- the midi output.
" Contains: 
" - a wrapper function, process_key(), which decides which function to call
"   depending on the input key, 
" - specialized functions for each of the note-string elemenst (pitch, acc,
"   caut, oct, dur, dot, art (for articulation signs etc.) and add
"   (whatever is left over...)
" - make_note(), which generates the new note string.
"
" TODO: add functions for art and add
"
python << EOF
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
        vim.command("normal a " + key)

process_key()

                                #Parse {{{2
#======================================================================
def parse(input_string):
    parsed_note = re.compile(notestring,  re.VERBOSE) 
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
    if vim.command("echo col('.')") == 1:
        vim.command("normal i " + n)
    else:
        vim.command("normal a " + n)


#======================================================================
                                #acc {{{2
#======================================================================
def acc(input_key):
    #get current note from vim and parse it into current{}
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
        # her er det en feil: jeg forandrer key og ikke val, eller tvert om ; er
        # for trøtt til å fikse det nå.
    for k in pitchmap:
        if pitchmap[k] == current['pitch']:
            pitchmap[k] = current['pitch'] + current['acc']
    vim.command("normal a" + make_note())

def reverse_lookup(d,v):
    for k in d:
        if d[k] == v:
            return k

#======================================================================
                                #dur {{{2
#======================================================================
def dur(input_key):
    #get current note from vim and parse it into current{}
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    current['dur'] = durmap[input_key]
    current['dot'] = ''
    vim.command("normal a" + make_note())

#======================================================================
                             #make_note {{{2
#======================================================================
def make_note():
    # bruker bare current, så ingen args er nødvendige
    new_note = ""
    for i in valid_note:
        new_note += current[i]
    return new_note

#======================================================================
                       #cautionary accidentals {{{2
#======================================================================
def caut(input_key):
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    current['caut'] = cautmap[input_key]
    vim.command("normal a" + make_note())

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
    vim.command("normal a" + make_note())

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
    vim.command("normal a" + make_note())


#dur = siste_dur
#def find_prev_dur():
#    dur_search = []
#    for i in durs:
#        dur_search[i] = '\\(' + durs[i] + '\\)'
#    dur_str = '\\|'.join(dur_search)
#    dur_match = vim.command("call search("+search_str+", 'bcpn')")
#    current['dur'] = durs[dur_match-1]

EOF
        endif
        redraw
    endwhile
endfunction 




" vim:fdm=marker

