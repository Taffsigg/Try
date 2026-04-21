-- PostgreSQL schema (representative, generated via Sequelize models)
CREATE TYPE user_role AS ENUM ('admin', 'finance', 'operations', 'viewer');
CREATE TYPE transaction_type AS ENUM ('deposit', 'withdrawal', 'trade', 'fee');
CREATE TYPE transaction_status AS ENUM ('pending', 'completed', 'failed');

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role user_role NOT NULL DEFAULT 'viewer',
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE clients (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  company_info TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE wallet_addresses (
  id SERIAL PRIMARY KEY,
  client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  label VARCHAR(255),
  address VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE transactions (
  id SERIAL PRIMARY KEY,
  client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  asset VARCHAR(255) NOT NULL,
  amount DECIMAL(20,8) NOT NULL,
  usd_equivalent DECIMAL(20,2) NOT NULL,
  type transaction_type NOT NULL,
  status transaction_status NOT NULL DEFAULT 'pending',
  notes TEXT,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE ledger_entries (
  id SERIAL PRIMARY KEY,
  transaction_id INTEGER UNIQUE NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  asset VARCHAR(255) NOT NULL,
  amount DECIMAL(20,8) NOT NULL,
  usd_value DECIMAL(20,2) NOT NULL,
  timestamp TIMESTAMP NOT NULL,
  status transaction_status NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE TABLE audit_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id),
  action VARCHAR(255) NOT NULL,
  entity VARCHAR(255) NOT NULL,
  entity_id VARCHAR(255),
  changes JSONB,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
