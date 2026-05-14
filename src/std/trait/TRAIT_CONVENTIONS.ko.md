<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-white.svg">
    <img src="assets/logo-black.svg" alt="rusty-luau" width="200" />
  </picture>
</p>

<p align="center">
  <a href="TRAIT_CONVENTIONS.md">English</a>
</p>

# Trait 컨벤션

[`src/std/trait`](src/std/trait/init.luau)으로 trait을 정의하고 구현하는 방법.

타입 관련 장치는 의도적으로 명시적으로 드러나 있습니다 - 이걸 똑똑한 런타임
래퍼 뒤에 숨기려던 이전 시도들은 풀 수 없는 타입 에러(`*CYCLE*`, "Calling
function ... is ambiguous")를 만들어 냈습니다. 이 컨벤션은 그 명시적인 부분들을
일관되게 유지해서, 쓰기 쉽고, 읽기 쉽고, 미묘하게 잘못 쓰기 어렵게 만듭니다.

동작하는 정식 레퍼런스는 [`src/std/trait/examples/`](src/std/trait/examples/)에
있습니다: `AnimalTrait` + `Sheep`/`Wolf` (non-generic), `IterTrait` +
`RangeIter` (generic).

## 단 하나의 핵심 규칙

**implementer의 public 타입에 있는 모든 메서드는 출처가 정확히 하나여야 합니다.**

교차 타입 안에서 어떤 메서드가 두 번 나타나면 - 한 번은 클래스 자신의 메서드
테이블에서, 한 번은 trait 계약에서 - 그 메서드는 *오버로드된* 함수가 되고
Luau는 그것의 호출을 거부합니다. 이전의 두 trait 설계 모두 정확히 이 지점에서
깨졌습니다.

아래의 컨벤션들은 그 규칙을 만족시키기 위한 기계적인 방법일 뿐입니다.

## Trait 정의하기

trait 모듈은 세 개의 타입을 export하고 `trait.define(defaults)`를 반환합니다:

- `Requires<Self, ...>` - required 메서드 계약. implementer 자신의 타입 `Self`
  (와 필요한 요소 타입들)에 대해 제네릭합니다. 제네릭 `Self`는 계약을 완전히
  타입 안전하게 유지합니다: implementer의 `(self: Sheep) -> string`은
  `any` 확장 없이 `Requires<Sheep>`를 정확히 만족합니다.
- `Defaults` - `typeof(defaults)`, default 메서드 테이블.
- `For<Self, ...>` - `Requires<...> & Defaults`. implementer가 자신의 public
  타입에 교차시키는 trait의 전체 표면.

```luau
local trait = require("../../trait")

-- required 메서드 계약. implementer의 타입 `Self`에 대해 제네릭.
export type Requires<Self> = {
    noise: (self: Self) -> string;
}

local defaults = {}

-- default 메서드는 *제네릭 함수*입니다. `self`는 `Self & Requires<Self>`:
--  * `& Requires<Self>` 덕분에 본문에서 required 메서드를 호출할 수 있습니다 -
--    `Self & Requires<Self>`가 `Self`의 서브타입이라서 `self:noise()`가 통과합니다;
--  * 앞쪽의 `Self`는 호출자가 자신의 완전한 구체 타입을 다시 넘길 수 있게 합니다.
-- *다른* default를 호출하는 default는 `Self & Requires<Self> & Defaults`를 씁니다.
function defaults.introduce<Self>(self: Self & Requires<Self>): ()
    print(`Hi-{ self:noise() }`)
end

export type Defaults = typeof(defaults)
export type For<Self> = Requires<Self> & Defaults

return trait.define(defaults)
```

규칙:

- default 메서드의 `self`는 **항상** `Self & Requires<Self>`입니다 (그 메서드가
  다른 default를 호출할 때만 `& Defaults`를 추가). 절대 `self: any`를 쓰지
  않습니다.
- `define`은 turbofish를 받지 않습니다 - `D`는 `defaults`로부터 추론됩니다.
- 제네릭 trait은 `Requires` / `For`에 타입 파라미터를 추가합니다 (예:
  `Requires<Self, T>`); `defaults` 테이블 자체는 non-generic으로 유지되며
  제네릭 *함수*들을 담습니다. 따라서 `define`은 여전히 평범한 호출 한 번입니다.

## Trait 구현하기

```luau
local trait = require("../../trait")
local AnimalTrait = require("./AnimalTrait")

-- 1. 평범한 메서드 테이블. required 메서드를 여기에 직접 작성합니다.
local SheepMethods = {}

function SheepMethods.noise(self: Sheep): string
    return "baaaaaah!"
end

-- 2. `impl`이 계약을 검사하고 (`noise`가 없거나 잘못된 타입이면 *바로 이 줄*에서
--    에러), trait의 default 메서드들을 런타임에 `SheepMethods`로 복사합니다.
--    turbofish: `<<typeof(methods), Trait.Requires<Self, ...>>>`.
trait.impl<<typeof(SheepMethods), AnimalTrait.Requires<Sheep>>>(SheepMethods, AnimalTrait)

-- 3. 프로토타입. `__index`를 `{}`로 캐스팅해서 *타입*이 메서드들을 다시
--    노출하지 않게 합니다 - 메서드는 오직 아래의 `& For<Self>`에서만 와야
--    하며, 그렇지 않으면 출처가 둘이 되어 ambiguous 오버로드로 무너집니다.
local SheepPrototype = table.freeze({
    __index = SheepMethods :: {};
})

-- 4. public 타입: 메타테이블 형태에 trait 표면을 교차시킨 것.
--    `& AnimalTrait.For<Sheep>`는 모든 trait 메서드의 단일 출처이며,
--    `Sheep <: AnimalTrait.For<Sheep>`가 자명하게 성립하도록 만듭니다.
export type Sheep = setmetatable<{
    read kind: "Sheep";
}, typeof(SheepPrototype)> & AnimalTrait.For<Sheep>

-- 5. 생성자. `:: Sheep` 캐스트는 필수입니다: 원시 `setmetatable` 값은 복사되어
--    들어온 default들을 자신의 타입에 담을 수 없으므로, 여기서 좁혀 줍니다.
local function new(): Sheep
    return table.freeze(setmetatable({
        kind = "Sheep" :: "Sheep";
    }, SheepPrototype)) :: Sheep
end

return table.freeze({
    new = new;
})
```

규칙:

- 메서드 테이블(`SheepMethods`)은 클래스 **자신의** 메서드만 담습니다.
  default는 여기에 절대 작성하지 않습니다 - `impl`이 런타임에 주입합니다.
- `impl`은 `typeof(methods)`와, 이 implementer의 `Self`(및 요소 타입들)로
  인스턴스화한 trait의 `Requires`로 turbofish합니다. 이 패턴에서 반환값은
  사용하지 않습니다; 호출의 목적은 계약 검사 + 런타임 default 복사입니다.
- `__index`는 **항상** `:: {}`로 캐스팅합니다.
- public 타입은 **항상** `setmetatable<Fields, typeof(Prototype)> & Trait.For<Self>`입니다.
- 생성자 본문은 **항상** `:: T`로 끝납니다.
- 여러 trait: `& TraitA.For<Self> & TraitB.For<Self>`처럼 추가하고, `impl`
  호출도 각각 한 번씩 합니다. (trait들의 메서드 이름은 충돌하면 안 됩니다.)

## 이상한 부분들이 왜 있는가 - "정리"하지 마세요

| 지울 수 있어 보이는 것 | 왜 남아 있어야 하는가 |
| --- | --- |
| `__index = methods :: {}` | `:: {}`가 없으면 메서드가 `__index`와 `& For<Self>` 양쪽에 타입으로 잡혀 ambiguous 오버로드가 됩니다. |
| 생성자의 `:: T` | `setmetatable` 값의 타입은 런타임에 복사된 default를 포함할 수 없습니다; 캐스트가 선언된 표면으로 좁혀 줍니다. |
| 모든 default 메서드의 제네릭 `<Self>` | non-generic / `any` `self`는 메서드 본문을 깨거나, implementer가 `any`를 받도록 강제합니다. |
| 표면을 명시적으로 적은 `& Trait.For<Self>` | `Impl <: Trait.For<Self>`를 자명하게 만들어, solver가 메타테이블을 통해 그것을 재구성하지 않고도 trait 메서드 호출이 해결되게 합니다. |
