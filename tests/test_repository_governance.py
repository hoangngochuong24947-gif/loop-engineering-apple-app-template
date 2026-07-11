from __future__ import annotations

import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class RepositoryGovernanceTests(unittest.TestCase):
    issue_forms = (
        ".github/ISSUE_TEMPLATE/feature.yml",
        ".github/ISSUE_TEMPLATE/bug.yml",
        ".github/ISSUE_TEMPLATE/operations.yml",
        ".github/ISSUE_TEMPLATE/config.yml",
    )
    workflows = (
        ".github/workflows/ci.yml",
        ".github/workflows/policy.yml",
        ".github/workflows/release.yml",
    )

    def read(self, relative_path: str) -> str:
        return (ROOT / relative_path).read_text(encoding="utf-8")

    def test_governance_file_set_exists(self) -> None:
        required = {
            *self.issue_forms,
            *self.workflows,
            ".github/PULL_REQUEST_TEMPLATE.md",
            ".github/CODEOWNERS",
            "docs/operations/release-runbook.md",
        }
        missing = sorted(path for path in required if not (ROOT / path).is_file())
        self.assertEqual(missing, [])

    def test_yaml_files_parse(self) -> None:
        for relative_path in (*self.issue_forms, *self.workflows):
            with self.subTest(path=relative_path):
                subprocess.run(
                    [
                        "ruby",
                        "-e",
                        'require "yaml"; YAML.safe_load(STDIN.read, aliases: true)',
                    ],
                    input=self.read(relative_path),
                    text=True,
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                )

    def test_issue_forms_capture_loop_contract(self) -> None:
        for relative_path in self.issue_forms[:3]:
            form = self.read(relative_path)
            with self.subTest(path=relative_path):
                self.assertIn("body:", form)
                self.assertIn("id: outcome", form)
                self.assertIn("id: acceptance", form)
                self.assertIn("id: verification", form)
                self.assertIn("required: true", form)

        config = self.read(self.issue_forms[3])
        self.assertIn("blank_issues_enabled: false", config)

    def test_ci_is_single_path_and_unsigned(self) -> None:
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("macos-", workflow)
        self.assertNotIn("matrix:", workflow)
        self.assertIn("brew install xcodegen", workflow)
        self.assertIn("xcodegen generate", workflow)
        self.assertIn("git diff --exit-code", workflow)
        self.assertIn("scripts/loop/verify-fast.sh", workflow)
        self.assertIn("scripts/loop/verify-focused.sh", workflow)
        self.assertIn("xcodebuild test", workflow)
        self.assertIn("generic/platform=iOS Simulator", workflow)
        self.assertIn("CODE_SIGNING_ALLOWED=NO", workflow)
        self.assertNotIn("DEVELOPMENT_TEAM", workflow)

    def test_policy_checks_main_provenance_secrets_and_templates(self) -> None:
        workflow = self.read(".github/workflows/policy.yml")
        self.assertNotIn("matrix:", workflow)
        self.assertIn("commits/$GITHUB_SHA/pulls", workflow)
        self.assertIn("Direct push to main", workflow)
        self.assertIn("PRIVATE KEY", workflow)
        self.assertIn("gh[pousr]_", workflow)
        self.assertIn("test_repository_governance.py", workflow)

    def test_release_is_tag_only_source_prerelease(self) -> None:
        workflow = self.read(".github/workflows/release.yml")
        self.assertIn("- 'v*'", workflow)
        self.assertNotIn("workflow_dispatch", workflow)
        self.assertNotIn("matrix:", workflow)
        self.assertIn("git archive", workflow)
        self.assertIn("shasum -a 256", workflow)
        self.assertIn("Known limitations", workflow)
        self.assertIn("Rollback reference", workflow)
        self.assertIn("gh release create", workflow)
        self.assertIn("--prerelease", workflow)
        self.assertNotIn("codesign", workflow.lower())
        self.assertNotIn("notary", workflow.lower())


if __name__ == "__main__":
    unittest.main()
