getStart () {
	grep -B1 "${match//\./\\.}" "tmp/subtitles.txt" |
		grep '[0-9][0-9]:[0-9][0-9]' | tr ',' '.' |awk '{print $1}'; 
}
getEnd () {
	grep -B1 "${match//\./\\.}" "tmp/subtitles.txt" |
		grep '[0-9][0-9]:[0-9][0-9]' | tr ',' '.' |awk '{print $3}';
}
addSeconds() {
	echo "$(date --date "@$(($(date --date "${1}" +%s)+${2}))" +%H:%M:%S)";
}
matchStart () {
	end=$lenght;
        while ! [ ${end} = ${position} ]; do
                match="${line:position:end}";
                if grep -q "${match//\./\\.}" "tmp/subtitles.txt"; then
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
                if grep -q "${match//\./\\.}" "tmp/subtitles.txt"; then
                        stamp="$(getEnd)";
			echo "$(date --date "@$(($(date --date "$stamp" +%s)+3))" +%H:%M:%S)";
                        return;
                fi;
                position=$((position+1));
        done;
	echo "Failed to match end of line: $line"; exit 1;
}
match () {
	line="${1}";
	lenght="${#line}";
	position=0;
	start="$(matchStart)";
	finish="$(matchEnd)";
	echo "${start} ${finish} ${line}" >> tmp/extracts.txt;
}
extract () {
	lineId=0;
	cat tmp/extracts.txt |sort >tmp/extracts-sorted.txt;
	cat tmp/extracts-sorted.txt |
	while read line; do
		start="$(echo "$line"|awk '{print $1}')";
		finish="$(echo "$line"|awk '{print $2}')";
		echo "$start $finish";
		echo "file '${PWD}/tmp/output${lineId}.mp4'" >> tmp/concate.txt;
		cat /dev/null | 
			ffmpeg -nostats -loglevel panic -i "$movie" -ss "${start}" -to "${finish}" -strict -2 tmp/output${lineId}.mp4;
		lineId=$((lineId+1));
	done;
}
sanitizeSubtitles () {
	cat "$subtitles" |
                iconv -c -t UTF-8 |
                sed 's/\.\+/\./g' |
                sed 's/([^)]*)//g' |
                sed 's/<[^>]*>//g' |
                tr '-' '_' | tr -d '\r' | grep -v '^[0-9]*$' |
                while read line; do
                        if ! echo "$line" | grep -q '^[0-9]'; then
                                echo -n "$line ";
                        else
                                echo; echo;
                                echo "$line";
                        fi;
                done > tmp/subtitles.txt;
}
summarize () {
	cat tmp/subtitles.txt |
		grep -v '^[ ]*$' | tr '-' '_' |grep -v '[0-9]' | tr -d '\r' |
		iconv -c -t UTF-8 > tmp/dialogs.utf.txt;
	~/.local/bin/sumy lex-rank --length=15 --file tmp/dialogs.utf.txt > tmp/dialogs.utf.summary.txt;
}
main () {
	movie="$1";
	subtitles="$2";
	rm tmp/* || true;
	rm out/output.mp4 || true;
	sanitizeSubtitles;
	summarize;
	cat tmp/dialogs.utf.summary.txt |
	while read line; do
		match "${line}";
	done;
	extract;
	cat /dev/null |ffmpeg -nostats -loglevel panic -f concat -i tmp/concate.txt -c copy out/output.mp4
}
set -ue
main "$@";
