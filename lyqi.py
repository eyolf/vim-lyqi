# coding: utf-8

#======================================================================
                #Flowchart
#======================================================================

#Tastetrykk. 
	#oversett til notenavn
	#hvilken gruppe tilhører det? Gå til tilsvarende funksjon

	#add?						change?

#def translate_input_key(key):
##lookup in maps and decide pos
## join pos and val in a tuplet 
	#val = keymap[key]
	#new_val = (key, val)

#def input(key)
    #case key <hvor er den i maps?>:
       #pitch   -> add_note(key)
       #dur     -> change_dur(key)
       #oct     -> change_oct()
       #etc.

#def change_dur(new_val):
    #parse_note(input_string) -> 
    #update_current(new_val)
    #generate_new_note_string(current, new_val)
    #return new_note

#def parse_note(input_string):
    ## RE-mapping, skal gi en dict(current_note) med riktige verdier for alle poster.
    #return current
    
#def update_current(pos, val):
    #current[pos] = val
    #return current
    
#def generate_new_note_string():
    ## bruker bare current, så ingen args er nødvendige
	#new_note = ""
	#for i in valid_note:
		#new_note += current[i]
	#return new_note

    
    
        
        
    


    

#======================================================================
							  #initial values
#======================================================================

import re
#import vim
  
# pitches (rhythms, ...)  contains the pitch names used in the file, plus
# "s" and "r"
# pitch_keys is a (user-defined) variable list of keyboard keys to go with
# the various pitch names
pitch_keys = ( "a", "s", "d", "f", "w", "e", "r", "q", "g" ) 
pitches = ( "c", "d", "e", "f", "g", "a", "b", "s", "r" )

rhythm_keys = ( "P", "O", "p", "o", "l", "k", "j", "h", "b", "L", "M" )
rhythms = ( "128", "64", "32", "16", "8", "4", "2", "1", "\\brevis", "\\longa", "\\maxima" )

acc_keys = ( "c", "v" )
accs = ( "eses", "es", "", "is", "isis" )

oct_keys = ( "u", "i" )
octs = ( ",", "'" )

valid_note = ("pitch", "acc", "caut", "oct", "dur", "dot", "art")

# pitchmap gives the current translation between keyb. input and output to
# document: pitchmap["a"] = "c".
# The dictionary is initialized with default values, but  will be changed
# along the way, to store the current values at any time, so that after a
# "is" is added to "c", pitchmap["a"] = "cis"
#
# TODO: er dette en god løsning; å la pitchmap være den foranderlige?
# Ja, fordi man da kan ha user-defined standardverdier.
pitchmap = dict(zip(pitch_keys, pitches))
rhythmap = dict(zip(rhythm_keys, rhythms))
accmap = dict(zip(acc_keys, accs))
octmap = dict(zip(oct_keys, octs))

To alternativer: map = {"pitches": pitchmap,  "rhythms": rhythmap,  etc. }
så blir map["pitches"]["a"] == "c"
map = ( pitchmap, rhythmap, accmap, octmap )

current = { "pitch": "c", "oct": 0, "acc": 0, "dur": 4, "dot": 0 }

# self-insert er vel enklest ordnet ved at lyqi-vim er i insert-mode med
# remapping av de fleste men ikke alle taster; ()[] blir dermed automatisk



#======================================================================
								#Functions
#======================================================================

#======================================================================
								   #Input
#======================================================================
# - hente input: isoler strengen:søke tilbake i filen etter
#   foregående korrekte notestreng (altså ikke tekststrenger, men akkorder
#   må kunne telles, i hvert fall for rytmens del), og hente en streng
#   -  kanskje  enkleste å gjøre internt i vim
#
# - finn strengen fra forrige whitespace (eller <) før tegn og frem til
#   cursor; strip trailing spaces.
#
# - enn så lenge begrenset til vanlige strenger, ikke akkorder. 
#
#
#  Bør også definere noen generelle funksjoner for interaksjon med vim:
#  get_pos() -- for å kunne vende tilbake til samme pos etter endringer
#  set_map() -- generere en map-streng ut fra pitchmap/rhythmap etc, for å
#               sette buffer-lokale mapper.
#  




#======================================================================
                             # strenge-parser
#======================================================================
# RE for parsing an input string representing a note name. The RE-string
# matches everything from "a" to "ases!,,\maxima...^\f", and also takes
# care of the syntactic inconsistency which allows both "es/as" and
# "ees/aes". Should this  
notestring = r"""
^(?P<pitchacc>
	(
		(?P<pitch>[a-g])
		(?P<acc>((es){1,2})|((is){1,2}))?
	)|(
		(as)|(ases)|(es)|(eses)
	)
)
(?P<caut>[?!]*)
(?P<oct>[,']*)
(?P<dur>(1|2|4|8|(16)|(32)|(64)|(\\breve)|(\\longa)|(\\maxima)))*
(?P<dot>[.]*)
(?P<art>([-_^\\].*)*)
$
"""

compiled_obj = re.compile(notestring,  re.VERBOSE)
match_obj = compiled_obj.search










