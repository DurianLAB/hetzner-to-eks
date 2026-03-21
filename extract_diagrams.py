#!/usr/bin/env python3
"""
Extract Mermaid diagrams from README.md and save as .mmd files.
"""

import re
import os

def extract_mermaid_blocks(content):
    """Extract all mermaid blocks from markdown content."""
    pattern = r'```mermaid\n(.*?)```'
    blocks = re.findall(pattern, content, re.DOTALL)
    return blocks

def create_title_from_context(content, index, block_preview):
    """Create a descriptive filename."""
    lines = content.split('\n')
    
    for i in range(len(lines)-1, -1, -1):
        line = lines[i].strip()
        if line.startswith('###'):
            title = line.lstrip('#').strip().lower().replace(' ', '-').replace('/', '-')
            return f"{index:02d}-{title}"
        elif line.startswith('##'):
            title = line.lstrip('#').strip().lower().replace(' ', '-').replace('/', '-')
            return f"{index:02d}-{title}"
    
    preview = block_preview[:30].replace('\n', ' ').replace(':', '').replace('/', '-')
    preview = ''.join(c for c in preview if c.isalnum() or c == ' ')
    preview = preview.strip().replace(' ', '-')[:30]
    return f"{index:02d}-{preview}"

def main():
    with open('README.md', 'r') as f:
        content = f.read()
    
    os.makedirs('diagrams-mmd', exist_ok=True)
    blocks = extract_mermaid_blocks(content)
    
    print(f"Found {len(blocks)} mermaid diagrams\n")
    
    for i, block in enumerate(blocks, 1):
        mermaid_code = block.strip()
        filename = create_title_from_context(content, i, mermaid_code)
        output_file = f"diagrams-mmd/{filename}.mmd"
        
        with open(output_file, 'w') as f:
            f.write(mermaid_code)
        print(f"Created: {output_file}")
    
    print(f"\nSaved {len(blocks)} .mmd files to: diagrams-mmd/")

if __name__ == "__main__":
    main()
