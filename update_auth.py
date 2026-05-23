import os

def update_login():
    path = 'lib/screens/auth/login_screen.dart'
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Update gradient and card
    content = content.replace('Color(0xFFF7931E)', 'Color(0xFFFFB347)')
    content = content.replace('borderRadius: BorderRadius.circular(20)', 'borderRadius: BorderRadius.circular(32)')
    content = content.replace('fontSize: 32', 'fontSize: 32, fontWeight: FontWeight.w900')
    content = content.replace('backgroundColor: Colors.orange', 'backgroundColor: const Color(0xFFFF6B35)') # if any
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Updated {path}')

def update_register():
    path = 'lib/screens/auth/register_screen.dart'
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace('Color(0xFFF7931E)', 'Color(0xFFFFB347)')
    content = content.replace('borderRadius: BorderRadius.circular(20)', 'borderRadius: BorderRadius.circular(32)')
    content = content.replace('fontSize: 32', 'fontSize: 32, fontWeight: FontWeight.w900')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Updated {path}')

def update_splash():
    path = 'lib/screens/splash_screen.dart'
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    content = content.replace('Color(0xFFF7931E)', 'Color(0xFFFFB347)')
    
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'Updated {path}')

if __name__ == '__main__':
    update_login()
    update_register()
    update_splash()
