import subprocess
import time
import argparse
import matplotlib.pyplot as plt

CACHED_STRICT_TIMES = {
    1009: 0.0821,
    104729: 2.9575,
    1299709: 14.7930,
    15485863: 45.9305,
    179424673: 132.8249,
    4294967291: 538.4286
}

def run_test(binary_path, flag, number):
    """Runs the C binary with the given flag and measures execution time."""
    command = [binary_path, str(number)]
    if flag:
        command.insert(1, flag)

    start_time = time.time()
    try:
        subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    except subprocess.CalledProcessError:
        print(f"Error running {binary_path} with {number}")
        return None

    return time.time() - start_time

def main():
    parser = argparse.ArgumentParser(description="Extended Benchmark for AKS Primality")
    parser.add_argument("binary_path", help="Path to the compiled C executable")
    parser.add_argument("--skip-strict", action="store_true", help="Skip running Strict AKS and use cached values for the first graph")
    args = parser.parse_args()

    # Expanded prime list up to 64-bits to properly stress the O(sqrt(n)) Naive test
    primes = [
        1009,                   # 10-bit
        104729,                 # 17-bit
        1299709,                # 21-bit
        15485863,               # 24-bit
        179424673,              # 28-bit
        4294967291,             # 32-bit
        1099511627791,          # 40-bit
        281474976710677,        # 48-bit
        72057594037928017,      # 56-bit
        18446744073709551557,    # 64-bit
        100000000000000000039,   # 67-bit
        1000000000000000000117,   # 70-bit
        11111111111111111111111,  # 73-bit
    ]

    bit_lengths = [n.bit_length() for n in primes]

    times_naive = []
    times_strict = []
    times_unproven = []

    print("Starting Extended Benchmark Suite...")

    for n in primes:
        bits = n.bit_length()
        print(f"\nTesting Prime: {n} ({bits}-bits)")

        # 1. Naive O(sqrt(n)) Test
        t_naive = run_test(args.binary_path, "--naive", n)
        times_naive.append(t_naive)
        print(f"  Naive Time:       {t_naive:.4f} seconds")

        # 2. AKS with Agrawal's Conjecture
        t_unproven = run_test(args.binary_path, "--use-unproven", n)
        times_unproven.append(t_unproven)
        print(f"  AKS Unproven:     {t_unproven:.4f} seconds")

        # 3. Strict AKS Test
        if bits <= 32:
            if args.skip_strict and n in CACHED_STRICT_TIMES:
                t_strict = CACHED_STRICT_TIMES[n]
                print(f"  AKS Strict (CACHE): {t_strict:.4f} seconds")
            else:
                t_strict = run_test(args.binary_path, None, n)
                print(f"  AKS Strict Time:  {t_strict:.4f} seconds")
            times_strict.append(t_strict)
        else:
            times_strict.append(None)

    # --- GRAPH 1: Up to 32-Bits (All Algorithms) ---
    plt.figure(figsize=(10, 6))

    # Filter data lists to only include the first 6 elements (up to 32 bits)
    idx_32 = sum(1 for b in bit_lengths if b <= 32)
    bits_small = bit_lengths[:idx_32]

    plt.plot(bits_small, times_naive[:idx_32], marker='o', linestyle='-', color='red', label='Naiwny $O(\\sqrt{n})$')
    plt.plot(bits_small, times_strict[:idx_32], marker='s', linestyle='-', color='blue', label='AKS (Ścisły Dowód)')
    plt.plot(bits_small, times_unproven[:idx_32], marker='^', linestyle='--', color='green', label="AKS (Hipoteza Agrawala)")

    plt.yscale('log')
    plt.xlabel('Rozmiar Liczby Pierwszej (Bity)', fontsize=12)
    plt.ylabel('Czas Wykonania (Sekundy) [Skala Logarytmiczna]', fontsize=12)
    plt.title('Porównanie Wydajności (do 32 bitów)', fontsize=14)
    plt.grid(True, which="both", ls="--", alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig("images/aks_benchmark_strict.png", dpi=300)
    print("\nZapisano wykres: 'aks_benchmark_strict.png'")

    # --- GRAPH 2: Up to 64-Bits (Naive vs Unproven) ---
    plt.figure(figsize=(10, 6))
    plt.plot(bit_lengths, times_naive, marker='o', linestyle='-', color='red', label='Naiwny $O(\\sqrt{n})$')
    plt.plot(bit_lengths, times_unproven, marker='^', linestyle='--', color='green', label="AKS (Hipoteza Agrawala)")

    plt.yscale('log')
    plt.xlabel('Rozmiar Liczby Pierwszej (Bity)', fontsize=12)
    plt.ylabel('Czas Wykonania (Sekundy) [Skala Logarytmiczna]', fontsize=12)
    plt.title('Zależność Czasu Od Rozmiaru Liczby (do 64 bitów)', fontsize=14)
    plt.grid(True, which="both", ls="--", alpha=0.5)
    plt.legend()
    plt.tight_layout()
    plt.savefig("images/aks_benchmark_extended.png", dpi=300)
    print("Zapisano wykres: 'aks_benchmark_extended.png'")

if __name__ == "__main__":
    main()
