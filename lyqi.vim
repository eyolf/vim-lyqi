" lyqi.vim
" @Author:      <+NAME+> (mailto:<+EMAIL+>)
" @Website:     <+WWW+>
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     14-May-2008.
" @Last Change: 19-Mai-2005.
" @Revision:    0.0
" %======================================================================
" TODO: 
" sjekke hva lyqi-tool gjør, og tilsv. for lilypond-tool
if &cp || exists("loaded_lyqi")
    finish
endif
let loaded_lyqi = 1


"
" %======================================================================
" LYQI-tool:
" %======================================================================
" konstanter:
"   languages
"   self-inserting-keys
"   self-ins.-char-keys
"            -string-keys
"   div. systemkonstanter
"   
" Interaktive funksjoner
"   generell funksjon for input av tastetrykk
"   spesifikke funksjoner for hver enkelt note, pause, change-dur,
"   change-alteration, oktav, cautionary, reminder
"                   må kunne rasjonaliseres...
"   
"
"   
"
"
" få fullstendig klarhet i syntaksen for noteuttrykk, som vel ser ut sånn:
"
" :
"
" [pitch][acc][oct][dur][dot][art]
"%======================================================================
"%======================================================================
"

"variabler, lånt fra lyqi
"script-variabler
let s:pitches = [ "c", "d", "e", "f", "g", "a", "b"]
let s:pitch_keys = [ "a", "s", "d", "f", "w", "e", "r", "g" ] 
let s:accs = [ "eses", "es", "", "is", "isis" ]
let s:rest = "r"
let s:skip = "s"
let s:oct_up = "'"
let s:oct_down = ","
let s:self_insert = "()<>{}[]|!?R "
"globale
let g:lyqi_rel_oct = 1 "brukes rel oct som default?
let g:lyqi_force_dur = 0 "skal tonelengde skrives inn alltid?
let g:lyqi_midi_command = "timidity -iA -B2,8 -0s -EFreverb=0"
let g:lyqi_midi_kbd = "mymidikbd"
let g:lyqi_use_midi = 1 "skal midi-processen starte automatisk?

"
" Programmet skal:
"
"
" 1. remappe tangentbordet, gjeldende for bufferen
" 
" 2. inneholde funksjoner for å modifisere foregående tekst, i følgende
" tilfeller ("tekst" i dette tilfelle betyr hele blokken, dvs. strengen før
" eller under cursor, omgitt enten av whitespace eller <>, og parset i
" forhold til en standardgruppe):
"   
"   ny degree: tilføyer et nytt noteobjekt, og oppdaterer $current. Eneste
"   grunn til å gjøre det, er for midi-ens del. En degree-inntastning skal
"   aldri i seg selv føre til en mer omfattende streng, men det må hele
"   tiden holdes styr på degree og oktav for sist innskrevne note.
"
"   når en ny rytmeverdi skrives inn: da skal verdien føyes til foregående
"   note, eller eksisterende verdi forandres, og $current oppdateres.
"
"   punkteringer: ren strengemodifikator: punkt legges til eksplisitt
"   rytmeverdi i strengen, hvis den eksisterer, eller forbindes med
"   gjeldende rytmeverdi og føyes til etter pitch-gruppe. Trenger forsåvidt
"   ikke lagres (vil man noen gang vite hvor mange punkteringer foregående
"   note hadde? I think not), men det skader vel ikke...
"
"   når et oktavtegn skrives inn: to ting skjer: strengen forandres på
"   enkelt vis (', legges til degree), og $current oppdateres
"
"   når en akksidental skrives inn: da skal det føyes is/es til foregående
"   degree, og dens verdi skal lagres, dvs. keyboard-kommandoen skal
"   forandres temporært. 
"
"   change_degree: trenger kanskje kommando for å forandre degree (ikke
"   samme som aug)
"
" Input-typer: degree_key, octave_key, rhythm_key, dot, change_aug, change_degree
" 
" Lagrede interne variabler:
"   curr_note
"   prev_note
"   default note constructions
"   curr_rhythm     | disse to er kanskje unødvendige; de er allerede del
"   curr_pitch      | av curr_note
"
"Modifikasjonen skjer "utenfor", dvs i en ekstern funksjon som sammenligner
"den parsede streng (curr_note) med en standard (note) og modifiserer i
"overensstemmelse med input. 
"
"   nødvendige funksjoner:
"		- hente input: søke tilbake i filen etter foregående korrekte
	"		notestreng (altså ikke tekststrenger, men akkorder må kunne
