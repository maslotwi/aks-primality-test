#set page(
  paper: "presentation-16-9",
  margin: (x: 2cm, y: 1.5cm),
  fill: rgb("#ffffff"),
)

#set text(font: "Liberation Serif", size: 22pt, lang: "pl")
#set heading(numbering: none)

// Stylizacja nagłówków
#show heading: it => block(below: 1.5em)[
  #text(weight: "bold", size: 1.5em, fill: rgb("#1a3a5f"))[#it.body]
]

// Pomocniczy styl dla punktów
#show list: set text(size: 0.9em)

// --- SLAJD 1: TYTUŁOWY ---
#align(center + horizon)[
  #text(size: 2em, weight: "bold", fill: rgb("#1a3a5f"))[
    Implementacja i Optymalizacja \ Testu Pierwszości AKS w Języku C
  ]
  #v(1em)
  #line(length: 40%, stroke: 2pt + rgb("#1a3a5f"))
  #v(1em)
  #text(size: 1.2em)[Marcel Słotwiński]
  #v(0.5em)
  #text(size: 0.8em, fill: gray)[Projekt Zaliczeniowy]
]

#pagebreak()
// --- SLAJD 2: PROBLEM DECYZYJNY ---
= Idea i tło historyczne

- *Problem:* Czy $n in P R I M E S$?
- *Podział naiwny:* $O(sqrt(n))$ -- czas wykładniczy względem rozmiaru wejścia ($log n$).
- *Przełom (2002):* Algorytm Agrawala, Kayala i Saxeny.
- *Status:* Pierwszy deterministyczny i bezwarunkowy test czasu wielomianowego.
- *Teoria:* Dowód, że $P R I M E S in P$.

#pagebreak()
// --- SLAJD 3: PODSTAWY MATEMATYCZNE ---
= Wielomianowy test Fermata

Tożsamość dla liczb pierwszych:
$ (X+a)^n equiv X^n + a #h(2mm) (mod n) $

#v(1em)
*Redukcja stopnia wielomianu:*
Zastosowanie pierścienia ilorazowego $bb(Z)_n [X] \/ (X^r - 1)$:

$ (X+a)^n equiv X^n + a #h(2mm) (mod X^r - 1, n) $

- Wielomianowy czas obliczeń dzięki binarnemu potęgowaniu.
- Dobór parametru $r$ kluczowy dla złożoności.

#pagebreak()
// --- SLAJD 4: SCHEMAT ALGORYTMU ---
= Algorytm AKS krok po kroku

+ Sprawdź, czy $n$ jest potęgą doskonałą ($n = a^b$).
+ Znajdź najmniejsze $r$ takie, że $o_r (n) > log^2 n$.
+ Jeśli $1 < gcd(a, n) < n$ dla $a lt.eq r$, zwróć *ZŁOŻONA*.
+ Jeśli $n lt.eq r$, zwróć *PIERWSZA*.
+ Dla $a = 1$ do $floor(sqrt(phi(r)) log_2 n)$:
  - Test kongruencji $(X+a)^n equiv X^n + a #h(2mm) (mod X^r - 1, n)$.
+ Jeśli testy przejdą pomyślnie, zwróć *PIERWSZA*.

#pagebreak()
// --- SLAJD 5: TEORIA VS PRAKTYKA ---
= Wyzwania implementacyjne

- *Złożoność:* $O^~ (log^(15/2) n)$ -- "wielomianowa", ale z dużymi stałymi.
- *Problem $O(r^2)$:* "Szkolne" mnożenie wielomianów wąskim gardłem.
- *Zasoby:* Przy 32 bitach wielomian ma stopień $approx 5000$.
- *Operacje:* Miliardy instrukcji GMP na każde potęgowanie.
- *Sprzęt:* $R_(23)$ (74 bity) wymaga optymalizacji, by zakończyć test w czasie < 1h.

#pagebreak()
// --- SLAJD 6: KOD (DIVIDER) ---
#align(center + horizon)[
  #text(size: 2.5em, weight: "bold", fill: rgb("#e67e22"))[
    PREZENTACJA KODU
  ]
  #v(1.5em)
  #rect(stroke: 1pt + gray, inset: 10pt)[
    #text(size: 0.8em)[Struktury GMP, Leniwe Modulo, Metoda Babilońska]
  ]
]

#pagebreak()
// --- SLAJD 7: OPTYMALIZACJE ---
= Kluczowe rozwiązania inżynierskie

- *Niejawne NWD:* Integracja sprawdzenia podzielności z pętlą szukania $r$.
- *Własności arytmetyki modularnej:* Akumulacja sum wielkich liczb (`mpz_addmul`) i redukcja na końcu.
- *Pierwiastek całkowitoliczbowy:* Czysto całkowitoliczbowa metoda babilońska.
- *Unsigned int 128-bitowy:* Wykorzystanie `__uint128_t` do ochrony przed overflow.

#pagebreak()
// --- SLAJD 8: WYNIKI - AKS STRICT ---
= Wyniki pomiarów klasycznego AKS

#grid(
  columns: (1fr, 1.2fr),
  [
    - Drastyczny narzut pętli Kroku 5 (liczba świadków $a$).
    - *Próg użyteczności:* Algorytm naiwny dominuje do $approx 30$ bitów.
    - *Wynik krytyczny (32 bity):*
      - *ok. 10 minut* (AMD Ryzen 7 5800X).
    - Skalowanie staje się niepraktyczne bez dodatkowych założeń.
  ],
  [
    #figure(
      image("images/aks_benchmark_strict.png", width: 100%),
      caption: [AKS Strict vs Naive (log Y)]
    )
  ]
)

#pagebreak()
// --- SLAJD 9: WYNIKI - HIPOTEZA AGRAWALA ---
= Przełom: Hipoteza Agrawala

#grid(
  columns: (1.2fr, 1fr),
  [
    #figure(
      image("images/aks_benchmark_extended.png", width: 100%),
      caption: [Zwycięstwo wielomianowości (log Y)]
    )
  ],
  [
    $ (X-1)^n equiv X^n - 1 (mod X^r - 1, n) $
    - Redukcja limitu świadków do $a = 1$.
    - *Crossover point:* 64 bity ($approx 23$ sekundy dla obu metod).
    - *Zwycięstwo:* Przy >64 bitach test naiwny kapituluje.
  ]
)

#pagebreak()
// --- SLAJD 10: WNIOSKI ---
= Wnioski

+ *Teoria:* AKS udowadnia, że pierwszość jest problemem łatwym obliczeniowo.
+ *Praktyka:* Klasyczny AKS wymaga optymalizacji (FFT) do realnych zastosowań.
+ *Synergia:* Połączenie optymalizacji C (Lazy Modulo) i matematycznych (Agrawal) pozwala na testowanie liczb 128-bitowych na komputerze PC.
+ *Konkluzja:* Czas wielomianowy zawsze wygrywa z wykładniczym po przekroczeniu bariery $n approx 2^(64)$.
