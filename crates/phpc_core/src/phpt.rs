use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptTest {
    sections: BTreeMap<String, String>,
}

impl PhptTest {
    pub fn section(&self, name: &str) -> Option<&str> {
        self.sections
            .get(&normalize_section_name(name))
            .map(String::as_str)
    }

    pub fn test_name(&self) -> Option<&str> {
        self.section("TEST").map(str::trim)
    }

    pub fn file(&self) -> Option<&str> {
        self.section("FILE")
    }

    pub fn expect(&self) -> Option<&str> {
        self.section("EXPECT")
    }

    pub fn skipif(&self) -> Option<&str> {
        self.section("SKIPIF")
    }
}

pub fn parse_phpt(source: &str) -> Result<PhptTest, String> {
    let mut sections = BTreeMap::new();
    let mut current_name: Option<String> = None;
    let mut current_body = String::new();

    for line in source.split_inclusive('\n') {
        let line_without_ending = line.trim_end_matches(['\r', '\n']);
        if let Some(name) = parse_section_header(line_without_ending) {
            if let Some(previous_name) = current_name.replace(name) {
                insert_section(&mut sections, previous_name, std::mem::take(&mut current_body))?;
            }
            continue;
        }

        if current_name.is_some() {
            current_body.push_str(line);
        } else if !line_without_ending.trim().is_empty() {
            return Err("expected .phpt section header before content".to_string());
        }
    }

    if let Some(previous_name) = current_name {
        insert_section(&mut sections, previous_name, current_body)?;
    }

    if sections.is_empty() {
        return Err("expected at least one .phpt section".to_string());
    }

    Ok(PhptTest { sections })
}

fn parse_section_header(line: &str) -> Option<String> {
    let name = line.strip_prefix("--")?.strip_suffix("--")?;
    if name.is_empty() || !name.chars().all(|ch| ch.is_ascii_uppercase() || ch == '_') {
        return None;
    }
    Some(name.to_string())
}

fn insert_section(
    sections: &mut BTreeMap<String, String>,
    name: String,
    body: String,
) -> Result<(), String> {
    if sections.insert(name.clone(), body).is_some() {
        return Err(format!("duplicate .phpt section `{name}`"));
    }
    Ok(())
}

fn normalize_section_name(name: &str) -> String {
    name.trim().to_ascii_uppercase()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_required_core_sections() {
        let phpt = parse_phpt(
            "--TEST--\nminimal echo\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok\n",
        )
        .unwrap();

        assert_eq!(phpt.test_name(), Some("minimal echo"));
        assert_eq!(phpt.file(), Some("<?php echo \"ok\";\n"));
        assert_eq!(phpt.expect(), Some("ok\n"));
        assert_eq!(phpt.skipif(), None);
    }

    #[test]
    fn parses_skipif_section() {
        let phpt = parse_phpt(
            "--TEST--\nskip example\n--SKIPIF--\n<?php die('skip reason'); ?>\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok\n",
        )
        .unwrap();

        assert_eq!(phpt.skipif(), Some("<?php die('skip reason'); ?>\n"));
    }

    #[test]
    fn rejects_content_before_first_section() {
        let err = parse_phpt("leading text\n--TEST--\nname\n").unwrap_err();
        assert!(err.contains("section header"));
    }

    #[test]
    fn rejects_duplicate_sections() {
        let err = parse_phpt("--TEST--\none\n--TEST--\ntwo\n").unwrap_err();
        assert!(err.contains("duplicate"));
    }
}
