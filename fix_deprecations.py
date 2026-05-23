import os
import re

def fix_deprecations(path):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Fix withOpacity -> withValues(alpha: ...)
    # Simple regex for .withOpacity(number)
    new_content = re.sub(r'\.withOpacity\((0\.\d+|[01])\)', r'.withValues(alpha: \1)', content)
    # Also handle .withOpacity(alpha) if alpha is a variable, but let's stick to simple ones for now
    
    # 2. Fix activeColor -> activeThumbColor in Switch
    new_content = new_content.replace('activeColor: Colors.orange', 'activeThumbColor: Colors.orange')
    new_content = new_content.replace('activeColor: const Color(0xFFFF6B35)', 'activeThumbColor: const Color(0xFFFF6B35)')
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'Fixed deprecations in {path}')

def walk_and_fix(dir_path):
    for root, dirs, files in os.walk(dir_path):
        for file in files:
            if file.endswith('.dart'):
                fix_deprecations(os.path.join(root, file))

if __name__ == '__main__':
    walk_and_fix('lib')
