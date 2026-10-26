import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ENTRYPOINTS = (
    Path("Defender") / "modules" / "lab.bicep",
    Path("MDELab") / "modules" / "mdelab.bicep",
    Path("MDILab") / "modules" / "mdilab.bicep",
    Path("Linux") / "modules" / "linux.bicep",
    Path("OceanLotus") / "modules" / "OceanLotus.bicep",
    Path("Common") / "tests" / "adSetup.bicep",
    Path("Common") / "tests" / "client.bicep",
    Path("Common") / "tests" / "servers.bicep",
)


def gateway_skus(template, supplied=None):
    parameters = {
        name: definition.get("defaultValue")
        for name, definition in template.get("parameters", {}).items()
    }
    parameters.update(supplied or {})

    def resolve(value):
        if isinstance(value, str):
            reference = re.fullmatch(r"\[parameters\('([^']+)'\)\]", value)
            if reference:
                return parameters[reference.group(1)]
        return value

    resources = template.get("resources", [])
    if isinstance(resources, dict):
        resources = resources.values()
    for resource in resources:
        properties = resource.get("properties", {})
        if resource["type"] == "Microsoft.Network/virtualNetworkGateways":
            sku = properties["sku"]
            yield resolve(sku["name"]), resolve(sku["tier"])
        if "template" in properties:
            arguments = {
                name: resolve(argument["value"] if isinstance(argument, dict) else argument)
                for name, argument in properties.get("parameters", {}).items()
            }
            yield from gateway_skus(properties["template"], arguments)


class GatewaySkuTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        az = shutil.which("az")
        if az is None:
            raise RuntimeError("Azure CLI with Bicep is required for infrastructure checks.")
        cls.templates = {}
        for entrypoint in ENTRYPOINTS:
            result = subprocess.run(
                [az, "bicep", "build", "--file", str(ROOT / entrypoint), "--stdout"],
                cwd=ROOT,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            if result.returncode:
                raise AssertionError(f"{entrypoint}\n{result.stdout}\n{result.stderr}")
            cls.templates[entrypoint] = json.loads(result.stdout)

    def test_all_compiled_gateways_use_az_sku_and_tier(self):
        for entrypoint, template in self.templates.items():
            with self.subTest(entrypoint=entrypoint):
                self.assertEqual(list(gateway_skus(template)), [("VpnGw1AZ", "VpnGw1AZ")])

    def test_oceanlotus_snapshot_uses_same_gateway_sku(self):
        snapshot = json.loads((ROOT / "OceanLotus" / "OceanLotus.json").read_text(encoding="utf-8"))
        entrypoint = Path("OceanLotus") / "modules" / "OceanLotus.bicep"
        self.assertEqual(
            list(gateway_skus(snapshot)),
            list(gateway_skus(self.templates[entrypoint])),
        )

    def test_no_bicep_entrypoint_reintroduces_non_az_sku(self):
        for entrypoint in ENTRYPOINTS:
            with self.subTest(entrypoint=entrypoint):
                self.assertNotRegex(
                    (ROOT / entrypoint).read_text(encoding="utf-8"),
                    r"['\"]VpnGw1['\"]",
                )


if __name__ == "__main__":
    unittest.main()
