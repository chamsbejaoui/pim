
import sys

def check_balance(filename):
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()
    
    stack = []
    line_no = 1
    char_no = 0
    
    for i, char in enumerate(content):
        if char == '\n':
            line_no += 1
            char_no = 0
        else:
            char_no += 1
            
        if char == '{':
            stack.append((line_no, char_no))
        elif char == '}':
            if not stack:
                print(f"Extra '}}' at line {line_no}, char {char_no}")
                return
            stack.pop()
            
    if stack:
        for l, c in stack:
            print(f"Unclosed '{{' at line {l}, char {c}")
    else:
        print("Braces are balanced")

if __name__ == "__main__":
    check_balance(sys.argv[1])
