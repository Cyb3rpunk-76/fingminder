#!/bin/bash

# ------------------------------------------------------------------
# run_zmevent.sh = create a mp4 video from zoneminder event and send
# to email
#
# Darney Lampert, 2018-02-18
# ------------------------------------------------------------------

source dbase.fnc
source ../bin.fnc

unitname="run_zmevent"
workpath=`pwd`/
imgtmpsufix="_zmevent.jpg"
videospath=/home/$OS_USER/MEDIASERVER/motion/zoneminder  # put here a directory that video event files will be copied
zm_imagespath=$videospath/.zm_images
sqlitezm=$videospath/$unitname.db
imagespath=/usr/share/zoneminder/www/events

function run_zmevent {
  Camera_ID=$2
  Event_ID=$1
  Event_Name=$(echo "$3" | sed -r 's/[~]+/ /g')
  Event_Type=$(echo "$4" | sed -r 's/[~]+/ /g')
  Event_Start=$(echo "$5" | sed -r 's/[~]+/ /g')
  Event_End=$(echo "$6" | sed -r 's/[~]+/ /g')
  Event_Note=$(echo "$8" | sed -r 's/[~]+/ /g')
  ES_Date=$(echo $Event_Start| cut -d' ' -f 1)
  ES_Time=$(echo $Event_Start| cut -d' ' -f 2)
  ES_Year=${ES_Date:2:2}
  ES_Month=${ES_Date:5:2}
  ES_Day=${ES_Date:8:2}
  ES_Hour=${ES_Time:0:2}
  ES_Minu=${ES_Time:3:2}
  ES_Segu=${ES_Time:6:2}
  ES_DTT=$(echo "$Event_Start" | tr " " -)
  Event_File_Base=$videospath/"zm_cam"$Camera_ID"_event"$Event_ID"_"$ES_Year$ES_Month$ES_Day"-"$ES_Hour$ES_Minu$ES_Segu
  Event_Video_File=$Event_File_Base.mp4
  Event_Text_File=$Event_File_Base.txt
  Event_Thumb_File=$Event_File_Base.jpg
  event_img_path=$zm_imagespath/"cam"$Camera_ID"_ev"$Event_ID"_"$ES_Year$ES_Month$ES_Day"-"$ES_Hour$ES_Minu$ES_Segu
  mkdir_ifnote $videospath
  mkdir_ifnote $zm_imagespath
  mkdir_ifnote $event_img_path
  frames=0
  thumbs=0
  thumbx=0
  if ! [[ -e $imagespath/$Camera_ID/$ES_Year/$ES_Month/$ES_Day/$ES_Hour/$ES_Minu/$ES_Segu ]]; then
    return 1
  fi
  for imagex in `ls -tr $imagespath/$Camera_ID/$ES_Year/$ES_Month/$ES_Day/$ES_Hour/$ES_Minu/$ES_Segu/*.jpg`
  do
    let "frames++" 2> /dev/null > /dev/null
    if [[ "$thumbx" -eq 0 ]]; then
      cp $imagex $Event_Thumb_File
      thumbx=1
    fi
    if [ "$thumbs" -eq 0 ]; then
      if [[ $imagex = *"analyse"* ]]; then
        cp $imagex $Event_Thumb_File
        thumbs=1
      fi
    fi
    if ! [ -L $imagex ]; then
      sudo mv $imagex $event_img_path/$(printf "%05d" $frames)$imgtmpsufix 2> /dev/null > /dev/null
      sudo ln -s $event_img_path/$(printf "%05d" $frames)$imgtmpsufix $imagex  2> /dev/null > /dev/null
    fi
  done
  ffmpeg -f image2 -framerate 20 -y -start_number 1 -i $event_img_path/"%05d"$imgtmpsufix -c:v libx264 -vf "fps=25,format=yuv420p" $Event_Video_File 2> /dev/null > /dev/null
  echo "-----------------------------------------------------------"      > $Event_Text_File
  echo "$OS_SERVERNAME Zoneminder new event: $Event_Name - $Event_Type"  >> $Event_Text_File
  echo "-----------------------------------------------------------"     >> $Event_Text_File
  echo "Event camera: "$Camera_ID                                        >> $Event_Text_File
  echo "Event start: "$Event_Start                                       >> $Event_Text_File
  echo "Event end: "$Event_End                                           >> $Event_Text_File
  echo "Event note: "$Event_Note                                         >> $Event_Text_File
  echo "-----------------------------------------------------------"     >> $Event_Text_File
  sqlite3 $sqlitezm "CREATE TABLE IF NOT EXISTS EVENTS \
                     ( Event_ID INTEGER, \
                       Camera_ID INTEGER, \
                       Event_Name TEXT, \
                       Event_Start TEXT, \
                       Event_End TEXT, \
                       Event_Note TEXT, \
                       Event_Video_File TEXT,
                       Event_Text_File TEXT,
                       Event_Thumb_File TEXT );"
  sqlite3 $sqlitezm "INSERT INTO EVENTS \
                     ( Event_ID, \
                       Camera_ID, \
                       Event_Name, \
                       Event_Start, \
                       Event_End, \
                       Event_Note, \
                       Event_Video_File, \
                       Event_Text_File, \
                       Event_Thumb_File ) \
                     VALUES \
                     ( $Event_ID, \
                       $Camera_ID, \
                       \"$Event_Name\", \
                       \"$Event_Start\", \
                       \"$Event_End\", \
                       \"$Event_Note\", \
                       \"$(basename $Event_Video_File)\", \
                       \"$(basename $Event_Text_File)\", \
                       \"$(basename $Event_Thumb_File)\" ); "

  mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWD $DB_NAMEBASE -e "call sp_zm_event_move($Event_ID,'"$(basename $Event_Video_File)"','"$(basename $Event_Text_File)"','"$(basename $Event_Thumb_File)"');"

#  mpack -s "$OS_SERVERNAME Zoneminder new event on camera $Camera_ID - $Event_Name - $Event_Type - $Event_Start" -d $TMPDIR/desc.txt  $Event_Video_File $OS_ADMINEMAIL 2> /dev/null > /dev/null
  rm -f $TMPDIR/* 2> /dev/null > /dev/null
  rmdir $TMPDIR 2> /dev/null > /dev/null
  return 0
}

csvfile=$1
pidfile=$2
while read pline; do
  run_zmevent $pline
done <$csvfile
if [ -f "$pidfile" ]; then
  rm -f $pidfile
fi

exit 0