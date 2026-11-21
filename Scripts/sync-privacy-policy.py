#!/usr/bin/env python3
"""Copy the app's policy to the website, or check that both copies agree."""
import argparse
import json
from pathlib import Path


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    parser.add_argument('--website-policy', type=Path,
                        default=root.parent / 'SpendyWebsite/src/data/privacy-policy.json')
    args = parser.parse_args()
    source = root / 'Spendy/Resources/privacy-policy.json'
    policy = json.loads(source.read_text())
    if args.check:
        if policy != json.loads(args.website_policy.read_text()):
            raise SystemExit('Privacy policies differ. Review the app policy, then run Scripts/sync-privacy-policy.py.')
        print('Privacy policy copies match.')
    else:
        args.website_policy.write_text(source.read_text())
        print(f'Updated {args.website_policy}. Deploying the website is a separate step.')


if __name__ == '__main__':
    main()