"			telles, i hvert fall for rytmens del), og hente en streng
"		- parse input: strengen kan variere fra "a" til "ais'4...^.[{
"			den skal så deles opp og fylle en liste (degree, aug, oct, rhythm,
"			dot, articulation) for current_note
"		- oppgradere prev_values med den nye verdien
"		- forandre strengen etter sml mellom curr_note og prev_values
"		- føre strengen tilbake til tekstfilen (og avspille en note)
"   
"       - pitch_acc
"       - rhythm_dot
"       - 
"
"%======================================================================
                             " strenge-parser
" %======================================================================
" 1. isoler strengen:
"   - enn så lenge begrenset til vanlige strenger, ikke akkorder.
"   - finn strengen fra forrige whitespace (eller <) før tegn og frem til cursor;
"   strip trailing spaces.
" 2. parse
"
function Lyqi_parser()
    normal B"pyiWel
    let g:curr_pitch_string= @p
    " grabs the previous whitespace-enclosed string
    " and leaves the cursor right after the string
    let i=strlen(g:curr_pitch_string)
    " decides the length of the string; could be useful...
    letter = substr(0,1)
    if letter == [a-g]
        curr_pitch['pitch'] = pitch_to_num(letter)
        "transl. to number, abspitch
    else 
        "innsett cursor i edit-mode på begynnelseschar. 
    endif
    for (i=1; i<=strlen(curr_note_str); i++)
        if curr_note_str[i] == [ie]\=s " ingen eller en ie + s
            curr_pitch['acc'] = acc_to_num(letter)
        elseif 
        endif

        if 

"3. check om strengen er korrekt: 
"
"   - må begynne med [a-g] -> curr_note['pitch']
"   - deretter: søk: 
"  curr_note =
"       pitch   (0-6, tilsv. c-b; default: 0), 
"       acc     (0-4, tilsv. bb til ##; default: 2
"       oct     (0 = lille c)
"       dur     (0=ĺonga, 1=brevis, 2=1, 3=2, 4=4 etc; real_dur = 2^(dur-2)
"       dot     (0-4; number of dots)
"       prev -- skal prev være med i definisjonen av en note? som en string
"       eller som en parset array?
"
" altså: 
" if curr_note_string =~
" [a-g]([ei]{0,1}s){0,1}[',]{0,1}([1248]|16|32|64|\\breve|\\longa){0,1}[.]*([_^\\].*)*
" " så utføres den valgte handling, 
" else 
" " gå tilbake til strengen i teksten for redigering.
" endif
"





"
" %======================================================================
" tonehøyde:
" %======================================================================
" 3. Ideelt sett skal hvert tangenttrykk  på notehøydetastene være et funksjonskall, som utfører
" følgende handlinger:
"   - innføye notetegn, pluss mellomslag 
"   - avspille en lyd, som ikke avhenger av tangenten som trykkes ned, men
"   av den variableen som aktiveres ved trykket: a aktiverer c/cis/ces,
"   hvis verdi dels skrives ut, dels spilles
"   - men de tastene skal ikke gjøre noe annet, vel?
"   - jo: hvert tastetrykk skal lagres i cur_pitch, for senere
"   sammenligninger
"   - men egentlig må sammenligningen gjøres med en søkfunksjon med
"   notetegnet før, ellers kan man ikke gå tilbake og endre tonehøyde for
"   en tidligere note (hvis cur_pitch = a, vil den jo forandre en
"   tidligere f til ais).
"   Så det er altså ingen grunn til å lagre cur_pitch; den brukes ikke til
"   noe. I stedet er det hele gamut som skal lagres,  så a=a inntil man
"   trykker # ved en a, da a=ais. Dette MÅ altså gjøres med søk og ikke med
"   lagret variabel, ellers går det galt... 
"   - spm: skal også noteverdien lagres for hver ny note? nei, hvordan
"   skulle det gå til..? 
"
" %======================================================================
" 4. rytmetastene skal:
" %======================================================================
"   - ikke spille noen lyd
"   - føye en rytmeverdi til foregående note
"   - forandre cur_dur
"
" %======================================================================
" 5. #/b-tastene skal:
" %======================================================================
"   - avspille lyd,
"   - forandre verdien for pitch-variabelen for noten foran (a=ais)
"   - applisere forandringen på noten foran
"
" %======================================================================
" dot:
" %======================================================================
" tricky. Hva gjør en dot egentlig? Den forandrer selvfølgelig noten foran,
" men vel ikke grunnverdien? På den annen side: spiller det noen rolle?
" Det blir et spørsmål om hva som skal skrives ut: hvis jeg går tilbake og
" legger til en . til en tidligere note, så må den jo vite hva som er
" gjeldende verdi, så . må søke tilbake til forrige lovlige noteverdi,
" legge til den pluss .
" Dot er med andre  ord en søkefunksjon. Den må dessuten søke etter
" tidligere dot-er, men bare i kombinasjon med dur. Så i følgende serie:
"
"    c d4 e4. f8 g4 a g f
"                     ^
" vil et trykk på . ved g søke tilbake etter første forekomst av [1248]\|\(16\)\|\(32\)
" spare den i en variabel (cur_dur? ja hvorfor ikke?), og sette den inn ved
" noten foran etter evt. oktavtegn ([a-g][',]*), så det blir
"
"                      v
"    c d4 e4. f8 g4 a g4. f
"
" men hva med en serie av punkterte noter:
"
"    c4. d e f g a b c
"                ^
" der vil et trykk på . ved a søke tilbake til 4, men at det for
" anledningen allerede er en . der, spiller ingen rolle; den skal likevel
" sette inn 4. ved a (som jo uansett er en redundans, men ok, det kan være
" en fordel, og det gjør ingen skade.)
"
" SPØRSMÅL:
" Skal disse funksjonene sette inn tekst direkte, eller hente inn gjeldene
" noteuttrykk, parse det, og så sette inn resultatet igjen? Det siste er
" vel det beste, i forbindelse med komplekse uttrykk med både pitch, dur,
" dot, og articulations? 
" og akkorder -- det avgjør saken. 
"
" %======================================================================
" Faste tegn
" %======================================================================
" slurs ~ settes inn direkte, med luft rundt
" rest/silent (oppfører seg som vanlige noter, bortsett fra at deres verdi
" ikke forandres).
" \ - settes inn direkte, og avviker midlertidig fra lyqi-mode, inntil ...
" hva? det trykkes \ igjen? Kanskje. Eller som i emacs: at det 
" 
"
"%======================================================================
                                  "Chords
