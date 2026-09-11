use std::ops::Range;

/// Decoded UTF-8 text with byte positions in the original SQL file.
#[derive(Debug, Clone)]
pub struct BodySource {
    text: String,
    // Each output byte maps to the entire input character/escape that produced it.
    origins: Vec<Range<usize>>,
    end: usize,
}

impl BodySource {
    pub fn text(&self) -> &str {
        &self.text
    }

    /// Map an output byte offset, including EOF, to an absolute SQL byte offset.
    /// An offset inside a decoded Unicode character maps to its source start.
    pub fn source_offset(&self, offset: usize) -> Option<usize> {
        if offset == self.text.len() {
            Some(self.end)
        } else {
            self.origins.get(offset).map(|range| range.start)
        }
    }

    /// Map a half-open output range. Escapes are included in their entirety.
    /// Empty ranges map to an empty range at the corresponding source position.
    pub fn source_range(&self, range: Range<usize>) -> Option<Range<usize>> {
        if range.start > range.end || range.end > self.text.len() {
            return None;
        }
        let start = self.source_offset(range.start)?;
        let end = if range.is_empty() {
            start
        } else {
            self.origins.get(range.end - 1)?.end
        };
        Some(start..end)
    }

    pub(crate) fn verbatim(text: &str, start: usize) -> Self {
        Self {
            text: text.to_owned(),
            origins: (start..start + text.len()).map(|i| i..i + 1).collect(),
            end: start + text.len(),
        }
    }

    /// Decode only content already bounded by a valid string_body node. Numeric
    /// escapes may span the grammar's escape node and its following content node.
    pub(crate) fn quoted(text: &str, start: usize) -> Result<Self, String> {
        let mut result = Self {
            text: String::with_capacity(text.len()),
            origins: Vec::with_capacity(text.len()),
            end: start + text.len(),
        };
        let mut i = 0;
        while i < text.len() {
            let begin = i;
            let c = text[i..].chars().next().unwrap();
            i += c.len_utf8();
            if c == '\'' {
                if !text[i..].starts_with('\'') {
                    return Err("Unpaired apostrophe in body content".into());
                }
                i += 1;
                result.push('\'', start + begin..start + i);
            } else if c == '\\' {
                let escaped = text[i..].chars().next().ok_or("Incomplete escape")?;
                i += escaped.len_utf8();
                let decoded = match escaped {
                    'n' => '\n',
                    'r' => '\r',
                    't' => '\t',
                    'b' => '\u{8}',
                    'f' => '\u{c}',
                    'x' | 'u' => {
                        let count = if escaped == 'x' { 2 } else { 4 };
                        let digits = text.get(i..i + count).ok_or("Incomplete numeric escape")?;
                        let value = u32::from_str_radix(digits, 16)
                            .map_err(|_| "Invalid numeric escape")?;
                        i += count;
                        if escaped == 'x' && value > 0x7f {
                            return Err("Non-ASCII hexadecimal escape is not supported; use a Unicode escape".into());
                        }
                        char::from_u32(value).ok_or("Escape is not a Unicode scalar value")?
                    }
                    '0'..='7' => {
                        let mut value = escaped.to_digit(8).unwrap();
                        let mut count = 1;
                        while count < 3 {
                            let Some(digit) = text[i..].chars().next().and_then(|c| c.to_digit(8))
                            else {
                                break;
                            };
                            value = value * 8 + digit;
                            i += 1;
                            count += 1;
                        }
                        if (count != 3 && !(escaped == '0' && count == 1)) || value > 0x7f {
                            return Err("Expected a three-digit ASCII octal escape or \\0".into());
                        }
                        char::from_u32(value).ok_or("Invalid octal escape")?
                    }
                    // Snowflake discards the backslash for unrecognized escapes.
                    other => other,
                };
                result.push(decoded, start + begin..start + i);
            } else {
                result.text.push(c);
                result
                    .origins
                    .extend((start + begin..start + i).map(|j| j..j + 1));
            }
        }
        Ok(result)
    }

    fn push(&mut self, c: char, origin: Range<usize>) {
        self.text.push(c);
        self.origins
            .extend(std::iter::repeat_n(origin, c.len_utf8()));
    }
}

/// A zero-based row and UTF-8 byte column, matching tree-sitter coordinates.
pub fn source_point(sql: &str, offset: usize) -> Option<tree_sitter::Point> {
    let prefix = sql.as_bytes().get(..offset)?;
    let row = prefix.iter().filter(|&&b| b == b'\n').count();
    let column = prefix
        .iter()
        .rposition(|&b| b == b'\n')
        .map_or(offset, |i| offset - i - 1);
    Some(tree_sitter::Point::new(row, column))
}
