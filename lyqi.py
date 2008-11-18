# coding: utf8

#======================================================================
                          #initialize values{{{1
#======================================================================
# pitches (rhythms, ...)  contains the pitch names used in the file, plus
# "s" and "r" pitch_keys is a (user-defined) variable list of keyboard keys
# to go with the various pitch names pitchmap gives the current translation
# between keyb. input and output to document:
# pitchmap["a"] = "c".  The dictionary is initialized with default values,
# but  will be changed along the way, to store the current values at any
# time, so that after a "is" is added to "c", pitchmap["a"] = "cis"

import re 
import math
import vim

loaded = vim.eval("g:loaded_Lyqi")
if loaded == 0.1:
    initialize()

def initialize():
    global pitches, pitch_keys, pitchmap
    pitches = ( "c", "d", "e", "f", "g", "a", "b", "s", "r", "R" )
    pitch_keys = ( "a", "s", "d", "f", "w", "e", "r", "q", "g", "G" ) 
    pitchmap = dict(zip(pitch_keys, pitches))
    vim.command("let g:loaded_Lyqi = 0")
    return pitchmap


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

current = {
        "pitch": "c", 
        "acc": "", 
        "caut": "",
        "oct": "",
        "dur": "", 
        "dot": "" ,
        "art": "",
        "add": ""
        }
new_note = ""
vim_note = ""

# RE for parsing an input string representing a note name. The RE-string
# matches everything from "a" to "ases!,,\maxima...^\f", and also takes
# care of the syntactic inconsistency which allows both "es/as" and
# "ees/aes". 

notestring = r"""^(?P<pitch>[a-grsR])
(?P<acc>(((ses)|(s))|((es){1,2})|((is){1,2}))?)
(?P<caut>[?!]*)
(?P<oct>[,']*)
(?P<dur>((16)|1|2|4|8|(32)|(64)|(\\breve)|(\\longa)|(\\maxima))?)
(?P<dot>[.]*)
(?P<art>([-_^\\].*)*)
(?P<add>.*)$"""


#======================================================================
                                #Functions {{{1
#======================================================================
                              #vim interaction {{{2
#======================================================================
def get_vim_key():
    input_key = vim.eval("b:input_key")
    return input_key
#======================================================================
def process_key(key):

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
        vim.command("normal a" + key)

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
# - forandre current['pitch'] 
# - avspille en lyd i overensstemmelse med cur_note['pitch'] og [oct]

def pitch(input_key):
    current['pitch'] = pitchmap[input_key]
    n = current['pitch']
    vim.command("normal a" + n + " ")

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
                             # make_note {{{2
#======================================================================
def make_note():
    # bruker bare current, så ingen args er nødvendige
    new_note = ""
    for i in valid_note:
        new_note += current[i]
    return new_note

#======================================================================
                       # cautionary accidentals {{{2
#======================================================================
def caut(input_key):
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    current['caut'] = cautmap[input_key]
    vim.command("normal a" + make_note())

#======================================================================
                            # octave signs {{{2
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
#if input = dot og dur ikke er definert:
#    #scan tilbake etter siste dur
#    TODO: make function for backwards scanning after rhythm value.
#    In the meantime, a default value of 4 will have to do.
#    dur = siste_dur
def dot():
    vim.command("call Get_current_note()")
    note = vim.eval("b:notestring")
    parse(note)
    if not current['dur']:
        current['dur'] = '4'
    current['dot'] += '.'
    vim.command("normal a" + make_note())


#def find_prev_dur():
#    dur_search = []
#    for i in durs:
#        dur_search[i] = '\\(' + durs[i] + '\\)'
#    dur_str = '\\|'.join(dur_search)
#    dur_match = vim.command("call search("+search_str+", 'bcpn')")
#    current['dur'] = durs[dur_match-1]


# %======================================================================
# Faste tegn
# %======================================================================
# slurs ~ settes inn direkte, med luft rundt
# rest/silent (oppfører seg som vanlige noter, bortsett fra at deres verdi
# ikke forandres).
# \ - settes inn direkte, og avviker midlertidig fra lyqi-mode, inntil ...
# hva? det trykkes \ igjen? Kanskje. Eller som i emacs: at det 
# 
#   funksjon for å forandre notetrinn
#   TODO- oppdaterer pitch
#       - fjerner [acc]-verdi (så "fes" og "fis" blir til "e"
#       - men endrer selvfølgelig ikke pitches

# add_markup [introduced by "\"; leaves lyqi-mode; return with <esc>]
#
# output
    
#%======================================================================
                               #change_degree {{{2
#======================================================================
# change_degree: trenger kanskje kommando for å forandre degree (ikke
# samme som aug)
#

#       - 
#

#

process_key(get_vim_key())

#======================================================================
                                  #Chords {{{1
#%======================================================================
# NB: unntak: chords, der [dur] står utenfor:
#
# < [pitch][oct][art] > [dur][dot]
#
# Chords er dessuten et spesialtilfelle som må tas hensyn til mht.
# forandring av rytmeverdi: prøver man å sette inn en 4 eller en .  etter
# en uavsluttet <, skal det gis feilmelding, og trykker man 4 mens man er
# innenfor en <>-blokk, skal det søkes framover, og ikke bakover. 
#
# 
# 
# TODO: hopper over midi-kommandoene enn så lenge


#%======================================================================
#Fra lyqi-tool (emacs) {{{2
#%======================================================================

