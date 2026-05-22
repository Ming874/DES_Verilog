# DES Verilog Simulation Script

Write-Host "--- Starting DES Simulation with LFSR ---" -ForegroundColor Cyan

# 0. Python Environment Setup
Write-Host "Checking Python environment..." -ForegroundColor Yellow
if (!(Test-Path ".venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Gray
    python -m venv .venv
}

# Activate venv and install dependencies
$VENV_PYTHON = ".\.venv\Scripts\python.exe"
& $VENV_PYTHON -m pip install --quiet pycryptodome

# 1. Compilation
Write-Host "Compiling source files..." -ForegroundColor Yellow
iverilog -g2012 -I ../src -s tb_des -o ../des_sim_v ../src/tb_des.v ../src/des_top.v ../src/des_round.v ../src/feistel.v ../src/sbox*.v ../src/lfsr.v

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Execution and Output Redirection
Write-Host "Running simulation..." -ForegroundColor Yellow
vvp ../des_sim_v > ../output.txt
Get-Content ../output.txt

# 3. Verification
Write-Host "Running Python verification script..." -ForegroundColor Yellow
& $VENV_PYTHON verify_tb.py >> ../output.txt
Get-Content ../output.txt -Tail 20

Write-Host "--- Simulation and Verification Finished ---" -ForegroundColor Cyan
Write-Host "You can view the detailed results in output.txt or open dump.vcd with GTKWave."
