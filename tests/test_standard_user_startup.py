"""Checks that normal Windows startup does not require elevation."""

import ast
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from core import setup_window  # noqa: E402


class StandardUserStartupTests(unittest.TestCase):
    def test_packaged_executable_does_not_request_elevation(self):
        source = (ROOT / "Location.spec").read_text(encoding="utf-8")
        self.assertIn("uac_admin=False", source)

    def test_setup_does_not_block_on_administrator_status(self):
        with patch.object(setup_window.plat, "IS_WINDOWS", True):
            items = {item.key: item for item in setup_window.build_items()}
        self.assertIn("apple_driver", items)
        self.assertNotIn("permission", items)

    def test_normal_startup_only_checks_driver(self):
        tree = ast.parse((ROOT / "main.py").read_text(encoding="utf-8"))
        main = next(node for node in tree.body if isinstance(node, ast.FunctionDef) and node.name == "main")
        calls = [node for node in ast.walk(main) if isinstance(node, ast.Call)
                 and isinstance(node.func, ast.Name) and node.func.id == "ensure_apple_driver"]
        self.assertEqual(1, len(calls))
        allow_install = next(keyword.value for keyword in calls[0].keywords
                             if keyword.arg == "allow_install")
        self.assertIsInstance(allow_install, ast.Constant)
        self.assertIs(allow_install.value, False)


if __name__ == "__main__":
    unittest.main()
