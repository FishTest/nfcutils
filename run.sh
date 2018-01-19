#!/bin/bash
menutitle="Data file selection"
startdir="./"
filext='mfd'
defaultdata="card.mfd"
function Filebrowser()
{
    if [ -z $2 ] ; then
        dir_list=$(ls -lhp  | awk -F ' ' ' { print $9 " " $5 } ')
    else
        cd "$2"
        dir_list=$(ls -lhp  | awk -F ' ' ' { print $9 " " $5 } ')
    fi

    curdir=$(pwd)
    if [ "$curdir" == "/" ] ; then  # Check if you are at root folder
        selection=$(whiptail --title "$1" \
                              --menu "PgUp/PgDn/Arrow Enter Selects File/Folder\nor Tab Key\n$curdir" 0 0 0 \
                              --cancel-button Cancel \
                              --ok-button Select $dir_list 3>&1 1>&2 2>&3)
    else   # Not Root Dir so show ../ BACK Selection in Menu
        selection=$(whiptail --title "$1" \
                              --menu "PgUp/PgDn/Arrow Enter Selects File/Folder\nor Tab Key\n$curdir" 0 0 0 \
                              --cancel-button Cancel \
                              --ok-button Select ../ BACK $dir_list 3>&1 1>&2 2>&3)
    fi

    RET=$?
    if [ $RET -eq 1 ]; then  # Check if User Selected Cancel
       return 1
    elif [ $RET -eq 0 ]; then
       if [[ -d "$selection" ]]; then  # Check if Directory Selected
          Filebrowser "$1" "$selection"
       elif [[ -f "$selection" ]]; then  # Check if File Selected
          if [[ $selection == *$filext ]]; then   # Check if selected File has .jpg extension
            if (whiptail --title "Confirm Selection" --yesno "DirPath : $curdir\nFileName: $selection" 0 0 \
                         --yes-button "Confirm" \
                         --no-button "Retry"); then
                filename="$selection"
                filepath="$curdir"    # Return full filepath  and filename as selection variables
            else
                Filebrowser "$1" "$curdir"
            fi
          else   # Not jpg so Inform User and restart
             whiptail --title "ERROR: File Must have .$filext Extension" \
                      --msgbox "$selection\nYou Must Select a .$filext File" 0 0
             Filebrowser "$1" "$curdir"
          fi
       else
          # Could not detect a file or folder so Try Again
          whiptail --title "ERROR: Selection Error" \
                   --msgbox "Error Changing to Path $selection" 0 0
          Filebrowser "$1" "$curdir"
       fi
    fi
}

function readcard(){
	DATANAME=$(whiptail --inputbox "What is your data file name?" 8 78 card.mfd --title "Data Filename Input" 3>&1 1>&2 2>&3)
	exitstatus=$?
	if [ $exitstatus = 0 ]; then
		defaultdata=$DATANAME
	else
		defaultdata="card.mfd"
	fi
	echo "------------------------------"
	echo $DATANAME
	echo $defaultdata
	if [ -f "$defaultdata" ]; then
		rm $defaultdata
	fi
	if [ -f "tmp.mfd" ]; then
		rm tmp.mfd
	fi
	if [ -f "3k.mfd" ]; then
		rm 3k.mfd
	fi
	nfc-mfclassic r a tmp.mfd
	dd if=/dev/zero of=3k.mfd bs=3k count=1
	cat tmp.mfd 3k.mfd >> $defaultdata
}
function writecard(){
	if [ -f "$defaultdata" ]; then
		nfc-mfclassic w a $defaultdata
	fi
}
function writecardunlocked(){
	if [ -f "$defaultdata" ]; then
		nfc-mfclassic W a $defaultdata
	fi
}
for (( ; ; ))
do
OPTION=$(whiptail --title "NFC tools" --menu "Choose an option(current data:$defaultdata)." \
--cancel-button "Exit" 16 58 5 \
"ReadTAG" "Read data from TAG." \
"WriteTAG" "Write data to TAG." \
"WriteTAGAll" "Write data to TAG(with block 0)." \
"SelectTAGData" "Select TAG data from file." \
"Exit" "Exit" \
3>&1 1>&2 2>&3)
case $OPTION in
	"ReadTAG")
	readcard
	;;
	"WriteTAG")
	writecard
	;;
	"WriteTAGAll")
	writecardunlocked
	;;
	"SelectTAGData")
	Filebrowser "$menutitle" "$startdir"
	if [ $? -eq 0 ]; then
		if [ $selection != "" ]; then
			defaultdata=$filename
		fi
	fi
	;;
	"Exit")
	exit
	;;
	"")
	exit
	;;
esac
done
