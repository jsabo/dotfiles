#!/usr/bin/env python3
"""Remove only obsolete links into this checkout, never independent user files."""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--target', type=Path, default=Path.home())
args = parser.parse_args()
checkout = Path(__file__).resolve().parents[1]
for name in ('.zshrc', '.colorprompt'):
    destination = args.target / name
    if destination.is_symlink() and destination.resolve() == checkout / name:
        destination.unlink()
        print(f'Removed obsolete dotfiles link: {destination}')
