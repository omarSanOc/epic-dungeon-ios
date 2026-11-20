#!/usr/bin/env python3
"""Test actual native app logic in an isolated Swift package, without changing Xcode signing."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--scratch-directory', type=Path, help='New directory outside the repository; retained for inspection.')
args = parser.parse_args()
root = Path(__file__).resolve().parent.parent
if args.scratch_directory:
    scratch = args.scratch_directory.resolve()
    if scratch == root or root in scratch.parents:
        parser.error('Use a scratch directory outside the repository.')
    scratch.mkdir(parents=True, exist_ok=False)
else:
    scratch = Path(tempfile.mkdtemp(prefix='emberkeep-native-tests-'))
source = scratch / 'Sources' / 'EmberNative'
source.mkdir(parents=True)
for path in list((root / 'Engine').glob('*.swift')) + [root / 'App' / name for name in (
    'GameModel.swift', 'Renderer.swift', 'Mesh.swift', 'MetalSurface.swift')]:
    shutil.copy2(path, source / path.name)
tests = scratch / 'Tests' / 'EmberNativeTests'
shutil.copytree(root / 'Tests' / 'EmberNativeTests', tests)
(scratch / 'Package.swift').write_text('''// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "EmberNative", platforms: [.macOS(.v14)], targets: [
    .target(name: "EmberNative"),
    .testTarget(name: "EmberNativeTests", dependencies: ["EmberNative"])
])
''')
print(f'Native test scratch: {scratch}', flush=True)
result = subprocess.run(['swift', 'test', '--package-path', str(scratch),
                         '--scratch-path', str(scratch / 'build')])
raise SystemExit(result.returncode)
