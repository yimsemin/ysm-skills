# 화풍 기준: 투컬러 리소그래프 에디토리얼 삽화

이미지 생성 도구와 무관한 기준이다. 프롬프트는 영어로 쓴다(대부분의 생성 모델에서 더 안정적).

## 화풍

- 손으로 그린 듯한 약간 불규칙한 외곽선, 단순화했지만 친근하고 개성 있는 인물·동물.
- 리소그래프 인쇄 질감: 거친 잉크 입자, 종이 결, 미세한 인쇄 위치 어긋남, 고르지 않은 채색.
- 아이콘이 아니라 **장면**을 그린다. 주제가 분명하고, 소품은 주제에 필요한 것만, 배경은 여유 있게 비운다.
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

`[ ]`만 채운다. 앞의 두 문장(화풍·팔레트)은 모든 후보에 같게 둔다.

```text
Hand-drawn two-color Risograph editorial illustration: slightly irregular imperfect outlines, grainy ink texture on paper, subtle misregistration between ink layers, uneven ink coverage, simplified friendly characters. Flat printed look, no gradients, no 3D, no photorealism, no smooth vector.
Palette: warm off-white paper (#FAFAF8), charcoal black ink (#171717), vivid cyan-teal ink (#0CCCCC); overlapping inks may blend.
Scene: [subject and situation]. Composition: [camera/viewpoint, framing, action, props, background]. Generous empty space around the subject.
Aspect ratio [1:1 | 3:2 | 16:9]. No text, no letters, no logos, no watermark.
```

- 참고 사진이 있으면: `Stylized portrait loosely based on the reference photo: keep [hair, glasses, facial hair…], simplified into the style above. Not a photographic likeness.`
- 수정 때는 한 줄을 더한다: `Keep unchanged: [composition, character, palette]. Change only: [요청한 부분].`

## 검수 기준

생성물을 보고 하나라도 어긋나면 알리고 다음 라운드에서 고친다.

1. 이미지 안에 글자·로고가 없다.
2. 선이 손그림처럼 불규칙하고 질감(입자, 종이 결, 어긋남)이 보인다. 매끈한 벡터·3D·사진 느낌이 아니다.
3. 팔레트가 요청한 색(기본이면 위 세 색)이고 그라데이션이 없다.
4. 주제가 한눈에 읽히고 소품이 주제와 관련 있다.
5. 후보끼리 구도·동작·소품이 실제로 다르고 화풍은 같다.
6. 비율이 용도에 맞다.
