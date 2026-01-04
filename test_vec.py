# Genera vettore di test per l'algoritmo
import random
from math import cos, sin, pi

# Genera 3 numeri complessi: A, B, W
def generate_test_vector(theta):
    A_real = random.uniform(-1, 1)
    A_imag = random.uniform(-1, 1)
    B_real = random.uniform(-1, 1)
    B_imag = random.uniform(-1, 1)

    W_real = cos(theta)
    W_imag = -sin(theta)
    
    A = complex(A_real, A_imag)
    B = complex(B_real, B_imag)
    W = complex(W_real, W_imag)
    
    return A, B, W

# Calcola il risultato del butterfly, compresi i risultati intermedi
def butterfly(A, B, W, scaling_factor):
    # Moltiplicazione di B per W
    A2 = 2*A

    # Valori intermedi
    WrBr = W.real * B.real
    WiBi = W.imag * B.imag
    WrBi = W.real * B.imag
    WiBr = W.imag * B.real

    S1 = A.real + WrBr
    S2 = S1 - WiBi
    S3 = 2*A.real - S2

    S4 = A.imag + WrBi
    S5 = S4 + WiBr
    S6 = 2*A.imag - S5
    
    # Somma e differenza
    Ap = complex(S2, S5)
    Bp = complex(S3, S6)
    
    # Applicazione del fattore di scaling
    out1 = Ap / scaling_factor
    out2 = Bp / scaling_factor
    
    # Stampa tutti i valori con 5 cifre decimali
    print(f"A: {A.real:.5f} + {A.imag:.5f}j\t\tB: {B.real:.5f} + {B.imag:.5f}j\t\tW: {W.real:.5f} + {W.imag:.5f}j")
    print(f"A2: {A2.real:.5f} + {A2.imag:.5f}j")
    print(f"WrBr: {WrBr:.5f}, WiBi: {WiBi:.5f}, WrBi: {WrBi:.5f}, WiBr: {WiBr:.5f}")
    print(f"S1: {S1:.5f}, S2: {S2:.5f}, S3: {S3:.5f}, S4: {S4:.5f}, S5: {S5:.5f}, S6: {S6:.5f}")
    print(f"A': {Ap.real:.5f} + {Ap.imag:.5f}j\tB': {Bp.real:.5f} + {Bp.imag:.5f}j")
    print(f"Output 1 (Ap scaled): {out1.real:.5f} + {out1.imag:.5f}j")
    print(f"Output 2 (Bp scaled): {out2.real:.5f} + {out2.imag:.5f}j")

if __name__ == "__main__":
    # Prendi seed dall'esterno
    seed = int(input("Seed: "))

    # Imposta il seed per la riproducibilità
    random.seed(seed)

    # Genera vettore di test
    A, B, W = generate_test_vector(pi/4)
    
    # Fattore di scaling
    scaling_factor = 4
    
    # Calcola il butterfly
    butterfly(A, B, W, scaling_factor)