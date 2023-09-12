chmod -R u+w /Users/markmeeus/Documents/projects/github/sandman/_build/

MIX_ENV=prod DEVELOPER_ID=6798Q58R9M mix Desktop.Installer


.... wip
# signing
MIX_ENV=prod mix run scripts/sign_macos_tempalte.exs 6798Q58R9M ./build_templates/MacOS/Sandman.app
# building beams and update app template
chmod -R u+w /Users/markmeeus/Documents/projects/github/sandman/_build/
MIX_ENV=prod mix Desktop.Installer
MIX_ENV=prod mix run scripts/release_macos_app.exs

codesign -s 6798Q58R9M --timestamp
      "-s",
      developer_id,
      "--timestamp",
      dmg
    ])
  end
# sign create and sign the dmg

xcrun notarytool submit _build/prod/Sandman-*.dmg --keychain-profile "AC_PASSWORD" --wait
artifacts/releases/MacOS/Sandman.app



xcrun notarytool log --keychain-profile "AC_PASSWORD" <request id>

--when ready
xcrun stapler staple  _build/prod/Sandman-*.dmg