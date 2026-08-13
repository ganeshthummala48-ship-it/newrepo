import socket
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
    s.connect(('8.8.8.8', 80))
    ip = s.getsockname()[0]
finally:
    s.close()
with open('ip3.txt', 'w', encoding='utf-8') as f:
    f.write(ip)
