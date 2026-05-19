#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  header: align(right)[Implementacja i Optymalizacja Testu Pierwszości AKS w Języku C],
  numbering: "1 / 1"
)
#set text(font: "New Computer Modern", size: 10pt, lang: "pl")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1.")

// Konfiguracja odstępów dla nagłówków
#show heading: it => {
  block(above: 1.5em, below: 1em)[#it]
}

// Konfiguracja odstępów dla bloków kodu
#show raw.where(block: true): set par(leading: 0.35em)
#show raw.where(block: true): set block(above: 1em, below: 1em)
#show raw: set text(size: 9pt)

#align(center)[
  #v(2em)
  #text(size: 20pt, weight: "bold")[Implementacja i Optymalizacja \ Testu Pierwszości AKS w Języku C] \
  #v(2em)
  #text(size: 12pt)[Autor: Marcel Słotwiński] \
  #v(3em)
]

#outline(title: "Spis Treści", depth: 2)
#pagebreak()

= Wstęp i Podstawy Teoretyczne

Przez dziesięciolecia efektywne określanie, czy dana liczba jest pierwsza, 
czy złożona (w czasie wielomianowym) bez opierania się na nieudowodnionych 
założeniach matematycznych, było jednym z głównych nierozwiązanych problemów 
informatyki teoretycznej. Krajobraz ten zmienił się diametralnie w 2002 
roku, kiedy to Manindra Agrawal, Neeraj Kayal i Nitin Saxena opublikowali swoją 
przełomową pracę "PRIMES is in P". Przedstawili w niej pierwszy bezwarunkowy, 
deterministyczny algorytm czasu wielomianowego do testowania pierwszości liczb.

Algorytm opiera się na bezpośrednim uogólnieniu Małego Twierdzenia Fermata 
do pierścieni wielomianów nad ciałami skończonymi. Zależy on od matematycznej 
tożsamości, która stwierdza, że dla dowolnej liczby całkowitej $a$ względnie 
pierwszej z $n$, liczba $n$ jest pierwsza wtedy i tylko wtedy, gdy spełniona 
jest poniższa kongruencja:

$ (X+a)^n equiv X^n + a #h(2mm) (mod n) $

Ponieważ bezpośrednie wyliczenie lewej strony tego równania wymaga obliczenia $n$ 
współczynników wielomianu (co zajmuje czas $O(n)$ i jest niewykonalne dla liczb 
stosowanych w kryptografii), autorzy zredukowali to zadanie. Zaproponowali oni 
obliczanie obu stron kongruencji modulo wielomian postaci $X^r - 1$, gdzie $r$ 
jest odpowiednio dobraną, niewielką liczbą całkowitą. Rdzeń zaimplementowanego 
przeze mnie algorytmu testuje zatem następującą zależność:

$ (X+a)^n equiv X^n + a #h(2mm) (mod X^r - 1, n) $

Sprawdzając ten warunek dla określonego przedziału wartości parametru $a$, aż do 
wyliczonego analitycznie limitu, algorytm zapewnia matematycznie absolutną 
gwarancję pierwszości badanego wejścia. Głównym celem mojego projektu było 
przeniesienie tej czystej teorii matematycznej na poziom wysoce zoptymalizowanego 
kodu w języku C, korzystającego z zewnętrznej biblioteki GMP (GNU Multiple Precision 
Arithmetic Library) do obsługi wielkich liczb całkowitych.

= Matematyczny Schemat Działania Algorytmu

Poniżej przedstawiam formalny, sformalizowany opis matematyczny poszczególnych 
kroków algorytmu AKS w jego klasycznej interpretacji, zgodnie z oryginalną 
publikacją naukową.

#v(0.5em)
#block(
  fill: rgb("f9f9f9"),
  inset: 12pt,
  radius: 4pt,
  stroke: 0.5pt + rgb("dddddd"),
  [
    *Algorytm AKS (Agrawal-Kayal-Saxena) krok po kroku:*
    
    #v(0.5em)
    *Wejście:* Liczba całkowita $n > 1$.
    
    1. *Test doskonałej potęgi:* Jeśli $n = a^b$ dla $a in NN$ oraz $b > 1$, zwróć wynik *ZŁOŻONA*.
    2. *Szukanie parametru $r$:* Znajdź najmniejszą liczbę $r$ taką, że rząd liczby $n$ modulo $r$ (oznaczany jako $o_r (n)$) spełnia nierówność $o_r (n) > log^2 n$.
    3. *Sprawdzenie dzielników:* Jeśli dla jakiejkolwiek liczby $a lt.eq r$ zachodzi warunek $1 < gcd(a, n) < n$, zwróć wynik *ZŁOŻONA*.
    4. *Przypadek graniczny:* Jeśli $n lt.eq r$, zwróć wynik *PIERWSZA*.
    5. *Główna pętla kongruencji:* Dla każdej liczby całkowitej $a$ od $1$ do $floor( sqrt(phi(r)) log_2 n )$ wykonaj test:
       - Jeśli $(X+a)^n equiv.not X^n + a #h(2mm) (mod X^r - 1, n)$, zwróć wynik *ZŁOŻONA*.
    6. *Wynik ostateczny:* Jeśli liczba $n$ przetrwa wszystkie powyższe weryfikacje bez wcześniejszego przerwania programu, zwróć wynik *PIERWSZA*.
  ]
)
#v(0.5em)

