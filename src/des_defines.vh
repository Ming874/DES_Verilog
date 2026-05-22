
`ifndef DES_DEFINES_VH
`define DES_DEFINES_VH

// DES Hardware Constants and Permutation Functions
// Automatic: 每次呼叫函數時，都為該次呼叫產生獨立的動態變數空間，確保它是 re-entrant

// Initial Permutation, IP: 將 64-bit Plaintext 依 DES 的 IP 表重排
function automatic [63:0] permute_IP(input [63:0] data);
    permute_IP = {
        data[64-58], data[64-50], data[64-42], data[64-34], data[64-26], data[64-18], data[64-10], data[64-2],
        data[64-60], data[64-52], data[64-44], data[64-36], data[64-28], data[64-20], data[64-12], data[64-4],
        data[64-62], data[64-54], data[64-46], data[64-38], data[64-30], data[64-22], data[64-14], data[64-6],
        data[64-64], data[64-56], data[64-48], data[64-40], data[64-32], data[64-24], data[64-16], data[64-8],
        data[64-57], data[64-49], data[64-41], data[64-33], data[64-25], data[64-17], data[64-9], data[64-1],
        data[64-59], data[64-51], data[64-43], data[64-35], data[64-27], data[64-19], data[64-11], data[64-3],
        data[64-61], data[64-53], data[64-45], data[64-37], data[64-29], data[64-21], data[64-13], data[64-5],
        data[64-63], data[64-55], data[64-47], data[64-39], data[64-31], data[64-23], data[64-15], data[64-7]
    };
endfunction

// Inverse Initial Permutation, IP_INV: 在 16 輪加密後，將最後的 64-bit 資料重排，得到最終 Ciphertext
function automatic [63:0] permute_IP_INV(input [63:0] data);
    permute_IP_INV = {
        data[64-40], data[64-8],  data[64-48], data[64-16], data[64-56], data[64-24], data[64-64], data[64-32],
        data[64-39], data[64-7],  data[64-47], data[64-15], data[64-55], data[64-23], data[64-63], data[64-31],
        data[64-38], data[64-6],  data[64-46], data[64-14], data[64-54], data[64-22], data[64-62], data[64-30],
        data[64-37], data[64-5],  data[64-45], data[64-13], data[64-53], data[64-21], data[64-61], data[64-29],
        data[64-36], data[64-4],  data[64-44], data[64-12], data[64-52], data[64-20], data[64-60], data[64-28],
        data[64-35], data[64-3],  data[64-43], data[64-11], data[64-51], data[64-19], data[64-59], data[64-27],
        data[64-34], data[64-2],  data[64-42], data[64-10], data[64-50], data[64-18], data[64-58], data[64-26],
        data[64-33], data[64-1],  data[64-41], data[64-9],  data[64-49], data[64-17], data[64-57], data[64-25]
    };
endfunction

// Expansion Permutation, E: 將右半部的 32-bit 資料擴充為 48-bit 以便後續與子金鑰進行 XOR。
function automatic [47:0] expand_32_48(input [31:0] data);
    expand_32_48 = {
        data[32-32], data[32-1],  data[32-2],  data[32-3],  data[32-4],  data[32-5],
        data[32-4],  data[32-5],  data[32-6],  data[32-7],  data[32-8],  data[32-9],
        data[32-8],  data[32-9],  data[32-10], data[32-11], data[32-12], data[32-13],
        data[32-12], data[32-13], data[32-14], data[32-15], data[32-16], data[32-17],
        data[32-16], data[32-17], data[32-18], data[32-19], data[32-20], data[32-21],
        data[32-20], data[32-21], data[32-22], data[32-23], data[32-24], data[32-25],
        data[32-24], data[32-25], data[32-26], data[32-27], data[32-28], data[32-29],
        data[32-28], data[32-29], data[32-30], data[32-31], data[32-32], data[32-1]
    };
endfunction

// P Permutation, P: 在 S-Box 取代完後，將 32-bit 輸出進一步打亂，增加加密混淆性。
function automatic [31:0] permute_32(input [31:0] data);
    permute_32 = {
        data[32-16], data[32-7],  data[32-20], data[32-21],
        data[32-29], data[32-12], data[32-28], data[32-17],
        data[32-1],  data[32-15], data[32-23], data[32-26],
        data[32-5],  data[32-18], data[32-31], data[32-10],
        data[32-2],  data[32-8],  data[32-24], data[32-14],
        data[32-32], data[32-27], data[32-3],  data[32-9],
        data[32-19], data[32-13], data[32-30], data[32-6],
        data[32-22], data[32-11], data[32-4],  data[32-25]
    };
endfunction

// PC-1 Permutation: Discard 8 parity bits and rearrange the remaining 56 bits
function automatic [55:0] permute_PC1(input [63:0] key);
    permute_PC1 = {
        key[64-57], key[64-49], key[64-41], key[64-33], key[64-25], key[64-17], key[64-9],
        key[64-1],  key[64-58], key[64-50], key[64-42], key[64-34], key[64-26], key[64-18],
        key[64-10], key[64-2],  key[64-59], key[64-51], key[64-43], key[64-35], key[64-27],
        key[64-19], key[64-11], key[64-3],  key[64-60], key[64-52], key[64-44], key[64-36],
        key[64-63], key[64-55], key[64-47], key[64-39], key[64-31], key[64-23], key[64-15],
        key[64-7],  key[64-62], key[64-54], key[64-46], key[64-38], key[64-30], key[64-22],
        key[64-14], key[64-6],  key[64-61], key[64-53], key[64-45], key[64-37], key[64-29],
        key[64-21], key[64-13], key[64-5],  key[64-28], key[64-20], key[64-12], key[64-4]
    };
endfunction

// PC-2 Permutation: Selects 48 bits from the 56-bit shifted key state
function automatic [47:0] permute_PC2(input [55:0] combined);
    permute_PC2 = {
        combined[56-14], combined[56-17], combined[56-11], combined[56-24], combined[56-1],  combined[56-5],
        combined[56-3],  combined[56-28], combined[56-15], combined[56-6],  combined[56-21], combined[56-10],
        combined[56-23], combined[56-19], combined[56-12], combined[56-4],  combined[56-26], combined[56-8],
        combined[56-16], combined[56-7],  combined[56-27], combined[56-20], combined[56-13], combined[56-2],
        combined[56-41], combined[56-52], combined[56-31], combined[56-37], combined[56-47], combined[56-55],
        combined[56-30], combined[56-40], combined[56-51], combined[56-45], combined[56-33], combined[56-48],
        combined[56-44], combined[56-49], combined[56-39], combined[56-56], combined[56-34], combined[56-53],
        combined[56-46], combined[56-42], combined[56-50], combined[56-36], combined[56-29], combined[56-32]
    };
endfunction

`endif