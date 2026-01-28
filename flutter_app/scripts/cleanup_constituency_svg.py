#!/usr/bin/env python3
"""
Clean up the constituency SVG to remove non-constituency elements.
"""
import re
import os

def cleanup_constituency_svg():
    input_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'election', 'nepal_constituencies.svg')

    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove protected-areas paths
    content = re.sub(r'<path[^>]*id="protected-areas[^"]*"[^>]*/>', '', content)

    # Remove rect elements (except inside clipPath)
    # First extract clipPath definitions
    clippath_content = re.findall(r'<clipPath[^>]*>.*?</clipPath>', content, re.DOTALL)

    # Remove all rect elements outside clipPath
    content = re.sub(r'<rect[^>]*id="rect201"[^>]*/>', '', content)
    content = re.sub(r'<rect[^>]*id="rect202"[^>]*/>', '', content)

    # Remove layers that don't contain constituency paths (keep layer12-layer21 for now, we'll see)
    # Actually let's just check what layers exist and keep them

    # Remove empty g elements
    content = re.sub(r'<g[^>]*>\s*</g>', '', content)

    # Remove excessive whitespace
    content = re.sub(r'\n\s*\n', '\n', content)
    content = re.sub(r'  +', ' ', content)

    with open(input_path, 'w', encoding='utf-8') as f:
        f.write(content)

    # Get count of constituency paths
    path_count = len(re.findall(r'id="[a-z]+-\d+"', content))
    print(f"Cleaned SVG written to {input_path}")
    print(f"Contains {path_count} constituency paths")

if __name__ == '__main__':
    cleanup_constituency_svg()
