-- Survey Loop 데이터 모델 (MySQL 8.x) · LOTTE AX Challenge 과제 7 제안용
-- 원칙: 응답 원문은 지우지 않고, 분류·제안·승인·성과는 별도 테이블에 쌓아 "근거 응답 ID"로 추적한다.
CREATE DATABASE IF NOT EXISTS survey_loop DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE survey_loop;

CREATE TABLE customer (
  customer_id   INT AUTO_INCREMENT PRIMARY KEY,
  alias_name    VARCHAR(40) NOT NULL,                     -- 식별정보 대신 가명 표기
  track         ENUM('B2B','B2C') NOT NULL,
  customer_type VARCHAR(40) NOT NULL,                     -- 예: 사진관 거래처, 인스탁스 구매 고객
  segment       VARCHAR(40) NOT NULL,                     -- 예: 소형 매장, 중대형 매장
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE survey (
  survey_id   INT AUTO_INCREMENT PRIMARY KEY,
  round_no    INT NOT NULL,                               -- 루프 회차
  customer_type VARCHAR(40) NOT NULL,
  status      ENUM('draft','approved','sent','closed') NOT NULL DEFAULT 'draft',
  approved_by VARCHAR(40) NULL,
  approved_at DATETIME NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_round (customer_type, round_no)
);

CREATE TABLE question_bank (
  q_id          INT AUTO_INCREMENT PRIMARY KEY,
  q_text        VARCHAR(300) NOT NULL,
  customer_type VARCHAR(40) NOT NULL,
  purpose_tag   VARCHAR(40) NOT NULL,                     -- 예: 재고, 납기, 만족도
  source        ENUM('past_survey','consulting','revision') NOT NULL,
  rule_check    ENUM('pass','leading','double','too_long') NOT NULL DEFAULT 'pass',
  active        TINYINT(1) NOT NULL DEFAULT 1
);

CREATE TABLE survey_question (
  survey_id INT NOT NULL,
  q_id      INT NOT NULL,
  order_no  INT NOT NULL,
  PRIMARY KEY (survey_id, q_id),
  FOREIGN KEY (survey_id) REFERENCES survey(survey_id),
  FOREIGN KEY (q_id) REFERENCES question_bank(q_id)
);

CREATE TABLE response (
  response_id    INT AUTO_INCREMENT PRIMARY KEY,
  survey_id      INT NOT NULL,
  customer_id    INT NOT NULL,
  channel        VARCHAR(20) NOT NULL,                    -- 영업 담당 방문, 이메일, 전화 설문 등
  raw_text       VARCHAR(1000) NOT NULL,                  -- 원문 보존
  rating         TINYINT NULL,
  dedup_key      CHAR(32) NOT NULL,                       -- MD5(customer_id + 정규화 문구)
  is_valid       TINYINT(1) NOT NULL DEFAULT 1,
  exclude_reason ENUM('duplicate','low_effort') NULL,
  submitted_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_dedup (survey_id, dedup_key),
  FOREIGN KEY (survey_id) REFERENCES survey(survey_id),
  FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

CREATE TABLE response_tag (                               -- LLM 분류 결과(고정 JSON 스키마)
  response_id   INT NOT NULL,
  run_no        INT NOT NULL,                             -- 같은 입력 반복 실행(재현성 측정)
  topic         VARCHAR(40) NOT NULL,
  sentiment     ENUM('neg','neu','pos') NOT NULL,
  urgency       TINYINT(1) NOT NULL DEFAULT 0,
  model_version VARCHAR(40) NOT NULL,
  PRIMARY KEY (response_id, run_no),
  FOREIGN KEY (response_id) REFERENCES response(response_id)
);

CREATE TABLE proposal (
  proposal_id    INT AUTO_INCREMENT PRIMARY KEY,
  survey_id      INT NOT NULL,
  segment        VARCHAR(40) NOT NULL,
  topic          VARCHAR(40) NOT NULL,
  title          VARCHAR(120) NOT NULL,
  action_plan    VARCHAR(500) NOT NULL,
  owner_dept     VARCHAR(40) NOT NULL,
  due_label      VARCHAR(40) NOT NULL,
  priority_score INT NOT NULL,
  status         ENUM('held','pending','approved','rejected') NOT NULL,
  hold_reason    VARCHAR(100) NULL,                       -- 표본 하한 미달, 근거 응답 없음 등
  FOREIGN KEY (survey_id) REFERENCES survey(survey_id)
);

CREATE TABLE proposal_evidence (                          -- 제안과 근거 응답의 연결(없으면 제안 불가)
  proposal_id INT NOT NULL,
  response_id INT NOT NULL,
  PRIMARY KEY (proposal_id, response_id),
  FOREIGN KEY (proposal_id) REFERENCES proposal(proposal_id),
  FOREIGN KEY (response_id) REFERENCES response(response_id)
);

CREATE TABLE approval_log (
  log_id      INT AUTO_INCREMENT PRIMARY KEY,
  proposal_id INT NOT NULL,
  actor       VARCHAR(40) NOT NULL,
  decision    ENUM('approve','reject','revise') NOT NULL,
  reason      VARCHAR(300) NULL,
  decided_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (proposal_id) REFERENCES proposal(proposal_id)
);

CREATE TABLE outcome (
  outcome_id  INT AUTO_INCREMENT PRIMARY KEY,
  proposal_id INT NOT NULL,
  metric      VARCHAR(60) NOT NULL,                       -- 예: 재주문율, 채택률
  baseline    DECIMAL(12,2) NULL,
  measured    DECIMAL(12,2) NULL,
  measured_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (proposal_id) REFERENCES proposal(proposal_id)
);