#======================================================================
								 #add_note
#======================================================================
# Den eneste som ikke forandrer en eksisterende streng men setter inn en ny
# utover det gjør den ikke annet enn å spille en note og forandre defaults.
#
# - innføye notetegn, pluss mellomslag 
#	 - dvs det trengs en funksjon for å "gobble" whitespace
#	 - hvis cursor er på en streng, skal noten innsettes ETTER strengen,{[]
# - forandre current_note['pitch']
# - avspille en lyd i overensstemmelse med cur_note['pitch'] og [oct]

def add_note(input_key):
	n = current['pitch'] = pitchmap[input_key]
	print_note(n)



#======================================================================
							   #print_note()
#======================================================================
#def print_note(pitch):
	#vim.command("normal BEa"+pitch)


#======================================================================
							   #change_pitch
#======================================================================


#======================================================================
								#change_dur
#======================================================================
#   - forandre cur_dur
#   - føye en rytmeverdi til foregående note
#   - ikke spille noen lyd
#
#======================================================================
								#change_acc
#======================================================================
# #/b-tastene skal:
# - avspille lyd,
# - forandre verdien for pitch-variabelen for noten foran (a=ais)
# - applisere forandringen på noten foran
#
#======================================================================
								 #add_dot
#======================================================================
# tricky. Hva gjør en dot egentlig? Den forandrer selvfølgelig noten foran,
# men vel ikke grunnverdien? På den annen side: spiller det noen rolle?
# Det blir et spørsmål om hva som skal skrives ut: hvis jeg går tilbake og
# legger til en . til en tidligere note, så må den jo vite hva som er
# gjeldende verdi, så . må søke tilbake til forrige lovlige noteverdi,
# legge til den pluss .
# Dot er med andre  ord en søkefunksjon. Den må dessuten søke etter
# tidligere dot-er, men bare i kombinasjon med dur. Så i følgende serie:
#
#    c d4 e4. f8 g4 a g f
#                     ^
# vil et trykk på . ved g søke tilbake etter første forekomst av [1248]\|\(16\)\|\(32\)
# spare den i en variabel (cur_dur? ja hvorfor ikke?), og sette den inn ved
# noten foran etter evt. oktavtegn ([a-g][',]*), så det blir
#
#                      v
#    c d4 e4. f8 g4 a g4. f
#
# men hva med en serie av punkterte noter:
#
#    c4. d e f g a b c
#                ^
# der vil et trykk på . ved a søke tilbake til 4, men at det for
# anledningen allerede er en . der, spiller ingen rolle; den skal likevel
# sette inn 4. ved a (som jo uansett er en redundans, men ok, det kan være
# en fordel, og det gjør ingen skade.)
#
# SPØRSMÅL:
# Skal disse funksjonene sette inn tekst direkte, eller hente inn gjeldene
# noteuttrykk, parse det, og så sette inn resultatet igjen? Det siste er
# vel det beste, i forbindelse med komplekse uttrykk med både pitch, dur,
# dot, og articulations? 
# og akkorder -- det avgjør saken. 
#
# %======================================================================
# Faste tegn
# %======================================================================
# slurs ~ settes inn direkte, med luft rundt
# rest/silent (oppfører seg som vanlige noter, bortsett fra at deres verdi
# ikke forandres).
# \ - settes inn direkte, og avviker midlertidig fra lyqi-mode, inntil ...
# hva? det trykkes \ igjen? Kanskje. Eller som i emacs: at det 
# 
#	funksjon for å forandre notetrinn
#	TODO- oppdaterer pitch
#		- fjerner [acc]-verdi (så "fes" og "fis" blir til "e"
#		- men endrer selvfølgelig ikke pitches

# add_markup [introduced by "\"; leaves lyqi-mode; return with <esc>]
#
# output
	
#======================================================================
								  #Input

#
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
# change_degree: trenger kanskje kommando for å forandre degree (ikke
# samme som aug)
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
#		- parse input: strengen kan variere fra "a" til "ais'4...^.[{
#			den skal så deles opp og fylle en liste (degree, aug, oct, rhythm,
#			dot, articulation) for current_note
#		- oppgradere prev_values med den nye verdien
#		- forandre strengen etter sml mellom curr_note og prev_values
#		- føre strengen tilbake til tekstfilen (og avspille en note)
#   
#       - pitch_acc
#       - rhythm_dot
#       - 
#

#
#%======================================================================
                                  #Chords
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
#Fra lyqi-tool (emacs)
#%======================================================================

#abspitch
#%======================================================================
#

#( let (( abspitch1 ( + ( * 7 ( lyqi-note-octave prevnote)) (lyqi-note-pitch prevnote)))
#abspitch1 = 
#finn forrige notes oktav, gange med 7 og legg til tallet for forrige note
#prevnote er en array som inneholder flere verdier: alle 
   #(abspitch2 (+ (* 7 (lyqi-note-octave note)) (lyqi-note-pitch note)))
   #)
   #(if (< (abs (- abspitch1 abspitch2)) 4) 
   ##"				; same relative octave
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
