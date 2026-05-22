# Overview of DES

- [**Ref: geeksforgeeks**](https://www.geeksforgeeks.org/computer-networks/data-encryption-standard-des-set-1/)

## Structure Overview
![image](https://hackmd.io/_uploads/BkVArzJT-l.png)
![image](https://hackmd.io/_uploads/SkaJ1Xy6Wx.png)

---

## Encryption Procedure

### 1. IP (Initial Permutation)

Divides the Plain/Cipher Text to:
- $LH_0$ (Even, 32 bits)
- $RH_0$ (Odd, 32 bits)

### 2. Iterate Feistel Cipher (the steps below) for 16 Rounds

$$\begin{cases} 
LH_i = RH_{i-1} \\ 
RH_i = LH_{i-1} \oplus F(RH_{i-1}, K_i) 
\end{cases}$$

- The procedure of round function F() 
    1. Expansion, 32 to 48 bits $\to$ **Diffusion**
    2. XOR with Key (48 bits)
    3. Substitution (Sbox $\times$ 8) $\to$ **Confusion**
            48 (6 $\times$ 8) bits $\to$ 32 (4 $\times$ 8) bits
            e.g. **1**0010**1** $\to$ Row 3, Column 2
    4. Permutation: 32 $\to$ 32 bits

- Key Schedule
    1. IP (PC-1): 64 bits $\to$ 8 parity bits + $C_0$ (28 bits) + $D_0$ (28 bits)
    2. Circular Left Shift (1 or 2 bits based on round)
    3. PC-2: Compress the key from 56 to 48 bits $\to$ $K_i$

### 3. $IP^{-1}$
### 4. Inverse $L_H$, $R_H$