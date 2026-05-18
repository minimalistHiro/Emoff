#!/usr/bin/env python3
"""Emoff markdown <-> Google Sheets helper.

This script intentionally keeps project-specific parsing small and explicit.
Set EMOFF_SPREADSHEET_ID or create scripts/sheets_config.json:
{"spreadsheet_id": "..."}
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
CONFIG = SCRIPTS / "sheets_config.json"
CREDENTIALS = SCRIPTS / "credentials.json"
SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]

DOC_TABS = {
    "business-model": ("ビジネスモデル", ROOT / "BUSINESS_MODEL.md"),
    "ideas": ("ビジネスアイデア", ROOT / "BUSINESS_IDEAS.md"),
    "app-screens": ("画面構成", ROOT / "APP_SCREENS.md"),
    "screen-design": ("画面設計", ROOT / "SCREEN_DESIGN.md"),
    "firestore": ("Firestore", ROOT / "FIRESTORE.md"),
    "ui-ux": ("UI_UX", ROOT / "UI_UX.md"),
    "app-store-texts": ("ストア掲載文", ROOT / "APP_STORE_TEXTS.md"),
    "default-settings": ("デフォルト設定値", ROOT / "DEFAULT_SETTINGS.md"),
}


def die(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def spreadsheet_id() -> str:
    value = os.environ.get("EMOFF_SPREADSHEET_ID", "").strip()
    if value:
        return value
    if CONFIG.exists():
        data = json.loads(CONFIG.read_text(encoding="utf-8"))
        value = str(data.get("spreadsheet_id", "")).strip()
        if value:
            return value
    die("EMOFF_SPREADSHEET_ID または scripts/sheets_config.json の spreadsheet_id を設定してください")


def sheets_service():
    if not CREDENTIALS.exists():
        die(f"Googleサービスアカウント鍵が見つかりません: {CREDENTIALS}")
    try:
        from google.oauth2.service_account import Credentials
        from googleapiclient.discovery import build
    except ImportError as exc:
        die(f"Google Sheets APIライブラリが不足しています: {exc}")
    creds = Credentials.from_service_account_file(CREDENTIALS, scopes=SCOPES)
    return build("sheets", "v4", credentials=creds)


def get_version() -> str:
    pubspec = ROOT / "pubspec.yaml"
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        match = re.match(r"^version:\s*(\d+\.\d+\.\d+)", line)
        if match:
            return match.group(1)
    die("pubspec.yaml から version を取得できません")


def md_table_rows(path: Path) -> list[list[str]]:
    rows: list[list[str]] = []
    in_table = False
    header_seen = False
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line.startswith("|"):
            cells = [c.strip() for c in line.strip("|").split("|")]
            if all(re.fullmatch(r":?-{3,}:?", c or "") for c in cells):
                header_seen = True
                continue
            if not in_table:
                in_table = True
                header_seen = False
                continue
            if header_seen and cells:
                rows.append(cells)
            continue
        if in_table:
            in_table = False
            header_seen = False
    return rows


def parse_sections(path: Path) -> list[list[str]]:
    rows = [["見出し2", "見出し3", "内容"]]
    h2 = ""
    h3 = ""
    buf: list[str] = []

    def flush() -> None:
        nonlocal buf
        text = "\n".join(buf).strip()
        if h2 and text:
            rows.append([h2, h3, text])
        buf = []

    if not path.exists():
        return rows
    for raw in path.read_text(encoding="utf-8").splitlines():
        if re.match(r"^# [^#]", raw) or raw.strip() == "---":
            continue
        m2 = re.match(r"^##\s+(.+)", raw)
        if m2:
            flush()
            h2 = m2.group(1).strip()
            h3 = ""
            continue
        m3 = re.match(r"^###\s+(.+)", raw)
        if m3:
            flush()
            h3 = m3.group(1).strip()
            continue
        buf.append(raw)
    flush()
    return rows


def parse_todo() -> list[list[str]]:
    return [["ID", "優先度", "内容", "状態"]] + md_table_rows(ROOT / "TODO.md")


def parse_review_items() -> list[list[str]]:
    path = ROOT / "REVIEW_ITEMS.md"
    rows = [["ID", "優先度", "カテゴリ", "内容", "状態"]]
    if not path.exists():
        return rows
    content = path.read_text(encoding="utf-8")
    blocks = re.split(r"\n---\n", content)
    for block in blocks:
        title = re.search(r"^###\s+(R-\d+):\s*(.+)$", block, flags=re.M)
        if not title:
            continue
        item_id = title.group(1)
        fields = {}
        for key in ("優先度", "カテゴリ", "内容", "状態"):
            m = re.search(rf"^-\s+\*\*{key}\*\*:\s*(.+)$", block, flags=re.M)
            fields[key] = m.group(1).strip() if m else ""
        rows.append([item_id, fields["優先度"], fields["カテゴリ"], fields["内容"], fields["状態"]])
    return rows


def parse_archive() -> list[list[str]]:
    return [["ID", "カテゴリ", "内容", "元の優先度", "アーカイブ理由", "アーカイブ日"]] + md_table_rows(
        ROOT / "ARCHIVED_IDEAS.md"
    )


def parse_qa(version: str | None = None) -> tuple[str, list[list[str]]]:
    version = version or get_version()
    path = ROOT / "qa" / f"QA_V{version}.md"
    if not path.exists():
        die(f"QAチェックリストが見つかりません: {path}")
    rows = [["テストID", "セクション", "区分", "共有", "テスト内容", "担当者", "結果", "実施日", "メモ"]]
    for raw in path.read_text(encoding="utf-8").splitlines():
        m = re.match(r"^-\s+\[(?: |x)\]\s+`([^`]+)`\s+(.+)$", raw)
        if not m:
            continue
        test_id = m.group(1)
        rest = m.group(2).strip()
        tags = re.findall(r"^\[([^\]]+)\]", rest)
        while rest.startswith("["):
            tag = re.match(r"^\[[^\]]+\]\s*", rest)
            if not tag:
                break
            rest = rest[tag.end() :]
        section = tags[0] if tags else ""
        category = next((t.split(":", 1)[1] for t in tags if t.startswith("由来:")), "")
        share = next((t.split(":", 1)[1] for t in tags if t.startswith("共有:")), "-")
        rows.append([test_id, section, category, share, rest, "", "未実施", "", ""])
    return version, rows


def update_tab(tab_name: str, rows: list[list[str]], dry_run: bool = False) -> None:
    if dry_run:
        print(f"[dry-run] {tab_name}: {max(len(rows) - 1, 0)} rows")
        return
    service = sheets_service()
    sid = spreadsheet_id()
    spreadsheet = service.spreadsheets().get(spreadsheetId=sid).execute()
    titles = {s["properties"]["title"] for s in spreadsheet["sheets"]}
    if tab_name not in titles:
        service.spreadsheets().batchUpdate(
            spreadsheetId=sid,
            body={"requests": [{"addSheet": {"properties": {"title": tab_name}}}]},
        ).execute()
    service.spreadsheets().values().clear(spreadsheetId=sid, range=f"{tab_name}!A:Z").execute()
    service.spreadsheets().values().update(
        spreadsheetId=sid,
        range=f"{tab_name}!A1",
        valueInputOption="USER_ENTERED",
        body={"values": rows},
    ).execute()
    print(f"{tab_name}: {max(len(rows) - 1, 0)} rows synced")


def qa_fail(version: str | None = None, dry_run: bool = False) -> None:
    version = version or get_version()
    tab_name = f"QA_V{version}"
    if dry_run:
        print(f"[dry-run] read {tab_name} fail/open rows")
        return
    service = sheets_service()
    result = service.spreadsheets().values().get(spreadsheetId=spreadsheet_id(), range=f"{tab_name}!A:I").execute()
    values = result.get("values", [])
    for row in values[1:]:
        result_value = row[6] if len(row) > 6 else ""
        if result_value in ("Fail", "未実施", ""):
            test_id = row[0] if row else ""
            desc = row[4] if len(row) > 4 else ""
            print(f"{test_id}\t{result_value or '未実施'}\t{desc}")


def export_qa_csv(version: str | None = None) -> None:
    version, rows = parse_qa(version)
    out = ROOT / f"QA_V{version}.csv"
    with out.open("w", encoding="utf-8-sig", newline="") as f:
        csv.writer(f).writerows(rows)
    print(out)


def sync_meeting_notes(dry_run: bool = False) -> None:
    notes_dir = ROOT / "meeting_notes"
    if not notes_dir.exists():
        die("meeting_notes/ が存在しません")
    for path in sorted(notes_dir.glob("*.md")):
        tab = f"議事録_{path.stem}"
        rows = parse_sections(path)
        update_tab(tab, rows, dry_run=dry_run)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("target", help="all/todo/review/qa/qa-fail/qa-csv/meeting-notes or doc target")
    parser.add_argument("--version")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.target == "todo":
        update_tab("TODO", parse_todo(), args.dry_run)
    elif args.target == "review":
        update_tab("要検討事項", parse_review_items(), args.dry_run)
    elif args.target == "archive":
        update_tab("アーカイブ", parse_archive(), args.dry_run)
    elif args.target == "qa":
        version, rows = parse_qa(args.version)
        update_tab(f"QA_V{version}", rows, args.dry_run)
    elif args.target == "qa-fail":
        qa_fail(args.version, args.dry_run)
    elif args.target == "qa-csv":
        export_qa_csv(args.version)
    elif args.target == "meeting-notes":
        sync_meeting_notes(args.dry_run)
    elif args.target == "all":
        update_tab("TODO", parse_todo(), args.dry_run)
        update_tab("要検討事項", parse_review_items(), args.dry_run)
        update_tab("アーカイブ", parse_archive(), args.dry_run)
        for key, (tab, path) in DOC_TABS.items():
            if path.exists():
                update_tab(tab, parse_sections(path), args.dry_run)
        if (ROOT / "qa").exists():
            version, rows = parse_qa(args.version)
            update_tab(f"QA_V{version}", rows, args.dry_run)
    elif args.target in DOC_TABS:
        tab, path = DOC_TABS[args.target]
        update_tab(tab, parse_sections(path), args.dry_run)
    else:
        die(f"未知のtargetです: {args.target}")


if __name__ == "__main__":
    main()
