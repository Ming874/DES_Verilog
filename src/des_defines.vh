
`ifndef DES_DEFINES_VH
`define DES_DEFINES_VH

// DES Hardware Constants and Permutation Functions
// Ps. 為了避免在不同合成器中遇到 array parameters 傳遞問題，故將各置換表實作為 automatic functions

// 初始置換函數 Initial Permutation, IP: 將 64-bit Plaintext 依 DES 的 IP 表重排
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

// 逆初始置換函數 Inverse Initial Permutation, IP_INV: 在 16 輪加密後，將最後的 64-bit 資料重排，得到最終 Ciphertext
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

// 擴展置換函數 Expansion Permutation, E: 接收右半部的 32-bit 資料，將其擴充為 48-bit 以便後續與子金鑰進行 XOR。
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

// P 置換函數 Permutation, P: 在 S-Box 取代完後，將 32-bit 的輸出進一步打亂，以增加加密的混淆性。
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

`endif
