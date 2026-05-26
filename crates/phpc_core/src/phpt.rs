use std::collections::BTreeMap;
use std::path::Path;

use crate::{run_php, run_php_with_base_dir};

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
    Skip { reason: String },
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
    run_phpt_with_phpc_base_dir(test, None)
}

pub fn run_phpt_with_phpc_in_dir(test: &PhptTest, base_dir: &Path) -> PhptRunReport {
    run_phpt_with_phpc_base_dir(test, Some(base_dir))
}

fn run_phpt_with_phpc_base_dir(test: &PhptTest, base_dir: Option<&Path>) -> PhptRunReport {
    let metadata = test.metadata();
    if let Some(skip) = metadata.skip.as_ref() {
        match classify_skipif(&skip.script) {
            Ok(Some(reason)) => {
                return PhptRunReport {
                    status: PhptRunStatus::Skip { reason },
                    expected_stdout: None,
                    actual_stdout: None,
                    metadata,
                }
            }
            Ok(None) => {}
            Err(reason) => {
                return PhptRunReport {
                    status: PhptRunStatus::Error { reason },
                    expected_stdout: None,
                    actual_stdout: None,
                    metadata,
                }
            }
        }
    }

    let file = match test.source_file() {
        Some(file) => file,
        None => {
            return PhptRunReport {
                status: PhptRunStatus::Error {
                    reason: "cannot run .phpt without FILE or FILEEOF section".to_string(),
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

    if expectation.kind == PhptExpectationKind::Regex {
        return PhptRunReport {
            status: PhptRunStatus::Unsupported {
                reason: "EXPECTREGEX matching is not implemented for phpc .phpt runs".to_string(),
            },
            expected_stdout: None,
            actual_stdout: None,
            metadata,
        };
    }

    let expected_stdout = normalize_phpt_output(expectation.body);
    let actual_stdout = match run_php_with_base_dir(file.body, base_dir) {
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

    let matches = expectation_matches(expectation.kind, &expected_stdout, &actual_stdout);
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

fn classify_skipif(script: &str) -> Result<Option<String>, String> {
    let output = normalize_phpt_output(&run_php(script)?);
    let reason = output.trim();
    if reason
        .get(..4)
        .is_some_and(|prefix| prefix.eq_ignore_ascii_case("skip"))
    {
        return Ok(Some(reason.to_string()));
    }
    Ok(None)
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
    output
        .replace("\r\n", "\n")
        .replace('\r', "\n")
        .trim_matches(is_php_trim_whitespace)
        .to_string()
}

fn is_php_trim_whitespace(ch: char) -> bool {
    matches!(ch, ' ' | '\t' | '\n' | '\r' | '\0' | '\x0B')
}

fn expectation_matches(kind: PhptExpectationKind, expected: &str, actual: &str) -> bool {
    match kind {
        PhptExpectationKind::Exact => actual == expected,
        PhptExpectationKind::Format => expectf_matches(expected, actual),
        PhptExpectationKind::Regex => false,
    }
}

fn expectf_matches(pattern: &str, actual: &str) -> bool {
    let tokens = expectf_tokens(pattern);
    match_expectf_tokens(&tokens, 0, actual, 0)
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum ExpectfToken {
    Literal(String),
    NonEmptyStringNoNewline,
    StringNoNewline,
    NonEmptyString,
    String,
    Whitespace,
    Digits,
    Integer,
    Hex,
    Float,
    Char,
    DirectorySeparator,
    Nul,
}

fn expectf_tokens(pattern: &str) -> Vec<ExpectfToken> {
    let mut tokens = Vec::new();
    let mut literal = String::new();
    let mut chars = pattern.chars().peekable();

    while let Some(ch) = chars.next() {
        if ch != '%' {
            literal.push(ch);
            continue;
        }

        let Some(specifier) = chars.next() else {
            literal.push('%');
            break;
        };

        let token = match specifier {
            '%' => {
                literal.push('%');
                continue;
            }
            's' => ExpectfToken::NonEmptyStringNoNewline,
            'S' => ExpectfToken::StringNoNewline,
            'a' => ExpectfToken::NonEmptyString,
            'A' => ExpectfToken::String,
            'w' => ExpectfToken::Whitespace,
            'd' => ExpectfToken::Digits,
            'i' => ExpectfToken::Integer,
            'x' => ExpectfToken::Hex,
            'f' => ExpectfToken::Float,
            'c' => ExpectfToken::Char,
            'e' => ExpectfToken::DirectorySeparator,
            '0' => ExpectfToken::Nul,
            other => {
                literal.push('%');
                literal.push(other);
                continue;
            }
        };

        if !literal.is_empty() {
            tokens.push(ExpectfToken::Literal(std::mem::take(&mut literal)));
        }
        tokens.push(token);
    }

    if !literal.is_empty() {
        tokens.push(ExpectfToken::Literal(literal));
    }

    tokens
}

fn match_expectf_tokens(
    tokens: &[ExpectfToken],
    token_index: usize,
    actual: &str,
    actual_index: usize,
) -> bool {
    if token_index == tokens.len() {
        return actual_index == actual.len();
    }

    match &tokens[token_index] {
        ExpectfToken::Literal(literal) => actual[actual_index..]
            .strip_prefix(literal)
            .is_some_and(|_| {
                match_expectf_tokens(
                    tokens,
                    token_index + 1,
                    actual,
                    actual_index + literal.len(),
                )
            }),
        ExpectfToken::NonEmptyStringNoNewline => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| !text.is_empty() && !text.contains('\n'),
        ),
        ExpectfToken::StringNoNewline => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| !text.contains('\n'),
        ),
        ExpectfToken::NonEmptyString => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| !text.is_empty(),
        ),
        ExpectfToken::String => {
            match_variable_width(tokens, token_index, actual, actual_index, |_| true)
        }
        ExpectfToken::Whitespace => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| text.chars().all(char::is_whitespace),
        ),
        ExpectfToken::Digits => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| !text.is_empty() && text.chars().all(|ch| ch.is_ascii_digit()),
        ),
        ExpectfToken::Integer => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| {
                let digits = if let Some(rest) =
                    text.strip_prefix('+').or_else(|| text.strip_prefix('-'))
                {
                    rest
                } else {
                    text
                };
                !digits.is_empty() && digits.chars().all(|ch| ch.is_ascii_digit())
            },
        ),
        ExpectfToken::Hex => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            |text| !text.is_empty() && text.chars().all(|ch| ch.is_ascii_hexdigit()),
        ),
        ExpectfToken::Float => match_variable_width(
            tokens,
            token_index,
            actual,
            actual_index,
            is_php_run_tests_float,
        ),
        ExpectfToken::Char => actual[actual_index..].chars().next().is_some_and(|ch| {
            match_expectf_tokens(
                tokens,
                token_index + 1,
                actual,
                actual_index + ch.len_utf8(),
            )
        }),
        ExpectfToken::DirectorySeparator => actual[actual_index..]
            .strip_prefix(std::path::MAIN_SEPARATOR)
            .is_some_and(|_| {
                match_expectf_tokens(
                    tokens,
                    token_index + 1,
                    actual,
                    actual_index + std::path::MAIN_SEPARATOR.len_utf8(),
                )
            }),
        ExpectfToken::Nul => actual[actual_index..].strip_prefix('\0').is_some_and(|_| {
            match_expectf_tokens(tokens, token_index + 1, actual, actual_index + 1)
        }),
    }
}

