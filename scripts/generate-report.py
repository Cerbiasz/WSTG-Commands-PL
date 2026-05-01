#!/usr/bin/env python3
"""
generate-report.py - Konwersja JSONL z Nuclei → Markdown + HTML report.

Funkcje:
- Grupowanie findings per WSTG ID + severity
- Deduplication based on (template-id, host, matched-at)
- Sorting: severity (critical → info), then alphabetical
- Markdown z table of contents
- HTML z basic styling + interactive filtering

Użycie:
    python3 generate-report.py results/ --output-md report.md --output-html report.html
    python3 generate-report.py results/  # auto-output: results/report.md, results/report.html
"""

import argparse
import json
import os
import sys
import html
from collections import defaultdict
from datetime import datetime
from pathlib import Path

SEVERITY_ORDER = {
    "critical": 0,
    "high": 1,
    "medium": 2,
    "low": 3,
    "info": 4,
    "unknown": 5,
}

SEVERITY_COLORS = {
    "critical": "#d73a49",
    "high": "#e36209",
    "medium": "#dbab09",
    "low": "#28a745",
    "info": "#0366d6",
    "unknown": "#6a737d",
}


def load_jsonl_files(results_dir: Path) -> list:
    """Load all JSONL files from results dir + subdirectories."""
    findings = []
    for jsonl_file in results_dir.rglob("*.jsonl"):
        with open(jsonl_file) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    findings.append(json.loads(line))
                except json.JSONDecodeError as e:
                    print(f"WARN: bad JSON in {jsonl_file}: {e}", file=sys.stderr)
    return findings


def deduplicate(findings: list) -> list:
    """Dedupe by (template-id, host, matched-at)."""
    seen = set()
    deduped = []
    for f in findings:
        key = (
            f.get("template-id", ""),
            f.get("host", ""),
            f.get("matched-at", ""),
        )
        if key not in seen:
            seen.add(key)
            deduped.append(f)
    return deduped


def group_by_wstg_category(findings: list) -> dict:
    """Group findings by WSTG category (INFO/CONF/INPV/...)."""
    groups = defaultdict(list)
    for f in findings:
        # Try template-id first (e.g., "wstg-inpv-05-sqli-error-based")
        template_id = f.get("template-id", "")
        category = "OTHER"
        if template_id.startswith("wstg-"):
            parts = template_id.split("-")
            if len(parts) >= 2:
                category = parts[1].upper()
        # Tags fallback
        elif f.get("info", {}).get("tags"):
            tags = f["info"]["tags"]
            if isinstance(tags, str):
                tags = tags.split(",")
            for tag in tags:
                if tag.startswith("wstg-v42-"):
                    parts = tag.split("-")
                    if len(parts) >= 4:
                        category = parts[2].upper()
                        break
        groups[category].append(f)
    return dict(sorted(groups.items()))


def severity_key(finding: dict) -> int:
    sev = finding.get("info", {}).get("severity", "unknown").lower()
    return SEVERITY_ORDER.get(sev, 99)


