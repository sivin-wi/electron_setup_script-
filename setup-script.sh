#!/bin/bash

# Electron + Vite + React + TypeScript + Tailwind CSS Setup Script
# Minimal scaffold without UI components

PROJECT_NAME="electron-vite-app"

echo "🚀 Setting up $PROJECT_NAME..."

# Create project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Initialize package.json
echo "📦 Initializing package.json..."
npm init -y

# Install dependencies
echo "📥 Installing dependencies..."
npm install electron react react-dom

echo "📥 Installing dev dependencies..."
npm install --save-dev \
  @types/node \
  @types/react \
  @types/react-dom \
  @vitejs/plugin-react \
  typescript \
  vite \
  electron-builder \
  concurrently \
  wait-on \
  cross-env \
  @tailwindcss/vite

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p src/main
mkdir -p src/renderer
mkdir -p src/types

# Create tsconfig.json
echo "⚙️  Creating tsconfig.json..."
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": true,
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "jsx": "react-jsx",
    "outDir": "./dist"
  },
  "include": ["src"]
}
EOF

# Create tsconfig.electron.json
echo "⚙️  Creating tsconfig.electron.json..."
cat > tsconfig.electron.json << 'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "module": "CommonJS",
    "moduleResolution": "node",
    "outDir": "./dist-electron"
  },
  "include": ["src/main/**/*"]
}
EOF

# Create vite.config.ts
echo "⚙️  Creating vite.config.ts..."
cat > vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
  server: {
    port: 5173
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
})
EOF

# Create tailwind.config.js
echo "⚙️  Creating tailwind.config.js..."
cat > tailwind.config.js << 'EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Create electron-builder.yml
echo "⚙️  Creating electron-builder.yml..."
cat > electron-builder.yml << 'EOF'
appId: com.electron.app
productName: Electron App
directories:
  output: release
files:
  - dist/**/*
  - dist-electron/**/*
  - package.json
mac:
  category: public.app-category.productivity
  target:
    - dmg
win:
  target:
    - nsis
linux:
  target:
    - AppImage
EOF

# Create index.html
echo "⚙️  Creating index.html..."
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:;" />
    <title>Electron App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/renderer/main.tsx"></script>
  </body>
</html>
EOF

# Create .gitignore
echo "⚙️  Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/

# Build outputs
dist/
dist-electron/
release/

# Environment
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
EOF

# Update package.json with scripts
echo "⚙️  Updating package.json..."
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.main = 'dist-electron/main.js';
pkg.scripts = {
  'dev': 'npm run build:electron && concurrently \"npm run dev:vite\" \"npm run dev:electron\"',
  'dev:vite': 'vite',
  'dev:electron': 'wait-on http://localhost:5173 && cross-env NODE_ENV=development electron . --watch',
  'build': 'npm run build:electron && vite build && electron-builder',
  'build:electron': 'tsc -p tsconfig.electron.json',
  'preview': 'vite preview'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"

# Create type definitions
echo "📝 Creating src/types/electron.d.ts..."
cat > src/types/electron.d.ts << 'EOF'
export interface ElectronAPI {
  // Add your IPC methods here
}

declare global {
  interface Window {
    electron: ElectronAPI;
  }
}
EOF

# Create main process files
echo "📝 Creating src/main/main.ts..."
cat > src/main/main.ts << 'EOF'
import { app, BrowserWindow } from 'electron';
import path from 'path';

let mainWindow: BrowserWindow | null = null;

const isDev = process.env.NODE_ENV === 'development';

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.setMenu(null);

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});
EOF

echo "📝 Creating src/main/preload.ts..."
cat > src/main/preload.ts << 'EOF'
import { contextBridge } from 'electron';

const electronAPI = {
  // Add your IPC methods here
};

contextBridge.exposeInMainWorld('electron', electronAPI);
EOF

# Create renderer CSS
echo "📝 Creating src/renderer/index.css..."
cat > src/renderer/index.css << 'EOF'
@import "tailwindcss";

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

#root {
  width: 100%;
  height: 100vh;
}
EOF

# Create renderer main.tsx
echo "📝 Creating src/renderer/main.tsx..."
cat > src/renderer/main.tsx << 'EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# Create App component
echo "📝 Creating src/renderer/App.tsx..."
cat > src/renderer/App.tsx << 'EOF'
import React from 'react';

function App() {
  return (
    <div className="min-h-screen bg-gray-900 flex items-center justify-center">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-white mb-4">
          Electron + Vite + React
        </h1>
        <p className="text-xl text-gray-400 mb-8">
          TypeScript + Tailwind CSS
        </p>
        <div className="flex gap-4 justify-center">
          <a
            href="https://electron.dev"
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition"
          >
            Electron Docs
          </a>
          <a
            href="https://vitejs.dev"
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition"
          >
            Vite Docs
          </a>
          <a
            href="https://tailwindcss.com"
            target="_blank"
            rel="noopener noreferrer"
            className="px-6 py-3 bg-cyan-600 hover:bg-cyan-700 text-white rounded-lg transition"
          >
            Tailwind Docs
          </a>
        </div>
      </div>
    </div>
  );
}

export default App;
EOF

# Create README
echo "📝 Creating README.md..."
cat > README.md << 'EOF'
# Electron + Vite + React + TypeScript + Tailwind CSS

A minimal Electron application scaffold with modern tooling.

## Features

- ⚡ Vite for fast development
- ⚛️ React 18 with TypeScript
- 🎨 Tailwind CSS v4 (no PostCSS needed)
- 🔥 Hot Module Reloading
- 📦 electron-builder for packaging
- 🔧 Full TypeScript support

## Project Structure

```
├── src/
│   ├── main/           # Electron main process
│   │   ├── main.ts
│   │   └── preload.ts
│   ├── renderer/       # React renderer process
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   └── index.css
│   └── types/          # TypeScript definitions
│       └── electron.d.ts
├── dist/               # Vite build output
├── dist-electron/      # Electron build output
├── release/            # Final packaged app
└── index.html
```

## Development

```bash
npm run dev
```

## Build

```bash
npm run build
```

## Tech Stack

- Electron 28+
- React 18
- TypeScript 5
- Vite 5
- Tailwind CSS 4
- electron-builder

## Getting Started

1. Install dependencies: `npm install`
2. Start development: `npm run dev`
3. Build the app: `npm run build`

## Customization

- Modify `src/renderer/App.tsx` for your UI
- Add IPC handlers in `src/main/main.ts`
- Configure Tailwind in `tailwind.config.js`
- Update build settings in `electron-builder.yml`
EOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   cd $PROJECT_NAME"
echo "   npm run dev"
echo ""
echo "🚀 Happy coding!"