"%======================================================================
" NB: unntak: chords, der [dur] står utenfor:
"
" < [pitch][oct][art] > [dur][dot]
"
" Chords er dessuten et spesialtilfelle som må tas hensyn til mht.
" forandring av rytmeverdi: prøver man å sette inn en 4 eller en .  etter
" en uavsluttet <, skal det gis feilmelding, og trykker man 4 mens man er
" innenfor en <>-blokk, skal det søkes framover, og ikke bakover. 
"
" 
" 
" hopper over midi-kommandoene enn så lenge

function print_note(pitch, acc, oct, dur, dot, prev)
    " defines note as the full LP note construction, e.g. ces'2..
    " depends on the previous note (for oct. placement), and on predefined
    " values for pitch/acc and dur/dot, fetched from other functions
    "
    let pitchacc="pitches[pitch].accs[acc]"
    "definer pitchacc
endfunction


    "abspitch
    "%======================================================================
    "

    ( let (( abspitch1 ( + ( * 7 ( lyqi-note-octave prevnote)) (lyqi-note-pitch prevnote)))
    abspitch1 = 
    finn forrige notes oktav, gange med 7 og legg til tallet for forrige note
    prevnote er en array som inneholder flere verdier: alle 
           (abspitch2 (+ (* 7 (lyqi-note-octave note)) (lyqi-note-pitch note)))
           )
           (if (< (abs (- abspitch1 abspitch2)) 4) 
           ""				; same relative octave
      (if (> abspitch1 abspitch2)
        (make-string (+ (/ (- abspitch1 abspitch2 4) 7) 1)
                     (lyqi-get-translation 'octave-down))
        (make-string (+ (/ (- abspitch2 abspitch1 4) 7) 1)
                     (lyqi-get-translation 'octave-up)))))

endfunction

  "(type 'note "note, rest or skip")
  "(pitch 0 "the actual note, from 0 (do) to 6 (si)")
  "(accidental 2 "from 0 (##) to 4 (bb)")
  "(octave 1 "octave 0 is starting with the do which
  "is in the second interline in a fourth line F-clef") 
  "(duration 3 "from 1 to 8, real-duration = 2^(duration - 1)")
  "(dots 0 "number of dots, from 0 to 4")
  "(force-duration nil "tells if duration must be written")
  "(previous nil "The previous note"))


"function store rhytm:
"når en rytmeverdi er satt, skal den lagres i en variabel
let dur = "4"
"og når en ny verdi skrives inn, skal den forandres tilsvarende, og
"føyes til gjeldende note:
if new_dur <> dur
    call change_dur(new_dur)


"
 "change  rhythm:
" 
function change_dur(new_dur)
    let dur = new_dur
endfunction
