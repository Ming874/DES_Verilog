import re
import sys
from Crypto.Cipher import DES

def verify_simulation(output_file="../output.txt"):
    lines = []
    # Try multiple encodings to handle PowerShell defaults (UTF-16) and standard UTF-8
    for enc in ["utf-16", "utf-8", "cp1252"]:
        try:
            with open(output_file, "r", encoding=enc) as f:
                lines = f.readlines()
            if lines:
                # If we found SIM_INPUT with this encoding, we are good
                if any("SIM_INPUT" in l for l in lines):
                    break
        except (UnicodeDecodeError, LookupError):
            continue
    
    if not lines:
        print(f"Error: {output_file} not found or empty.")
        return

    inputs = []
    outputs = []

    # Regex patterns to parse the simulation output
    # [50000] SIM_INPUT: Case= 0 PT=0000000000000000 KEY=0000000000000000 MASK=xxxxxxxxxxxxxxxx
    # [210000] SIM_OUTPUT: CT=8ca64de9c1b123a7
    input_pattern = re.compile(r"\[\d+\] SIM_INPUT: Case=\s*(\d+) PT=([0-9a-fA-F]+) KEY=([0-9a-fA-F]+) MASK=([0-9a-fA-F]+)")
    output_pattern = re.compile(r"\[\d+\] SIM_OUTPUT: CT=([0-9a-fA-F]+)")

    for line in lines:
        in_match = input_pattern.search(line)
        if in_match:
            inputs.append({
                "case": int(in_match.group(1)),
                "pt": in_match.group(2),
                "key": in_match.group(3),
                "mask": in_match.group(4)
            })
        
        out_match = output_pattern.search(line)
        if out_match:
            outputs.append(out_match.group(1))

    if not inputs:
        print("No simulation inputs found in output.txt.")
        return

    print("\n" + "="*60)
    print(f"{'Case':<5} | {'Plaintext':<16} | {'Key':<16} | {'Status':<8}")
    print("-" * 60)

    results_to_append = ["\n=== Verification Results ===\n"]
    passed_count = 0

    for i, inp in enumerate(inputs):
        if i >= len(outputs):
            print(f"Case {inp['case']:>2}: Missing output from simulation.")
            continue
        
        pt_hex = inp['pt']
        key_hex = inp['key']
        sim_ct_hex = outputs[i].upper()

        # Calculate expected CT using Python DES
        key = bytes.fromhex(key_hex)
        plaintext = bytes.fromhex(pt_hex)
        cipher = DES.new(key, DES.MODE_ECB)
        expected_ct_hex = cipher.encrypt(plaintext).hex().upper()

        status = "PASS" if sim_ct_hex == expected_ct_hex else "FAIL"
        if status == "PASS":
            passed_count += 1
        
        print(f"{inp['case']:>4}  | {pt_hex} | {key_hex} | {status}")
        
        result_line = f"Case {inp['case']:>2}: PT={pt_hex} KEY={key_hex} MASK={inp['mask']} EXP={expected_ct_hex} SIM={sim_ct_hex} -> {status}"
        results_to_append.append(result_line + "\n")

    print("-" * 60)
    summary = f"Verification Summary: {passed_count}/{len(inputs)} passed."
    print(summary)
    
    print("\n=== Detailed Result Log ===")
    for line in results_to_append[1:]: # Skip the header we already printed in spirit
        print(line.strip())

if __name__ == "__main__":
    verify_simulation()
