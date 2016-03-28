getStamps () {
	grep -F -B1 "${match}" "tmp/$name-subtitles.txt" |
                grep '[0-9][0-9]:[0-9][0-9]' | tr ',' '.'
}
getStart () {
	getStamps | awk '{print $1}'; 
}
getEnd () {
	getStamps | awk '{print $3}'; 
}
addSeconds() {
	echo "$(date --date "@$(($(date --date "2015-01-01 ${1}" +%s)+${2}))" +%H:%M:%S)";
} && (addSeconds "01:03:22.777" "1" |grep -q '01:03:23') || exit 1;
matchStart () {
	end=$lenght;
        while ! [ ${end} = ${position} ]; do
                match="${line:position:end}";
                if grep -qF "${match}" "tmp/$name-subtitles.txt"; then
                        addSeconds "$(getStart)" "-1";
                        return;
                fi;
                end=$((end-1));
        done;
	echo "Failed to match start of line: $line"; exit 1;
}
matchEnd () {
	matchStart > /dev/null;
	if [ ${end} = ${lenght} ]; then 
		addSeconds "$(getEnd)" "3";
		return;
	fi
	position=$((end+1));
	end=${lenght};
        while ! [ ${end} = ${position} ]; do
                match="${line:position:end}";
                if grep -qF "${match}" "tmp/$name-subtitles.txt"; then
			addSeconds "$(getEnd)" "3";
                        return;
                fi;
                position=$((position+1));
        done;
	echo "Failed to match end of line: $line"; exit 1;
}
match () {
	cat tmp/$name-dialogs.utf.summary.txt |
	while read line; do
		lenght="${#line}";
		position=0;
		start="$(matchStart)";
		finish="$(matchEnd)";
		echo "${start} ${finish} ${line}" >> tmp/$name-extracts.txt;
	done;
}
extract () {
	lineId=0;
	cat tmp/$name-extracts.txt |sort >tmp/$name-extracts-sorted.txt;
	cat tmp/$name-extracts-sorted.txt |
	while read line; do
		start="$(echo "$line"|awk '{print $1}')";
		finish="$(echo "$line"|awk '{print $2}')";
		echo "$start $finish";
		echo "file '${PWD}/tmp/$name-summary${lineId}.mp4'" >> tmp/$name-concate.txt;
		cat /dev/null | 
			ffmpeg -nostats -loglevel panic -i "$movie" -ss "${start}" -to "${finish}" -map_metadata -1 $OPTIONS tmp/$name-summary${lineId}.mp4;
		lineId=$((lineId+1));
	done;
	cat /dev/null |ffmpeg -nostats -loglevel panic -f concat -i tmp/$name-concate.txt -c copy out/$name-summary.mp4
}
sanitizeSubtitles () {
	cat "$subtitles" |
                iconv -c -t UTF-8 |
		# Tripple dot overuse causes trouble.
                #sed 's/\.\+/\./g' | 
                sed 's/([^)]*)//g' |
                sed 's/<[^>]*>//g' |
                tr '-' '_' | tr -d '\r' | grep -v '^[0-9]*$' |
                while read line; do
                        if ! echo "$line" | grep -q '^[0-9]'; then
                                echo -n "$line ";
                        else
                                echo; 
                                echo "$line";
                        fi;
                done |
		grep -v '^[ ]*$' > tmp/$name-subtitles.txt;
}
summarize () {
	cat tmp/$name-subtitles.txt |grep -v '^[0-9]' > tmp/$name-dialogs.utf.txt;
	~/.local/bin/sumy lex-rank --length=15 --file tmp/$name-dialogs.utf.txt > tmp/$name-dialogs.utf.summary.txt;
}
main () {
	movie="$1";
	name="$(basename "$1")";
	subtitles="$2";
	if [ "$#" = 3 ] && [ "$3" = "-fast" ]; then
		OPTIONS="-c copy";	
	else
		OPTIONS="-strict -2";
	fi
	rm tmp/$name-* || true;
	rm out/$name-summary.mp4 || true;
	sanitizeSubtitles;
	summarize;
	match;
	extract;
}
set -ue
main "$@";
