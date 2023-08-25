
Erlang moet gecompiled zijn met --disable-dynamic-ssl-lib
Open ssl met homebrew

deze werkt ni ?
export KERL_CONFIGURE_OPTIONS="-–disable-dynamic-ssl-lib --without-javac --with-ssl=/usr/local/Cellar/openssl@3/3.1.2"

=> deze werkt
export KERL_CONFIGURE_OPTIONS="-–disable-dynamic-ssl-lib --without-javac --with-ssl=/usr/local/Cellar/openssl@3/3.1.2

=> asdf kan
=> dit kan ook
kerl build git https://github.com/erlang/otp.git OTP-26.0.2 erlang-kerl-26

