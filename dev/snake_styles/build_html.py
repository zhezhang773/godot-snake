import os

base = r'G:\autoclawcode\dev\snake_styles'
svgs = []
for i in range(1, 11):
    with open(os.path.join(base, f'style_{i:02d}.svg'), 'r', encoding='utf-8') as f:
        svgs.append(f.read())

names = [
    'Pure Square', 'Rounded Square', 'Circles', 'Pill / Capsule', 'Diamond',
    'Hexagon', 'Squircle', 'Star / Cross', 'Blob (Organic)', 'Bordered Block'
]
descs = [
    '\u7ecf\u5178\u50cf\u7d20\u98ce\u683c\uff0c\u9510\u5229\u8fb9\u89d2',
    '\u67d4\u548c\u5706\u89d2\uff0c\u53cb\u597d\u6574\u6d01',
    '\u5e73\u6ed1\u5706\u5f62\u8eab\u4f53\uff0c\u5706\u6da6\u53ef\u7231',
    '\u80f6\u56ca\u9020\u578b\uff0c\u6d41\u7545\u8854\u63a5',
    '\u65cb\u8f6c\u65b9\u5757\uff0c\u4f18\u96c5\u51e0\u4f55',
    '\u8702\u7a9d\u7ed3\u6784\uff0c\u81ea\u7136\u611f',
    'iOS \u98ce\u683c\uff0c\u73b0\u4ee3\u7b80\u7ea6',
    '\u661f\u5f62\u5341\u5b57\uff0c\u68f1\u89d2\u5206\u660e',
    '\u6709\u673a\u91cd\u53e0\uff0c\u6bdb\u6bdb\u866b\u611f',
    '\u63cf\u8fb9\u65b9\u5757\uff0c3D \u660e\u6697'
]

parts = []
parts.append('<!DOCTYPE html>')
parts.append('<html><head><meta charset="utf-8"><title>Snake Styles</title>')
parts.append('<style>')
parts.append('body{background:#0a0c14;color:#fff;font-family:Segoe UI,Arial,sans-serif;margin:0;padding:20px}')
parts.append('h1{text-align:center;margin-bottom:30px;color:#3ddb73}')
parts.append('.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;max-width:1300px;margin:0 auto}')
parts.append('.card{background:#141824;border-radius:12px;overflow:hidden;border:1px solid #1e2438}')
parts.append('.card:hover{border-color:#3ddb73}')
parts.append('.preview{background:#0f141e;display:flex;align-items:center;justify-content:center;min-height:400px}')
parts.append('.preview svg{width:100%;height:auto}')
parts.append('.info{padding:12px 16px}')
parts.append('.name{font-size:16px;font-weight:600;color:#e0e4ec}')
parts.append('.desc{font-size:13px;color:#7a8099;margin-top:4px}')
parts.append('</style></head><body>')
parts.append('<h1>Snake Style Preview</h1>')
parts.append('<div class="grid">')

for i in range(10):
    parts.append(f'<div class="card"><div class="preview">{svgs[i]}</div>')
    parts.append(f'<div class="info"><div class="name">#{i+1} - {names[i]}</div>')
    parts.append(f'<div class="desc">{descs[i]}</div></div></div>')

parts.append('</div></body></html>')

html = '\n'.join(parts)
out = os.path.join(base, 'preview_all.html')
with open(out, 'w', encoding='utf-8') as f:
    f.write(html)
print(f'Saved: {out}')
print(f'Size: {os.path.getsize(out)} bytes')
