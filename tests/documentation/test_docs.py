import fnmatch
import json
import re
import subprocess
import sys
import tempfile
import unittest
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

import markdown
import yaml
from mkdocs.exceptions import PluginError

from docs.hooks import PAGE_ALIASES, RepositoryLinksExtension


ROOT = Path(__file__).resolve().parents[2]
SITE_URL = "https://davidmcwee.com/labs/"
PORTAL_TEMPLATE_PREFIX = "https://portal.azure.com/#create/Microsoft.Template/uri/"
PUBLISHED_TEMPLATE_ROOT = "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/published/"
DEPLOYMENT_ARTIFACTS = {
    "Defender": "dev/Defender/lab.json",
    "MDELab": "pub/MDELab/mdelab.json",
    "MDILab": "pub/MDILab/mdilab.json",
    "Linux": "pub/Linux/linux.json",
    "OceanLotus": "pub/OceanLotus/OceanLotus.json",
}
LAB_GUIDES = {
    "Defender": ("lab.bicep", [
        ("LabAd", "2022-Datacenter", "10.0.2.5"),
        ("LabSubAd", "2022-Datacenter", "10.0.2.6"),
        ("WinClient11", "win11-23h2-ent", "10.0.2.40"),
        ("Win2016", "2016-Datacenter", "10.0.2.50"),
        ("Win2022", "2022-Datacenter", "10.0.2.51"),
        ("LinuxUbuntu", "22_04-lts-gen2", "10.0.2.52"),
    ]),
    "MDELab": ("mdelab.bicep", [
        ("LabAd", "2022-Datacenter", "10.0.2.5"),
        ("Win2016", "2016-Datacenter", "10.0.2.50"),
        ("Win2022", "2022-Datacenter", "10.0.2.51"),
        ("LinuxUbuntu", "22_04-lts-gen2", "10.0.2.52"),
        ("WinClient11", "win11-23h2-ent", "10.0.2.53"),
    ]),
    "MDILab": ("mdilab.bicep", [
        ("LabSubAd1", "2022-Datacenter", "10.0.2.15"),
        ("LabSubAd2", "2022-Datacenter", "10.0.2.16"),
        ("Win2022", "2022-Datacenter", "10.0.2.50"),
        ("WinClient11", "win11-23h2-ent", "10.0.2.51"),
    ]),
    "Linux": ("linux.bicep", [
        ("LinuxUbuntu", "22_04-lts-gen2", "10.0.2.50"),
        ("LinuxSuseOs1", "gen2", "10.0.2.51"),
    ]),
    "OceanLotus": ("OceanLotus.bicep", [
        ("vhagar", "2019-DataCenter", "10.90.30.20"),
        ("drogon", "22_04-lts-gen2", "10.90.30.7"),
        ("kali", "kali-2024-4", "10.90.30.26"),
    ]),
}
SCENARIO_GUIDES = {
    "MDELab": Path("Attacks") / "README.md",
    "MDILab": Path("Attacks") / "README.md",
    "Linux": Path("Scenarios") / "README.md",
    "OceanLotus": Path("Scenarios") / "README.md",
}


def first_table(section):
    rows = []
    for line in section.splitlines():
        if line.startswith("|"):
            rows.append([cell.strip().strip("`") for cell in line.strip("|").split("|")])
        elif rows:
            break
    return rows[2:]


class PublisherWorkflowTests(unittest.TestCase):
    def test_shared_gateway_updates_trigger_validated_serial_publication(self):
        workflow = yaml.load(
            (ROOT / ".github" / "workflows" / "main.yml").read_text(encoding="utf-8"),
            Loader=yaml.BaseLoader,
        )
        self.assertIn("workflow_dispatch", workflow["on"])
        self.assertEqual(workflow["on"]["push"]["branches"], ["dev", "master"])
        for source in (
            "Common/modules/network.bicep",
            ".github/workflows/main.yml",
            "tests/infrastructure/test_gateway_sku.py",
        ):
            with self.subTest(source=source):
                self.assertTrue(any(
                    fnmatch.fnmatchcase(source, pattern)
                    for pattern in workflow["on"]["push"]["paths"]
                ))
        self.assertEqual(workflow["concurrency"], {
            "group": "bicep-publish",
            "cancel-in-progress": "false",
        })
        job = workflow["jobs"]["build-and-push"]
        self.assertEqual(
            job["if"],
            "github.ref == 'refs/heads/dev' || github.ref == 'refs/heads/master'",
        )
        build = next(step for step in job["steps"] if step["name"] == "Build Bicep to ARM JSON")
        script = build["with"]["inlineScript"]
        self.assertTrue(script.startswith("set -e\n"))
        self.assertIn("python3 -m unittest discover -s tests/infrastructure", script)


