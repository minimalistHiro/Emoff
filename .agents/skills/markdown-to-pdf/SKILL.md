---
name: markdown-to-pdf
description: 指定されたマークダウンファイルをPDF化してデスクトップに保存する。「〇〇をPDF化して」「〇〇をPDFにして」「〇〇をPDFに変換して」「〇〇のPDFを作って」等の依頼が対象。
---

# Markdown to PDF Skill

## 概要

指定されたマークダウンファイルをPDFに変換し、デスクトップ（`/Users/kanekohiroki/Desktop/`）に保存する。
変換方式は **Python + Chrome ヘッドレス** を使用する。

## 手順

### 1. 対象ファイルの特定

- ユーザーが指定したマークダウンファイルを特定する。
- 複数ファイルが指定された場合は、すべてのファイルを対象とする。
- ファイルパスが曖昧な場合は、プロジェクトルート `/Users/kanekohiroki/Desktop/emoff/` から `Glob` ツールで検索して特定する。
- ファイルが存在しない場合はユーザーに確認する。

### 2. 出力ファイル名の決定

- 出力PDFファイル名は `{元のファイル名（拡張子なし）}.pdf` とする。
- 保存先は `/Users/kanekohiroki/Desktop/{ファイル名}.pdf` とする。

### 3. PDF変換の実行（Python + Chrome ヘッドレス）

以下のPythonスクリプトをBashツールで実行する。`{入力ファイルパス}` と `{ファイル名}` を対象ファイルに合わせて置換すること。
複数ファイルの場合は、それぞれ並列にBashツールを呼び出して同時変換する。

```bash
python3 - << 'PYEOF'
import subprocess, sys, os, tempfile

input_path = "{入力ファイルパスの絶対パス}"
output_path = "/Users/kanekohiroki/Desktop/{ファイル名}.pdf"

try:
    import markdown
    with open(input_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
    html_body = markdown.markdown(md_content, extensions=['tables', 'fenced_code', 'toc'])
except ImportError:
    import re
    with open(input_path, 'r', encoding='utf-8') as f:
        md_content = f.read()
    html_body = md_content
    html_body = re.sub(r'^# (.+)$', r'<h1>\1</h1>', html_body, flags=re.MULTILINE)
    html_body = re.sub(r'^## (.+)$', r'<h2>\1</h2>', html_body, flags=re.MULTILINE)
    html_body = re.sub(r'^### (.+)$', r'<h3>\1</h3>', html_body, flags=re.MULTILINE)
    html_body = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', html_body)
    html_body = re.sub(r'`(.+?)`', r'<code>\1</code>', html_body)
    html_body = re.sub(r'^- (.+)$', r'<li>\1</li>', html_body, flags=re.MULTILINE)
    html_body = html_body.replace('\n', '<br>')

html = f"""<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<style>
  body {{ font-family: 'Hiragino Kaku Gothic ProN', 'Hiragino Sans', sans-serif; margin: 40px; line-height: 1.8; color: #333; }}
  h1 {{ color: #1a1a2e; border-bottom: 2px solid #1a1a2e; padding-bottom: 8px; }}
  h2 {{ color: #16213e; border-bottom: 1px solid #ccc; padding-bottom: 4px; }}
  h3 {{ color: #0f3460; }}
  code {{ background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }}
  pre {{ background: #f4f4f4; padding: 16px; border-radius: 6px; overflow-x: auto; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ border: 1px solid #ddd; padding: 8px 12px; text-align: left; }}
  th {{ background: #f0f0f0; }}
  blockquote {{ border-left: 4px solid #ccc; margin: 0; padding-left: 16px; color: #666; }}
  li {{ margin: 4px 0; }}
</style>
</head>
<body>
{html_body}
</body>
</html>"""

with tempfile.NamedTemporaryFile(mode='w', suffix='.html', delete=False, encoding='utf-8') as f:
    f.write(html)
    tmp_html = f.name

chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
result = subprocess.run([
    chrome,
    "--headless", "--disable-gpu", "--no-sandbox",
    f"--print-to-pdf={output_path}",
    "--print-to-pdf-no-header",
    f"file://{tmp_html}"
], capture_output=True, text=True)

os.unlink(tmp_html)

if os.path.exists(output_path):
    print(f"SUCCESS: {output_path}")
else:
    print(f"FAILED: {result.stderr}")
    sys.exit(1)
PYEOF
```

### 4. 結果の報告

- 変換成功時：「`/Users/kanekohiroki/Desktop/{ファイル名}.pdf` に保存しました」と報告する。
- 変換失敗時：エラー内容を報告する。

## 注意事項

- 日本語を含むMarkdownは文字化けに注意。UTF-8で処理すること。
- 変換前に必ずファイルの存在確認を行う。
- 既に同名のPDFがデスクトップに存在する場合は上書きする（ユーザーに事前通知不要）。
- 複数ファイル指定時は並列にBashツールを呼び出して効率的に変換する。
