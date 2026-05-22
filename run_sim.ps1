# DES Verilog Simulation Script

Write-Host "--- Starting DES Simulation with LFSR ---" -ForegroundColor Cyan

# 1. Compilation
Write-Host "Compiling source files..." -ForegroundColor Yellow
iverilog -g2012 -I src -s tb_des -o des_sim_v src/tb_des.v src/des_top.v src/des_round.v src/feistel.v src/sbox*.v src/lfsr.v

if ($LASTEXITCODE -ne 0) {
    Write-Host "Compilation failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

# 2. Execution and Output Redirection
Write-Host "Running simulation and saving output to output.txt..." -ForegroundColor Yellow
vvp des_sim_v | Tee-Object -FilePath "output.txt"

Write-Host "--- Simulation Finished ---" -ForegroundColor Cyan
Write-Host "You can view the results in output.txt or open dump.vcd with GTKWave."
