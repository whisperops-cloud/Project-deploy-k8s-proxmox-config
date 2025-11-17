[pve]
%{ for ip in ip_pves ~}
${ip} ansible_python_interpreter=/usr/bin/python3
%{ endfor ~}

[pve_master]
${ip_pves[0]} ansible_python_interpreter=/usr/bin/python3