= Modyfikacje Architektoniczne i Optymalizacje Sprzętowe

Tłumaczenie akademickiej matematyki dyskretnej na wydajny i bezpieczny kod 
w języku C wymagało ode mnie podjęcia kilku kluczowych decyzji inżynierskich. 
Zaimplementowałem szereg krytycznych optymalizacji niskopoziomowych, które 
zwiększają kulturę pracy programu na nowoczesnych architekturach CPU.

== Niejawne Sprawdzanie Największego Wspólnego Dzielnika
Krok 3 w oryginalnej pracy naukowej wymaga jawnego sprawdzenia, czy zachodzi 
warunek $1 < gcd(a, n) < n$ dla wszystkich wartości $a lt.eq r$, co ma na celu 
wyłapanie małych czynników pierwszych. Zamiast pisać oddzielną, kosztowną 
pętlę do wyliczania NWD przy pomocy algorytmu Euklidesa (która wprowadzałaby 
złożoność $O(r log n)$), zintegrowałem to sprawdzenie bezpośrednio z pętlą 
poszukującą odpowiedniego parametru $r$.

Ponieważ mój program testuje kolejne wartości sekwencyjnie (inkrementując $r$ 
od wartości początkowej $2$ wzwyż), jeśli liczba $n$ posiada jakikolwiek wspólny 
dzielnik z $r$, badana reszta z dzielenia $n$ przez obecne $r$ wyniesie dokładnie 
$0$. Mój kod naturalnie przechwytuje najmniejszy czynnik pierwszy na długo przed 
tym, jak licznik pętli osiągnie problematyczne wartości złożone. Pozwoliło to 
na całkowite wyeliminowanie dedykowanej funkcji NWD ze struktury programu.

== Optymalizacja Leniwego Modulo (Lazy Modulo)
Mnożenie wielomianów o dużych współczynnikach wiąże się z ogromnym obciążeniem 
jednostki centralnej, wynikającym z ciągłych operacji alokacji i zwalniania 
pamięci podręcznej dla struktur wielkich liczb biblioteki GMP. Aby zredukować 
ten narzut obliczeniowy, wykorzystałem dedykowaną instrukcję `mpz_addmul`.

Zamiast wykonywać kosztowną redukcję modulo po każdym pojedynczym mnożeniu 
współczynników wewnątrz zagnieżdżonych pętli, pozwoliłem wewnętrznej strukturze 
na nieskrępowaną akumulację surowych sum. Maksymalna teoretyczna wartość takiego 
akumulatora wynosi $r dot.op n^2$, co bez problemu mieści się w pamięci
struktur GMP bez ryzyka przepełnienia rejestrów. Dopiero po zsumowaniu wszystkich 
odpowiednich wyrazów dla danego stopnia wielomianu wykonuję pojedyncze wywołanie 
redukcji modulo. Rozwiązanie to zmniejszyło liczbę wywołań kosztownej funkcji 
`mpz_mod` z rzędu wielu milionów do zaledwie kilku tysięcy na jedną iterację.

== Całkowitoliczbowa Metoda Babilońska
Obliczenie ostatecznego limitu pętli głównej wymaga wyciągnięcia pierwiastka 
kwadratowego z iloczynu funkcji $phi$ Eulera oraz wyliczonej stałej. Użycie 
standardowej biblioteki zmiennoprzecinkowej `<math.h>` i rzutowania na typ 
`double` przy dużych danych wejściowych nieuchronnie skutkowałoby utratą 
precyzji bitowej lub błędami zaokrągleń.

