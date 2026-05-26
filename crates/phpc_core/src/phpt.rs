use std::collections::BTreeMap;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptTest {
    sections: BTreeMap<String, String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptSkip {
    pub script: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptXfail {
    pub reason: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptMetadata {
    pub skip: Option<PhptSkip>,
    pub xfail: Option<PhptXfail>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptHarnessInput {
    pub name: Option<String>,
    pub file: String,
    pub expect: String,
    pub metadata: PhptMetadata,
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

    pub fn xfail(&self) -> Option<&str> {
        self.section("XFAIL")
    }

    pub fn metadata(&self) -> PhptMetadata {
        PhptMetadata {
            skip: self.skipif().map(|script| PhptSkip {
                script: script.to_string(),
            }),
            xfail: self.xfail().map(|reason| PhptXfail {
                reason: normalize_metadata_reason(reason),
            }),
        }
    }

    pub fn harness_input(&self) -> Result<PhptHarnessInput, String> {
        let file = self
            .file()
            .ok_or_else(|| "cannot build .phpt harness input without FILE section".to_string())?;
        let expect = self
            .expect()
            .ok_or_else(|| "cannot build .phpt harness input without EXPECT section".to_string())?;

        Ok(PhptHarnessInput {
            name: self.test_name().map(str::to_string),
            file: file.to_string(),
            expect: expect.to_string(),
            metadata: self.metadata(),
        })
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

fn normalize_metadata_reason(reason: &str) -> String {
    reason
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .collect::<Vec<_>>()
        .join("\n")
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
    fn exposes_skip_metadata_without_executing_skipif() {
        let phpt = parse_phpt(
            "--TEST--\nskip metadata\n--SKIPIF--\n<?php if (!extension_loaded('foo')) die('skip foo missing'); ?>\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok\n",
        )
        .unwrap();

        assert_eq!(
            phpt.metadata().skip,
            Some(PhptSkip {
                script: "<?php if (!extension_loaded('foo')) die('skip foo missing'); ?>\n"
                    .to_string()
            })
        );
    }

    #[test]
    fn parses_xfail_metadata_reason() {
        let phpt = parse_phpt(
            "--TEST--\nxfail example\n--XFAIL--\n  known upstream failure\n\n  requires ext/example\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok\n",
        )
        .unwrap();

        assert_eq!(
            phpt.xfail(),
            Some("  known upstream failure\n\n  requires ext/example\n")
        );
        assert_eq!(
            phpt.metadata().xfail,
            Some(PhptXfail {
                reason: "known upstream failure\nrequires ext/example".to_string()
            })
        );
    }

    #[test]
    fn builds_harness_input_with_static_metadata() {
        let phpt = parse_phpt(
            "--TEST--\nharness input\n--SKIPIF--\n<?php die('skip optional extension'); ?>\n--XFAIL--\nknown gap\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok\n",
        )
        .unwrap();

        let input = phpt.harness_input().unwrap();

        assert_eq!(input.name, Some("harness input".to_string()));
        assert_eq!(input.file, "<?php echo \"ok\";\n");
        assert_eq!(input.expect, "ok\n");
        assert_eq!(
            input.metadata.skip,
            Some(PhptSkip {
                script: "<?php die('skip optional extension'); ?>\n".to_string()
            })
        );
        assert_eq!(
            input.metadata.xfail,
            Some(PhptXfail {
                reason: "known gap".to_string()
            })
        );
    }

    #[test]
    fn rejects_harness_input_without_expected_output() {
        let phpt = parse_phpt("--TEST--\nmissing expect\n--FILE--\n<?php echo \"ok\";\n").unwrap();

        let err = phpt.harness_input().unwrap_err();

        assert!(err.contains("EXPECT section"));
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
