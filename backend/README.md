# NOVA Backend

Express + SQLite API for NOVA.

## Setup

1. Install Node 18+.
2. Install deps:

```
cd backend
npm install
```

3. Create env (optional):

```
copy .env.example .env # Windows
# or
cp .env.example .env   # macOS/Linux
```

4. Run:

```
npm run dev
# or
npm start
```

## Endpoints

- GET /health
- POST /auth/register {email, password}
- POST /auth/login {email, password}
- GET /products
- POST /products {name, price, stock?}
- GET /sales
- POST /sales {product_id, product_name, quantity, unit_price, sale_date}
- GET /summary/daily?date=yyyy-mm-dd

DB file: data/nova.db (auto-created).

