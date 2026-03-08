Pod::Spec.new do |s|
  s.name             = 'lua_engine'
  s.version          = '0.0.1'
  s.summary          = 'Embedded Lua 5.4 scripting engine for Flutter macOS.'
  s.homepage         = 'https://github.com/voidash/constitution-of-nepal'
  s.license          = { :type => 'MIT' }
  s.author           = { 'NagarikPatro' => 'dev@nagarikpatro.com' }
  s.platform         = :osx, '11.0'
  s.swift_version    = '5.0'

  s.source           = { :path => '.' }
  s.source_files     = [
    'Classes/**/*.{swift,h,c}',
    '../src/lua54/*.{c,h}'
  ]
  s.exclude_files    = [
    '../src/lua54/lua.c',
    '../src/lua54/luac.c'
  ]

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/../src/lua54',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) LUA_USE_MACOSX',
    # Lua C files must NOT use ARC
    'OTHER_CFLAGS' => '$(inherited) -fno-objc-arc',
  }

  s.dependency 'FlutterMacOS'
end
