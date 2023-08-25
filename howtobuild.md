chmod -R u+w /Users/markmeeus/Documents/projects/github/sandman/_build/

MIX_ENV=prod DEVELOPER_ID=6798Q58R9M mix Desktop.Installer



xcrun notarytool submit _build/prod/Sandman-*.dmg --keychain-profile "AC_PASSWORD" --wait



xcrun notarytool log --keychain-profile "AC_PASSWORD" <request id>

--when ready
xcrun stapler staple  _build/prod/Sandman-*.dmg