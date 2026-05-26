use std::collections::BTreeMap;

use crate::run_php;

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

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PhptExpectationKind {
    Exact,
    Format,
    Regex,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PhptFileKind {
    File,
    FileEof,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PhptFile<'a> {
    pub kind: PhptFileKind,
    pub body: &'a str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PhptExpectation<'a> {
    pub kind: PhptExpectationKind,
    pub body: &'a str,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptHarnessInput {
    pub name: Option<String>,
    pub file: String,
    pub file_kind: PhptFileKind,
    pub expectation_kind: PhptExpectationKind,
    pub expectation_body: String,
    pub metadata: PhptMetadata,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PhptRunStatus {
    Pass,
    Fail,
    Xfail,
    UnexpectedPass,
    Unsupported { reason: String },
    Error { reason: String },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PhptRunReport {
    pub status: PhptRunStatus,
    pub expected_stdout: Option<String>,
    pub actual_stdout: Option<String>,
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

    pub fn fileeof(&self) -> Option<&str> {
        self.section("FILEEOF")
    }

    pub fn source_file(&self) -> Option<PhptFile<'_>> {
        if let Some(body) = self.file() {
            return Some(PhptFile {
                kind: PhptFileKind::File,
                body,
            });
        }
        self.fileeof().map(|body| PhptFile {
            kind: PhptFileKind::FileEof,
            body,
        })
    }

    pub fn expect(&self) -> Option<&str> {
        self.section("EXPECT")
    }

    pub fn expectf(&self) -> Option<&str> {
        self.section("EXPECTF")
    }

    pub fn expectregex(&self) -> Option<&str> {
        self.section("EXPECTREGEX")
    }

    pub fn expectation(&self) -> Option<PhptExpectation<'_>> {
        for (section_name, kind) in [
            ("EXPECT", PhptExpectationKind::Exact),
            ("EXPECTF", PhptExpectationKind::Format),
            ("EXPECTREGEX", PhptExpectationKind::Regex),
        ] {
            if let Some(body) = self.section(section_name) {
                return Some(PhptExpectation { kind, body });
            }
        }
        None
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
        let file = self.source_file().ok_or_else(|| {
            "cannot build .phpt harness input without FILE or FILEEOF section".to_string()
        })?;
        let expectation = self.expectation().ok_or_else(|| {
            "cannot build .phpt harness input without EXPECT, EXPECTF, or EXPECTREGEX section"
                .to_string()
        })?;

        Ok(PhptHarnessInput {
            name: self.test_name().map(str::to_string),
            file: file.body.to_string(),
            file_kind: file.kind,
            expectation_kind: expectation.kind,
            expectation_body: expectation.body.to_string(),
            metadata: self.metadata(),
        })
    }
}

pub fn run_phpt_with_phpc(test: &PhptTest) -> PhptRunReport {
    let metadata = test.metadata();
    let file = match test.file() {
        Some(file) => file,
        None => {
            return PhptRunReport {
                status: PhptRunStatus::Error {
                    reason: "cannot run .phpt without FILE section".to_string(),
                },
                expected_stdout: None,
                actual_stdout: None,
                metadata,
            }
        }
    };
    let expectation = match test.expectation() {
        Some(expectation) => expectation,
        None => {
            return PhptRunReport {
                status: PhptRunStatus::Error {
                    reason: "cannot run .phpt without EXPECT, EXPECTF, or EXPECTREGEX section"
                        .to_string(),
                },
                expected_stdout: None,
                actual_stdout: None,
                metadata,
            }
        }
    };

    if expectation.kind != PhptExpectationKind::Exact {
        let section = match expectation.kind {
            PhptExpectationKind::Exact => unreachable!(),
            PhptExpectationKind::Format => "EXPECTF",
            PhptExpectationKind::Regex => "EXPECTREGEX",
        };
        return PhptRunReport {
            status: PhptRunStatus::Unsupported {
                reason: format!("{section} matching is not implemented for phpc .phpt runs"),
            },
            expected_stdout: None,
            actual_stdout: None,
            metadata,
        };
    }

    let expected_stdout = normalize_phpt_output(expectation.body);
    let actual_stdout = match run_php(file) {
        Ok(output) => normalize_phpt_output(&output),
        Err(reason) => {
            return PhptRunReport {
                status: PhptRunStatus::Error { reason },
                expected_stdout: Some(expected_stdout),
                actual_stdout: None,
                metadata,
            }
        }
    };

    let matches = actual_stdout == expected_stdout;
    let status = match (matches, metadata.xfail.is_some()) {
        (true, false) => PhptRunStatus::Pass,
        (false, false) => PhptRunStatus::Fail,
        (false, true) => PhptRunStatus::Xfail,
        (true, true) => PhptRunStatus::UnexpectedPass,
    };

    PhptRunReport {
        status,
        expected_stdout: Some(expected_stdout),
        actual_stdout: Some(actual_stdout),
        metadata,
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
    validate_source_file_sections(&sections)?;
    validate_expectation_sections(&sections)?;

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

fn normalize_phpt_output(output: &str) -> String {
    output.replace("\r\n", "\n").replace('\r', "\n")
}

fn validate_expectation_sections(sections: &BTreeMap<String, String>) -> Result<(), String> {
    let expectation_count = ["EXPECT", "EXPECTF", "EXPECTREGEX"]
        .iter()
        .filter(|section| sections.contains_key(**section))
        .count();
    if expectation_count > 1 {
        return Err("multiple .phpt expectation sections".to_string());
    }
    Ok(())
}

fn validate_source_file_sections(sections: &BTreeMap<String, String>) -> Result<(), String> {
    if sections.contains_key("FILE") && sections.contains_key("FILEEOF") {
        return Err("multiple .phpt source file sections".to_string());
    }
    Ok(())
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
        assert_eq!(
            phpt.source_file(),
            Some(PhptFile {
                kind: PhptFileKind::File,
                body: "<?php echo \"ok\";\n"
            })
        );
        assert_eq!(phpt.expect(), Some("ok\n"));
        assert_eq!(
            phpt.expectation(),
            Some(PhptExpectation {
                kind: PhptExpectationKind::Exact,
                body: "ok\n"
            })
        );
        assert_eq!(phpt.skipif(), None);
    }

    #[test]
    fn parses_fileeof_source_section() {
        let phpt =
            parse_phpt("--TEST--\nfileeof\n--FILEEOF--\n<?php echo \"ok\";\n--EXPECT--\nok\n")
                .unwrap();

        assert_eq!(phpt.file(), None);
        assert_eq!(phpt.fileeof(), Some("<?php echo \"ok\";\n"));
        assert_eq!(
            phpt.source_file(),
            Some(PhptFile {
                kind: PhptFileKind::FileEof,
                body: "<?php echo \"ok\";\n"
            })
        );
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
    fn parses_format_expectation_section() {
        let phpt = parse_phpt(
            "--TEST--\nformat expectation\n--FILE--\n<?php echo __FILE__;\n--EXPECTF--\n%s.php\n",
        )
        .unwrap();

        assert_eq!(phpt.expect(), None);
        assert_eq!(phpt.expectf(), Some("%s.php\n"));
        assert_eq!(
            phpt.expectation(),
            Some(PhptExpectation {
                kind: PhptExpectationKind::Format,
                body: "%s.php\n"
            })
        );
    }

    #[test]
    fn parses_regex_expectation_section() {
        let phpt = parse_phpt(
            "--TEST--\nregex expectation\n--FILE--\n<?php echo 123;\n--EXPECTREGEX--\n/[0-9]+/\n",
        )
        .unwrap();

        assert_eq!(phpt.expectregex(), Some("/[0-9]+/\n"));
        assert_eq!(
            phpt.expectation(),
            Some(PhptExpectation {
                kind: PhptExpectationKind::Regex,
                body: "/[0-9]+/\n"
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
        assert_eq!(input.file_kind, PhptFileKind::File);
        assert_eq!(input.expectation_kind, PhptExpectationKind::Exact);
        assert_eq!(input.expectation_body, "ok\n");
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
    fn builds_harness_input_with_fileeof_source() {
        let phpt = parse_phpt(
            "--TEST--\nharness fileeof\n--FILEEOF--\n<?php echo \"ok\";\n--EXPECT--\nok\n",
        )
        .unwrap();

        let input = phpt.harness_input().unwrap();

        assert_eq!(input.file, "<?php echo \"ok\";\n");
        assert_eq!(input.file_kind, PhptFileKind::FileEof);
        assert_eq!(input.expectation_body, "ok\n");
    }

    #[test]
    fn builds_harness_input_with_non_exact_expectation() {
        let phpt = parse_phpt(
            "--TEST--\nharness input format\n--FILE--\n<?php echo __FILE__;\n--EXPECTF--\n%s.php\n",
        )
        .unwrap();

        let input = phpt.harness_input().unwrap();

        assert_eq!(input.expectation_kind, PhptExpectationKind::Format);
        assert_eq!(input.expectation_body, "%s.php\n");
        assert_eq!(input.metadata, phpt.metadata());
    }

    #[test]
    fn rejects_harness_input_without_expected_output() {
        let phpt = parse_phpt("--TEST--\nmissing expect\n--FILE--\n<?php echo \"ok\";\n").unwrap();

        let err = phpt.harness_input().unwrap_err();

        assert!(err.contains("EXPECT"));
    }

    #[test]
    fn rejects_harness_input_without_source_file() {
        let phpt = parse_phpt("--TEST--\nmissing file\n--EXPECT--\nok\n").unwrap();

        let err = phpt.harness_input().unwrap_err();

        assert!(err.contains("FILE or FILEEOF"));
    }

    #[test]
    fn rejects_multiple_expectation_sections() {
        let err = parse_phpt(
            "--TEST--\nambiguous\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok\n--EXPECTF--\n%s\n",
        )
        .unwrap_err();

        assert!(err.contains("multiple"));
    }

    #[test]
    fn rejects_multiple_source_file_sections() {
        let err = parse_phpt(
            "--TEST--\nambiguous source\n--FILE--\n<?php echo \"file\";\n--FILEEOF--\n<?php echo \"fileeof\";--EXPECT--\nfile\n",
        )
        .unwrap_err();

        assert!(err.contains("source file"));
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

    #[test]
    fn runs_exact_expectation_with_phpc() {
        let phpt = parse_phpt(
            "--TEST--\nrunnable echo\n--FILE--\n<?php echo 'hello'; echo \"\\n\";\n--EXPECT--\nhello\n",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt),
            PhptRunReport {
                status: PhptRunStatus::Pass,
                expected_stdout: Some("hello\n".to_string()),
                actual_stdout: Some("hello\n".to_string()),
                metadata: phpt.metadata(),
            }
        );
    }

    #[test]
    fn normalizes_line_endings_before_comparing_exact_expectation() {
        let phpt = parse_phpt(
            "--TEST--\ncrlf expectation\n--FILE--\n<?php echo \"hello\\n\";\n--EXPECT--\nhello\r\n",
        )
        .unwrap();

        assert_eq!(run_phpt_with_phpc(&phpt).status, PhptRunStatus::Pass);
    }

    #[test]
    fn reports_phpc_parse_errors_as_phpt_run_errors() {
        let phpt = parse_phpt(
            "--TEST--\nunsupported PHP\n--FILE--\n<?php var_dump(1);\n--EXPECT--\nint(1)\n",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt).status,
            PhptRunStatus::Error {
                reason: "unsupported PHP statement near `var_dump(1);\n`".to_string(),
            }
        );
    }

    #[test]
    fn reports_unsupported_expectation_matchers() {
        let phpt =
            parse_phpt("--TEST--\nformat\n--FILE--\n<?php echo '1';\n--EXPECTF--\n%d\n").unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt).status,
            PhptRunStatus::Unsupported {
                reason: "EXPECTF matching is not implemented for phpc .phpt runs".to_string(),
            }
        );
    }

    #[test]
    fn classifies_mismatched_xfail() {
        let phpt = parse_phpt(
            "--TEST--\nexpected fail\n--XFAIL--\nknown missing behavior\n--FILE--\n<?php echo \"actual\";\n--EXPECT--\nexpected\n",
        )
        .unwrap();

        let report = run_phpt_with_phpc(&phpt);

        assert_eq!(report.status, PhptRunStatus::Xfail);
        assert_eq!(
            report.metadata.xfail,
            Some(PhptXfail {
                reason: "known missing behavior".to_string()
            })
        );
    }

    #[test]
    fn classifies_matching_xfail_as_unexpected_pass() {
        let phpt = parse_phpt(
            "--TEST--\nunexpected pass\n--XFAIL--\nwas missing\n--FILE--\n<?php echo \"ok\";\n--EXPECT--\nok",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt).status,
            PhptRunStatus::UnexpectedPass
        );
    }
}
