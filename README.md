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

MITライセンスに従う。

--------------------
Takayuki YATO (aka. "ZR")  
https://github.com/zr-tex8r
