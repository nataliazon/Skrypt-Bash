# usage gallmake.sh path_to_directory unique_name "album name" "album date" "album description" cover_filename

user="xxx"
password="xxx"

#jesli nie podano odpowiedniej liczby parametrow, skrypt konczy sie
if [ $# -lt 6 ]
then echo "Musisz podac 6 parametrow: ./gallmake.sh sciezka_do_folderu unikalna_nazwa \"Nazwa Albumu\" \"Data Albumu\" \"Opis Albumu\" nazwa_pliku_z_okladka"
exit 2
else
	
	#mozna uzyc defaultowej sciezki do miejsca gdzie trzymamy obrazki, przy uruchomieniu programu zamiast sciezki wpisujemy wtedy "default"
	if [ "$1" = "default" ] 
		then dirpath="/Users/nataliazon/Pictures/obrazki"
	else
		dirpath="$1"
	fi
	
	uniname="$2"
	albname="$3"
	albdate="$4"
	albdesc="$5"
	albcov="$6"
	
	
	#wyswietlamy parametry wpisane przez uzytkownika
	echo "||||| Sciezka do wybranego katalogu: $dirpath"
	echo "||||| Unikalna nazwa: $uniname"
	echo "||||| Nazwa albumu: $albname"
	echo "||||| Data albumu: $albdate"
	echo "||||| Opis albumu: $albdesc"
	echo "||||| Nazwa pliku z okladka: $albcov"
fi

cd $dirpath

    read -p "Czy laczyc sie z serwerem? (mozna pominac jesli w podanym katalogu sa pliki lista_plikow.txt, galeria.html i album.html) t/n     " yn

	if [ $yn == "t" ] || [ $yn == "tak" ]
	then
	

ftp -n -v ftp.spnr2siekierczyna.pl << EOT
ascii
user $user $password
prompt
dir /www/albumy lista_plikow.txt
get /www/galeria.html galeria.html
get /www/album.html album.html
bye 
EOT

	fi

#obcinamy niepotrzebne dane i umieszczamy w nowym pliku same nazwy plikow
awk '{print $9}' lista_plikow.txt > lista_nazw.txt


#sprawdzamy czy wybrana nazwa rzeczywiscie jest unikalna
while read line
do
	echo -e -n "Sprawdzam nazwe: $line ..."
	if [ "$2" = "$line" ]
		then echo "Nazwa jest juz zajeta."
		rm galeria.html
		rm lista_nazw.txt
		exit 3
	else
		echo -e "OK"
	fi
done <  "lista_nazw.txt"
rm lista_nazw.txt





mkdir $uniname

star="*"
slash="/"
beginning="zdj"
big="_big.jpg"
small="_small.jpg"
galeria="galeria.html"
album="album.html"
cover="cover.jpg"
format=".jpg"
html=".html"

iterator=0

FILES=$dirpath$slash$star

lista="lista_plikow.txt"


#zmniejszamy rozmiar zdjęć i tworzymy miniaturki (przy miniaturkach wymuszamy rozdzielczosc 183x137)
rozsz="jpg"
rozsz2="JPG"
for f in $FILES
do	
	type=${f: -3}
	if [ "$type" == "$rozsz" ] || [ "$type" == "$rozsz2" ]
	then
		echo -e -n "Przetwarzam plik: $f ..."
		#echo $iterator
		convert $f -resize 800x800 $uniname$slash$beginning$iterator$big
		convert $f -resize 183x137\! $uniname$slash$beginning$iterator$small
		echo "ZROBIONE"
		let "iterator += 1"
	fi
done



#tworzymy obrazek okladki albumu (wymuszamy rozdzielczosc)
convert $dirpath$slash$albcov -resize 320x230\! $uniname$slash$cover


#tworzymy fragment html ktory odpowiada za link do albumu w pliku galeria.html
let jeden=1

part1='<div><a href="albumy/'
part2=$uniname$jeden$html
part3='"><img class="miniaturka" src="albumy/'
part4=$uniname
part5='/cover.jpg" /></a><div class="divopis"><a href="albumy/'
part6=$uniname$html
part7='"><h3 class="tytul">Album: '
part8=$albname
part9='</h3></a><h3 class="data">'
part10=$albdate
part11='</h3><p class="opis">'
part12=$albdesc
part13='</p></div></div>'

whole=$part1$part2$part3$part4$part5$part6$part7$part8$part9$part10$part11$part12$part13

#wstawiamy wygenerowany kod html w odpowiednie miejsce w pliku galeria.html
sed -e "52a\
$whole" galeria.html > galeria1.html

rm galeria.html
mv galeria1.html galeria.html


#tworzymy plik z kodem html opakowujacym nowy album wzorujac sie na pliku album.html

head -57 album.html > tempalbum.txt
tail -42 album.html >> tempalbum.txt

#liczymy ile album ma miec stron

let x=$iterator+3
let y=$x/9
let z=$y*9

if [ $z -eq $x ]
	then
	let liczba_stron=$y
else
	let liczba_stron=$y+1
fi



block1="<a class=\"group3\" href=\""
block2="\" title=\"\"></a>"
block3="<div id=\"foto"
block4="\"><a class=\"group3\" href=\""
block5="\" title=\"\"><img class=\"miniaturka\" src=\""
block6="\" /></a></div>"



    
block7="<div id=\"strony\"><a href=\""
block8="\"><div id=\"strzalka_lewo\""
dontdisplay=" style=\"display:none;\""
block9="></div></a><div id=\"srodek_strony\"><p id=\"strony_paragraph\"><span id=\"strony_text\">Strona: </span>"
active1="<span id=\"strony_active\">"
active2=" </span>"
inactive1="<a href=\""
inactive2="\"><span id=\"strony_liczby\">"
inactive3=" </span></a>"
block10="</p></div><a href=\""
block11="\"><div id=\"strzalka_prawo\""
block12="></div></a></div>"

block13="<div id=\"album_title\"><div id=\"album_title_date\"><p id=\"pdate\">"
block14="</p></div><div id=\"album_title_text\"><p id=\"ptitle\">"
block15="</p></div></div>"


#generujemy kolejne strony albumu
#for i in $(jot $liczba_stron)
for i in `seq 1 $liczba_stron`
do
	echo -n "Przetwarzam strone numer: $i ..."
	head -57 album.html > tempalbum.txt
	
	#jesli generujemy strone pierwszsza
	if [ $i -eq 1 ]
	then 
		let page_photo_no=4
		let global_photo_start_no=0
		let global_photo_end_no=5
	else
		let page_photo_no=1
		let k=$i-1
		let temp=$k*9
		let global_photo_start_no=$temp-3
		if [ $i -ne $liczba_stron ]
		then
			let global_photo_end_no=$global_photo_start_no+8
		#jesli generujemy strone ostatnia
		else
			let j=$iterator-1
			let global_photo_end_no=$j
		fi
	fi
	
	#jesli generujemy strone pierwsza
	if [ $i -eq 1 ]
	then
		albumtytul=$block13$albdate$block14$albname$block15
		echo $albumtytul >> tempalbum.txt
	fi
	
	let wczesniejsze=$global_photo_start_no-1
	
	echo "<!-- wczesniejsze zdjecia -->" >> tempalbum.txt
	let u=0
	#jesli sa jakies zdjecia z poprzednich stron do podlinkowania
	if [ $wczesniejsze -ne -1 ]
		then
			 
			while [[ $u -le $wczesniejsze ]] 
			do
				
    			string=$block1$uniname$slash$beginning$u$big$block2
    			echo $string >> tempalbum.txt
    			((u = u + 1))
			done
	fi
	
	echo "<!-- koniec wczesniejsze -->" >> tempalbum.txt
	
	
		while [[ $u -le $global_photo_end_no ]] 
			do
				
    			string=$block3$page_photo_no$block4$uniname$slash$beginning$u$big$block5$uniname$slash$beginning$u$small$block6
    			echo $string >> tempalbum.txt
    			((u = u + 1))
    			((page_photo_no = page_photo_no + 1))
			done
	
	
	echo "<!-- pozostale zdjecia -->" >> tempalbum.txt
	let r=$global_photo_end_no+1
	
	while [[ $r -lt $iterator ]] 
			do
				
    			string=$block1$uniname$slash$beginning$r$big$block2
    			echo $string >> tempalbum.txt
    			((r = r + 1))
			done
	
	echo "<!-- koniec pozostale -->" >> tempalbum.txt
	
	let p=$i-1
	
	if [ $i -eq 1 ]
	then
		poczatek=$block7$uniname$i$html$block8$dontdisplay$block9
	else
		poczatek=$block7$uniname$p$html$block8$block9
	fi
	
	echo $poczatek >> tempalbum.txt
	
	
	#for e in $(jot $liczba_stron)
	for e in `seq 1 $liczba_stron`
	do
		
		if [ $e -eq $i ]
		then
			srodek=$active1$e$active2
		else
			srodek=$inactive1$uniname$e$html$inactive2$e$inactive3
		fi	
		echo $srodek >> tempalbum.txt
	done
	
	let n=$i+1
	if [ $i -eq $liczba_stron ]
	then
		koniec=$block10$uniname$i$html$block11$dontdisplay$block12
	else
		koniec=$block10$uniname$n$html$block11$block12
	fi
	
	echo $koniec >> tempalbum.txt
	
	tail -42 album.html >> tempalbum.txt
	cp tempalbum.txt $uniname$i$html
	
	echo "ZROBIONE"
done
	
rm tempalbum.txt
koncowka="*.html"


    read -p "Czy wyslac wygenerowane pliki na serwer do katalogu TEST? t/n     " yn

	if [ $yn == "t" ] || [ $yn == "tak" ]
	then
	echo "Wysylanie"
	testing=1
		
	
		ftp -n -v ftp.spnr2siekierczyna.pl << EOT
		ascii
		user $user $password
		prompt
		cd www/test
		put galeria.html
		cd albumy
		mput $uniname$koncowka
		mkdir $uniname
		cd $uniname
		lcd $uniname
		mput *.jpg
		bye 
EOT
		
	else
	 	echo "Pliki NIE zostaly umieszczone na serwerze w katalogu TEST."
		testing=0
	fi


    read -p "Czy opublikować wygenerowane pliki na serwerze? t/n     " yn

	if [ $yn == "t" ] || [ $yn == "tak" ]
	then
	read -p "Czy jestes pewien swojej decyzji? t/n     " yn2
	
	    if [ $yn2 == "t" ] || [ $yn2 == "tak" ]
	    then
	      echo "Wysylanie"
	
		
	
		ftp -n -v ftp.spnr2siekierczyna.pl << EOT
		ascii
		user $user $password
		prompt
		cd www
		put galeria.html
		cd albumy
		mput $uniname$koncowka
		mkdir $uniname
		cd $uniname
		lcd $uniname
		mput *.jpg
		bye 
EOT
		


	    fi
	
	else
	 	echo "Pliki NIE zostaly opublikowane na serwerze."

	fi
	
	read -p "Czy usunac wygenerowane pliki z dysku? t/n        " yn

	if [ $yn == "t" ] || [ $yn == "tak" ]
	then
		rm galeria.html
		rm album.html
		rm -rf $uniname
		rm $uniname$koncowka
		rm lista_plikow.txt
	fi
	
	
	if [ $testing -eq 1 ] 
	then	

echo "Czekaj, trwa czyszczenie katalogu TEST."

		ftp -n -v ftp.spnr2siekierczyna.pl << EOT
		ascii
		user $user $password
		prompt
		cd www/test/albumy	
		cd $uniname
		mdelete *
		cd ..
		rmdir $uniname
		bye 
EOT

fi


