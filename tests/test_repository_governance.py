from __future__ import annotations

import json
import re
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
            ".github/rulesets/main.json",
            ".github/rulesets/tags-v.json",
            "docs/operations/release-runbook.md",
            "scripts/apply-rulesets.sh",
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

        bug = self.read(".github/ISSUE_TEMPLATE/bug.yml")
        self.assertIn("- type/bug", bug)
        self.assertIn("id: scope", bug)
        self.assertIn("id: dependencies", bug)

    def test_ci_is_single_path_and_unsigned(self) -> None:
        workflow = self.read(".github/workflows/ci.yml")
        self.assertIn("macos-", workflow)
        self.assertNotIn("matrix:", workflow)
        self.assertIn("brew install xcodegen", workflow)
        self.assertIn("xcodegen generate", workflow)
        self.assertIn("git status --porcelain=v1 --untracked-files=all", workflow)
        self.assertIn("scripts/loop/verify-fast.sh", workflow)
        self.assertIn("scripts/loop/verify-focused.sh", workflow)
        self.assertIn("xcodebuild test", workflow)
        self.assertIn("generic/platform=iOS Simulator", workflow)
        self.assertIn("CODE_SIGNING_ALLOWED=NO", workflow)
        self.assertNotIn("DEVELOPMENT_TEAM", workflow)
        focused_index = workflow.index("scripts/loop/verify-focused.sh")
        test_index = workflow.index("xcodebuild test")
        self.assertLess(focused_index, test_index)
        self.assertNotIn("exit 0", workflow[focused_index:test_index])

    def test_policy_checks_main_provenance_secrets_and_templates(self) -> None:
        workflow = self.read(".github/workflows/policy.yml")
        self.assertNotIn("matrix:", workflow)
        self.assertIn("commits/$GITHUB_SHA/pulls", workflow)
        self.assertIn("merge_commit_sha == $sha", workflow)
        self.assertIn(".merged_at != null", workflow)
        self.assertIn("Direct push to main", workflow)
        self.assertIn("PRIVATE KEY", workflow)
        self.assertIn("gh[pousr]_", workflow)
        self.assertNotIn(":(exclude).github/workflows/policy.yml", workflow)
        self.assertIn("/issues/$issue_number", workflow)
        self.assertIn("issues: read", workflow)
        self.assertIn('has("pull_request")', workflow)
        self.assertIn('git diff --check "$BASE_SHA" "$HEAD_SHA"', workflow)
        self.assertIn("test_repository_governance.py", workflow)
        self_patterns = (
            re.compile(r"-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----"),
            re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}\b"),
            re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
            re.compile(r"(?i)\bAuthorization:\s*Bearer\s+[A-Za-z0-9._~-]{16,}"),
        )
        self.assertFalse(
            any(pattern.search(workflow) for pattern in self_patterns),
            "Secret patterns must scan policy.yml without matching their own definitions",
        )

    def test_direct_main_filter_requires_the_exact_merged_commit(self) -> None:
        sha = "a" * 40
        pulls = [
            {"state": "open", "merged_at": None, "merge_commit_sha": sha},
            {
                "state": "closed",
                "merged_at": "2026-07-11T00:00:00Z",
                "merge_commit_sha": "b" * 40,
            },
            {
                "state": "closed",
                "merged_at": "2026-07-11T00:00:00Z",
                "merge_commit_sha": sha,
            },
        ]
        completed = subprocess.run(
            [
                "jq",
                "--arg",
                "sha",
                sha,
                '[.[] | select(.state == "closed" and .merged_at != null and .merge_commit_sha == $sha)] | length',
            ],
            input=json.dumps(pulls),
            text=True,
            check=True,
            stdout=subprocess.PIPE,
        )
        self.assertEqual(completed.stdout.strip(), "1")

    def test_rulesets_protect_main_and_release_tags(self) -> None:
        main = json.loads(self.read(".github/rulesets/main.json"))
        tags = json.loads(self.read(".github/rulesets/tags-v.json"))

        self.assertEqual(main["target"], "branch")
        self.assertEqual(main["enforcement"], "active")
        self.assertIn("~DEFAULT_BRANCH", main["conditions"]["ref_name"]["include"])
        main_rules = {rule["type"]: rule for rule in main["rules"]}
        self.assertIn("pull_request", main_rules)
        self.assertIn("deletion", main_rules)
        self.assertIn("non_fast_forward", main_rules)
        required_checks = main_rules["required_status_checks"]["parameters"]
        self.assertEqual(
            {item["context"] for item in required_checks["required_status_checks"]},
            {"policy", "verify"},
        )

        self.assertEqual(tags["target"], "tag")
        self.assertEqual(tags["enforcement"], "active")
        self.assertIn("refs/tags/v*", tags["conditions"]["ref_name"]["include"])
        self.assertEqual({rule["type"] for rule in tags["rules"]}, {"deletion", "update"})

        installer = self.read("scripts/apply-rulesets.sh")
        self.assertIn("--method POST", installer)
        self.assertIn("--method PUT", installer)
        self.assertIn("rulesets/$ruleset_id", installer)

        runbook = self.read("docs/operations/release-runbook.md")
        self.assertIn("18800528", runbook)
        self.assertIn("18800529", runbook)

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
