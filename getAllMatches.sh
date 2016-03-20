getStart () {
	grep -B2 "${match}" "${subtitles}" |
		grep '[0-9][0-9]:[0-9][0-9]' | tr ',' '.' |awk '{print $1}'; 
}
getEnd () {
	grep -B2 "${match}" "${subtitles}" |
		grep '[0-9][0-9]:[0-9][0-9]' | tr ',' '.' |awk '{print $3}';
}
addSeconds() {
	echo "$(date --date "@$(($(date --date "${1}" +%s)+${2}))" +%H:%M:%S)";
}
matchStart () {
	end=$((lenght-1));
        while ! [ ${end} = ${position} ]; do
                match="${line:position:end}";
                if grep -q "${match}" "${subtitles}"; then
                        addSeconds "$(getStart)" "-1";
                        return;
                fi;
                end=$((end-1));
        done;
	echo "Failed to match start of line: $line"; exit 1;
}
matchEnd () {
	matchStart > /dev/null;
	if [ ${end} = $((lenght-1)) ]; then 
		addSeconds "$(getEnd)" "3";
		return;
	fi
	position=$((end+1));
	end=$((lenght-1));
        while ! [ ${end} = ${position} ]; do
                match="${line:position:end}";
                if grep -q "${match}" "${subtitles}"; then
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
	echo "${start} ${finish}";
	cat /dev/null | ffmpeg -nostats -loglevel panic -i "$movie" -ss "${start}" -to "${finish}" -c copy tmp/output${lineId}.mp4;
	lineId=$((lineId+1));
}
summarize () {
	cat "$subtitles" |grep -v '^[ ]*$' | tr '-' '_' |grep -v '[0-9]' |
		iconv -c -t UTF-8 > tmp/dialogs.utf.txt;
	~/.local/bin/sumy lex-rank --length=10 --file tmp/dialogs.utf.txt > tmp/dialogs.utf.summary.txt;
}
main () {
	movie="$1";
	subtitles="$2";
	rm tmp/* || true;
	rm out/output.mp4 || true;
	lineId=0;
	summarize;
	cat tmp/dialogs.utf.summary.txt |
	while read line; do
		match "${line}";
	done;
	cat /dev/null |ffmpeg -f concat -i <(ls -1 tmp/output*|sed "s|\(.*\)|file '$PWD/\1'|") -c copy out/output.mp4
}
set -ue
main "$@";
