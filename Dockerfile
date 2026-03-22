FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy README.md to be served as index
COPY README.md /usr/share/nginx/html/README.md

# Create a simple HTML wrapper that renders README.md content
RUN cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hetzner to AWS EKS Migration Guide</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 2rem;
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
        pre code { background: transparent; padding: 0; }
        .mermaid { background: #fff; text-align: center; margin: 2rem 0; }
        hr { border: none; border-top: 1px solid #eee; margin: 2rem 0; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        blockquote { border-left: 4px solid #ddd; padding-left: 1rem; margin: 1rem 0; color: #666; }
    </style>
</head>
<body>
    <div id="content">Loading...</div>
    <script>
        mermaid.initialize({ startOnLoad: true, theme: 'default' });

        async function loadReadme() {
            try {
                const response = await fetch('README.md');
                let markdown = await response.text();
                
                // Convert markdown to HTML
                markdown = markdown
                    // Headers
                    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
                    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
                    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
                    // Code blocks (mermaid)
                    .replace(/```mermaid\n([\s\S]*?)```/g, '<div class="mermaid">$1</div>')
                    // Code blocks
                    .replace(/```(\w+)?\n([\s\S]*?)```/g, '<pre><code>$2</code></pre>')
                    // Inline code
                    .replace(/`([^`]+)`/g, '<code>$1</code>')
                    // Tables
                    .replace(/\|(.+)\|\n\|[-:\s|]+\|\n((?:\|.+\|\n?)+)/g, (match, header, rows) => {
                        const headers = header.split('|').filter(h => h.trim());
                        const rowsHtml = rows.trim().split('\n').map(row => {
                            const cells = row.split('|').filter(c => c.trim());
                            return '<tr>' + cells.map(c => `<td>${c.trim()}</td>`).join('') + '</tr>';
                        }).join('');
                        return '<table><thead><tr>' + headers.map(h => `<th>${h}</th>`).join('') + '</tr></thead><tbody>' + rowsHtml + '</tbody></table>';
                    })
                    // Bold
                    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
                    // Italic
                    .replace(/\*(.+?)\*/g, '<em>$1</em>')
                    // Links
                    .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>')
                    // Horizontal rules
                    .replace(/^---$/gm, '<hr>')
                    // Line breaks
                    .replace(/\n\n/g, '</p><p>')
                    .replace(/\n/g, '<br>');

                document.getElementById('content').innerHTML = '<p>' + markdown + '</p>';
                mermaid.run();
            } catch (error) {
                document.getElementById('content').innerHTML = '<p>Error loading README: ' + error.message + '</p>';
            }
        }
        loadReadme();
    </script>
</body>
</html>
HTMLEOF

# Copy nginx config for SPA routing
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