Rozwiązałem ten problem, implementując własną, czysto całkowitoliczbową 
wersję algorytmu Newtona-Raphsona (znaną jako metoda babilońska). Zastosowałem 
w niej sztywne, bezwarunkowe filtry wejściowe oraz zmodyfikowany warunek 
zakończenia pętli. Dzięki temu algorytm nie wpada w pułapkę nieskończonej 
oscylacji między dwoma sąsiednimi stanami dyskretnymi, co jest powszechną wadą 
naiwnych implementacji tej metody na liczbach całkowitych.

= Analiza Fragmentów Kodu Źródłowego

Poniżej przedstawiam kluczowy fragment implementacji operacji mnożenia dwóch 
wielomianów modulo. Zwracam uwagę na makro `mpz_sgn`, które wykonuje się w 
stałym czasie $O(1)$ poprzez bezpośredni odczyt wewnętrznego pola rozmiaru 
struktury GMP. Pozwala ono na natychmiastowe pominięcie zerowych elementów, 
co daje ogromne przyspieszenie obliczeń przy rzadkich wielomianach początkowych.

```c
void poly_mod_multiply(
  poly_t result, const poly_t a, 
  const poly_t b, const mpz_t modulus) {

    poly_memset(result, 0); 
    
    for (size_t i = 0; i < a->length; i++) {
        // Optymalizacja O(1): natychmiastowe pominięcie pustych współczynników
        if(mpz_sgn(a->coefficients[i]) == 0) continue; 
        
        for (size_t j = 0; j < b->length; j++) {
            if(mpz_sgn(b->coefficients[j]) == 0) continue;
            
            uint64_t new_degree = (i+j) % a->length;
            
            // Leniwe Modulo: bezpieczna akumulacja bez redukcji wewnątrz pętli
            mpz_addmul(result->coefficients[new_degree], 
                       a->coefficients[i], 
                       b->coefficients[j]);
        }
    }
    
    // Ostateczna redukcja modulo przeprowadzana poza pętlą O(r^2)
    for(size_t i = 0; i < result->length; i++) {
        mpz_mod(result->coefficients[i], result->coefficients[i], modulus);
    }
}
```

Drugim najważniejszym elementem systemu jest pętla wyszukująca właściwą wartość 
rzędu multiplikatywnego. To w niej zintegrowałem niejawny test podzielności:

```c
uint64_t r = 2;
while(true) {
    if(mpz_cmp_ui(n, r) <= 0) return true;
    
    // Niejawne sprawdzenie podzielności zastępujące klasyczny algorytm Euklidesa
    uint64_t remainder = mpz_fdiv_ui(n, r);
    if (remainder == 0) return false;

    bool is_order_large_enough = true;
    uint64_t current_remainder = remainder;

    // Rzutowanie na 128-bitów chroni przed przepełnieniem (overflow) przy potęgowaniu
    for (uint64_t k = 1; k <= bound; k++) {
        if (current_remainder == 1) {
            is_order_large_enough = false;
            break;
        }
        current_remainder = 
          ((__uint128_t)current_remainder * (__uint128_t)remainder) % r;
    }
    if(is_order_large_enough) break;
    r++;
}
```

Zastosowanie natywnego typu `__uint128_t` chroni obliczenia potęgowe przed 
przepełnieniem bez konieczności kosztownego angażowania struktur GMP wewnątrz 
tej pętli. Stanowi to zarazem ostateczną barierę sprzętową kodu – wymusza, 
aby parametr $r$ mieścił się w rejestrze 64-bitowym, co teoretycznie pozwala 
na walidację liczb o rozmiarach rzędu 4 miliardów bitów.

= Wydajność Obliczeniowa i Ograniczenia

Mimo że algorytm AKS udowodnił, iż problem testowania pierwszości leży w klasie 
P, asymptotyczna wielomianowość nie oznacza automatycznie natychmiastowego 
działania w praktyce inżynierskiej.

Zaimplementowana przeze mnie wersja wykorzystuje tak zwany "szkolny" algorytm 
mnożenia wielomianów o złożoności kwadratowej $O(r^2)$. Dla liczby pierwszej o 
rozmiarze 64 bitów, wartość parametru $r$ oscyluje w granicach 5000. Podniesienie 
takiego wielomianu do kwadratu wymusza wykonanie minimum 25 milionów operacji 
dodawania i mnożenia w strukturach GMP na każdą iterację potęgowania binarnego. 
Z uwagi na konieczność wykonania około 96 takich kroków dla 64 bitów, procesor 
musi przetworzyć miliardy niskopoziomowych instrukcji asemblerowych.

