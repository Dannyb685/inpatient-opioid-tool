import sys
import re

def check_structure(filename):
    print(f"Checking {filename}...")
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print("File not found.")
        return

    balance = 0
    stack = []
    
    # Simple state machine to ignore strings and comments
    in_block_comment = False
    
    for i, line in enumerate(lines):
        line_num = i + 1
        # Remove line comments // ...
        # (This is naive, doesn't handle strings with // properly but good enough for brace check usually)
        # Better: basic char parsing
        
        # Helper to strip comments safely-ish
        # We'll just parse char by char
        
        j = 0
        while j < len(line):
            char = line[j]
            
            # Skip comments
            if in_block_comment:
                if j + 1 < len(line) and line[j] == '*' and line[j+1] == '/':
                    in_block_comment = False
                    j += 1
                j += 1
                continue
                
            if j + 1 < len(line) and line[j] == '/' and line[j+1] == '*':
                in_block_comment = True
                j += 1
                j += 1
                continue
                
            if j + 1 < len(line) and line[j] == '/' and line[j+1] == '/':
                break # Line comment
                
            if char == '{':
                balance += 1
            elif char == '}':
                balance -= 1
                if balance < 0:
                    print(f"!! Extraneous closing brace '}}' found at Line {line_num}")
                    return
            
            j += 1
            
    if balance > 0:
        print(f"!! Missing {balance} closing brace(s). File ends with clear open scope.")
    elif balance == 0:
        print("Structure OK. Balanced.")

files = [
    "swift_native_export/AssessmentStore.swift",
    "swift_native_export/CalculatorStore.swift",
    "swift_native_export/CalculatorView.swift",
    "swift_native_export/RiskAssessmentView.swift"
]

for f in files:
    check_structure(f)
