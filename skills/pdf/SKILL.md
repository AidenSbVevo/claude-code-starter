---
name: pdf
description: "Any task with PDF files: extract text/tables, merge or combine, split, rotate, watermark, create PDFs, fill PDF forms (bundled scripts), encrypt/decrypt, extract images, OCR scanned PDFs. Trigger whenever the user mentions a .pdf file or asks to produce one."
license: Proprietary. LICENSE.txt has complete terms
---

# PDF Processing Guide

## Overview

This guide covers essential PDF processing operations using Python libraries and command-line tools. It routes each task to the right tool; for advanced features, JavaScript libraries, and detailed recipes, see reference.md. If you need to fill out a PDF form, read forms.md and follow its instructions.

## Quick Reference

| Task | Best Tool | Approach |
|------|-----------|----------|
| Merge/split PDFs | pypdf | `PdfWriter` + `add_page()`; one page per file to split |
| Rotate/crop pages | pypdf | `page.rotate(90)`; set `page.mediabox` to crop |
| Read metadata | pypdf | `reader.metadata` |
| Add watermark | pypdf | `page.merge_page(watermark_page)`; recipe in reference.md |
| Encrypt/decrypt | pypdf or qpdf | `writer.encrypt(...)`; recipes in reference.md |
| Extract text | pdfplumber | `page.extract_text()` |
| Extract tables | pdfplumber | `page.extract_tables()`; feed rows to pandas |
| Create PDFs | reportlab | Canvas or Platypus |
| Render pages as images | pypdfium2 | see reference.md |
| Command line merge/split | qpdf | `qpdf --empty --pages file1.pdf file2.pdf -- merged.pdf` |
| Extract embedded images | pdfimages | `pdfimages -j input.pdf prefix` (poppler-utils) |
| OCR scanned PDFs | pytesseract + pdf2image | Convert to image first; recipe in reference.md |
| Fill PDF forms | bundled scripts | See forms.md |

## Python Libraries

- **pypdf** — page-level manipulation: merge, split, rotate, crop, watermark,
  metadata, encryption. Avoid its `extract_text()` on very large documents.
- **pdfplumber** — text and table extraction with layout and coordinates.
  Custom table settings and visual debugging: see reference.md.
- **reportlab** — create PDFs: `canvas` for direct drawing, Platypus
  (`SimpleDocTemplate`, `Paragraph`, `Table`) for flowing documents.
  **IMPORTANT**: never use Unicode subscript/superscript characters
  (₀₁₂₃, ⁰¹²³) — the built-in fonts lack these glyphs and render solid black
  boxes. Use `<sub>`/`<super>` markup in Paragraph objects instead; see
  reference.md.
- **pypdfium2** — fast rendering of pages to images (PDFium bindings); see
  reference.md.

## Command-Line Tools

- **pdftotext** (poppler-utils) — quick text extraction; `-layout` preserves
  layout, `-f`/`-l` select a page range, `-bbox-layout` adds coordinates.
- **qpdf** — merge, split, rotate, encrypt/decrypt, linearize, repair.
- **pdfimages** (poppler-utils) — extract embedded images; much faster than
  rendering pages.
- **pdftk** (if available) — merge (`cat`), split (`burst`), rotate.

Advanced usage for all of these is in reference.md.

## Filling PDF Forms

Read forms.md before writing any code — it is a step-by-step workflow with
hard ordering requirements. It covers both fillable (AcroForm) PDFs and
non-fillable PDFs (text annotations placed via structure extraction or visual
estimation), using the bundled scripts below.

## Bundled Scripts

Run from this skill's directory with `python scripts/<name> ...`. Usage and
ordering are specified in forms.md.

| Script | Purpose |
|--------|---------|
| `check_fillable_fields.py` | Detect whether a PDF has fillable form fields |
| `extract_form_field_info.py` | Dump fillable field IDs, types, and positions to JSON |
| `fill_fillable_fields.py` | Fill fillable fields from a field_values.json |
| `extract_form_structure.py` | Extract labels/lines/checkboxes with coordinates from non-fillable forms |
| `check_bounding_boxes.py` | Validate fields.json bounding boxes before filling |
| `fill_pdf_form_with_annotations.py` | Write text annotations onto non-fillable forms |
| `convert_pdf_to_images.py` | Render each PDF page to a PNG |

## Next Steps

See reference.md for detailed recipes:

- pypdfium2 rendering and text extraction
- JavaScript libraries: pdf-lib (create/modify/merge), pdfjs-dist (render,
  extract text/annotations)
- Advanced poppler-utils and qpdf usage (bbox text extraction, image
  conversion, optimization, repair, encryption)
- pdfplumber advanced: character-level coordinates, custom table settings,
  visual debugging
- reportlab advanced: styled tables, subscript/superscript markup
- Watermarking, cropping, batch processing, and memory management for large
  PDFs
- Troubleshooting: encrypted PDFs, corrupted PDFs, OCR fallback for scanned
  documents
