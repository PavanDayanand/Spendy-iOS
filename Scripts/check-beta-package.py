#!/usr/bin/env python3
"""Check local beta archive contents; distribution signing is a separate gate."""
import plistlib
import sys
from pathlib import Path


def check(app: Path) -> None:
    if not app.is_dir() or app.suffix != '.app':
        raise ValueError('Pass the archived Spendy.app directory')
    bundles = [app, app / 'PlugIns/SpendyWidgets.appex', app / 'PlugIns/SpendyAction.appex']
    version = None
    for bundle in bundles:
        info = plistlib.loads((bundle / 'Info.plist').read_bytes())
        current = (info['CFBundleShortVersionString'], info['CFBundleVersion'])
        if version is not None and current != version:
            raise ValueError(f'Version mismatch in {bundle.name}')
        version = current
        plistlib.loads((bundle / 'PrivacyInfo.xcprivacy').read_bytes())
        binary = (bundle / info['CFBundleExecutable']).read_bytes()
        for marker in (b'SPENDY_UI_TEST_MODE', b'Readiness expense'):
            if marker in binary:
                raise ValueError(f'Debug fixture marker in {bundle.name}')
    if list(app.rglob('spendy_demo_data.json')):
        raise ValueError('Personal demo ledger found in app bundle')
    print('Beta package checks passed: extensions, matching versions, privacy plists, no debug fixture markers.')
    print('Distribution signing and TestFlight validation remain separate.')


if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError('Usage: check-beta-package.py /path/to/Spendy.app')
        check(Path(sys.argv[1]))
    except (ValueError, KeyError, OSError, plistlib.InvalidFileException) as error:
        print(f'Beta package check failed: {error}', file=sys.stderr)
        sys.exit(1)
