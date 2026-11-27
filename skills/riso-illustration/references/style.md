# 화풍 기준: 투컬러 리소그래프 에디토리얼 삽화

이미지 생성 도구와 무관한 기준이다. 프롬프트는 영어로 쓴다(대부분의 생성 모델에서 더 안정적).

## 기본 화풍

- 손으로 그린 듯한 약간 불규칙한 외곽선, 단순화했지만 친근하고 개성 있는 인물·동물.
- 리소그래프 인쇄 질감: 거친 잉크 입자, 종이 결, 미세한 인쇄 위치 어긋남, 고르지 않은 채색.
- 한 장면에 메시지 하나를 담는다. 주제에 필요한 인물·소품을 두고 여백을 확보한다.
- 손은 단순하게 그리고, 자세와 손동작은 장면 속 행동에 맞춘다.
- 피한다: 사실적 묘사, 3D 렌더링, 매끈한 벡터, 그라데이션, 이미지 안의 글자·로고·워터마크.

## 팔레트

| 역할 | 기본값 | 프롬프트에 쓸 말 |
|---|---|---|
| 배경(종이) | `#FAFAF8` | warm off-white paper |
| 주 잉크 | `#171717` | charcoal black ink |
| 강조 | `#0CCCCC` | vivid cyan-teal ink |

- 모델은 헥스 코드를 정확히 지키지 못하므로 **색 이름과 헥스를 함께** 쓴다.
- 사용자가 색을 바꾸면 해당 역할만 교체하고 화풍 문장은 그대로 둔다(예: 강조 → orange `#F26B1D`).
- 2색 인쇄이지만 두 잉크가 겹친 부분의 혼색, 잉크 농도에 따른 명암은 허용한다. 색 수를 엄격히 세지 않는다.

## 프롬프트 골격

기본 화풍에서는 `[ ]`를 채운다. 지정된 스타일 가이드가 있으면 화풍·팔레트 문장을 해당 기준으로 바꾼다. 같은 작업의 후보에는 공통 기준을 적용한다.

```text
Hand-drawn two-color Risograph editorial illustration with slightly irregular outlines, grainy ink on paper, subtle ink misregistration, uneven ink coverage, and simplified friendly characters.
Palette: warm off-white paper (#FAFAF8), charcoal black ink (#171717), vivid cyan-teal ink (#0CCCCC); overlapping inks may blend.
Scene and composition: [situation, viewpoint, framing, action, and essential props]. Leave generous space around the subject. Use simple hands with natural gestures where visible.
Aspect ratio [1:1 | 3:2 | 16:9]. No text, logos, or watermark.
```

- 참고 사진이 있으면: `Stylized portrait loosely based on the reference photo: keep [hair, glasses, facial hair…], simplified into the style above. Not a photographic likeness.`
- 새 장면에 캐릭터 시트나 기준 삽화를 쓸 때는 참고 이미지마다 계승할 외형·화풍을 명시하고 새 구도를 지시한다.
- 수정 때는 한 줄을 더한다: `Keep unchanged: [composition, character, palette]. Change only: [요청한 부분].`

## 검수 기준

1. 구도와 행동이 전달할 메시지를 한눈에 보여 주고, 인물·소품·여백이 이를 뒷받침한다. 손동작은 자연스럽고 행동에 맞는다.
2. 배경색·팔레트·선·질감·캐릭터 외형이 적용한 스타일 기준과 맞는다. 대표 참조가 있으면 나란히 비교한다.
3. 같은 문서나 시리즈의 인접 삽화 및 다른 후보와 구도·행동이 불필요하게 반복되지 않는다. 새 장면이 필요한 경우 기준 삽화의 크롭·반전·색상 변경본을 재사용하지 않는다.
4. 이미지의 비율과 원본 해상도가 배치 목적에 맞고, 사용할 크기에서 읽힌다. 의도하지 않은 글자·로고·워터마크가 있는지 확인한다.
