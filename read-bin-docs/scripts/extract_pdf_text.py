#!/usr/bin/env python3
"""
Extract text from PDF files using pypdf.

Usage:
    python extract_pdf_text.py <pdf_file>
    python extract_pdf_text.py <pdf_file> --output <output_file>
    python extract_pdf_text.py <pdf_file> --pages 1-5
"""

import sys
import argparse
from pathlib import Path

try:
    from pypdf import PdfReader
except ImportError:
    print("Error: pypdf not installed. Install with: pip install pypdf", file=sys.stderr)
    sys.exit(1)


def extract_text(pdf_path, pages=None):
    """
    Extract text from PDF file.

    Args:
        pdf_path: Path to PDF file
        pages: Optional list of page numbers (1-indexed) or None for all pages

    Returns:
        Extracted text as string
    """
    try:
        reader = PdfReader(pdf_path)
        text = ""
        total_pages = len(reader.pages)

        if pages is None:
            pages = list(range(1, total_pages + 1))

        for page_num in pages:
            if page_num < 1 or page_num > total_pages:
                print(f"Warning: Page {page_num} out of range (1-{total_pages})", file=sys.stderr)
                continue

            page = reader.pages[page_num - 1]
            page_text = page.extract_text()
            if page_text:
                text += page_text
                if page_num < max(pages):
                    text += "\n\n"

        return text
    except Exception as e:
        print(f"Error reading PDF: {e}", file=sys.stderr)
        sys.exit(1)


def parse_page_range(page_str, total_pages):
    """Parse page range string like '1-5' or '1,3,5' into list of page numbers."""
    pages = []
    for part in page_str.split(','):
        part = part.strip()
        if '-' in part:
            start, end = part.split('-')
            start, end = int(start.strip()), int(end.strip())
            pages.extend(range(start, min(end + 1, total_pages + 1)))
        else:
            pages.append(int(part))
    return sorted(set(pages))


def main():
    parser = argparse.ArgumentParser(description="Extract text from PDF files")
    parser.add_argument("pdf_file", help="Path to PDF file")
    parser.add_argument("--output", "-o", help="Output file (default: stdout)")
    parser.add_argument("--pages", help="Page range (e.g., '1-5' or '1,3,5')")

    args = parser.parse_args()

    pdf_path = Path(args.pdf_file)
    if not pdf_path.exists():
        print(f"Error: File not found: {pdf_path}", file=sys.stderr)
        sys.exit(1)

    pages = None
    if args.pages:
        reader = PdfReader(pdf_path)
        pages = parse_page_range(args.pages, len(reader.pages))

    text = extract_text(pdf_path, pages)

    if args.output:
        Path(args.output).write_text(text, encoding='utf-8')
        print(f"Text extracted to: {args.output}", file=sys.stderr)
    else:
        print(text)


if __name__ == "__main__":
    main()
