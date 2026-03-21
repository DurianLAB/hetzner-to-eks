#!/usr/bin/env python3
"""
Convert Mermaid diagrams in README.md to PNG files using Kroki API.
Usage: python3 convert_diagrams.py
"""

import re
import os
import json
from urllib.parse import quote
from urllib.request import Request, urlopen
from urllib.error import URLError

KROKI_BASE = "https://kroki.io"

def mermaid_to_image(mermaid_code, output_file, format="png"):
    """Convert mermaid code to image using Kroki API (POST method)."""
    url = f"{KROKI_BASE}/mermaid/{format}"
    
    payload = json.dumps({
        "mermaid": mermaid_code
    }).encode('utf-8')
    
    headers = {
        'Content-Type': 'application/json',
        'Accept': 'image/png'
    }
    
    try:
        request = Request(url, data=payload, headers=headers, method='POST')
        response = urlopen(request, timeout=60)
        content = response.read()
        
        if len(content) < 1000:
            print(f"Error: {output_file} - Response too small, likely error")
            return False
            
        with open(output_file, 'wb') as f:
            f.write(content)
        print(f"OK: {output_file} ({len(content)//1024}KB)")
        return True
    except URLError as e:
        print(f"Error: {output_file} - {e}")
        return False
    except Exception as e:
        print(f"Error: {output_file} - {e}")
        return False

def extract_mermaid_blocks(content):
    """Extract all mermaid blocks from markdown content."""
    pattern = r'```mermaid\n(.*?)```'
    blocks = re.findall(pattern, content, re.DOTALL)
    return blocks

def create_title_from_context(content, index, block_preview):
    """Create a descriptive filename from context."""
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
    
    os.makedirs('diagrams-png', exist_ok=True)
    blocks = extract_mermaid_blocks(content)
    
    print(f"Found {len(blocks)} mermaid diagrams\n")
    
    success = 0
    for i, block in enumerate(blocks, 1):
        mermaid_code = block.strip()
        filename = create_title_from_context(content, i, mermaid_code)
        output_file = f"diagrams-png/{filename}.png"
        
        if mermaid_to_image(mermaid_code, output_file, "png"):
            success += 1
    
    print(f"\nConverted {success}/{len(blocks)} diagrams to: diagrams-png/")

if __name__ == "__main__":
    main()