fn is_php_run_tests_float(text: &str) -> bool {
    let mut rest = text
        .strip_prefix('+')
        .or_else(|| text.strip_prefix('-'))
        .unwrap_or(text);

    let leading_digits = leading_ascii_digit_count(rest);
    rest = &rest[leading_digits..];

    if let Some(after_dot) = rest.strip_prefix('.') {
        let fraction_digits = leading_ascii_digit_count(after_dot);
        if fraction_digits == 0 {
            return false;
        }
        rest = &after_dot[fraction_digits..];
    } else if leading_digits == 0 {
        return false;
    }

    if let Some(after_marker) = rest.strip_prefix('E').or_else(|| rest.strip_prefix('e')) {
        let exponent = after_marker
            .strip_prefix('+')
            .or_else(|| after_marker.strip_prefix('-'))
            .unwrap_or(after_marker);
        let exponent_digits = leading_ascii_digit_count(exponent);
        if exponent_digits == 0 {
            return false;
        }
        rest = &exponent[exponent_digits..];
    }

    rest.is_empty()
}

fn leading_ascii_digit_count(text: &str) -> usize {
    text.char_indices()
        .find_map(|(index, ch)| (!ch.is_ascii_digit()).then_some(index))
        .unwrap_or(text.len())
}

fn match_variable_width(
    tokens: &[ExpectfToken],
    token_index: usize,
    actual: &str,
    actual_index: usize,
    accepts: impl Fn(&str) -> bool,
) -> bool {
    for end_index in char_boundary_indices_from(actual, actual_index) {
        let candidate = &actual[actual_index..end_index];
        if accepts(candidate) && match_expectf_tokens(tokens, token_index + 1, actual, end_index) {
            return true;
        }
    }
    false
}