class LabLandingPageTests(unittest.TestCase):
    def test_quick_deploy_and_portal_use_same_published_template(self):
        for name, artifact in DEPLOYMENT_ARTIFACTS.items():
            guide = (ROOT / name / "README.md").read_text(encoding="utf-8")
            quick_deploy = guide.split("## Quick Deploy\n", 1)[1].split(
                "\n## Deployment parameters", 1
            )[0]
            commands = re.findall(r'--template-uri "([^"]+)"', quick_deploy)
            buttons = [
                unquote(link.removeprefix(PORTAL_TEMPLATE_PREFIX))
                for link in PageLinks(markdown.markdown(quick_deploy)).links
                if link.startswith(PORTAL_TEMPLATE_PREFIX)
            ]
            with self.subTest(lab=name):
                self.assertEqual(commands, [PUBLISHED_TEMPLATE_ROOT + artifact])
                self.assertEqual(buttons, commands)
                self.assertNotIn("--template-file", quick_deploy)
                self.assertNotIn("Legacy deployment button", quick_deploy)

    def test_consistent_sections(self):
        expected = [
            "Quick Deploy", "Deployment parameters", "Deployed machines",
            "Network and access", "Post-deployment configuration", "Next steps",
        ]
        for name in LAB_GUIDES:
            with self.subTest(lab=name):
                guide = (ROOT / name / "README.md").read_text(encoding="utf-8")
                self.assertEqual(re.findall(r"^## (.+)$", guide, re.MULTILINE), expected)

    def test_parameter_names_and_defaults_match_bicep(self):
        for name, (entrypoint, _) in LAB_GUIDES.items():
            guide = (ROOT / name / "README.md").read_text(encoding="utf-8")
            bicep = (ROOT / name / "modules" / entrypoint).read_text(encoding="utf-8")
            section = guide.split("## Deployment parameters\n", 1)[1]
            documented = {row[0]: row[1] for row in first_table(section)}
            parameters = dict(re.findall(
                r"^param (\w+) string(?: = '([^']*)')?\s*$", bicep, re.MULTILINE
            ))
            with self.subTest(lab=name):
                self.assertEqual(set(documented), set(parameters))
                for parameter, default in parameters.items():
                    if default:
                        self.assertEqual(documented[parameter], default)
                    else:
                        self.assertIn("Required", documented[parameter])

    def test_machine_inventory(self):
        for name, (entrypoint, expected) in LAB_GUIDES.items():
            guide = (ROOT / name / "README.md").read_text(encoding="utf-8")
            bicep = (ROOT / name / "modules" / entrypoint).read_text(encoding="utf-8")
            section = guide.split("## Deployed machines\n", 1)[1]
            machines = [(row[0], row[2], row[3]) for row in first_table(section)]
            with self.subTest(lab=name):
                self.assertEqual(machines, expected)
                for machine, sku, ip in machines:
                    self.assertIn(f"'{machine}'", bicep)
                    self.assertIn(f"'{sku}'", bicep)
                    if f"'{ip}'" not in bicep:
                        self.assertIn("'10.0.2.${i+50}'", bicep)
                        array = re.search(
                            r"var (?:labServers|linuxServers) = \[(.*?)^\]",
                            bicep, re.MULTILINE | re.DOTALL,
                        ).group(1)
                        names = re.findall(r"name:\s*'([^']+)'", array)
                        self.assertEqual(ip, f"10.0.2.{names.index(machine) + 50}")

    def test_legacy_linux_inventory_is_separate(self):
        source = (ROOT / "Linux/azuredeploy.json").read_text(encoding="utf-8-sig")
        template = json.loads(re.sub(r"^\s*//.*$", "", source, flags=re.MULTILINE))
        guide = (ROOT / "docs/deployment-alignment.md").read_text(encoding="utf-8")
        legacy = guide.split("### Previous Linux ARM inventory\n", 1)[1]
        rows = first_table(legacy)
        expected = [
            (vm["Name"], vm["SKU"], f"10.0.2.{i + 30}")
            for i, vm in enumerate(template["variables"]["LinuxServers"])
        ]
        self.assertEqual([(row[0], row[2], row[3]) for row in rows], expected)


