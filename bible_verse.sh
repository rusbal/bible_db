#!/bin/bash
# bible_verse.sh

APP_VERSION=1.1.2

##################
# Helper functions

display_appname ()
{
    tput setaf 7
    echo "bible_verse.sh"
}

display_about ()
{
    tput setaf 7
    echo
    echo "   This application uses Open Source software such as bash, Linux programs (read, sed, awk, tput), and MySQL database."
    echo "      Bible copyright is owned by the persons responsible for the production of such versions used on this software."
    echo "      Please respect the copyright of each Bible versions installed."
    echo "      This software is free to use subject to the copyright of Bible versions installed."
    echo
    echo "   Author: Raymond S. Usbal <raymond@philippinedev.com>"
    echo "   Date: 4 April 2012"
    echo "   Latest update: 11 April 2012"
    echo "   Version: $APP_VERSION"
}

display_short_help ()
{
    echo "   $(tput setaf 3)$(tput bold)q$(tput setaf 4) quit this application"
    echo "   $(tput setaf 3)$(tput bold)?$(tput setaf 4) display help information"
    echo
}

display_help ()
{
    ##########################
    # Display help information

    echo
    display_appname
    tput sgr0
    display_about

    echo
    echo "$(tput bold)$(tput setaf 1)Commands:"
    echo "   $(tput setaf 3)$(tput bold)ls$(tput setaf 4) list Bible versions installed"
    echo "   $(tput setaf 3)$(tput bold)sw {version}$(tput setaf 4) switch to another version"
    echo
    echo "   $(tput setaf 3)$(tput bold)bls$(tput setaf 4) list book abbreviations"
    echo "   $(tput setaf 3)$(tput bold){book abbrev} {chapter}[{:|SPACE}{verse}]$(tput setaf 4) enters the scripture view mode"
    echo "   $(tput setaf 4)   navigation: $(tput setaf 3)$(tput bold)> [n], < [n], SPACE, .$(tput setaf 4) display next [n], previous [n], or same chapter"
    echo "   $(tput setaf 4)   navigation: $(tput setaf 3)$(tput bold):{n}$(tput setaf 4) display particular verse, $(tput setaf 3)$(tput bold)a:{n}$(tput setaf 4) for all Bible versions installed"
    echo "   $(tput setaf 4)   exit mode: $(tput setaf 3)$(tput bold)clx$(tput setaf 4) exits scripture view mode"
    echo
    echo "   $(tput setaf 3)$(tput bold)hi [{highlight word}]$(tput setaf 4) set this word to be highlighted"
    echo "   $(tput setaf 3)$(tput bold)hilite$(tput setaf 4) shows the highlighted word"
    echo
    echo "   $(tput setaf 3)$(tput bold){search word}$(tput setaf 4) word to search in the entire Bible"
    echo
    echo "   $(tput setaf 3)$(tput bold)cls$(tput setaf 4) clear screen"
    
    display_short_help
}

