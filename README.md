# News4Dummies

## Local development

```bash
npm install
npm run dev
```

Build for production with `npm run build` (output in `dist/`). Pushes to `main` deploy automatically to GitHub Pages via `.github/workflows/deploy.yml`.

The app is a PWA (see `vite.config.ts`'s `VitePWA` block and `public/icons/`). The icons there are placeholders generated for scaffolding — swap them for real branding whenever that's decided.
