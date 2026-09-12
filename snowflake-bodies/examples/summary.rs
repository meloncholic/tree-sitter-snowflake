//! Summarize local SQL files without printing source text or identifiers.
use snowflake_bodies::{Analyzer, BodyStatus};
use std::{collections::BTreeMap, error::Error, fs, path::PathBuf};

fn main() -> Result<(), Box<dyn Error>> {
    let mut pending: Vec<PathBuf> = std::env::args_os().skip(1).map(PathBuf::from).collect();
    if pending.is_empty() {
        return Err("usage: summary <SQL file or corpus directory> ...".into());
    }
    let mut analyzer = Analyzer::new()?;
    let mut files = 0;
    let mut sql_failures = 0;
    let mut statuses = BTreeMap::<String, usize>::new();
    let mut rules = BTreeMap::<&str, usize>::new();
    while let Some(path) = pending.pop() {
        let metadata = fs::symlink_metadata(&path)?;
        if metadata.is_symlink() {
            continue;
        }
        if metadata.is_dir() {
            for entry in fs::read_dir(path)? {
                pending.push(entry?.path());
            }
            continue;
        }
        if !path
            .extension()
            .is_some_and(|e| e.eq_ignore_ascii_case("sql"))
        {
            continue;
        }
        let bytes = fs::read(path)?;
        let sql = decode(&bytes)?;
        let result = analyzer.analyze(&sql)?;
        files += 1;
        sql_failures += usize::from(!result.sql_errors.is_empty());
        for body in result.bodies {
            *statuses
                .entry(format!("{:?}: {:?}", body.language, body.status))
                .or_default() += 1;
            if body.status == BodyStatus::Parsed {
                let source = body.source.as_ref().unwrap();
                for finding in &body.findings {
                    assert!(sql.get(finding.range.clone()).is_some());
                }
                assert!(source.source_offset(source.text().len()).unwrap() <= sql.len());
            }
            for finding in body.findings {
                *rules.entry(finding.rule_id).or_default() += 1;
            }
        }
        for finding in result.findings {
            *rules.entry(finding.rule_id).or_default() += 1;
        }
    }
    println!("SQL files: {files}; files with SQL syntax errors: {sql_failures}");
    for (status, count) in statuses {
        println!("{status}: {count}");
    }
    for (rule, count) in rules {
        println!("{rule}: {count}");
    }
    Ok(())
}

fn decode(bytes: &[u8]) -> Result<String, Box<dyn Error>> {
    if bytes.starts_with(&[0xff, 0xfe]) || bytes.starts_with(&[0xfe, 0xff]) {
        if !bytes.len().is_multiple_of(2) {
            return Err("Odd-length UTF-16 input".into());
        }
        let little_endian = bytes[0] == 0xff;
        let units: Vec<_> = bytes[2..]
            .as_chunks::<2>()
            .0
            .iter()
            .map(|b| {
                if little_endian {
                    u16::from_le_bytes([b[0], b[1]])
                } else {
                    u16::from_be_bytes([b[0], b[1]])
                }
            })
            .collect();
        Ok(String::from_utf16(&units)?)
    } else {
        Ok(
            std::str::from_utf8(bytes.strip_prefix(&[0xef, 0xbb, 0xbf]).unwrap_or(bytes))?
                .to_owned(),
        )
    }
}
