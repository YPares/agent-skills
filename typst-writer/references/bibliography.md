# Basic Setup

```typst
// In your document, cite with @label
Some text with a citation @smith2023.
Multiple citations @jones2024 @doe2025.

// At the end of your document
#bibliography("references.bib", title: "References", style: "ieee")
```

# Citation Styles

- `"ieee"` - IEEE numeric style [1], [2], [3]
- `"apa"` - APA author-year style (Smith, 2023)
- `"chicago-author-date"` - Chicago author-date style
- `"chicago-notes"` - Chicago notes and bibliography style
- `"mla"` - MLA style

# BibTeX Format (.bib files)

```bibtex
@article{smith2023,
  title = {Title of the Article},
  author = {Smith, John and Doe, Jane},
  journal = {Journal Name},
  year = {2023},
  volume = {10},
  pages = {123--145},
}

@online{webresource,
  title = {Web Page Title},
  author = {Author Name},
  year = {2024},
  url = {https://example.com},
  urldate = {2024-11-19},
}

@book{doe2025,
  title = {Book Title},
  author = {Doe, Jane},
  publisher = {Publisher Name},
  year = {2025},
}
```

# Bibliography Function Parameters

```typst
#bibliography(
  "file.bib",           // Path to bibliography file
  title: "References",  // Section title (or none for no title)
  style: "ieee",        // Citation style
  full: false,          // Show all entries or only cited ones
)
```
