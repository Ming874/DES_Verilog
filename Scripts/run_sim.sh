#!/bin/bash

# DES Verilog Simulation Script (Bash version)

echo -e "\033[0;36m--- Starting DES Simulation with LFSR ---\033[0m"

# 0. Python Environment Setup
echo -e "\033[0;33mChecking Python environment...\033[0m"
if [ ! -d ".venv" ]; then
    echo -e "\033[0;37mCreating virtual environment...\033[0m"
    python3 -m venv .venv
fi

# Activate venv and install dependencies
source .venv/bin/activate
pip install --quiet pycryptodome

# 1. Compilation
echo -e "\033[0;33mCompiling source files...\033[0m"
iverilog -g2012 -I ../src -s tb_des -o ../des_sim_v ../src/tb_des.v ../src/des_top.v ../src/des_round.v ../src/feistel.v ../src/sbox*.v ../src/lfsr.v

if [ $? -ne 0 ]; then
    echo -e "\033[0;31mCompilation failed!\033[0m"
    exit 1
fi

# 2. Execution and Output Redirection
echo -e "\033[0;33mRunning simulation...\033[0m"
vvp ../des_sim_v > ../output.txt
cat ../output.txt

# 3. Verification
echo -e "\033[0;33mRunning Python verification script...\033[0m"
python3 verify_tb.py >> ../output.txt
tail -n 30 ../output.txt

echo -e "\033[0;36m--- Simulation and Verification Finished ---\033[0m"
echo "You can view the detailed results in output.txt or open dump.vcd with GTKWave."
