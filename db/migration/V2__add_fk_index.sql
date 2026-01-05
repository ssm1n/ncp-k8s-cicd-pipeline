-- users.email에 유니크 제약 추가
ALTER TABLE users
  ADD CONSTRAINT uk_users_email UNIQUE (email);
 
-- orders.user_id → users.id FK 추가
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_user
  FOREIGN KEY (user_id)
  REFERENCES users(id);
 
-- 조회 성능 테스트용 복합 인덱스 추가
ALTER TABLE orders
  ADD INDEX idx_user_created (user_id, created_at);
