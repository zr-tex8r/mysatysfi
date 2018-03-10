mysatysfi
=========

Vagrant運用のWindowsマシンでもSATySFiしたいやつ

準備
----

  * Vagrant
  * Perl

手順
----

（cloneしたディレクトリで）

  * `vagrant up`する
  * `vagrant ssh`してVMにログイン
      * `nohup foolysh_server /vagrant/foolysh &`を実行
      * `exit`でVMを抜ける
  * `vagrant/foolysh`ディレクトリのフルパス名を環境変数`WYNHOTEP_FOOLYSH_DIR`に設定
  * `perl wynhotep/wynhotep.pl`でSATySFiできる
  * 楽しい！

ライセンス
----------

`startup/`内のフォントファイルは各々のライセンスに従う。

  * `ipaex*.ttf`：IPAフォントライセンスv1.0
  * `Junicode*.ttf`： OFL v1.1

上記以外のコンテンツはMITライセンスに従う。

--------------------
Takayuki YATO (aka. "ZR")  
https://github.com/zr-tex8r