W warunkach testowych, pełne sprawdzenie 64-bitowej liczby pierwszej zajmuje 
około 27 sekund na procesorze AMD Ryzen 7 5800X. Pokazuje to ogromne wymagania 
obliczeniowe bezwarunkowego testu AKS i wyjaśnia, dlaczego w kryptografii 
produkcyjnej (np. generowanie kluczy RSA) wciąż powszechnie stosuje się 
probabilistyczny test Millera-Rabina. Wersje zaawansowane wymagają wdrożenia 
mnożenia opartego na Szybkiej Transformacie Fouriera (FFT) w celu zejścia do 
złożoności $O(r log r)$, co jednak znacząco komplikuje architekturę pamięciową.

= Wpływ Hipotezy Agrawala na Efektywność Algorytmu

Głównym powodem tak potężnego narzutu obliczeniowego testu AKS jest konieczność 
wykonywania Kroku 5 dla ogromnej liczby niezależnych świadków $a$. Empirycznie 
można jednak łatwo dowieść, że niemal każda liczba złożona (nieposiadająca skrajnie 
małych czynników pierwszych) dyskwalifikowana jest już przy pierwszej próbie, 
czyli dla wartości $a=1$.

Twórcy algorytmu sformułowali hipotezę (zwaną Hipotezą Agrawala), która mówi, 
że jeśli $r$ jest liczbą pierwszą niedzielącą $n$ i spełniony jest warunek:

$ (X-1)^n equiv X^n - 1 #h(2mm) (mod X^r - 1, n) $

wtedy $n$ jest liczbą pierwszą bądź zachodzi kongruencja $n^2 equiv 1 mod r$. 
Założenie prawdziwości tej hipotezy redukuje poszukiwany limit iteracji $a$ do 
wartości równej dokładnie jeden.

Zintegrowałem to podejście w mojej aplikacji, udostępniając użytkownikowi flagę 
`--use-unproven`. Eliminacja potężnej liczby pętli wymaganej do ścisłego, 
bezwarunkowego dowodu matematycznego skutkuje drastycznym skróceniem czasu 
procesorowego. Milionowa liczba pierwsza (ok. 24-bitowa) jest weryfikowana w 
czasie poniżej 80 milisekund, a testowanie liczb 128-bitowych staje się w pełni 
wykonalne na domowym komputerze osobistym.

= Analiza Pomiarów Empirycznych

W celu dokładnego zbadania charakterystyki skalowania czasowego mojego 
programu, przeprowadziłem serię pomiarów dla trzech dostępnych trybów: testu 
naiwnego $O(sqrt(n))$, ścisłego dowodu AKS oraz trybu opartego na wspomnianej 
hipotezie Agrawala. Wyniki zestawiono na poniższym wykresie.

#figure(
  image("aks_benchmark_results.png", width: 90%),
  caption: [Porównanie wydajności zaimplementowanych trybów testowych.]
)

Wykres w skali logarytmicznej idealnie obrazuje ograniczenia poszczególnych 
metod. Podejście naiwne $O(sqrt(n))$, choć bezkonkurencyjne dla małych danych, 
wykazuje gwałtowny, wykładniczy wzrost czasu wykonania. Już w okolicy 28-30 bitów 
staje się ono całkowicie nieefektywne w pesymistycznych scenariuszach testowych.

Klasyczny, pełny algorytm AKS cechuje się znacznie stabilniejszą krzywą wzrostu, 
jednak jego wysoki koszt początkowy (wynikający z obsługi pamięci GMP i pętli 
wielu świadków $a$) powoduje, że przegrywa on z podejściem naiwnym aż do 
momentu osiągnięcia granicy około 28 bitów. Dopiero powyżej tej wartości ujawnia 
się przewaga wielomianowej natury algorytmu. Zastosowanie flagi 
`--use-unproven` (hipoteza Agrawala) całkowicie eliminuje ten problem, przesuwając 
krzywą czasową o kilka rzędów wielkości w dół i pozwalając na swobodne testowanie 
dużych struktur danych.

#pagebreak()
= Literatura

#v(0.5em)
#line(length: 100%, stroke: 0.5pt)
#v(0.5em)

+ [Agrawal2004] M. Agrawal, N. Kayal, N. Saxena, "PRIMES is in P", _Annals of Mathematics_, 160, 781-793, 2004.
+ [Menezes1996] A. J. Menezes, P. C. van Oorschot, S. A. Vanstone, _Handbook of Applied Cryptography_, CRC Press, 1996.
+ [Wobst2002] R. Wobst, _Kryptologia: budowa i łamanie zabezpieczeń_, Wydawnictwo EXIT, Warszawa, 2002.
