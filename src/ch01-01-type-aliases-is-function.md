# 型エイリアスは関数である
TSの型レベルプログラミングでは型エイリアスを関数と考えます。  
型の世界なので純粋な関数です。  

```ts
// 引数が0個の関数(もしくは定数)
type F0 = ...;

// 引数を1個受け取る関数
type F1<A> = ...;

// 引数を2個受け取る関数
type F2<A, B> = ...;

// これは引数に型を指定するのと似ている
type G1<A extends Type> = ...;
```

例として`boolean`型の引数`X`を1つ受け取り、`X`が`true`なら`1`を、`false`なら`0`を返す関数`F`を定義してみます。

```ts
type F<X extends boolean> = X extends true ? 1 : 0;

// 1
type A = F<true>;

// 0
type B = F<false>;
```

これを見ると型エイリアスが少し関数に見えてきたのではないでしょうか？