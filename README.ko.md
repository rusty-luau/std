<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/logo-white.svg">
    <img src="assets/logo-black.svg" alt="rusty-luau" width="200" />
  </picture>
</p>

<p align="center">
  <a href="README.md">English</a>
</p>

# rusty-luau/std

Luau를 위한 Rust 스타일 표준 라이브러리. [Lute](https://github.com/luau-lang/lute) 위에서 동작합니다.

## 개요

Luau는 기본적으로 격리되어 있고, 주로 Roblox 같은 호스트 환경에 임베드되는 언어라서, 독립형 유틸리티 생태계가 Rust 같은 언어에 비해 빈약합니다. `Result`, `Option`, `Future` 같은 Rust의 기본 구성 요소들은 커뮤니티 차원에서 부분적으로 포팅되어 있지만, `Iter<T>`나 그 너머의 표준 라이브러리 표면은 여전히 비어 있습니다. 이 리포지토리는 Rust 표준 라이브러리를 가능한 한 관용적인 형태로 Luau에 옮겨서 그 공백을 메우려는 시도입니다.

## 목표

Rust 스타일의 빌딩 블록을 제공합니다. `snake_case` 메서드, `Result` 기반 에러 처리, 명시적인 케이스 처리 등 Rust 컨벤션을 따릅니다. 장기 목표는 Rust 개발자가 `std`에서 일반적으로 찾을 만한 것들 대부분을 다루는 것이고, 우선 algebraic data type부터 시작해 iterator, collection 등으로 확장해 나갈 예정입니다.

이 프로젝트는 의도적으로 야심찬 목표를 잡고 있습니다. 결과물이 프로덕션 코드나 게임 개발에서 실용적으로 쓰일지는 미지수입니다. 다만 Luau 개발자에게는 익숙한 추상화를, Rust 개발자에게는 Luau로 들어오는 길을 덜 낯설게 해 준다는 점에 가치가 있다고 봅니다.

## 상태

`0.1.0` 이전. 아직 minor 릴리스도 태그하지 않은 단계입니다. 안정화되기 전까지는 설치 가이드, 빠른 시작 가이드, 그리고 렌더링된 문서 사이트(`rusty-luau.github.io` 등)는 없습니다.

## 문서화

소스 코드 주석은 [moonwave](https://eryn.io/moonwave/) 형식으로 작성됩니다. 추후 moonwave가 rusty-luau가 표현하고자 하는 바에 부족하다고 판단되면, rusty-luau 전용 docgen을 별도로 개발할 가능성도 있습니다.

## AI에 대해
이 프로젝트에서는 AI 에이전트를 사용합니다. 저희는 AI 에이전트를 아래의 경우에만 사용합니다.

- 테스트 케이스 작성
- 복잡한 타입 & 타입 함수 작성 및 자문
- 번역

모든 AI 에이전트의 작업물들은 전부 사람이 추가 검토를 하고 있습니다.