def render_markdown(findings: list, output_path: Path):
    """Generate Markdown report."""
    grouped = group_by_wstg_category(findings)
    total = len(findings)

    # Severity counts
    sev_counts = defaultdict(int)
    for f in findings:
        sev = f.get("info", {}).get("severity", "unknown").lower()
        sev_counts[sev] += 1

    lines = []
    lines.append("# WSTG Nuclei Suite — Report")
    lines.append("")
    lines.append(f"**Generated**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"**Total findings**: {total}")
    lines.append("")

    # Severity summary
    lines.append("## Severity Summary")
    lines.append("")
    lines.append("| Severity | Count |")
    lines.append("|---|---|")
    for sev in ["critical", "high", "medium", "low", "info", "unknown"]:
        if sev_counts[sev] > 0:
            lines.append(f"| {sev.upper()} | {sev_counts[sev]} |")
    lines.append("")

    # Table of contents
    lines.append("## Table of Contents")
    lines.append("")
    for cat, items in grouped.items():
        lines.append(f"- [WSTG-{cat}](#wstg-{cat.lower()}) ({len(items)} findings)")
    lines.append("")

    # Per category
    for cat, items in grouped.items():
        lines.append(f"## WSTG-{cat}")
        lines.append("")
        # Sort by severity then template
        items_sorted = sorted(items, key=lambda x: (severity_key(x), x.get("template-id", "")))
        # Group per template
        by_template = defaultdict(list)
        for f in items_sorted:
            by_template[f.get("template-id", "unknown")].append(f)

        for tmpl_id, tmpl_findings in by_template.items():
            info = tmpl_findings[0].get("info", {})
            name = info.get("name", tmpl_id)
            severity = info.get("severity", "unknown").upper()
            lines.append(f"### [{severity}] {name}")
            lines.append("")
            lines.append(f"**Template**: `{tmpl_id}` | **Findings**: {len(tmpl_findings)}")
            lines.append("")

            # Description (first 500 chars)
            desc = info.get("description", "")
            if desc:
                lines.append(f"> {desc.strip()[:500]}")
                lines.append("")

            # References
            refs = info.get("reference", [])
            if refs:
                lines.append("**References**:")
                for ref in refs[:3]:
                    lines.append(f"- {ref}")
                lines.append("")

            # Per-finding details
            lines.append("**Affected URLs**:")
            lines.append("")
            for f in tmpl_findings[:50]:  # limit per template
                matched_at = f.get("matched-at", f.get("host", "unknown"))
                extracted = f.get("extracted-results", [])
                lines.append(f"- `{matched_at}`")
                if extracted:
                    for ex in extracted[:5]:
                        lines.append(f"  - Extracted: `{ex[:200]}`")
            if len(tmpl_findings) > 50:
                lines.append(f"- ... ({len(tmpl_findings) - 50} more)")
            lines.append("")

    output_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Markdown report: {output_path}")


def render_html(findings: list, output_path: Path):
    """Generate HTML report with interactive filtering."""
    grouped = group_by_wstg_category(findings)
    total = len(findings)

    sev_counts = defaultdict(int)
    for f in findings:
        sev = f.get("info", {}).get("severity", "unknown").lower()
        sev_counts[sev] += 1

    html_parts = []
    html_parts.append("""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>WSTG Nuclei Suite — Report</title>
<style>
  body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; max-width: 1400px; margin: 0 auto; padding: 20px; color: #24292e; }
  h1 { border-bottom: 2px solid #e1e4e8; padding-bottom: 10px; }
  h2 { border-bottom: 1px solid #e1e4e8; padding-bottom: 8px; margin-top: 40px; }
  h3 { margin-top: 30px; }
  .meta { background: #f6f8fa; padding: 10px 15px; border-radius: 6px; margin-bottom: 20px; }
  .severity-badge { display: inline-block; padding: 2px 10px; border-radius: 4px; color: white; font-size: 0.85em; font-weight: bold; }
  details { background: #f6f8fa; border-radius: 6px; padding: 12px 16px; margin-bottom: 12px; }
  summary { cursor: pointer; font-weight: 600; }
  summary:hover { color: #0366d6; }
  code { background: #f3f4f6; padding: 1px 6px; border-radius: 3px; font-size: 0.9em; }
  pre { background: #f6f8fa; padding: 12px; border-radius: 6px; overflow-x: auto; }
  table { border-collapse: collapse; width: 100%; margin: 15px 0; }
  th, td { padding: 8px 12px; text-align: left; border: 1px solid #e1e4e8; }
  th { background: #f6f8fa; }
  .filters { background: #fff8c5; padding: 12px; border-radius: 6px; margin: 15px 0; border: 1px solid #d4af37; }
  .filters label { margin-right: 15px; cursor: pointer; }
  .url-list { font-family: monospace; font-size: 0.9em; }
  .url-list li { margin-bottom: 4px; }
  .toc { background: #f6f8fa; padding: 12px 20px; border-radius: 6px; }
  .toc ul { margin: 0; padding-left: 20px; }
  .hidden { display: none !important; }
</style>
</head>
<body>""")

    html_parts.append(f"<h1>WSTG Nuclei Suite — Report</h1>")
    html_parts.append(f'<div class="meta">')
    html_parts.append(f"<strong>Generated</strong>: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}<br>")
    html_parts.append(f"<strong>Total findings</strong>: {total}")
    html_parts.append(f"</div>")

    # Severity summary
    html_parts.append("<h2>Severity Summary</h2>")
    html_parts.append("<table><tr><th>Severity</th><th>Count</th></tr>")
    for sev in ["critical", "high", "medium", "low", "info", "unknown"]:
        if sev_counts[sev] > 0:
            color = SEVERITY_COLORS.get(sev, "#6a737d")
            html_parts.append(
                f'<tr><td><span class="severity-badge" style="background:{color}">{sev.upper()}</span></td>'
                f'<td>{sev_counts[sev]}</td></tr>'
            )
    html_parts.append("</table>")

    # Filter controls
    html_parts.append('<div class="filters"><strong>Filter by severity:</strong> ')
    for sev in ["critical", "high", "medium", "low", "info"]:
        html_parts.append(
            f'<label><input type="checkbox" class="sev-filter" data-sev="{sev}" checked> {sev.upper()}</label> '
        )
    html_parts.append("</div>")

    # TOC
    html_parts.append("<h2>Table of Contents</h2>")
    html_parts.append('<div class="toc"><ul>')
    for cat, items in grouped.items():
        html_parts.append(f'<li><a href="#wstg-{cat.lower()}">WSTG-{cat}</a> ({len(items)} findings)</li>')
    html_parts.append("</ul></div>")

    # Per category
    for cat, items in grouped.items():
        html_parts.append(f'<h2 id="wstg-{cat.lower()}">WSTG-{cat}</h2>')

        items_sorted = sorted(items, key=lambda x: (severity_key(x), x.get("template-id", "")))
        by_template = defaultdict(list)
        for f in items_sorted:
            by_template[f.get("template-id", "unknown")].append(f)

        for tmpl_id, tmpl_findings in by_template.items():
            info = tmpl_findings[0].get("info", {})
            name = info.get("name", tmpl_id)
            severity = info.get("severity", "unknown").lower()
            color = SEVERITY_COLORS.get(severity, "#6a737d")

            html_parts.append(f'<details class="finding" data-sev="{severity}">')
            html_parts.append(
                f'<summary><span class="severity-badge" style="background:{color}">{severity.upper()}</span> '
                f'{html.escape(name)} ({len(tmpl_findings)})</summary>'
            )
            html_parts.append(f'<p><strong>Template</strong>: <code>{html.escape(tmpl_id)}</code></p>')

            desc = info.get("description", "")
            if desc:
                html_parts.append(f"<p>{html.escape(desc.strip())}</p>")

            refs = info.get("reference", [])
            if refs:
                html_parts.append("<p><strong>References</strong>:</p><ul>")
                for ref in refs[:5]:
                    html_parts.append(f'<li><a href="{html.escape(ref)}" target="_blank">{html.escape(ref)}</a></li>')
                html_parts.append("</ul>")

            html_parts.append("<p><strong>Affected URLs</strong>:</p>")
            html_parts.append('<ul class="url-list">')
            for f in tmpl_findings[:50]:
                matched_at = f.get("matched-at", f.get("host", "unknown"))
                html_parts.append(f"<li><code>{html.escape(matched_at)}</code>")
                extracted = f.get("extracted-results", [])
                if extracted:
                    html_parts.append("<ul>")
                    for ex in extracted[:3]:
                        ex_str = str(ex)[:200]
                        html_parts.append(f"<li>Extracted: <code>{html.escape(ex_str)}</code></li>")
                    html_parts.append("</ul>")
                html_parts.append("</li>")
            if len(tmpl_findings) > 50:
                html_parts.append(f"<li>... ({len(tmpl_findings) - 50} more)</li>")
            html_parts.append("</ul>")
            html_parts.append("</details>")

    # Filter JS
    html_parts.append("""
<script>
document.querySelectorAll('.sev-filter').forEach(cb => {
  cb.addEventListener('change', () => {
    const enabled = Array.from(document.querySelectorAll('.sev-filter:checked')).map(c => c.dataset.sev);
    document.querySelectorAll('.finding').forEach(el => {
      el.classList.toggle('hidden', !enabled.includes(el.dataset.sev));
    });
  });
});
</script>
</body>
</html>""")

    output_path.write_text("\n".join(html_parts), encoding="utf-8")
    print(f"HTML report: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="Generate WSTG report from Nuclei JSONL output")
    parser.add_argument("results_dir", help="Directory with JSONL files")
    parser.add_argument("--output-md", help="Output Markdown path (default: results_dir/report.md)")
    parser.add_argument("--output-html", help="Output HTML path (default: results_dir/report.html)")
    args = parser.parse_args()

    results_dir = Path(args.results_dir)
    if not results_dir.is_dir():
        print(f"ERROR: {results_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    findings = load_jsonl_files(results_dir)
    if not findings:
        print("WARN: no findings loaded from JSONL files", file=sys.stderr)

    findings = deduplicate(findings)
    print(f"Loaded {len(findings)} unique findings")

    md_path = Path(args.output_md or results_dir / "report.md")
    html_path = Path(args.output_html or results_dir / "report.html")

    render_markdown(findings, md_path)
    render_html(findings, html_path)

    return 0


if __name__ == "__main__":
    sys.exit(main())
