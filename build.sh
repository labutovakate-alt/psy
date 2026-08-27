#!/bin/sh
# Собирает две сборки из page.html (единственный источник правды):
#   index.html    для хостинга, фотографии лежат рядом отдельными файлами
#   artifact.html для публикации артефактом, фотографии вшиты в HTML
# Правьте только page.html, потом запустите ./build.sh
set -eu
cd "$(dirname "$0")"

HEAD='<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="Психолог, подход IFS. Работа с внутренним конфликтом, самокритикой и тревогой. Онлайн, на русском и английском.">
<meta property="og:title" content="Екатерина Лабутова · психолог, IFS-терапевт">
<meta property="og:description" content="Работаю с внутренним конфликтом, самокритикой, тревогой и травмой. Онлайн, на русском и английском.">
<meta property="og:type" content="website">
<link rel="icon" href="data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 100 100%22><rect width=%22100%22 height=%22100%22 fill=%22%230E1A1D%22/><text x=%2250%22 y=%2268%22 font-size=%2252%22 text-anchor=%22middle%22 fill=%22%23EDDFC7%22 font-family=%22Georgia,serif%22>Е</text></svg>">'

{
  printf '%s\n' "$HEAD"
  # Всё до </style> включительно уходит в <head>, остальное в <body>.
  awk '{ print } /^<\/style>$/ && !done { print "</head>\n<body>"; done=1 }' page.html
  printf '</body>\n</html>\n'
} > index.html

python3 - <<'PY'
import base64, io, os, re
src = io.open('page.html', encoding='utf-8').read()

def inline(m):
    name = m.group(1)
    if not os.path.exists(name):
        raise SystemExit('нет файла: ' + name)
    b64 = base64.b64encode(open(name, 'rb').read()).decode('ascii')
    return 'src="data:image/jpeg;base64,%s"' % b64

body, n = re.subn(r'src="([^"]+\.jpe?g)(?:\?[^"]*)?"', inline, src)
io.open('artifact.html', 'w', encoding='utf-8').write(body)
print('artifact.html: вшито изображений %d, размер %d KB' % (n, os.path.getsize('artifact.html') // 1024))
PY

echo "index.html: $(wc -c < index.html | tr -d ' ') байт (+ photo-*.jpg рядом)"