#abspitch
#%======================================================================
#

#( let (( abspitch1 ( + ( * 7 ( lyqi-note-octave prevnote)) (lyqi-note-pitch prevnote)))
#abspitch1 = 
#finn forrige notes oktav, gange med 7 og legg til tallet for forrige note
#prevnote er en array som inneholderzc flere verdier: alle 
   #(abspitch2 (+ (* 7 (lyqi-note-octave note)) (lyqi-note-pitch note)))
   #)
   #(if (< (abs (- abspitch1 abspitch2)) 4) 
   ##"              ; same relative octave
#(if (> abspitch1 abspitch2)
#(make-string (+ (/ (- abspitch1 abspitch2 4) 7) 1)
             #(lyqi-get-translation 'octave-down))
#(make-string (+ (/ (- abspitch2 abspitch1 4) 7) 1)
             #(lyqi-get-translation 'octave-up)))))

#(type 'note "note, rest or skip")
#(pitch 0 "the actual note, from 0 (do) to 6 (si)")
#(accidental 2 "from 0 (##) to 4 (bb)")
#(octave 1 "octave 0 is starting with the do which
#is in the second interline in a fourth line F-clef") 
#(duration 3 "from 1 to 8, real-duration = 2^(duration - 1)")
#(dots 0 "number of dots, from 0 to 4")
#(force-duration nil "tells if duration must be written")
#(previous nil "The previous note"))


#%======================================================================
#Vim-options
#%======================================================================
#let g:lyqi_midi_command = "timidity -iA -B2,8 -0s -EFreverb=0"
#let g:lyqi_midi_kbd = "mymidikbd"
#let g:lyqi_use_midi = 1 #skal midi-processen starte automatisk?
# evt. intro for vim
#if &cp || exists("loaded_lyqi")
    #finish
#endif
#let loaded_lyqi = 1



#======================================================================
                #Flowchart {{{1
#======================================================================

#input fra vim:
#se lyqi.vim

#Tastetrykk. 
#    (1) oversett til notenavn
#    (2) hvilken gruppe tilhører det? Gå til tilsvarende funksjon

#    notenavn:
#        (3) finne posisjon (etter streng under eller  før cursor)
#        (4) oppdatere current med det nye notenavnet
#        (5) lage ny notestreng (som bare består av notenavn)
#        (6) innføre strengen i dok. på den funne posisjon
#        (7) spille lyd

#    rytme: (ex: "j")
#        (8) hente streng under eller før cursor
#        (9) parse streng
#        (4) oppdatere med ny verdi
#        (5) lage ny streng
#        (10) erstatte gammel med ny streng
#        (7) spille lyd
        
#    oktav, caut, dot:
#        som ovenfor

#    artikulasjon:
## to typer, som trigges av "\" og  
#        (11) 
        
# Programmet skal:
#
#
# 1. remappe tangentbordet, gjeldende for bufferen
# 
# 2. inneholde funksjoner for å modifisere foregående tekst, i følgende
# tilfeller ("tekst" i dette tilfelle betyr hele blokken, dvs. strengen før
# eller under cursor, omgitt enten av whitespace eller <>, og parset i
# forhold til en standardgruppe):
#   
# ny degree: tilføyer et nytt noteobjekt, og oppdaterer $current. Eneste
# grunn til å gjøre det, er for midi-ens del. En degree-inntastning skal
# aldri i seg selv føre til en mer omfattende streng, men det må hele
# tiden holdes styr på degree og oktav for sist innskrevne note.
#
# når en ny rytmeverdi skrives inn: da skal verdien føyes til foregående
# note, eller eksisterende verdi forandres, og $current oppdateres.
#
# punkteringer: ren strengemodifikator: punkt legges til eksplisitt
# rytmeverdi i strengen, hvis den eksisterer, eller forbindes med
# gjeldende rytmeverdi og føyes til etter pitch-gruppe. Trenger forsåvidt
# ikke lagres (vil man noen gang vite hvor mange punkteringer foregående= 
# note hadde? I think not), men det skader vel ikke...
#
# når et oktavtegn skrives inn: to ting skjer: strengen forandres på
# enkelt vis (', legges til degree), og $current oppdateres
#
# når en akksidental skrives inn: da skal det føyes is/es til foregående
# degree, og dens verdi skal lagres, dvs. keyboard-kommandoen skal
# forandres temporært. 
#
# Input-typer: degree_key, octave_key, rhythm_key, dot, change_aug, change_degree
# 
# Lagrede interne variabler:
#   curr_note
#   prev_note
#   default note constructions
#   curr_rhythm     | disse to er kanskje unødvendige; de er allerede del
#   curr_pitch      | av curr_note
#
#Modifikasjonen skjer "utenfor", dvs i en ekstern funksjon som sammenligner
#den parsede streng (curr_note) med en standard (note) og modifiserer i
#overensstemmelse med input. 
#
#   nødvendige funksjoner:
#       - parse input: strengen kan variere fra "a" til "ais'4...^.[{
#           den skal så deles opp og fylle en liste (degree, aug, oct, rhythm,
#           dot, articulation) for current_note
#       - oppgradere prev_values med den nye verdien
#       - forandre strengen etter sml mellom curr_note og prev_values
#       - føre strengen tilbake til tekstfilen (og avspille en note)
#   
#       - pitch_acc
#       - rhythm_dot
# vim: fdm=marker
