; Headings
(atx_heading) @markup.heading
(setext_heading) @markup.heading

; Emphasis
(emphasis) @markup.italic
(strong_emphasis) @markup.bold

; Code
(code_span) @markup.raw.inline
(fenced_code_block) @markup.raw.block
(indented_code_block) @markup.raw.block

; Links
(link) @markup.link
(image) @markup.link
(autolink) @markup.link.url

; Lists
(list_marker_minus) @punctuation.special
(list_marker_plus) @punctuation.special
(list_marker_star) @punctuation.special
(list_marker_dot) @punctuation.special

; Quotes
(block_quote) @markup.quote

; Horizontal rules
(thematic_break) @punctuation.special
