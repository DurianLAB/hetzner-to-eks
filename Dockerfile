FROM nginx:alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Copy README.md to be served as index
COPY README.md /usr/share/nginx/html/README.md

# Create HTML wrapper with proper markdown and mermaid rendering
RUN cat > /usr/share/nginx/html/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hetzner to AWS EKS Migration Guide</title>
    
    <!-- Mermaid -->
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    
    <!-- Marked.js for markdown parsing -->
    <script src="https://cdn.jsdelivr.net/npm/marked@12/marked.min.js"></script>
    
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
        pre code { background: transparent; padding: 0; color: #d4d4d4; }
        .mermaid { background: #fff; text-align: center; margin: 2rem 0; padding: 1rem; border: 1px solid #eee; border-radius: 8px; }
        hr { border: none; border-top: 1px solid #eee; margin: 2rem 0; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        #loading { color: #666; font-style: italic; }
        .error { color: #c00; background: #fee; padding: 1rem; border-radius: 8px; margin: 1rem 0; }
    </style>
</head>
<body>
    <div id="content">
        <p id="loading">Loading documentation...</p>
    </div>
    
    <script>
        // Initialize Mermaid with proper settings
        mermaid.initialize({ 
            startOnLoad: false,
            theme: 'default',
            securityLevel: 'loose',
            fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
        });

        // Configure marked to handle code blocks properly
        marked.setOptions({
            highlight: function(code, lang) {
                if (lang === 'mermaid') {
                    // Return mermaid code as-is for later processing
                    return '<div class="mermaid">' + code + '</div>';
                }
                return code;
            },
            langPrefix: 'language-',
            breaks: false,
            gfm: true
        });

        // Custom renderer for code blocks
        const renderer = new marked.Renderer();
        const originalCodeRenderer = renderer.code.bind(renderer);
        
        renderer.code = function(code, lang, escaped) {
            if (lang === 'mermaid') {
                // Return mermaid div directly
                return '<div class="mermaid">' + code + '</div>';
            }
            // For other code blocks, escape HTML
            const escapedCode = code
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
            const langClass = lang ? ` language-${lang}` : '';
            return `<pre><code class="${langClass}">${escapedCode}</code></pre>`;
        };

        marked.use({ renderer });

        async function loadReadme() {
            const contentDiv = document.getElementById('content');
            
            try {
                const response = await fetch('README.md');
                if (!response.ok) {
                    throw new Error('Failed to load README.md');
                }
                
                let markdown = await response.text();
                
                // Parse markdown to HTML
                let html = marked.parse(markdown);
                
                // Replace mermaid divs that might have been double-encoded
                html = html.replace(/<div class="mermaid"><div class="mermaid">/g, '<div class="mermaid">');
                html = html.replace(/<\/div><\/div>/g, '</div>');
                
                // Insert HTML
                contentDiv.innerHTML = html;
                
                // Find all mermaid elements and render them
                const mermaidElements = document.querySelectorAll('.mermaid');
                if (mermaidElements.length > 0) {
                    mermaid.run(mermaidElements);
                }
                
            } catch (error) {
                contentDiv.innerHTML = `<div class="error">Error loading documentation: ${error.message}</div>`;
                console.error('Error loading README:', error);
            }
        }

        // Load when DOM is ready
        document.addEventListener('DOMContentLoaded', loadReadme);
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
