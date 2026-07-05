#!/usr/bin/env python3
with open('raco/command.scrbl') as f:
    lines = f.readlines()
balance = 0
for i, line in enumerate(lines, 1):
    old = balance
    for ch in line:
        if ch == '{':
            balance += 1
        elif ch == '}':
            balance -= 1
    if old != balance:
        print(f'Line {i}: balance={balance}: {line.rstrip()[:100]}')
