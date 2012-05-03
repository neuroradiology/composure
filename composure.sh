#!/bin/bash
# Composure - don't fear the UNIX chainsaw...
#             these light-hearted shell functions make programming the shell
#             easier and more intuitive
# by erichs, 2012

# latest source available at http://git.io/composure

# define default metadata keywords:
about ()   { :; }
group ()   { :; }
param ()   { :; }
author ()  { :; }
example () { :; }

cite ()
{
    about creates a new meta keyword for use in your functions
    param 1: keyword
    example $ cite url
    example $ url http://somewhere.com
    group composure

    typeset keyword=$1
    for keyword in $*; do
        eval "function $keyword { :; }"
    done
}


draft ()
{
    about wraps last command into a new function
    param 1: name to give function
    example $ ls
    example $ draft list
    example $ list
    group composure

    typeset func=$1
    eval 'function ' $func ' { ' $(fc -ln -1) '; }'
    typeset file=$(mktemp /tmp/draft.XXXX)
    typeset -f $func > $file
    transcribe $func $file draft
    rm $file 2>/dev/null
}

glossary ()
{
    about displays help summary for all functions, or summary for a group of functions
    param 1: optional, group name
    example $ glossary
    example $ glossary misc
    group composure

    typeset targetgroup=${1:-}

    for func in $(listfunctions); do
        typeset about="$(metafor $func about)"
        if [ -n "$targetgroup" ]; then
            typeset group="$(metafor $func group)"
            if [ "$group" != "$targetgroup" ]; then
                continue  # skip non-matching groups, if specified
            fi
        fi
        letterpress "$about" $func
    done
}

letterpress ()
{
    typeset metadata=$1 leftcol=${2:- } rightcol

    if [ -z "$metadata" ]; then
        return
    fi

    OLD=$IFS; IFS=$'\n'
    for rightcol in $metadata; do
        printf "%-20s%s\n" $leftcol $rightcol
    done
    IFS=$OLD
}

listfunctions ()
{

    typeset x ans
    typeset this=$(for x in $(ps -p $$); do ans=$x; done; echo $ans | sed 's/^-*//')
    case "$this" in
        bash)
            typeset -F | awk '{print $3}'
            ;;
        *)
            typeset +f | sed 's/()$//'
            ;;
    esac
}

metafor ()
{
    about prints function metadata associated with keyword
    param 1: function name
    param 2: meta keyword
    example $ metafor glossary example
    group composure
    typeset func=$1 keyword=$2
    typeset -f $func | sed -n "s/;$//;s/^[ 	]*$keyword \([^([].*\)*$/\1/p"
}

revise ()
{
    about loads function into editor for revision
    param 1: name of function
    example $ revise myfunction
    group composure

    typeset func=$1
    typeset temp=$(mktemp /tmp/revise.XXXX)

    # populate tempfile...
    if [ -f ~/.composure/$func.sh ]; then
        # ...with contents of latest git revision...
        cat ~/.composure/$func.sh >> $temp
    else
        # ...or from ENV if not previously versioned
        typeset -f $func >> $temp
    fi

    if [ -z "$EDITOR" ]
    then
      typeset EDITOR=vi
    fi

    $EDITOR $temp
    source $temp

    transcribe $func $temp revise
    rm $temp
}

reference ()
{
    about displays apidoc help for a specific function
    param 1: function name
    example $ reference revise
    group composure

    typeset func=$1

    typeset about="$(metafor $func about)"
    letterpress "$about" $func

    typeset params="$(metafor $func param)"
    if [ -n "$params" ]; then
        echo "parameters:"
        letterpress "$params"
    fi

    typeset examples="$(metafor $func example)"
    if [ -n "$examples" ]; then
        echo "examples:"
        letterpress "$examples"
    fi
}

transcribe ()
{
    about store function in ~/.composure git repository
    param 1: function name
    param 2: file containing function
    param 3: operation label
    example $ transcribe myfunc /tmp/myfunc.sh 'scooby-doo version'
    example stores your function changes with:
    example master 7a7e524 scooby-doo version myfunc
    group composure

    typeset func=$1
    typeset file=$2
    typeset operation="$3"

    if git --version >/dev/null 2>&1; then
        if [ -d ~/.composure ]; then
            (
                cd ~/.composure
                if git rev-parse 2>/dev/null; then
                    if [ ! -f $file ]; then
                        echo "Oops! Couldn't find $file to version it for you..."
                        return
                    fi
                    cp $file ~/.composure/$func.sh
                    git add --all .
                    git commit -m "$operation $func"
                fi
            )
        fi
    fi
}

: <<EOF
License: The MIT License

Copyright © 2012 Erich Smith

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
EOF