fn char_boundary_indices_from(text: &str, start: usize) -> Vec<usize> {
    let mut indices = vec![start];
    indices.extend(
        text[start..]
        .char_indices()
        .skip(1)
            .map(|(index, _)| start + index),
    );
    indices.push(text.len());
    indices
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
    fn classifies_skipif_output_as_skipped() {
        let phpt = parse_phpt(
            "--TEST--\nskipped test\n--SKIPIF--\n<?php echo 'skip optional extension';\n--FILE--\n<?php var_dump(1);\n--EXPECT--\nint(1)\n",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt),
            PhptRunReport {
                status: PhptRunStatus::Skip {
                    reason: "skip optional extension".to_string(),
                },
                expected_stdout: None,
                actual_stdout: None,
                metadata: phpt.metadata(),
            }
        );
    }

    #[test]
    fn continues_when_skipif_output_is_empty() {
        let phpt = parse_phpt(
            "--TEST--\nnot skipped\n--SKIPIF--\n<?php echo '';\n--FILE--\n<?php echo 'ok';\n--EXPECT--\nok",
        )
        .unwrap();

        assert_eq!(run_phpt_with_phpc(&phpt).status, PhptRunStatus::Pass);
    }

    #[test]
    fn reports_skipif_phpc_errors_as_phpt_run_errors() {
        let phpt = parse_phpt(
            "--TEST--\nunsupported skipif\n--SKIPIF--\n<?php if (true) echo 'skip';\n--FILE--\n<?php echo 'ok';\n--EXPECT--\nok",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt).status,
            PhptRunStatus::Error {
                reason: "unsupported PHP statement near `if (true) echo 'skip';\n`".to_string(),
            }
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
                expected_stdout: Some("hello".to_string()),
                actual_stdout: Some("hello".to_string()),
                metadata: phpt.metadata(),
            }
        );
    }

    #[test]
    fn runs_fileeof_exact_expectation_with_phpc() {
        let phpt = parse_phpt(
            "--TEST--\nrunnable fileeof echo\n--FILEEOF--\n<?php echo 'hello'; echo \"\\n\";\n--EXPECT--\nhello\n",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt),
            PhptRunReport {
                status: PhptRunStatus::Pass,
                expected_stdout: Some("hello".to_string()),
                actual_stdout: Some("hello".to_string()),
                metadata: phpt.metadata(),
            }
        );
    }

    #[test]
    fn runs_file_body_with_relative_require_from_base_dir() {
        let dir = unique_temp_dir("phpc-phpt-base-dir");
        let _ = std::fs::remove_dir_all(&dir);
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join("inc.php"), "<?php echo 'include';").unwrap();
        let phpt = parse_phpt(
            "--TEST--\nrelative require\n--FILE--\n<?php echo 'before-'; require 'inc.php'; echo '-after';\n--EXPECT--\nbefore-include-after\n",
        )
        .unwrap();

        let report = run_phpt_with_phpc_in_dir(&phpt, &dir);

        let _ = std::fs::remove_dir_all(&dir);
        assert_eq!(
            report,
            PhptRunReport {
                status: PhptRunStatus::Pass,
                expected_stdout: Some("before-include-after".to_string()),
                actual_stdout: Some("before-include-after".to_string()),
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
    fn trims_run_tests_section_newline_before_comparing_exact_expectation() {
        let phpt = parse_phpt(
            "--TEST--\nphp-src basic 001 shape\n--FILE--\n<?php echo \"Hello World\"?>\n--EXPECT--\nHello World\n",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt),
            PhptRunReport {
                status: PhptRunStatus::Pass,
                expected_stdout: Some("Hello World".to_string()),
                actual_stdout: Some("Hello World".to_string()),
                metadata: phpt.metadata(),
            }
        );
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
            parse_phpt("--TEST--\nregex\n--FILE--\n<?php echo '1';\n--EXPECTREGEX--\n/[0-9]+/\n")
                .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt).status,
            PhptRunStatus::Unsupported {
                reason: "EXPECTREGEX matching is not implemented for phpc .phpt runs".to_string(),
            }
        );
    }

    #[test]
    fn runs_expectf_expectation_with_phpc() {
        let phpt =
            parse_phpt("--TEST--\nformat\n--FILE--\n<?php echo 'item 123';\n--EXPECTF--\n%s %d")
                .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt),
            PhptRunReport {
                status: PhptRunStatus::Pass,
                expected_stdout: Some("%s %d".to_string()),
                actual_stdout: Some("item 123".to_string()),
                metadata: phpt.metadata(),
            }
        );
    }

    #[test]
    fn runs_fileeof_expectf_expectation_with_phpc() {
        let phpt =
            parse_phpt("--TEST--\nformat fileeof\n--FILEEOF--\n<?php echo 'item 123';\n--EXPECTF--\n%s %d")
                .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt),
            PhptRunReport {
                status: PhptRunStatus::Pass,
                expected_stdout: Some("%s %d".to_string()),
                actual_stdout: Some("item 123".to_string()),
                metadata: phpt.metadata(),
            }
        );
    }

    #[test]
    fn reports_expectf_mismatch_as_failure() {
        let phpt =
            parse_phpt("--TEST--\nformat fail\n--FILE--\n<?php echo 'item abc';\n--EXPECTF--\n%s %d")
                .unwrap();

        assert_eq!(run_phpt_with_phpc(&phpt).status, PhptRunStatus::Fail);
    }

    #[test]
    fn expectf_uppercase_string_tokens_allow_empty_matches() {
        assert!(expectf_matches("prefix%Ssuffix", "prefixsuffix"));
        assert!(expectf_matches("prefix%Asuffix", "prefixsuffix"));
    }

    #[test]
    fn expectf_whitespace_token_allows_empty_match() {
        assert!(expectf_matches("left%wright", "leftright"));
        assert!(expectf_matches("left%wright", "left \n\tright"));
    }

    #[test]
    fn expectf_directory_separator_and_nul_tokens_match_literals() {
        let pattern = format!("root%edir%0end");
        let actual = format!("root{}dir\0end", std::path::MAIN_SEPARATOR);

        assert!(expectf_matches(&pattern, &actual));
    }

    #[test]
    fn expectf_lowercase_string_tokens_reject_empty_matches() {
        assert!(!expectf_matches("prefix%ssuffix", "prefixsuffix"));
        assert!(!expectf_matches("prefix%asuffix", "prefixsuffix"));
    }

    #[test]
    fn expectf_float_token_uses_php_run_tests_shape() {
        assert!(expectf_matches("%f", "1"));
        assert!(expectf_matches("%f", "1.0"));
        assert!(expectf_matches("%f", ".5"));
        assert!(expectf_matches("%f", "-12.345"));
        assert!(expectf_matches("%f", "6.02E+23"));
        assert!(!expectf_matches("%f", "NaN"));
        assert!(!expectf_matches("%f", "inf"));
        assert!(!expectf_matches("%f", "1."));
        assert!(!expectf_matches("%f", "."));
    }

    #[test]
    fn classifies_mismatched_expectf_xfail() {
        let phpt = parse_phpt(
            "--TEST--\nformat xfail\n--XFAIL--\nknown format mismatch\n--FILE--\n<?php echo 'item abc';\n--EXPECTF--\n%s %d",
        )
        .unwrap();

        assert_eq!(run_phpt_with_phpc(&phpt).status, PhptRunStatus::Xfail);
    }

    #[test]
    fn classifies_matching_expectf_xfail_as_unexpected_pass() {
        let phpt = parse_phpt(
            "--TEST--\nformat unexpected pass\n--XFAIL--\nwas missing\n--FILE--\n<?php echo 'item 123';\n--EXPECTF--\n%s %d",
        )
        .unwrap();

        assert_eq!(
            run_phpt_with_phpc(&phpt).status,
            PhptRunStatus::UnexpectedPass
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

    fn unique_temp_dir(prefix: &str) -> std::path::PathBuf {
        let nanos = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("system time after epoch")
            .as_nanos();
        std::env::temp_dir().join(format!("{prefix}-{}-{nanos}", std::process::id()))
    }
}