class ScenarioContextTests(unittest.TestCase):
    def test_active_scenarios_share_sections_and_parameter_format(self):
        core = [
            "Overview", "MITRE ATT&CK Mapping", "Attack Simulation", "Setup",
            "Scenario Execution", "Expected Alerts", "Why Does This Matter",
            "Best Practices", "Clean-Up",
        ]
        mandatory = {
            ("AccountOverPermissions.md", "UserName"),
            ("RemoteCodeExecution.md", "ComputerName"),
        }
        for lab in ("MDELab", "MDILab"):
            for path in (ROOT / lab / "Attacks").glob("*.md"):
                relative = path.relative_to(ROOT).as_posix()
                if path.name == "README.md" or relative in PAGE_ALIASES:
                    continue
                with self.subTest(path=relative):
                    guide = path.read_text(encoding="utf-8")
                    prose = re.sub(r"(?ms)^```.*?^```[^\n]*", "", guide)
                    headings = re.findall(r"^## (.+)$", prose, re.MULTILINE)
                    expected = core + [
                        name for name in ("Manual Commands", "References")
                        if name in headings
                    ]
                    self.assertEqual(headings, expected)
                    if path.name == "AccountAdvancedHunting.md":
                        self.assertNotIn("#### Parameters", guide)
                        continue
                    parameters = guide.split("#### Parameters\n", 1)[1]
                    header = next(line for line in parameters.splitlines() if line.startswith("|"))
                    self.assertEqual(
                        header, "| Parameter | Type | Required | Default | Description |",
                    )
                    rows = first_table(parameters)
                    self.assertTrue(rows)
                    for row in rows:
                        self.assertEqual(len(row), 5)
                        self.assertTrue(row[0].startswith("-"))
                        name = row[0].lstrip("-")
                        self.assertEqual(
                            row[2], "Yes" if (path.name, name) in mandatory else "No",
                        )
                        if row[1] == "Switch":
                            self.assertEqual(row[3], "Not set")

    def test_account_hunting_retains_manual_workflow_and_compatibility_anchors(self):
        guide = (ROOT / "MDELab" / "Attacks" / "AccountAdvancedHunting.md").read_text(
            encoding="utf-8",
        )
        for command in (
            "net user MdeHuntingTest * /add",
            "net localgroup Administrators MdeHuntingTest /add",
            "net user MdeHuntingTest /delete",
        ):
            self.assertIn(command, guide)
        self.assertIn("### Prerequisites", guide)
        self.assertIn("### Expected Output", guide)
        self.assertIn("### Create Custom Detection", guide)
        for anchor in ("scenario", "cleanup", "queries"):
            self.assertIn(f'<a id="{anchor}"></a>', guide)
        for number in range(1, 7):
            self.assertIn(f"CreateAccount-Query{number}.kql", guide)
        self.assertIn("CreateAccount-QueryFinal.kql", guide)

    def test_renamed_scenario_sections_retain_compatibility_anchors(self):
        honeytoken = (ROOT / "MDILab" / "Attacks" / "HoneytokenAccount.md").read_text(
            encoding="utf-8",
        )
        for anchor in (
            "expected-mdi-alerts", "why-honeytokens-are-effective",
            "best-practices-for-honeytoken-accounts", "detections",
        ):
            self.assertIn(f'<a id="{anchor}"></a>', honeytoken)
        for name in (
            "CredentialDumping.md", "EventLog.md", "PasswordDetection.md",
            "ServiceExecution.md",
        ):
            guide = (ROOT / "MDELab" / "Attacks" / name).read_text(encoding="utf-8")
            with self.subTest(guide=name):
                self.assertIn('<a id="additional-manual-commands"></a>', guide)

    def test_overviews_use_consistent_sections_and_deployment_inventory(self):
        headings = [
            "Deployment context", "Accounts and sign-in", "Machines and roles",
            "Before running a scenario", "Scenarios", "Cleanup",
        ]
        for name, relative in SCENARIO_GUIDES.items():
            with self.subTest(lab=name):
                guide = (ROOT / name / relative).read_text(encoding="utf-8")
                deployment = (ROOT / name / "README.md").read_text(encoding="utf-8")
                self.assertEqual(re.findall(r"^## (.+)$", guide, re.MULTILINE), headings)
                scenarios = first_table(guide.split("## Machines and roles\n", 1)[1])
                deployed = first_table(deployment.split("## Deployed machines\n", 1)[1])
                self.assertEqual(
                    [row[:4] for row in scenarios], [row[:4] for row in deployed],
                )
                self.assertIn("../README.md", guide)
                self.assertIn(f"../modules/{LAB_GUIDES[name][0]}", guide)
                self.assertIn(f"{relative.parent.as_posix()}/README.md", deployment)

    def test_account_and_domain_defaults_match_bicep(self):
        for name, relative in SCENARIO_GUIDES.items():
            with self.subTest(lab=name):
                guide = (ROOT / name / relative).read_text(encoding="utf-8")
                entrypoint = ROOT / name / "modules" / LAB_GUIDES[name][0]
                parameters = dict(re.findall(
                    r"^param (\w+) string(?: = '([^']*)')?\s*$",
                    entrypoint.read_text(encoding="utf-8"), re.MULTILINE,
                ))
                accounts = guide.split("## Accounts and sign-in\n", 1)[1].split("\n## ", 1)[0]
                if parameters["username"]:
                    self.assertIn(f'`{parameters["username"]}`', accounts)
                    self.assertIn(f'`.\\{parameters["username"]}`', accounts)
                else:
                    self.assertIn(
                        "no default administrator username",
                        " ".join(accounts.replace("**", "").lower().split()),
                    )
                context = guide.split("## Deployment context\n", 1)[1].split("\n## ", 1)[0]
                for parameter in (
                    "domainName", "domainNetbiosName",
                    "subDomain1", "subDomain2", "netbiosName1", "netbiosName2",
                ):
                    if parameter in parameters:
                        self.assertIn(f"`{parameter}`", context)
                        self.assertIn(f"`{parameters[parameter]}`", context)

    def test_hydrated_accounts_and_groups_match_script_and_landing_pages(self):
        script = (ROOT / "Common" / "DSC" / "DcHydrate.ps1").read_text(encoding="utf-8")
        definitions = re.findall(
            r'@\{\s*Name\s*=\s*"([^"]+)";\s*AccountName\s*=\s*"([^"]+)";'
            r'\s*Groups\s*=\s*@\(([^)]*)\)\s*\}', script,
        )
        self.assertTrue(definitions, "No hydration account definitions found")
        expected = []
        for display, account, groups in definitions:
            memberships = re.findall(r'"([^"]+)"', groups)
            expected.append([display, account, "; ".join(memberships) + "." if memberships else "None."])
        for name in ("MDELab", "MDILab", "Defender"):
            deployment = (ROOT / name / "README.md").read_text(encoding="utf-8")
            heading = (
                "### Accounts and scenario sign-in\n" if name == "MDELab"
                else "### User Accounts (created by DcHydrate.ps1)\n"
            )
            with self.subTest(lab=name, page="deployment"):
                self.assertEqual(first_table(deployment.split(heading, 1)[1]), expected)
            if name in SCENARIO_GUIDES:
                guide = (ROOT / name / SCENARIO_GUIDES[name]).read_text(encoding="utf-8")
                with self.subTest(lab=name, page="scenarios"):
                    self.assertEqual(
                        first_table(guide.split("## Accounts and sign-in\n", 1)[1]), expected,
                    )

    def test_individual_guides_point_to_matching_host_and_setup(self):
        for name in ("MDELab", "MDILab"):
            client = next(row for row in LAB_GUIDES[name][1] if row[0] == "WinClient11")
            for path in (ROOT / name / "Attacks").glob("*.md"):
                if path.name == "README.md":
                    continue
                with self.subTest(path=path.relative_to(ROOT)):
                    guide = path.read_text(encoding="utf-8")
                    note = re.search(r"^> \*\*Lab context:.*(?:\n>.*)*", guide, re.MULTILINE)
                    self.assertIsNotNone(note)
                    self.assertIn(f"`{client[0]}` (`{client[2]}`)", note.group())
                    self.assertIn("README.md#before-running-a-scenario", note.group())

    def test_mdi_examples_use_deployed_hosts_and_not_unrelated_domains(self):
        machines = {row[0] for row in LAB_GUIDES["MDILab"][1]}
        for path in (ROOT / "MDILab" / "Attacks").glob("*.md"):
            with self.subTest(path=path.relative_to(ROOT)):
                guide = path.read_text(encoding="utf-8")
                examples = "\n".join(re.findall(r"```[^\n]*\n(.*?)```", guide, re.DOTALL))
                self.assertNotRegex(
                    examples,
                    r"(?i)\b(?:DC0[12]|SERVER0[12]|WORKSTATION0[12]|contoso\.com|MSMDI\.local|CONTOSO\\)",
                )
                for target in re.findall(
                    r'-(?:ComputerName|DomainController)\s+"([^"]+)"', examples,
                ):
                    self.assertIn(target.split(".")[0], machines)

    def test_normalized_mdi_guides_match_common_sections_and_parameters(self):
        for guide_name, script_name in (
            ("LdapRecon.md", "Invoke-LdapRecon.ps1"),
            ("NetworkMappingRecon.md", "Invoke-DnsZoneTransfer.ps1"),
            ("SuspiciousAccountAddition.md", "Invoke-SuspiciousAccountAddition.ps1"),
        ):
            with self.subTest(guide=guide_name):
                guide = (ROOT / "MDILab" / "Attacks" / guide_name).read_text(encoding="utf-8")
                self.assertEqual(re.findall(r"^## (.+)$", guide, re.MULTILINE), [
                    "Overview", "MITRE ATT&CK Mapping", "Attack Simulation", "Setup",
                    "Scenario Execution", "Expected Alerts", "Why Does This Matter",
                    "Best Practices", "Clean-Up",
                ])
                script = (ROOT / "MDILab" / "Attacks" / script_name).read_text(
                    encoding="utf-8",
                )
                parameters = re.findall(
                    r"^\s+\[(?:string(?:\[\])?|int|switch|securestring)\]\$(\w+)",
                    script.split("\n)\n", 1)[0], re.MULTILINE,
                )
                self.assertTrue(parameters)
                rows = first_table(guide.split("#### Parameters\n", 1)[1])
                self.assertEqual([row[0].lstrip("-") for row in rows], parameters)
                self.assertIn(f"./{script_name}", guide)
                self.assertNotRegex(guide, r"\bxxx\b")

    def test_ldap_guide_matches_script_exports_and_credentials(self):
        guide = (ROOT / "MDILab" / "Attacks" / "LdapRecon.md").read_text(encoding="utf-8")
        script = (ROOT / "MDILab" / "Attacks" / "Invoke-LdapRecon.ps1").read_text(
            encoding="utf-8",
        )
        exports = re.findall(r'Export-Csv -Path "\$OutputPath\\([^"]+\.csv)"', script)
        self.assertTrue(exports)
        for filename in exports:
            with self.subTest(export=filename):
                self.assertIn(f"`{filename}`", guide)
        self.assertIn("./Invoke-LdapRecon.ps1", guide)
        self.assertIn("Password = $credential.Password", guide)
        self.assertIn(
            '-CleanUp -OutputPath (Join-Path $env:TEMP "LdapRecon-Scenario")', guide,
        )

    def test_network_mapping_distinguishes_axfr_and_matches_cleanup_path(self):
        guide = (ROOT / "MDILab" / "Attacks" / "NetworkMappingRecon.md").read_text(
            encoding="utf-8",
        )
        self.assertIn("does not send AXFR", guide)
        self.assertIn("ls -d mayor.mcweeinc.com", guide)
        self.assertIn("ResolveDnsName_LabSubAd1.mayor.mcweeinc.com.txt", guide)
        self.assertIn(
            '-CleanUp -OutputPath (Join-Path $env:TEMP "NetworkMappingRecon")', guide,
        )

    def test_suspicious_account_cleanup_targets_the_same_account_and_groups(self):
        guide = (ROOT / "MDILab" / "Attacks" / "SuspiciousAccountAddition.md").read_text(
            encoding="utf-8",
        )
        self.assertIn("Password = $credential.GetNetworkCredential().Password", guide)
        cleanup = guide.split("## Clean-Up\n", 1)[1]
        for group in ("Domain Admins", "Backup Operators"):
            with self.subTest(group=group):
                self.assertIn(
                    f'-UserName "bad.user" -DomainGroup "{group}" -Cleanup', cleanup,
                )
        self.assertIn("-Cleanup -DeleteUser", cleanup)
        self.assertNotIn("T1484", guide)

    def test_legacy_mde_entrypoint_does_not_duplicate_inventory(self):
        guide = (ROOT / "MDELab" / "Attacks.md").read_text(encoding="utf-8")
        self.assertIn("./Attacks/README.md", guide)
        self.assertNotRegex(guide, r"(?m)^\|")

    def test_session_enumeration_links_use_one_canonical_guide(self):
        self.assertEqual(
            PAGE_ALIASES["MDILab/Attacks/SmbSessionEnumeration.md"],
            "MDILab/Attacks/NetSessionEnumeration.md",
        )
        for path in (
            ROOT / "mkdocs.yml",
            ROOT / "MDILab" / "Attacks" / "README.md",
        ):
            with self.subTest(path=path.relative_to(ROOT)):
                source = path.read_text(encoding="utf-8")
                self.assertNotIn("SmbSessionEnumeration.md", source)
                self.assertEqual(source.count("NetSessionEnumeration.md"), 1)


