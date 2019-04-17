# 再帰
型エイリアスは関数なのでループ処理も行いたいです。  
しかし型の世界は純粋なのでループではなく再帰を使います。これは関数型言語と同じです。  
では再帰を行う方法を解説します。

今回はサンプルとして型レベル自然数の足し算を実装してみます。  
まず型レベル自然数の定義として以下のコードを使います。

```ts
type Zero = null;
type Nat = Zero | { pred: Nat };

type Succ<N extends Nat> = { pred: N };
type Pred<N extends Nat> = N extends { pred: infer X } ? X : Zero;

type N0 = Zero;
type N1 = Succ<N0>;
type N2 = Succ<N1>;
type N3 = Succ<N2>;
type N4 = Succ<N3>;
type N5 = Succ<N4>;
```

`Nat`は`null`は`0`を表し、`{ pred: null }`は`1`を表し、`{ pred: { pred: null } }`は`2`を表し…といった再帰的な型レベル自然数です。  
`Succ`はインクリメント、`Pred`はデクリメントです。`0`をデクリメントすると`0`になります。  
また`N0`〜`N5`は`0`〜`5`を表すエイリアスです。エイリアスを作っていないだけで`6`以上の値も当然表すことが出来ます。  

では足し算をどう実装すればいいでしょうか？  
値の世界でのコードは以下のようになることが想像出来ると思います。

```ts
function add(a: number, b: number): number {
  if (b === 0) {
    return a;
  } else {
    return add(a + 1, b - 1);
  }
}
```

今回はこれを型の世界で実装します。まず思いつく実装は以下のような実装ですね。

```ts
type Add<A extends Nat, B extends Nat> = B extends Zero ? A : Add<Succ<A>, Pred<B>>;
```

しかしこれは`Type alias 'Add' circularly references itself.`というエラーが発生します。  
TypeScriptの型エイリアスでは基本的に再帰は許可されていないのです。  

しかし例外があります。それはオブジェクト型です。  
例えば以下のような型は問題なくコンパイルが通ります。  

```ts
type Foo = {
  foo: Foo
};
```

つまりオブジェクト型の中であれば再帰的な定義が可能です。  
これとIndex Signatures機能を使ってこの制限を回避するテクニックを使います。  

今回の足し算の例では以下のようになります。  

```ts
type Add<A extends Nat, B extends Nat> = {
  0: A,
  1: Add<Succ<A>, Pred<B>>,
}[B extends Zero ? 0 : 1];
```

ちゃんと動くか確かめてみましょう。

```ts
assertType<TypeEq<Add<N0, N0>, N0>>();
assertType<TypeEq<Add<N3, N0>, N3>>();
assertType<TypeEq<Add<N0, N3>, N3>>();
assertType<TypeEq<Add<N2, N3>, N5>>();
```

きちんとコンパイルが通るので動いています。

一般的に分岐が2つの時は以下のように書きます。  

```ts
type Add<A extends Nat, B extends Nat> = {
  0: /* 条件0の結果値(基底部を書くことが多い) */,
  1: /* 条件1の結果値(ここで再帰を行うことが多い) */,
}[/* 条件 */ ? 0 : 1];
```

インデックスに`0, 1`を使っていますがこれは`"a", "b"`などでも構いません。
分岐が3つ以上の時も例えば以下のように数字と条件を増やすだけです。

```ts
type Add<A extends Nat, B extends Nat> = {
  0: /* 条件0の結果値 */,
  1: /* 条件1の結果値 */,
  2: /* 条件2の結果値 */,
}[/* 条件 */ ? 0 : /* 条件 */ ? 1 : 2];
```

ただし注意点としてオブジェクトの中で再帰を行っていても明らかに無限再帰となる条件はコンパイルエラーとなります。  
例えば以下の例はエラーとなります。

```ts
type Ex1<T> = {
  0: T,
  1: Ex1<T>
}[1];
```

ただし定義部分でチェック出来ないが、使用部分で無限再帰、もしくは再帰の上限を越えた場合はその時にエラーになります。  
例えば以下のコードだけではコンパイルが正常に通ります。  

```ts
type Ex2<T extends number> = {
  0: T,
  1: Ex2<T>
}[T extends number ? 0 : 1];
```

このコードを追加しても問題ありません。  

```ts
type A = Ex2<1>;
```

しかし以下のコードを追加すると無限再帰となりエラーが発生します。  

```ts
type B = Ex2<"a">;
```

この例ではコードを追加した時点で`Ex2`の定義部分にエラーが発生します(これはかなり気持ち悪い) 
ただし使用部分でエラーが発生することもあります。  
どっちでエラーが発生するかの条件は調査中です。

以上で再帰の紹介を終わります。