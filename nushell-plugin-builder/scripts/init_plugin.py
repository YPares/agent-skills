#!/usr/bin/env python3
"""
Script to initialize a new Nushell plugin project from template.
"""

import argparse
import shutil
import sys
from pathlib import Path


def snake_to_pascal(snake_str: str) -> str:
    """Convert snake_case to PascalCase."""
    return "".join(word.capitalize() for word in snake_str.split("_"))


def init_plugin(plugin_name: str, output_dir: Path) -> None:
    """Initialize a new plugin from template."""
    # Validate plugin name
    if not plugin_name.replace("_", "").replace("-", "").isalnum():
        print(f"Error: Plugin name '{plugin_name}' contains invalid characters", file=sys.stderr)
        print("Plugin name should only contain letters, numbers, hyphens, and underscores", file=sys.stderr)
        sys.exit(1)

    # Normalize plugin name to snake_case
    plugin_name_snake = plugin_name.replace("-", "_")
    plugin_name_pascal = snake_to_pascal(plugin_name_snake)

    # Determine template directory
    script_dir = Path(__file__).parent
    template_dir = script_dir.parent / "assets" / "plugin-template"

    if not template_dir.exists():
        print(f"Error: Template directory not found at {template_dir}", file=sys.stderr)
        sys.exit(1)

    # Create output directory
    project_dir = output_dir / f"nu_plugin_{plugin_name_snake}"

    if project_dir.exists():
        print(f"Error: Directory {project_dir} already exists", file=sys.stderr)
        sys.exit(1)

    print(f"Creating plugin project: {project_dir}")

    # Copy template
    shutil.copytree(template_dir, project_dir)

    # Replace placeholders in files
    # Order matters: replace longer strings first to avoid partial replacements
    replacements = [
        ("PLUGIN_NAMEPlugin", f"{plugin_name_pascal}Plugin"),
        ("PLUGIN_NAMECommand", f"{plugin_name_pascal}Command"),
        ("PLUGIN_NAME", plugin_name_snake),
    ]

    for file_path in project_dir.rglob("*"):
        if file_path.is_file() and file_path.suffix in [".rs", ".toml", ".md"]:
            content = file_path.read_text()
            for placeholder, replacement in replacements:
                content = content.replace(placeholder, replacement)
            file_path.write_text(content)

    print(f"✅ Plugin '{plugin_name_snake}' created successfully at {project_dir}")
    print()
    print("Next steps:")
    print(f"  cd {project_dir}")
    print("  cargo build")
    print(f"  plugin add target/debug/nu_plugin_{plugin_name_snake}")
    print(f"  plugin use {plugin_name_snake}")
    print(f'  "test" | {plugin_name_snake}')


def main():
    parser = argparse.ArgumentParser(
        description="Initialize a new Nushell plugin project from template"
    )
    parser.add_argument(
        "plugin_name",
        help="Name of the plugin (e.g., 'my_plugin' or 'my-plugin')",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path.cwd(),
        help="Output directory for the plugin project (default: current directory)",
    )

    args = parser.parse_args()
    init_plugin(args.plugin_name, args.output_dir)


if __name__ == "__main__":
    main()
