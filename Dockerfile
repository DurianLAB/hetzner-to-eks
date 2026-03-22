FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy README.md
COPY README.md /usr/share/nginx/html/README.md

# Create HTML wrapper with markdown and mermaid rendering
RUN cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hetzner to AWS EKS Migration Guide</title>
    
    <!-- Mermaid (older stable version that works with script tags) -->
    <script src="https://cdn.jsdelivr.net/npm/mermaid@9/dist/mermaid.min.js"></script>
    
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
            background: #fff;
        }
        h1, h2, h3 { margin: 1.5rem 0 1rem; color: #1a1a1a; }
        h1 { border-bottom: 2px solid #333; padding-bottom: 0.5rem; }
        h2 { border-bottom: 1px solid #ddd; padding-bottom: 0.25rem; }
        table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
        th, td { border: 1px solid #ddd; padding: 0.75rem; text-align: left; }
        th { background: #f5f5f5; font-weight: 600; }
        tr:nth-child(even) { background: #fafafa; }
        code { background: #f4f4f4; padding: 0.2rem 0.4rem; border-radius: 3px; font-size: 0.9em; }
        pre { background: #1e1e1e; color: #d4d4d4; padding: 1rem; border-radius: 8px; overflow-x: auto; margin: 1rem 0; }
        pre code { background: transparent; padding: 0; color: #d4d4d4; }
        .mermaid { background: #fff; text-align: center; margin: 2rem 0; padding: 1rem; }
        hr { border: none; border-top: 1px solid #eee; margin: 2rem 0; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        #loading { color: #666; font-style: italic; }
        .error { color: #c00; background: #fee; padding: 1rem; border-radius: 8px; margin: 1rem 0; }
        .content h1:first-child { margin-top: 0; }
        .content p { margin: 0.75rem 0; }
        .content ul, .content ol { margin: 0.75rem 0; padding-left: 2rem; }
        .content li { margin: 0.25rem 0; }
        .content blockquote { border-left: 4px solid #ddd; padding-left: 1rem; margin: 1rem 0; color: #666; }
    </style>
</head>
<body>
    <div id="loading">Loading documentation...</div>
    <div id="content" class="content"></div>
    
    <script>
        // Initialize Mermaid
        mermaid.initialize({
            startOnLoad: false,
            theme: 'default',
            securityLevel: 'loose',
            fontFamily: 'inherit'
        });

        // Simple markdown parser
        function parseMarkdown(text) {
            const lines = text.split('\n');
            let html = [];
            let inCodeBlock = false;
            let inMermaidBlock = false;
            let codeContent = [];
            let key = 0;
            
            for (let i = 0; i < lines.length; i++) {
                let line = lines[i];
                
                // Code block start/end
                if (line.trim().startsWith('```')) {
                    const lang = line.trim().slice(3);
                    if (!inCodeBlock) {
                        inCodeBlock = true;
                        if (lang === 'mermaid') {
                            inMermaidBlock = true;
                            codeContent = [];
                        } else {
                            html.push('<pre><code>');
                        }
                    } else {
                        inCodeBlock = false;
                        if (inMermaidBlock) {
                            inMermaidBlock = false;
                            const id = 'mermaid-' + (key++);
                            html.push('<div class="mermaid" id="' + id + '">' + codeContent.join('\n') + '</div>');
                            codeContent = [];
                        } else {
                            html.push('</code></pre>');
                        }
                    }
                    continue;
                }
                
                if (inCodeBlock) {
                    if (inMermaidBlock) {
                        codeContent.push(line);
                    } else {
                        html.push(escapeHtml(line));
                    }
                    continue;
                }
                
                // Headers
                if (line.startsWith('### ')) {
                    html.push('<h3>' + line.slice(4) + '</h3>');
                } else if (line.startsWith('## ')) {
                    html.push('<h2>' + line.slice(3) + '</h2>');
                } else if (line.startsWith('# ')) {
                    html.push('<h1>' + line.slice(2) + '</h1>');
                }
                // Horizontal rule
                else if (line.trim() === '---') {
                    html.push('<hr>');
                }
                // Table
                else if (line.startsWith('|')) {
                    // Collect table rows
                    const tableLines = [line];
                    while (i + 1 < lines.length && lines[i + 1].startsWith('|')) {
                        i++;
                        tableLines.push(lines[i]);
                    }
                    html.push(parseTable(tableLines));
                }
                // Unordered list
                else if (line.match(/^[\-\*] /)) {
                    html.push('<li>' + parseInline(line.slice(2)) + '</li>');
                }
                // Empty line
                else if (line.trim() === '') {
                    html.push('');
                }
                // Paragraph
                else {
                    html.push('<p>' + parseInline(line) + '</p>');
                }
            }
            
            // Wrap consecutive <li> in <ul>
            html = html.join('\n');
            html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>');
            
            return html;
        }

        function parseTable(lines) {
            if (lines.length < 2) return '';
            
            let html = '<table>';
            const isHeader = lines[1].includes('---');
            const startRow = isHeader ? 2 : 1;
            
            for (let i = 0; i < lines.length; i++) {
                const row = lines[i];
                const cells = row.split('|').filter((c, i, a) => i > 0 && i < a.length - 1);
                
                if (i === 0) {
                    html += '<thead><tr>';
                    cells.forEach(cell => html += '<th>' + cell.trim() + '</th>');
                    html += '</tr></thead><tbody>';
                } else if (i === 1 && isHeader) {
                    continue;
                } else {
                    html += '<tr>';
                    cells.forEach(cell => html += '<td>' + cell.trim() + '</td>');
                    html += '</tr>';
                }
            }
            
            html += '</tbody></table>';
            return html;
        }

        function parseInline(text) {
            return text
                .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
                .replace(/\*(.+?)\*/g, '<em>$1</em>')
                .replace(/`([^`]+)`/g, '<code>$1</code>')
                .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
        }

        function escapeHtml(text) {
            return text
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
        }

        async function loadReadme() {
            const contentDiv = document.getElementById('content');
            const loadingDiv = document.getElementById('loading');
            
            try {
                const response = await fetch('README.md');
                if (!response.ok) throw new Error('Failed to load');
                
                const markdown = await response.text();
                loadingDiv.style.display = 'none';
                contentDiv.innerHTML = parseMarkdown(markdown);
                
                // Render mermaid diagrams
                await mermaid.run({
                    querySelector: '.mermaid'
                });
                
            } catch (error) {
                loadingDiv.innerHTML = '<div class="error">Error: ' + error.message + '</div>';
            }
        }

        loadReadme();
    </script>
</body>
</html>
HTMLEOF

RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location = /health { \
        access_log off; \
        return 200 "OK"; \
        add_header Content-Type text/plain; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
