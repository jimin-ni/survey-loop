USE survey_loop;
-- 페르소나 기반 합성 데이터(B2B 사진관 거래처 10곳). 실제 고객·실제 수치가 아님.
INSERT INTO customer(alias_name,track,customer_type,segment) VALUES
('거래처 A','B2B','사진관 거래처','소형 매장'),
('거래처 B','B2B','사진관 거래처','소형 매장'),
('거래처 C','B2B','사진관 거래처','소형 매장'),
('거래처 D','B2B','사진관 거래처','소형 매장'),
('거래처 E','B2B','사진관 거래처','소형 매장'),
('거래처 F','B2B','사진관 거래처','중대형 매장'),
('거래처 G','B2B','사진관 거래처','중대형 매장'),
('거래처 H','B2B','사진관 거래처','중대형 매장'),
('거래처 I','B2B','사진관 거래처','중대형 매장'),
('거래처 J','B2B','사진관 거래처','중대형 매장');
INSERT INTO survey(round_no,customer_type,status,approved_by,approved_at) VALUES (1,'사진관 거래처','closed','시연 담당자','2026-11-01 10:00:00');
INSERT INTO question_bank(q_text,customer_type,purpose_tag,source,rule_check) VALUES
('인화지·약품 주문 주기는 어떻게 결정하십니까?','사진관 거래처','재고','consulting','pass'),
('납기 지연이 영업에 영향을 준 적이 있습니까?','사진관 거래처','납기','past_survey','pass'),
('장비 고장 시 대응 속도에 만족하십니까?','사진관 거래처','기술지원','past_survey','pass'),
('우수한 인화지의 품질과 납기에 매우 만족하셨죠?','사진관 거래처','만족도','past_survey','leading'),
('가장 불편했던 점을 자유롭게 적어 주세요.','사진관 거래처','공통','past_survey','pass');
INSERT INTO survey_question(survey_id,q_id,order_no) VALUES (1,1,1),(1,2,2),(1,3,3),(1,5,4);  -- 유도 문항(q_id 4)은 규칙 검사에서 제외
INSERT INTO response(survey_id,customer_id,channel,raw_text,rating,dedup_key,is_valid,exclude_reason) VALUES
(1,1,'영업 담당 방문','인화지 주문 주기가 불규칙해서 재고 부담이 커요',2,'569b44c795842528eabb47bf80f839b9',1,NULL),
(1,2,'이메일','인화지 주문 주기가 불규칙해서 재고 부담이 커요',2,'c552c6ba5d5e53a9ff735bff3b804529',1,NULL),
(1,3,'전화 설문','최소 주문 단위가 커서 재고가 쌓여요',3,'41c0f37a72abc2d9cd74cdd0599b3075',1,NULL),
(1,4,'영업 담당 방문','인화지 주문 주기가 불규칙해서 재고 부담이 커요',2,'28e06dad0a105360c5dfe1ef785977ad',1,NULL),
(1,5,'이메일','담당자 응대가 좋아요',5,'20c4a000894a096539999f9892df4b58',1,NULL),
(1,6,'영업 담당 방문','납기가 늦어져서 영업에 차질이 있었어요',3,'2d61182f1f844e257507db0883f1cb6b',1,NULL),
(1,7,'이메일','납기가 늦어져서 영업에 차질이 있었어요',2,'5949a4d2f8e376a3ec1ba5ef9f6971d8',1,NULL),
(1,8,'전화 설문','장비가 고장 났을 때 대응이 늦었어요',3,'2e36d764ab8b3530f44b6e19811ef1ab',1,NULL),
(1,9,'이메일','담당자 응대가 좋아요',5,'c96aebafd79edf5fa7194c750f0d2adc',1,NULL),
(1,10,'영업 담당 방문','인화지 주문 주기가 불규칙해서 재고 부담이 커요',2,'dc0807826416c3e30fa8b96bb0f0e537',1,NULL),
(1,1,'영업 담당 방문','인화지 주문 주기가 불규칙해서 재고 부담이 커요',2,'569b44c795842528eabb47bf80f839b9',0,'duplicate'),
(1,9,'이메일','ㅇㅇ',NULL,'3e8711f26db7017b59ec0e4bbbf54bd7',0,'low_effort');

-- 심어 둔 정답 신호(평가 하네스의 기준): 이 신호를 에이전트가 찾아내는지 정밀도·재현율로 잰다.
--  소형 매장(유효 5건): 재고·주문 4건(A·B·C·D) → 제안 후보. 긍정 1건(E)
--  중대형 매장(유효 5건): 납기 2건(F·G), 장비 1건(H), 재고 1건(J), 긍정 1건(I) → 단일 주제 근거가 2건 이하이므로 제안 보류가 정답
--  제외 대상 2건: 거래처 A 중복 재제출, 거래처 I 무성의 응답('ㅇㅇ')
-- 확인 쿼리:
-- SELECT c.segment, COUNT(*) n FROM response r JOIN customer c USING(customer_id) WHERE r.is_valid=1 GROUP BY c.segment;