class PageLinks(HTMLParser):
    def __init__(self, content):
        super().__init__(convert_charrefs=True)
        self.links = []
        self.ids = set()
        self.canonical = None
        self.feed(content)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        if tag == "link" and attrs.get("rel") == "canonical":
            self.canonical = attrs["href"]
        if tag in {"a", "link"} and "href" in attrs:
            self.links.append(attrs["href"])
        if tag in {"img", "script"} and "src" in attrs:
            self.links.append(attrs["src"])


class RepositoryLinkTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        for name in ("README.md", "docs/start.md", "Lab/README.md", "Lab/run.ps1"):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("Example", encoding="utf-8")
        self.extension = RepositoryLinksExtension(self.root, "https://github.com/dmcwee/labs")
        self.extension.pages = {
            self.root / "README.md": "README.md",
            self.root / "docs/start.md": "start.md",
            self.root / "Lab/README.md": "Lab/README.md",
        }
        self.extension.source = self.root / "README.md"
        self.extension.source_uri = "README.md"

    def test_general_guide_mapping_preserves_fragment(self):
        self.assertEqual(self.extension.resolve("docs/start.md#setup"), "start.md#setup")

    def test_guide_can_link_back_to_environment(self):
        self.extension.source = self.root / "docs/start.md"
        self.extension.source_uri = "start.md"
        self.assertEqual(self.extension.resolve("../Lab/README.md"), "Lab/README.md")

    def test_directory_readme_becomes_documentation_link(self):
        self.assertEqual(self.extension.resolve("Lab"), "Lab/README.md")

    def test_legacy_page_alias_uses_canonical_guide(self):
        (self.root / "Lab.md").write_text("Legacy index", encoding="utf-8")
        self.extension.pages[self.root / "Lab.md"] = "Lab/README.md"
        self.assertEqual(self.extension.resolve("Lab.md"), "Lab/README.md")

    def test_script_links_use_raw_downloads(self):
        self.assertEqual(
            self.extension.resolve("Lab/run.ps1"),
            "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/master/Lab/run.ps1",
        )

    def test_external_links_and_fragments_are_unchanged(self):
        for href in ("https://portal.azure.com/#create/example", "mailto:example@example.com", "#setup"):
            with self.subTest(href=href):
                self.assertEqual(self.extension.resolve(href), href)

    def test_missing_root_relative_and_escaping_links_fail(self):
        for href in ("missing.md", "/Lab/README.md", "../README.md"):
            with self.subTest(href=href), self.assertRaises(PluginError):
                self.extension.resolve(href)

    def test_unpublished_documentation_fails(self):
        (self.root / "unpublished.md").write_text("Example", encoding="utf-8")
        with self.assertRaises(PluginError):
            self.extension.resolve("unpublished.md")

    def test_code_examples_are_not_rewritten(self):
        rendered = markdown.Markdown(extensions=[self.extension, "fenced_code"]).convert(
            "```\n[example](missing.md)\n```\n\n[Start](docs/start.md)"
        )
        self.assertIn("[example](missing.md)", rendered)
        self.assertIn('href="start.md"', rendered)


class BuiltSiteTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.temp.cleanup)
        cls.site = Path(cls.temp.name)
        result = subprocess.run(
            [
                sys.executable, "-m", "mkdocs", "build", "--strict",
                "--site-dir", str(cls.site),
            ],
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        if result.returncode:
            raise AssertionError(result.stdout + result.stderr)
        cls.pages = {
            path: PageLinks(path.read_text(encoding="utf-8"))
            for path in cls.site.rglob("*.html")
        }

    def test_session_enumeration_has_one_published_guide(self):
        self.assertTrue(
            (self.site / "MDILab" / "Attacks" / "NetSessionEnumeration" / "index.html").exists()
        )
        self.assertFalse(
            (self.site / "MDILab" / "Attacks" / "SmbSessionEnumeration").exists()
        )
        for path, page in self.pages.items():
            with self.subTest(page=path.relative_to(self.site)):
                self.assertFalse(any("SmbSessionEnumeration" in link for link in page.links))

    def test_canonical_urls_include_project_subpath(self):
        for path, page in self.pages.items():
            if path.name == "404.html":
                continue
            route = path.relative_to(self.site).as_posix().removesuffix("index.html")
            with self.subTest(path=path):
                self.assertEqual(page.canonical, SITE_URL + route)
        self.assertFalse((self.site / "CNAME").exists())
        self.assertFalse((ROOT / "CNAME").exists())

    def test_local_links_images_scripts_and_anchors_resolve(self):
        for path, page in self.pages.items():
            for href in page.links:
                url = urlsplit(href)
                if url.scheme or url.netloc:
                    continue
                with self.subTest(page=path.relative_to(self.site), href=href):
                    if url.path.startswith("/"):
                        self.assertTrue(url.path.startswith("/labs/"))
                        target = self.site / unquote(url.path.removeprefix("/labs/"))
                    elif url.path:
                        target = path.parent / unquote(url.path)
                    else:
                        target = path
                    target = target.resolve()
                    self.assertTrue(target.is_relative_to(self.site))
                    if target.is_dir():
                        target /= "index.html"
                    self.assertTrue(target.is_file(), f"Missing target: {target}")
                    if url.fragment and target.suffix == ".html":
                        self.assertIn(unquote(url.fragment), self.pages[target].ids)

    def test_reader_journey_and_raw_download(self):
        self.assertIn("getting-started/", self.pages[self.site / "index.html"].links)
        self.assertIn(
            "../MDELab/",
            self.pages[self.site / "getting-started/index.html"].links,
        )
        self.assertIn(
            "../MDELab/Attacks/",
            self.pages[self.site / "getting-started/index.html"].links,
        )
        for name in ("MDELab", "MDILab"):
            self.assertIn("Attacks/", self.pages[self.site / name / "index.html"].links)
            self.assertIn("../getting-started/", self.pages[self.site / name / "index.html"].links)
        self.assertIn(
            "https://raw.githubusercontent.com/dmcwee/labs/refs/heads/master/MDILab/Attacks/Invoke-DnsZoneTransfer.ps1",
            self.pages[self.site / "MDILab/Attacks/DnsZoneTransfer/index.html"].links,
        )
        for name in LAB_GUIDES:
            self.assertIn(f"{name}/", self.pages[self.site / "index.html"].links)
            self.assertTrue((self.site / name / "index.html").is_file())

    def test_rendered_deployment_buttons_match_quick_deploy(self):
        for name, artifact in DEPLOYMENT_ARTIFACTS.items():
            source = (ROOT / name / "README.md").read_text(encoding="utf-8")
            destinations = self.pages[self.site / name / "index.html"].links
            expected = [
                link for link in PageLinks(markdown.markdown(source)).links
                if link.startswith("https://portal.azure.com/")
            ]
            actual = [
                link for link in destinations
                if link.startswith("https://portal.azure.com/")
            ]
            with self.subTest(environment=name):
                self.assertTrue(expected)
                self.assertEqual(actual, expected)
                self.assertEqual(
                    [unquote(link.removeprefix(PORTAL_TEMPLATE_PREFIX)) for link in actual],
                    [PUBLISHED_TEMPLATE_ROOT + artifact],
                )
                self.assertIn("../deployment-alignment/", destinations)

    def test_scenario_context_journey_and_sections(self):
        for name, relative in SCENARIO_GUIDES.items():
            with self.subTest(lab=name):
                directory = relative.parent
                page = self.pages[self.site / name / directory / "index.html"]
                self.assertIn(f"{directory.as_posix()}/", self.pages[self.site / name / "index.html"].links)
                self.assertIn("../", page.links)
                for anchor in (
                    "deployment-context", "accounts-and-sign-in", "machines-and-roles",
                    "before-running-a-scenario", "scenarios", "cleanup",
                ):
                    self.assertIn(anchor, page.ids)

    def test_search_and_sitemap_use_project_routes(self):
        search = json.loads((self.site / "search/search_index.json").read_text(encoding="utf-8"))
        locations = [entry["location"] for entry in search["docs"]]
        self.assertEqual(len(locations), len(set(locations)), "Duplicate search routes")
        self.assertIn("MDILab/Attacks/DnsZoneTransfer/", locations)
        self.assertIn("getting-started/", locations)
        sitemap = (self.site / "sitemap.xml").read_text(encoding="utf-8")
        self.assertIn(SITE_URL + "MDILab/Attacks/DnsZoneTransfer/", sitemap)

    def test_source_edit_links_point_to_actual_repository_paths(self):
        for uri, source in (("getting-started", "docs/getting-started.md"), ("MDILab", "MDILab/README.md")):
            self.assertIn(
                f"https://github.com/dmcwee/labs/edit/master/{source}",
                self.pages[self.site / uri / "index.html"].links,
            )

    def test_pages_deployment_is_confined_to_master(self):
        workflow = yaml.load(
            (ROOT / ".github/workflows/docs.yml").read_text(encoding="utf-8"),
            Loader=yaml.BaseLoader,
        )
        self.assertIn("pull_request", workflow["on"])
        self.assertEqual(workflow["on"]["push"]["branches"], ["master"])
        self.assertEqual(workflow["permissions"], {"contents": "read"})
        deploy = workflow["jobs"]["deploy"]
        self.assertEqual(
            deploy["if"],
            "github.ref == 'refs/heads/master' && github.event_name != 'pull_request'",
        )
        self.assertEqual(deploy["permissions"], {"pages": "write", "id-token": "write"})


if __name__ == "__main__":
    unittest.main()
