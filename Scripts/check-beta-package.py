#!/usr/bin/env python3
"""Check local beta archive contents; distribution signing is a separate gate."""
import plistlib
import json
import sys
from pathlib import Path
from urllib.parse import urlparse


def check(app: Path) -> None:
    if not app.is_dir() or app.suffix != '.app':
        raise ValueError('Pass the archived Spendy.app directory')
    bundles = [app, app / 'PlugIns/SpendyWidgets.appex', app / 'PlugIns/SpendyAction.appex']
    version = None
    expected_identifiers = ('com.Spendy', 'com.Spendy.widgets', 'com.Spendy.Action')
    for bundle, identifier in zip(bundles, expected_identifiers):
        info = plistlib.loads((bundle / 'Info.plist').read_bytes())
        if info['CFBundleIdentifier'] != identifier:
            raise ValueError(f'Unexpected bundle identifier in {bundle.name}')
        current = (info['CFBundleShortVersionString'], info['CFBundleVersion'])
        if version is not None and current != version:
            raise ValueError(f'Version mismatch in {bundle.name}')
        version = current
        privacy = plistlib.loads((bundle / 'PrivacyInfo.xcprivacy').read_bytes())
        defaults = next((entry for entry in privacy.get('NSPrivacyAccessedAPITypes', [])
                         if entry.get('NSPrivacyAccessedAPIType') == 'NSPrivacyAccessedAPICategoryUserDefaults'), {})
        if not {'CA92.1', '1C8F.1'}.issubset(defaults.get('NSPrivacyAccessedAPITypeReasons', [])):
            raise ValueError(f'Missing app/App Group UserDefaults reasons in {bundle.name}')
        binary = (bundle / info['CFBundleExecutable']).read_bytes()
        for marker in (b'SPENDY_UI_TEST_MODE', b'Readiness expense'):
            if marker in binary:
                raise ValueError(f'Debug fixture marker in {bundle.name}')
    if list(app.rglob('spendy_demo_data.json')):
        raise ValueError('Personal demo ledger found in app bundle')
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if not any(key in info for key in ('UILaunchScreen', 'UILaunchScreens', 'UILaunchStoryboardName', 'UILaunchStoryboards')):
        raise ValueError('Missing launch-screen configuration')
    for key in ('NSCameraUsageDescription', 'NSPhotoLibraryUsageDescription'):
        if not info.get(key, '').strip():
            raise ValueError(f'Missing permission description: {key}')
    if not info.get('CFBundleIcons', {}).get('CFBundlePrimaryIcon', {}).get('CFBundleIconName'):
        raise ValueError('Missing compiled primary app icon')
    policy = json.loads((app / 'privacy-policy.json').read_text())
    url = urlparse(policy.get('privacyPolicyURL') or '')
    if url.scheme != 'https' or not url.netloc:
        raise ValueError('Privacy policy must have a public HTTPS URL')
    if not policy.get('contactEmail') or not policy.get('sections'):
        raise ValueError('Privacy policy is missing contact details or sections')
    for manifest in app.rglob('PrivacyInfo.xcprivacy'):
        plistlib.loads(manifest.read_bytes())
    print('Beta package checks passed: identifiers, versions, extensions, privacy manifests, policy, permissions, launch screen, icon, no debug fixtures.')
    print('Policy URL reachability and privacy-manifest completeness require separate review.')
    print('Distribution signing and TestFlight validation remain separate.')


if __name__ == '__main__':
    try:
        if len(sys.argv) != 2:
            raise ValueError('Usage: check-beta-package.py /path/to/Spendy.app')
        check(Path(sys.argv[1]))
    except (ValueError, KeyError, OSError, plistlib.InvalidFileException) as error:
        print(f'Beta package check failed: {error}', file=sys.stderr)
        sys.exit(1)
