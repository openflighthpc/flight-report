echo -e "\n=== top (first 20 lines) ===" 
top -b -n1 | head -n 20 
echo -e "\n=== ps aux (top 10 by CPU) ==="
ps aux --sort=-%cpu | head -n 10
