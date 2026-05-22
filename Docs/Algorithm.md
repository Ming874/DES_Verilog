# DES Algorithm Overview

High-level summary of the Data Encryption Standard (DES) process.

---

## 1. Initial Processing (IP)
*   **Input**: 64-bit Plaintext.
*   **Permutation**: Rearranges bits according to the IP table.
*   **Split**: Divided into **$L_0$** (32-bit) and **$R_0$** (32-bit).

---

## 2. 16 Rounds of Feistel Cipher
Each round $i$ follows these equations:
$$\begin{cases} 
L_i = R_{i-1} \\ 
R_i = L_{i-1} \oplus F(R_{i-1}, K_i) 
\end{cases}$$

### The Round Function $F(R, K)$
1.  **Expansion (E)**: 32 $\to$ 48 bits. (**Diffusion**)
2.  **Key XOR**: XOR result with 48-bit subkey $K_i$.
3.  **Substitution (S-Box)**: 48 $\to$ 32 bits using 8 S-Boxes. (**Confusion**)
4.  **Permutation (P)**: Scrambles the 32-bit output.

---

## 3. Key Schedule
Generates 16 subkeys ($K_1$ to $K_{16}$) from a 64-bit master key:
1.  **PC-1**: Discards 8 parity bits (64 $\to$ 56 bits).
2.  **Split & Shift**: Divide into two 28-bit halves; circular left shift (1 or 2 bits per round).
3.  **PC-2**: Selects 48 bits from the shifted halves to form subkey $K_i$.

---

## 4. Final Processing
1.  **32-bit Swap**: Swap the final halves ($R_{16}, L_{16}$).
2.  **Inverse IP ($IP^{-1}$)**: The final permutation to produce 64-bit Ciphertext.

---

## Structure Reference
![Architecture](https://hackmd.io/_uploads/BkVArzJT-l.png)
*(Ref: [GeeksforGeeks](https://www.geeksforgeeks.org/computer-networks/data-encryption-standard-des-set-1/))*
