import os

def fix_file(path, braces=1):
    if not os.path.exists(path): return
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read().strip()
    
    # Count open and close braces
    open_b = content.count('{')
    close_b = content.count('}')
    
    diff = open_b - close_b
    if diff > 0:
        content += '\n' + ('}' * diff)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content + '\n')
        print(f'Fixed {path} (added {diff} braces)')
    else:
        print(f'{path} seems ok (diff={diff})')

files = [
    'lib/screens/first_aid/first_aid_screen.dart',
    'lib/screens/ngo/ngo_finder_screen.dart',
    'lib/screens/pets/add_pet_screen.dart',
    'lib/screens/pets/pet_detail_screen.dart',
    'lib/screens/scanner/qr_scanner_screen.dart',
    'lib/screens/scan_pet_screen.dart',
    'lib/screens/notifications_screen.dart',
    'lib/screens/scanner/scanned_pet_info_screen.dart',
    'lib/screens/pets/report_found_pet_screen.dart',
    'lib/screens/pets/pet_tracking_screen.dart'
]

if __name__ == '__main__':
    for f in files:
        fix_file(f)