set_version ()
{
    if [ "$SECOND_PARAM" = "" ]; then
        FRES=""
    else
        
        ###########################
        # Command: sw <kjv|niv|...>
        #  Version was set

        VERSION="${SECOND_PARAM}"

        if [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then
            FRES="_proceed_"
        else
            FRES=""
        fi
    fi
}

display_bible_versions ()
{
    SQL="SELECT short_name, name FROM versions"
    RES=$(echo "$SQL" | mysql -uroot -proot1 bible_db | grep -v short_name)

    ACTIVE="_no_"

    while read VER; do 
        if [[ $VER == $VERSION* ]]; then
            ACTIVE="_yes_"
            tput setaf 3;tput bold
            echo "  $VER"
        else
            tput sgr0
            echo "  $VER"
        fi
    done < <(echo "$RES")

    if [ "$ACTIVE" = "_no_" ]; then
        VERSION="KJV"
        echo "$(tput setaf 4)$(tput bold)No version is active!$(tput sgr0)$(tput setaf 4)  KJV activated."
    fi
}

display_book_abbreviation_list ()
{
    SQL="SELECT CONCAT(UPPER(SUBSTRING(testament, 1, 1)), 'T: ', GROUP_CONCAT(abbreviation ORDER BY id ASC SEPARATOR ', ')) FROM books GROUP BY testament"
    RES=$(echo "$SQL" | mysql -uroot -proot1 bible_db | grep -v abbreviation)

    while read LINE; do 
        LINE="$(echo "$LINE" | sed "s/^/$(tput setaf 3)$(tput bold)/g")"
        LINE="$(echo "$LINE" | sed "s/:/:$(tput sgr0)  /g")"
        LINE="$(echo "$LINE" | sed "s/,/$(tput setaf 3),$(tput sgr0)/g")"
        echo "  $LINE"
    done < <(echo "$RES")
}

display_scripture ()
{
    ########################
    # Display a book chapter

    if [[ "$VERSE_N" =~ ^[0-9]+$ ]]; then
        VERSE_COND=" AND t.verse = $VERSE_N"
    else
        VERSE_COND=""
    fi

    if [ "$ALL_VERSIONS" = "_true_" ]; then
        SQL="$SQL_SET_NAMES""SELECT CONCAT_WS(' ', RPAD(v.short_name, 4, ' '), b.abbreviation, CONCAT_WS(':', LPAD('"$CHAPTER_N"', 3, ' '), LPAD(t.verse, 2, ' '))), t.texts
            FROM books b 
            INNER JOIN texts t ON t.books_id = b.id AND t.chapter = "$CHAPTER_N"
            LEFT JOIN versions v ON v.id = t.versions_id
            WHERE b.abbreviation = '"$BOOK_ABBREV"'$VERSE_COND
            ORDER BY t.verse;"
    else
        SQL="$SQL_SET_NAMES""SELECT CONCAT_WS(' ', b.abbreviation, CONCAT_WS(':', LPAD('"$CHAPTER_N"', 3, ' '), LPAD(t.verse, 2, ' '))), t.texts
            FROM books b 
            INNER JOIN texts t ON t.books_id = b.id AND t.chapter = "$CHAPTER_N"
            INNER JOIN versions v ON v.id = t.versions_id AND v.short_name = '"$VERSION"'
            WHERE b.abbreviation = '"$BOOK_ABBREV"'$VERSE_COND
            ORDER BY t.verse;"
    fi

    RES=$(echo "$SQL" | mysql -uroot -proot1 bible_db | grep -v texts)

    if [ "$RES" = "" ]; then

        #####################
        # Scripture not found

        ABBREV=$(echo "SELECT id FROM books WHERE abbreviation = \"$BOOK_ABBREV\"" | mysql -uroot -proot1 bible_db | grep -v id)
        if [ "$ABBREV" = "" ]; then

            ##################################
            # Book abbreviation does not exist
            
            echo "$(tput setaf 1)$(tput bold)${BOOK_ABBREV^^}$(tput sgr0)$(tput setaf 1) is not recognized. Please use the recognized abbreviations as follows:"

            tput setaf 3; tput bold
            display_book_abbreviation_list
            tput sgr0

        else
            if [ "$FLOW" = "_next_verse_" -a "$RETURN" != "_yes_" ]; then

                ########################################
                # Let's try again searching next chapter

                let "CHAPTER_N=CHAPTER_N+1"
                VERSE_N="1"
                RETURN="_yes_"

                display_scripture

                return

            else
                echo "$(tput setaf 1)You have reached the end of $(tput bold)${BOOK_ABBREV^^}.$(tput sgr0)"
            fi
        fi

        ############################
        # End of Book, reset chapter
        CHAPTER_N=""

        return
    fi

    ##########################
    # Found, display scripture

    while read LINE; do 
        if [[ "$LINE" == *#* ]] || [[ "$LINE" == *\:\ 1* ]] || [ "$ALL_VERSIONS" = "_true_" ]; then

            ##########################
            # Beginning of a paragraph

            if [ "$VERSE_COND" = "" ]; then
                echo
            fi

            LINE="$(echo "$LINE" | sed "s/^/$(tput bold)$(tput setaf 4)/g")"
            # LINE="$(echo "$LINE" | sed "s/\t/$(tput sgr0)  /g")"
            LINE="$(echo "$LINE" | sed "s/#//")"

        else
            IDX="$(awk -v a="$LINE" -v b=":" 'BEGIN{print index(a,b)}')"
            LINE=${LINE:$IDX}

            LINE="$(echo "$LINE" | sed "s/^/$(tput setaf 4)/g")"
            # LINE="$(echo "$LINE" | sed "s/\t/$(tput sgr0)  /g")"
        fi

        echo "$LINE" | sed "s/\<"$HILITE_WORD"\>/$(tput setaf 3)$(tput bold)"$HILITE_WORD"$(tput sgr0)/g"
    done < <(echo "$RES")
}

search_the_bible ()
{
    ########################
    # Search the whole Bible

    if [ "$NEGATIVE_PARAM" = "" ]; then
        SQL_EXCLUDE=""
    else
        SQL_EXCLUDE="AND NOT t.texts LIKE '%"$NEGATIVE_PARAM"%'"
    fi

    if [ "$SQL" = "" ]; then
        SQL="$SQL_SET_NAMES""SELECT CONCAT_WS(' ', LPAD(b.abbreviation, 7, ' '), CONCAT_WS(':', LPAD(t.chapter, 2, ' '), LPAD(t.verse, 2, ' '))),t.texts 
            FROM texts t 
            INNER JOIN versions v ON v.id = t.versions_id AND v.short_name = '"$VERSION"'
            LEFT JOIN words_to_texts w2 ON w2.texts_id = t.id 
            LEFT JOIN words w ON w.id = w2.words_id 
            LEFT JOIN books b ON b.id = t.books_id 
            WHERE w.word =  \""$FIRST_PARAM"\" "$SQL_EXCLUDE"
            GROUP BY t.id
            ORDER BY b.id, t.chapter, t.verse;"
    fi

    if [ "$SECOND_PARAM" = "" ]; then
        RES=$(echo "$SQL" | mysql -uroot -proot1 bible_db | grep -v texts)
    else
        if [ "$THIRD_PARAM" = "" ]; then
            RES=$(echo "$SQL" | mysql -uroot -proot1 bible_db | grep "$SECOND_PARAM" | grep -v texts)
        else
            RES=$(echo "$SQL" | mysql -uroot -proot1 bible_db | grep "$SECOND_PARAM" | grep "$THIRD_PARAM" | grep -v texts)
        fi
    fi

    if [ "$RES" = "" ]; then

        if [ "$VERSION" = "KJV" ]; then
            echo "$(tput setaf 1)$(tput bold)No match$(tput sgr0)$(tput setaf 1), try to change case of words or use other word variations."
        else
            echo "$(tput setaf 1)$(tput bold)No match$(tput sgr0)$(tput setaf 1), try to change case of words or use other word variations or switch to another version."
            echo "$(tput setaf 4)$(tput bold)Search function works only on KJV.$(tput sgr0)$(tput setaf 4) Active version is $(tput bold)$VERSION."
        fi
    else
        echo "$(tput sgr0)$(tput bold)$(tput setaf 4)======= search results =======$(tput sgr0)"

        if [ "$HILITE_WORD" = "" ]; then
            REU=$RES
        else
            REU="$(echo "$RES" | sed "s/\<"$HILITE_WORD"\>/$(tput setaf 3)$(tput bold)"$HILITE_WORD"$(tput sgr0)/g")"
        fi

        REV="$(echo "$REU" | sed "s/\<"$FIRST_PARAM"\>/$(tput setaf 1)$(tput bold)"$FIRST_PARAM"$(tput sgr0)/g")"

        if [ "$SECOND_PARAM" = "" ]; then
            REY=$REV
        else
            if [ "$THIRD_PARAM" = "" ]; then
                REY="$(echo "$REV" | sed "s/"$SECOND_PARAM"/$(tput setaf 1)"$SECOND_PARAM"$(tput sgr0)/g")"
            else
                REW="$(echo "$REV" | sed "s/"$SECOND_PARAM"/$(tput setaf 1)"$SECOND_PARAM"$(tput sgr0)/g")"
                REY="$(echo "$REW" | sed "s/"$THIRD_PARAM"/$(tput sgr 0 1)$(tput setaf 1)"$THIRD_PARAM"$(tput sgr0)/g")"
            fi
        fi

        REZ="$(echo "$REY" | sed "s/^/$(tput setaf 4)/g")"
        # REQ="$(echo "$REZ" | sed "s/\t/$(tput sgr0)  /g")"
        OUT="$(echo "$REY" | sed "s/^$/d/")"

        echo "$OUT"
        MATCH="$(echo "$OUT" | wc -l)"
        echo "$(tput setaf 7)Matches: $(tput bold)"$MATCH
    fi
}

assign_parameters ()
{
    ARRAY=(${COMMAND//:/ })

    FIRST_PARAM="${ARRAY[0]}"
    SECOND_PARAM="${ARRAY[1]}"
    THIRD_PARAM="${ARRAY[2]}"
    FOURTH_PARAM="${ARRAY[3]}"

    if [[ $FIRST_PARAM == \<* ]] || [[ $FIRST_PARAM == \>* ]]; then
        FIRST_PARAM="${ARRAY[0]:0:1}"
        SECOND_PARAM="${ARRAY[0]:1}"
        THIRD_PARAM="${ARRAY[1]}"
        FOURTH_PARAM="${ARRAY[2]}"

    elif [[ "$FIRST_PARAM" =~ ^[0-9]+$ ]]; then
        FIRST_PARAM="$FIRST_PARAM $SECOND_PARAM"
        SECOND_PARAM="${ARRAY[2]}"
        THIRD_PARAM="${ARRAY[3]}"
        FOURTH_PARAM=""
    fi
}

assign_negative_param ()
{
    if [ "${SECOND_PARAM:0:1}" = "-" ]; then
        NEGATIVE_PARAM="${SECOND_PARAM:1}"
        SECOND_PARAM=""
        THIRD_PARAM=""
        FOURTH_PARAM=""

    elif [ "${THIRD_PARAM:0:1}" = "-" ]; then
        NEGATIVE_PARAM="${THIRD_PARAM:1}"
        THIRD_PARAM=""
        FOURTH_PARAM=""

    elif [ "${FOURTH_PARAM:0:1}" = "-" ]; then
        NEGATIVE_PARAM="${FOURTH_PARAM:1}"
        FOURTH_PARAM=""

    else
        NEGATIVE_PARAM=""
    fi
}

next_scripture ()
{
    if [[ "$SECOND_PARAM" =~ ^[0-9]+$ ]]; then
        ADJ="$SECOND_PARAM"
    else
        ADJ="1"
    fi

    if [ "$FLOW" = "_next_chapter_" ]; then
        let "CHAPTER_N=CHAPTER_N+$ADJ"
    elif [ "$FLOW" = "_next_verse_" ]; then
        let "VERSE_N=VERSE_N+$ADJ"
    fi
}
    
previous_scripture ()
{
    if [[ "$SECOND_PARAM" =~ ^[0-9]+$ ]]; then
        ADJ="$SECOND_PARAM"
    else
        ADJ="1"
    fi

    if [ "$FLOW" = "_next_chapter_" ]; then
        if [ "$ADJ" -ge "$CHAPTER_N" ]; then
            if [ "$CHAPTER_N" -eq "1" ]; then
                BROWSE_DIRECTION="_no_browse_"
            else
                CHAPTER_N="1"
            fi
        else
            let "CHAPTER_N=CHAPTER_N-$ADJ"
        fi

    elif [ "$FLOW" = "_next_verse_" ]; then
        if [ "$ADJ" -ge "$VERSE_N" ]; then
            if [ "$VERSE_N" -eq "1" ]; then
                BROWSE_DIRECTION="_no_browse_"
            else
                VERSE_N="1"
            fi
        else
            let "VERSE_N=VERSE_N-$ADJ"
        fi
    fi
}

#######
# Start

SQL_SET_NAMES="SET NAMES 'utf8';"

if [ "$1" = "" ]; then
    VERSION="KJV"
else
    VERSION="${1^^}"
fi

BROWSE_DIRECTION=">"

display_appname
echo "ver $APP_VERSION"
echo; display_bible_versions
echo; display_short_help

#########################
# Loop until user (q)uits

while :; do

    ############
    # Initialize
    SQL=""
    RES=""
    THIRD_PARAM=""
    NAVIGATE=""


    ###################
    # Here's our prompt

    tput sgr0
    read -p "$(tput bold)$(tput setaf 7)${VERSION}> $(tput sgr0)" COMMAND


    ###############
    # Prepare input

    assign_parameters
    assign_negative_param


    ###############
    # Process input

    if [ "$FIRST_PARAM" = "q" ]; then
        break

    elif [ "$FIRST_PARAM" = "cls" ]; then
        clear
        continue

    elif [ "$FIRST_PARAM" = "?" ]; then
        display_help
        continue

    elif [ "$FIRST_PARAM" = "sw" ]; then
        set_version

        if [ "$FRES" = "_proceed_" ]; then
            MODE="_scripture_"
            ALL_VERSIONS=""
        else
            continue
        fi

    elif [ "$FIRST_PARAM" = "ls" ]; then
        tput sgr0
        display_bible_versions
        continue

    elif [ "$FIRST_PARAM" = "bls" ]; then
        tput sgr0
        display_book_abbreviation_list
        continue

    elif [ "$FIRST_PARAM" = "hi" ]; then
        if [ "$SECOND_PARAM" = "" ]; then
            HILITE_WORD=""
        else
            HILITE_WORD="$SECOND_PARAM"
        fi
        
        continue

    elif [ "$FIRST_PARAM" = "hilite" ]; then
        if [ "$HILITE_WORD" != "" ]; then
            echo "$(tput setaf 3;tput bold)$HILITE_WORD"
        fi
        continue

    else

        ############
        # Navigation

        NAVIGATE="_true_"

        if [ "$FIRST_PARAM" = "" ] && [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then

            if [ "$BROWSE_DIRECTION" = ">" ]; then
                next_scripture

            elif [ "$BROWSE_DIRECTION" = "<" ]; then
                previous_scripture
                if [ "$BROWSE_DIRECTION" = "_no_browse_" ]; then
                    BROWSE_DIRECTION=">" # Reset to forward navigation
                    echo "$(tput setaf 1)Navigation forward"
                    continue
                fi
            fi

        elif [ "$FIRST_PARAM" = "" ]; then
            continue

        elif [ "$FIRST_PARAM" = ">" ] && [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then
            
            BROWSE_DIRECTION=">"
            next_scripture
            
        elif [ "$FIRST_PARAM" = "<" ] && [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then

            BROWSE_DIRECTION="<"
            previous_scripture
            if [ "$BROWSE_DIRECTION" = "_no_browse_" ]; then
                BROWSE_DIRECTION=">" # Reset to forward navigation
                echo "$(tput setaf 1)Already showing first verse"
                continue
            fi

        elif [ "$FIRST_PARAM" = "." ] && [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then

            : # Same scripture

        elif [ "$FIRST_PARAM" = "clx" ] && [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then

            ########################
            # Clear scripture memory

            BOOK_ABBREV=""
            CHAPTER_N=""
            VERSE_N=""
            FLOW=""
            HILITE_WORD=""
            continue

        elif [ "$FIRST_PARAM" = ">" -o "$FIRST_PARAM" = "<" -o "$FIRST_PARAM" = "."  -o "$FIRST_PARAM" = "clx" ]; then

            ###########################################
            # Not in scripture mode, cannot use command

            echo "$(tput setaf 1)$(tput bold)$FIRST_PARAM$(tput sgr0)$(tput setaf 1) is valid only in scripture view mode"
            continue
        fi
    fi


    if [ "$FIRST_PARAM" = "" -o "$FIRST_PARAM" = "." -o "$FIRST_PARAM" = "<" -o "$FIRST_PARAM" = ">" ]; then
        MODE="_scripture_"

    elif [ "$NAVIGATE" = "_true_" ]; then

        ARR2=(${COMMAND///})

        if [ "${ARR2[0]:0:2}" = "a:" ] && [[ ${ARR2[0]:2} =~ ^[0-9]+$ ]]; then
            ##################################################
            # View particular verse for all versions installed
            # (command) a:1 for verse 1

            if [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then
                MODE="_scripture_"
                VERSE_N="${ARR2[0]:2}"
                FLOW="_next_verse_"

                ALL_VERSIONS="_true_"
            else
                echo "$(tput setaf 1)Use $(tput bold)${ARR2[0]}$(tput sgr0)$(tput setaf 1) to view this verse for all available versions of the Bible but enter book and chapter first"
                continue
            fi

        else

            ALL_VERSIONS=""

            if [[ "$SECOND_PARAM" =~ ^[0-9]+$ ]]; then
                BOOK_ABBREV="$FIRST_PARAM"
                CHAPTER_N="$SECOND_PARAM"
                VERSE_N="$THIRD_PARAM"
                MODE="_scripture_"
            else
                MODE="_command_"
            fi

            FLOW=""

            if [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then
                FLOW="_next_chapter_"
            fi

            if [[ "$VERSE_N" =~ ^[0-9]+$ ]]; then
                FLOW="_next_verse_"
            fi


            ##########################
            # View particular verse
            # (command) :1 for verse 1

            if [ "${ARR2[0]:0:1}" = ":" ] && [[ ${ARR2[0]:1} =~ ^[0-9]+$ ]]; then
                if [[ "$CHAPTER_N" =~ ^[0-9]+$ ]]; then
                    MODE="_scripture_"
                    VERSE_N="${ARR2[0]:1}"
                    FLOW="_next_verse_"
                else
                    echo "$(tput setaf 1)Use $(tput bold)${ARR2[0]}$(tput sgr0)$(tput setaf 1) to view this verse but enter book and chapter first"
                    continue
                fi
            fi
        fi
    fi


    ###################
    # Output processing

    tput sgr0

    if [ "$MODE" = "_scripture_" ]; then
        display_scripture
    else
        search_the_bible
    fi

done

tput sgr0
# eof
