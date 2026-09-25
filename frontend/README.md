# Frontend: React + TypeScript + Vite

See the [root README](../README.md) for setup and [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md#frontend-structure)
for the folder structure.

```bash
npm install
npm run dev          # http://localhost:5173, proxies /api -> http://localhost:3000 (override: API_PROXY_TARGET)
npm run typecheck    # tsc strict
npm run lint         # ESLint (typescript-eslint strictTypeChecked, react-hooks)
npm run format       # Prettier
npm run build        # production bundle in dist/
```

For a separately hosted API, set `VITE_API_URL` (see `.env.example`) and add the SPA's origin to the API's
`CORS_ORIGINS`.
