# Test Pierwszości AKS w Języku C

Wysoko zoptymalizowana implementacja pierwszego w historii informatyki deterministycznego, bezwarunkowego testu pierwszości czasu wielomianowego (Agrawal-Kayal-Saxena). Projekt napisany w języku C z wykorzystaniem biblioteki **GMP** (GNU Multiple Precision Arithmetic Library) do obsługi arytmetyki wielkich liczb.

## Dokumentacja Projektu

Pełen opis matematyczny, analiza złożoności oraz omówienie wprowadzonych optymalizacji sprzętowych znajdują się w poniższych plikach:
* [Raport z projektu (PDF)](https://github.com/maslotwi/aks-primality-test/blob/main/opracowanie.pdf)
* [Prezentacja zaliczeniowa (PDF)](https://github.com/maslotwi/aks-primality-test/blob/main/prezentacja.pdf)

---

## Główne cechy i optymalizacje

* **Ścisły Dowód Matematyczny:** Pełna implementacja bezwarunkowego algorytmu weryfikującego pierwszość w czasie wielomianowym.
* **Hipoteza Agrawala (`--use-unproven`):** Opcjonalna flaga redukująca złożoność algorytmu, pozwalająca na weryfikację liczb 128-bitowych w ułamku sekundy.
* **Leniwe Modulo (Lazy Modulo):** Optymalizacja mnożenia wielomianów `O(r^2)` poprzez akumulację sum pośrednich i wykonanie operacji redukcji modulo tylko raz na zakończenie pętli.
* **Niejawne NWD (Implicit GCD):** Całkowita eliminacja algorytmu Euklidesa poprzez sekwencyjne badanie reszt z dzielenia w trakcie wyszukiwania rzędu multiplikatywnego.
* **Integer Newton:** Własna, całkowitoliczbowa implementacja metody babilońskiej (pierwiastkowanie) uodporniona na błędy precyzji zmiennoprzecinkowej.

---

## Wymagania

Do skompilowania projektu potrzebne są:
* Kompilator języka C (np. `GCC` lub `Clang`)
* `CMake`
* Biblioteka `GMP` (w systemach Debian/Ubuntu: `sudo apt-get install libgmp-dev`)

---

## Budowanie Projektu (Release Mode)

Aby algorytm działał z maksymalną wydajnością (co jest **krytyczne** dla testowania dużych liczb pierwszych), projekt należy zbudować w trybie Release. Włączy to zaawansowane optymalizacje kompilatora (m.in. flagę `-O3`).

[CODEBLOCK]bash
# 1. Utworzenie i konfiguracja katalogu budowania w trybie Release
mkdir build-release
cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release

# 2. Kompilacja
cmake --build build-release
[CODEBLOCK]

*(Jeśli chcesz zbudować wersję deweloperską z symbolami debugowania, pomiń flagę `-DCMAKE_BUILD_TYPE=Release`).*

---

## Użycie (CLI)

Program obsługuje trzy tryby działania, przekazywane jako argumenty wiersza poleceń:

**1. Ścisły Test AKS (Domyślny)**
Matematycznie udowodniony test pierwszości. Ze względu na potężną złożoność obliczeniową, przeznaczony głównie dla liczb do 32 bitów.
[CODEBLOCK]bash
./build-release/kryptografia-aks 15485863
[CODEBLOCK]

**2. Test AKS z Hipotezą Agrawala**
Drastycznie redukuje liczbę sprawdzanych świadków. Umożliwia błyskawiczne weryfikowanie ogromnych liczb pierwszej (np. 64-bitowych i 128-bitowych).
[CODEBLOCK]bash
./build-release/kryptografia-aks --use-unproven 18446744073709551557
[CODEBLOCK]

**3. Naiwny Test O(sqrt(n))**
Wykorzystywany do celów porównawczych (benchmarkingu). Bardzo szybki dla małych liczb, jednak jego czas wykonania rośnie wykładniczo.
[CODEBLOCK]bash
./build-release/kryptografia-aks --naive 4294967291
[CODEBLOCK]
