USING: accessors assocs command-line io io.encodings.binary
io.files io.streams.string kernel math multiline namespaces
peg.ebnf prettyprint sequences ;

IN: 5050brainf

<PRIVATE

TUPLE: 5050brainf pointer memory ;

: <5050brainf> ( -- 5050brainf )
    0 H{ } clone 5050brainf boa ;

: get-memory ( 5050brainf -- 5050brainf value )
    dup [ pointer>> ] [ memory>> ] bi at 0 or ;

: set-memory ( 5050brainf value -- 5050brainf )
    over [ pointer>> ] [ memory>> ] bi set-at ;

: (+) ( 5050brainf n -- 5050brainf )
    [ get-memory ] dip + 255 bitand set-memory ;

: (-) ( 5050brainf n -- 5050brainf )
    [ get-memory ] dip - 255 bitand set-memory ;

: (.) ( 5050brainf -- 5050brainf )
    get-memory write1 ;

: (,) ( 5050brainf -- 5050brainf )
    read1 set-memory ;

: (>) ( 5050brainf n -- 5050brainf )
    '[ _ + ] change-pointer ;

: (<) ( 5050brainf n -- 5050brainf )
    '[ _ - ] change-pointer ;

: (#) ( 5050brainf -- 5050brainf )
    dup
    [ "ptr=" write pointer>> pprint ]
    [ ",mem=" write memory>> pprint nl ] bi ;

: compose-all ( seq -- quot )
    [ ] [ compose ] reduce ;

EBNF: parse-5050brainf [=[

inc-ptr  = (">")+  => [[ length '[ _ (>) ] ]]
dec-ptr  = ("<")+  => [[ length '[ _ (<) ] ]]
inc-mem  = ("+")+  => [[ length '[ _ (+) ] ]]
dec-mem  = ("-")+  => [[ length '[ _ (-) ] ]]
output   = "."  => [[ [ (.) ] ]]
input    = ","  => [[ [ (,) ] ]]
debug    = "#"  => [[ [ (#) ] ]]
space    = [ \t\n\r]+ => [[ [ ] ]]
unknown  = (.)  => [[ "Invalid input" throw ]]

ops   = inc-ptr|dec-ptr|inc-mem|dec-mem|output|input|debug|space
loop  = "[" {loop|ops}+ "]" => [[ second compose-all '[ [ get-memory zero? ] _ until ] ]]

code  = (loop|ops|unknown)*  => [[ compose-all ]]

]=]

PRIVATE>

MACRO: run-5050brainf ( code -- quot )
    parse-5050brainf '[ <5050brainf> @ drop flush ] ;

: get-5050brainf ( code -- result )
    [ run-5050brainf ] with-string-writer ; inline

<PRIVATE

: (run-5050brainf) ( code -- )
    [ <5050brainf> ] dip parse-5050brainf call( x -- x ) drop flush ;

PRIVATE>

: 5050brainf-main ( -- )
    command-line get [
        read-contents (run-5050brainf)
    ] [
        [ binary file-contents (run-5050brainf) ] each
    ] if-empty ;

MAIN: 5050brainf-main