DLD="dlang.org"
rm docs/html/*

ROOT=$PWD

function dodoc {
	file=$1
	newfile=${file//\//_}
	
	fileExt=.${2-d}
	
	file=source/$file$fileExt
	newfile=docs/html/$newfile.html
	
	command="dmd -Df$newfile -c -o- -Isource -unittest "
	command=$command" -version=StdDdoc"
	command=$command" $DLD/html.ddoc $DLD/dlang.org.ddoc $DLD/std.ddoc $DLD/macros.ddoc $DLD/std_navbar-prerelease.ddoc project.ddoc "
	command=$command$file
	$($command)
}

function recursiverm() {
  for d in *; do
    if [ -d $d ]; then
      (cd $d; recursiverm "$1$d/")
	else
		filename=$(basename "$1$d")
		extension="${filename##*.}"
		filename="${filename%.*}"
		
		pushd $ROOT > /dev/null
		dodoc "$1$filename" "$extension"
		popd > /dev/null
    fi
  done
}

(cd source; recursiverm)