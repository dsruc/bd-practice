CREATE ROLE admin_role LOGIN PASSWORD 'admin_pass' SUPERUSER;

CREATE ROLE app_user LOGIN PASSWORD 'app_user_pass';
GRANT CONNECT ON DATABASE company_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;

CREATE ROLE read_only_role LOGIN PASSWORD 'user_password';
GRANT CONNECT ON DATABASE company_db TO read_only_role;
GRANT USAGE ON SCHEMA public TO read_only_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only_role;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
