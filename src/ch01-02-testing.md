# 型のテスト
前章で「型エイリアスは関数である」と書きました。  
関数であればテストをするのは当然ですよね？  
実際、型レベルプログラミングでの型エイリアスは複雑で、バグも頻繁に発生するのでテストは必要です。  
今回は型のテストを行う方法を解説します。  

## `TypeEq`を除くコード

```ts
type TypeEq<A, B> = /* AとBが等しければtrueを、そうでなければfalseを返す型関数 */;

function assertType<_T extends true>() { }
function assertNotType<_T extends false>() { }
```

`TypeEq`は別に解説したいので後で解説します。  
`assertType`は以下のように使います。  

### 例1

```ts
assertType<true>();

// コンパイルエラー
assertType<false>();
```

`assertNotType`はfalseのみコンパイルが通るバージョンです。  
ただし以下のような場合もコンパイルが通ってしまうので`TypeEq`はバグのないように気をつけて実装する必要があります。  

```ts
assertType<any>();
assertType<never>();
```

実際は`TypeEq`と組み合わせて以下のように使います。  
```ts
// OK
assertType<TypeEq<1, 1>>();

// コンパイルエラー
assertType<TypeEq<1, 2>>();

// コンパイルエラー
assertType<TypeEq<any, 1>>();

// OK
assertType<TypeEq<1, ReturnType<() => 1>>>();
```

では`TypeEq`の実装を考えましょう。  
まず型の比較と考えて一番に思いつくのは`extends`ですね。  

```ts
type TypeEq<A, B> = A extends B ? true : false;
```

しかしこれでは上手く動きません。

```ts
// false
type A = TypeEq<{}, { x: number }>;

// true(おかしい)
type B = TypeEq<{ x: number }, {}>;
```

`extends`は継承関係のチェックだからです。  
`A extends B && B extends A`のような以下のコードではどうでしょうか？

```ts
type TypeEq<A, B> = A extends B ? B extends A ? true : false : false;
```

さっきの問題は解決しましたが、union typeが絡むと上手く動きません。  

```ts
// false
type A = TypeEq<{}, { x: number }>;
// false
type B = TypeEq<{ x: number }, {}>;
// true
type C = TypeEq<{ x: number }, { x: number }>;
// boolean(おかしい)
type D = TypeEq<1 | 2, 1>;
// boolean(おかしい)
type E = TypeEq<1 | 2, 1 | 2>;
```

これはconditional typeの分配機能が原因です。  
分配機能を抑制しましょう。  
conditional typeの分配機能の制御については別の章で解説します。  

```ts
type TypeEq<A, B> = [A] extends [B] ? [B] extends [A] ? true : false : false;
```

さっきの問題は解決しましたが、`any`が絡むと上手く動きません。

```ts
// false
type A = TypeEq<1 | 2, 1>;
// true
type B = TypeEq<1 | 2, 1 | 2>;
// true
type C = TypeEq<any, 1>;
```

これは`A extends B ? true : false`は`A`型の変数を`B`型の変数に代入可能であれば`true`を返すからです。  
例えば以下のコードはコンパイルが通ります。  

```ts
declare const x: { x: any };
const y: { x: number } = x;

declare const a: { x: number };
const b: { x: any } = x;
```

これは`any`が任意の型と相互に互換性があるからです。  
この問題を解決するには任意の`A, B`を含み、`A`と`B`が異なる方である時(`any`を含んでいても)互換性のない型を考える必要があります。  
具体的には`<T>() => T extends X ? 1 : 2`という型が存在します。  
ちなみにこの型、型エイリアスにしてしまうと`any`を含む時互換性が生まれてしまうので型エイリアスにしてはいけません。何故このような動作をするかは私もまだ理解出来ていません。  
ではこの型を使って`TypeEq`を完成させましょう。  

```ts
type TypeEq<A, B> = (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;

// false
type A = TypeEq<1, 2>;
// true
type B = TypeEq<1, 1>;
// false
type C = TypeEq<any, 1>;
// false
type D = TypeEq<never, 1>;
// false
type E = TypeEq<{ x: number, y: number }, { x: number } & { y: number }>;
```

この型であれば上手く動きます。  
注意してほしいのは`E`のパターンです。交差型は別の方として扱われるのでこれは`false`になります。仕様です。  
ちなみに``<T>() => T extends X ? 1 : 2``という型は`X`が別の型の時、片方向のみの互換性ではなく相互に互換性がないので、`A extends B && B extends A`のような事をしなくても交換法則がなりたちます。  

以上で型のテストの解説は終わりです。  
上手く動く`TypeEq`の実装を順番に考えていったため長くなりましたが、実際に使うのは最後に紹介した実装なのでこれをしっかりと抑えましょう。