#!/bin/bash
#
# Convert mermaid diagrams to PNG/PDF
#

set -e

echo "=== Mermaid Diagram Converter ==="
echo ""

# Find mermaid-cli
MMDC=$(find ~/.npm/_npx -name "cli.js" -path "*/mermaid-cli/*" 2>/dev/null | head -1)

if [ -z "$MMDC" ]; then
    echo "Installing mermaid-cli..."
    npx --yes @mermaid-js/mermaid-cli mmdc --version > /dev/null 2>&1
    MMDC=$(find ~/.npm/_npx -name "cli.js" -path "*/mermaid-cli/*" 2>/dev/null | head -1)
fi

if [ -z "$MMDC" ]; then
    echo "Error: Could not find mermaid-cli"
    exit 1
fi

echo "Using: $MMDC"
echo ""

# Extract diagrams if no .mmd files exist
if [ ! -d "diagrams-mmd" ] || [ -z "$(ls -A diagrams-mmd/*.mmd 2>/dev/null)" ]; then
    echo "Extracting mermaid diagrams from README.md..."
    python3 extract_diagrams.py
    echo ""
fi

# Create output directories
mkdir -p diagrams-png diagrams-pdf

# Convert to PNG
echo "Converting to PNG..."
for f in diagrams-mmd/*.mmd; do
    name=$(basename "$f" .mmd)
    echo -n "  $name.png... "
    node "$MMDC" -i "$f" -o "diagrams-png/${name}.png" -w 1920 -H 1080 -b white 2>/dev/null
    [ -f "diagrams-png/${name}.png" ] && echo "OK" || echo "FAILED"
done

echo ""

# Convert to PDF
echo "Converting to PDF..."
for f in diagrams-mmd/*.mmd; do
    name=$(basename "$f" .mmd)
    echo -n "  $name.pdf... "
    node "$MMDC" -i "$f" -o "diagrams-pdf/${name}.pdf" -w 1920 -H 1080 2>/dev/null
    [ -f "diagrams-pdf/${name}.pdf" ] && echo "OK" || echo "FAILED"
done

echo ""
echo "Done! Check diagrams-png/ and diagrams-pdf/"
