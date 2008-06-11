# User customizable variables.

RUBY_INSTALL_NAME = 'macruby'
RUBY_SO_NAME = RUBY_INSTALL_NAME
ARCHS = %w{ppc i386}
FRAMEWORK_NAME = 'MacRuby'
FRAMEWORK_INSTDIR = '/Library/Frameworks'

# Everything below this comment should *not* be customized.

version_h = File.read('version.h')
NEW_RUBY_VERSION = version_h.scan(/#\s*define\s+RUBY_VERSION\s+\"([^"]+)\"/)[0][0]
MACRUBY_VERSION = version_h.scan(/#\s*define\s+MACRUBY_VERSION\s+(.*)/)[0][0]

NEW_RUBY_PLATFORM = 'universal-darwin' + `uname -r`.scan(/^\d+.\d+/)[0]

FRAMEWORK_PATH = File.join(FRAMEWORK_INSTDIR, FRAMEWORK_NAME + '.framework')
FRAMEWORK_VERSION = File.join(FRAMEWORK_PATH, 'Versions', MACRUBY_VERSION)
FRAMEWORK_USR = File.join(FRAMEWORK_VERSION, 'usr')
FRAMEWORK_USR_LIB = File.join(FRAMEWORK_USR, 'lib')
FRAMEWORK_USR_LIB_RUBY = File.join(FRAMEWORK_USR_LIB, 'ruby')

RUBY_LIB = File.join(FRAMEWORK_USR_LIB_RUBY, NEW_RUBY_VERSION)
RUBY_ARCHLIB = File.join(RUBY_LIB, NEW_RUBY_PLATFORM)
RUBY_SITE_LIB = File.join(FRAMEWORK_USR_LIB_RUBY, 'site_ruby')
RUBY_SITE_LIB2 = File.join(RUBY_SITE_LIB, NEW_RUBY_VERSION)
RUBY_SITE_ARCHLIB = File.join(RUBY_SITE_LIB2, NEW_RUBY_PLATFORM)
RUBY_VENDOR_LIB = File.join(FRAMEWORK_USR_LIB_RUBY, 'vendor_ruby')
RUBY_VENDOR_LIB2 = File.join(RUBY_VENDOR_LIB, NEW_RUBY_VERSION)
RUBY_VENDOR_ARCHLIB = File.join(RUBY_VENDOR_LIB2, NEW_RUBY_PLATFORM)

ARCHFLAGS = ARCHS.map { |a| '-arch ' + a }.join(' ')
CFLAGS = "-I. -I./include -I/usr/include/libxml2 #{ARCHFLAGS} -fno-common -pipe -O2 -g -Wall -Wno-parentheses"
OBJC_CFLAGS = CFLAGS + " -fobjc-gc-only"
LDFLAGS = "-lpthread -ldl -lxml2 -lobjc -lffi -lauto -framework Foundation"
DLDFLAGS = "-dynamiclib -undefined suppress -flat_namespace -install_name #{File.join(FRAMEWORK_USR_LIB, 'lib' + RUBY_SO_NAME + '.dylib')} -current_version #{MACRUBY_VERSION} -compatibility_version #{MACRUBY_VERSION}"

OBJS = %w{ 
  array bignum class compar complex dir enum enumerator error eval load proc 
  file gc hash inits io marshal math numeric object pack parse process prec 
  random range rational re regcomp regenc regerror regexec regparse regsyntax
  ruby signal sprintf st string struct time transcode util variable version
  blockinlining compile debug iseq vm vm_dump thread cont id objc bs encoding
  main dln dmyext enc/ascii missing/lgamma_r prelude miniprelude gc-stub
}

def exec_line(line)
  $stderr.puts line
  exit 1 unless system(line)
end

require 'fileutils'

class Builder
  attr_reader :objs, :cflags
  attr_accessor :objc_cflags, :ldflags, :dldflags

  def initialize(objs)
    @objs = objs.dup
    @cflags = CFLAGS
    @objc_cflags = OBJC_CFLAGS
    @ldflags = LDFLAGS
    @dldflags = DLDFLAGS
    @obj_sources = {}
    @header_paths = {}
  end

  def build
    OBJS.each do |obj| 
      if should_build?(obj) 
        s = obj_source(obj)
        flags = File.extname(s) == '.m' ? @objc_cflags : @cflags
        cc("#{flags} -c #{s} -o #{obj}.o")
      end
    end
  end
 
  def link_executable(name, objs=nil, ldflags=nil)
    link(objs, ldflags, "-o #{name}", name)
  end

  def link_dylib(name, objs=nil, ldflags=nil)
    link(objs, ldflags, "#{@dldflags} -o #{name}", name)
  end

  def link_archive(name, objs=nil)
    objs ||= @objs
    if should_link?(name, objs)
      FileUtils.rm_f(name)
      exec_line("/usr/bin/ar rcu #{name} #{objs.map { |x| x + '.o' }.join(' ') }")
      exec_line("/usr/bin/ranlib #{name}")
    end
  end

  def clean
    @objs.map { |o| o + '.o' }.select { |o| File.exist?(o) }.each { |o| FileUtils.rm_f(o) }
  end
 
  private

  def cc(args)
    exec_line("/usr/bin/gcc #{args}")
  end

  def link(objs, ldflags, args, name)
    objs ||= @objs
    ldflags ||= @ldflags
    line = "#{@cflags} #{objs.map { |x| x + '.o' }.join(' ') } #{ldflags} #{args}"
    cc(line) if should_link?(name, objs)
  end

  def should_build?(obj)
    if File.exist?(obj + '.o')
      src_time = File.mtime(obj_source(obj))
      obj_time = File.mtime(obj + '.o')
      src_time > obj_time \
        or dependencies[obj].any? { |f| File.mtime(f) > obj_time }
    else
      true
    end
  end

  def should_link?(bin, objs)
    if File.exist?(bin)
      mtime = File.mtime(bin)
      objs.any? { |o| File.mtime(o + '.o') > mtime }
    else
      true
    end
  end

  def err(*args)
    $stderr.puts args
    exit 1
  end

  def obj_source(obj)
    s = @obj_sources[obj]
    unless s
      s = ['.c', '.m'].map { |e| obj + e }.find { |p| File.exist?(p) }
      err "cannot locate source file for object `#{obj}'" if s.nil?
      @obj_sources[obj] = s
    end
    s
  end

  HEADER_DIRS = %w{. include include/ruby}
  def header_path(hdr)
    p = @header_paths[hdr]
    unless p
      p = HEADER_DIRS.map { |d| File.join(d, hdr) }.find { |p| File.exist?(p) }
      @header_paths[hdr] = p
    end
    p
  end
  
  def locate_headers(cont, src)
    txt = File.read(src)
    txt.scan(/#include\s+\"([^"]+)\"/).flatten.each do |header|
      p = header_path(header)
      if p
        cont << p
        locate_headers(cont, p)
      end
    end
  end
  
  def dependencies
    unless @obj_dependencies
      @obj_dependencies = {}
      @objs.each do |obj| 
        ary = []
        locate_headers(ary, obj_source(obj))
        @obj_dependencies[obj] = ary.uniq
      end
    end
    @obj_dependencies
  end
end

$builder = Builder.new(OBJS)

task :default => [:all]

task :config_h do
  config_h = 'include/ruby/config.h'
  if !File.exist?(config_h) \
  or File.mtime(config_h) < File.mtime(config_h + '.in') \
  or File.mtime(config_h) < File.mtime(__FILE__)
    new_config_h = File.read(config_h + '.in') << "\n"
    flag = ['/System/Library/Frameworks', '/Library/Frameworks'].any? do |p|
      File.exist?(File.join(p, 'BridgeSupport.framework'))
    end 
    new_config_h << "#define HAVE_BRIDGESUPPORT_FRAMEWORK #{flag ? 1 : 0}\n"
    flag = File.exist?('/usr/include/auto_zone.h')
    new_config_h << "#define HAVE_AUTO_ZONE_H #{flag ? 1 : 0}\n"
    new_config_h << "#define RUBY_PLATFORM \"#{NEW_RUBY_PLATFORM}\"\n"
    new_config_h << "#define RUBY_LIB \"#{RUBY_LIB}\"\n"
    new_config_h << "#define RUBY_ARCHLIB \"#{RUBY_ARCHLIB}\"\n"
    new_config_h << "#define RUBY_SITE_LIB \"#{RUBY_SITE_LIB}\"\n"
    new_config_h << "#define RUBY_SITE_LIB2 \"#{RUBY_SITE_LIB2}\"\n"
    new_config_h << "#define RUBY_SITE_ARCHLIB \"#{RUBY_SITE_ARCHLIB}\"\n"
    new_config_h << "#define RUBY_VENDOR_LIB \"#{RUBY_VENDOR_LIB}\"\n"
    new_config_h << "#define RUBY_VENDOR_LIB2 \"#{RUBY_VENDOR_LIB2}\"\n"
    new_config_h << "#define RUBY_VENDOR_ARCHLIB \"#{RUBY_VENDOR_ARCHLIB}\"\n"
    if !File.exist?(config_h) or File.read(config_h) != new_config_h
      File.open(config_h, 'w') { |io| io.print new_config_h }
      ext_dir = ".ext/include/#{NEW_RUBY_PLATFORM}/ruby"
      FileUtils.mkdir_p(ext_dir)
      FileUtils.cp(config_h, ext_dir)
    end
  end
end

task :objects => [:config_h] do
  exec_line "/usr/bin/ruby -I. tool/compile_prelude.rb prelude.rb miniprelude.c.new"
  if !File.exist?('miniprelude.c') or File.read('miniprelude.c') != File.read('miniprelude.c.new')
    FileUtils.mv('miniprelude.c.new', 'miniprelude.c')
  else
    FileUtils.rm('miniprelude.c.new')
  end
  if !File.exist?('prelude.c')
    FileUtils.touch('prelude.c') # create empty file nevertheless
  end
  $builder.build
end

task :miniruby => [:objects] do
  $builder.link_executable('miniruby', OBJS - ['prelude'])
end

task :rbconfig => [:miniruby] do
  rbconfig = <<EOS
# This file was created when MacRuby was built.  Any changes made to this file 
# will be lost the next time MacRuby is built.

module RbConfig
  RUBY_VERSION == "#{NEW_RUBY_VERSION}" or
    raise "ruby lib version (#{NEW_RUBY_VERSION}) doesn't match executable version (\#{RUBY_VERSION})"

  TOPDIR = File.dirname(__FILE__).chomp!("/lib/ruby/#{NEW_RUBY_VERSION}/#{NEW_RUBY_PLATFORM}")
  DESTDIR = '' unless defined? DESTDIR
  CONFIG = {}
  CONFIG["DESTDIR"] = DESTDIR
  CONFIG["INSTALL"] = '/usr/bin/install -c'
  CONFIG["prefix"] = (TOPDIR || DESTDIR + "#{FRAMEWORK_USR}")
  CONFIG["EXEEXT"] = ""
  CONFIG["ruby_install_name"] = "#{RUBY_INSTALL_NAME}"
  CONFIG["RUBY_INSTALL_NAME"] = "#{RUBY_INSTALL_NAME}"
  CONFIG["RUBY_SO_NAME"] = "#{RUBY_SO_NAME}"
  CONFIG["SHELL"] = "/bin/sh"
  CONFIG["PATH_SEPARATOR"] = ":"
  CONFIG["PACKAGE_NAME"] = ""
  CONFIG["PACKAGE_TARNAME"] = ""
  CONFIG["PACKAGE_VERSION"] = ""
  CONFIG["PACKAGE_STRING"] = ""
  CONFIG["PACKAGE_BUGREPORT"] = ""
  CONFIG["exec_prefix"] = "$(prefix)"
  CONFIG["bindir"] = "$(exec_prefix)/bin"
  CONFIG["sbindir"] = "$(exec_prefix)/sbin"
  CONFIG["libexecdir"] = "$(exec_prefix)/libexec"
  CONFIG["datarootdir"] = "$(prefix)/share"
  CONFIG["datadir"] = "$(datarootdir)"
  CONFIG["sysconfdir"] = "$(prefix)/etc"
  CONFIG["sharedstatedir"] = "$(prefix)/com"
  CONFIG["localstatedir"] = "$(prefix)/var"
  CONFIG["includedir"] = "$(prefix)/include"
  CONFIG["oldincludedir"] = "/usr/include"
  CONFIG["docdir"] = "$(datarootdir)/doc/$(PACKAGE)"
  CONFIG["infodir"] = "$(datarootdir)/info"
  CONFIG["htmldir"] = "$(docdir)"
  CONFIG["dvidir"] = "$(docdir)"
  CONFIG["pdfdir"] = "$(docdir)"
  CONFIG["psdir"] = "$(docdir)"
  CONFIG["libdir"] = "$(exec_prefix)/lib"
  CONFIG["localedir"] = "$(datarootdir)/locale"
  CONFIG["mandir"] = "$(datarootdir)/man"
  CONFIG["DEFS"] = ""
  CONFIG["ECHO_C"] = "\\\\\\\\c"
  CONFIG["ECHO_N"] = ""
  CONFIG["ECHO_T"] = ""
  CONFIG["LIBS"] = ""
  CONFIG["build_alias"] = ""
  CONFIG["host_alias"] = ""
  CONFIG["target_alias"] = ""
  CONFIG["BASERUBY"] = "ruby"
  CONFIG["MAJOR"], CONFIG["MINOR"], CONFIG["TEENY"] = [#{NEW_RUBY_VERSION.scan(/\d+/).map { |x| "\"" + x + "\"" }.join(', ')}]
  CONFIG["build"] = "i686-apple-darwin9.0.0"
  CONFIG["build_cpu"] = "i686"
  CONFIG["build_vendor"] = "apple"
  CONFIG["build_os"] = "darwin9.0.0"
  CONFIG["host"] = "i686-apple-darwin9.0.0"
  CONFIG["host_cpu"] = "i686"
  CONFIG["host_vendor"] = "apple"
  CONFIG["host_os"] = "darwin9.0.0"
  CONFIG["target"] = "i686-apple-darwin9.0.0"
  CONFIG["target_cpu"] = "i686"
  CONFIG["target_vendor"] = "apple"
  CONFIG["target_os"] = "darwin9.0"
  CONFIG["CC"] = "gcc"
  CONFIG["CFLAGS"] = "-fno-common -pipe $(cflags)"
  CONFIG["LDFLAGS"] = ""
  CONFIG["CPPFLAGS"] = "$(cppflags)"
  CONFIG["OBJEXT"] = "o"
  CONFIG["CXX"] = "g++"
  CONFIG["CXXFLAGS"] = ""
  CONFIG["CPP"] = "gcc -E"
  CONFIG["GREP"] = "/usr/bin/grep"
  CONFIG["EGREP"] = "/usr/bin/grep -E"
  CONFIG["GNU_LD"] = "no"
  CONFIG["CPPOUTFILE"] = "-o conftest.i"
  CONFIG["OUTFLAG"] = "-o "
  CONFIG["COUTFLAG"] = "-o "
  CONFIG["RANLIB"] = "ranlib"
  CONFIG["AR"] = "ar"
  CONFIG["AS"] = "as"
  CONFIG["ASFLAGS"] = ""
  CONFIG["NM"] = ""
  CONFIG["WINDRES"] = ""
  CONFIG["DLLWRAP"] = ""
  CONFIG["OBJDUMP"] = ""
  CONFIG["LN_S"] = "ln -s"
  CONFIG["SET_MAKE"] = ""
  CONFIG["INSTALL_PROGRAM"] = "$(INSTALL)"
  CONFIG["INSTALL_SCRIPT"] = "$(INSTALL)"
  CONFIG["INSTALL_DATA"] = "$(INSTALL) -m 644"
  CONFIG["RM"] = "rm -f"
  CONFIG["CP"] = "cp"
  CONFIG["MAKEDIRS"] = "mkdir -p"
  CONFIG["ALLOCA"] = ""
  CONFIG["DLDFLAGS"] = ""
  CONFIG["ARCH_FLAG"] = "#{ARCHFLAGS}"
  CONFIG["STATIC"] = ""
  CONFIG["CCDLFLAGS"] = "-fno-common"
  CONFIG["LDSHARED"] = "$(CC) -dynamic -bundle -undefined suppress -flat_namespace #{ARCHFLAGS}"
  CONFIG["LDSHAREDXX"] = "$(CXX) -dynamic -bundle -undefined suppress -flat_namespace"
  CONFIG["DLEXT"] = "bundle"
  CONFIG["DLEXT2"] = ""
  CONFIG["LIBEXT"] = "a"
  CONFIG["LINK_SO"] = ""
  CONFIG["LIBPATHFLAG"] = " -L%s"
  CONFIG["RPATHFLAG"] = ""
  CONFIG["LIBPATHENV"] = "DYLD_LIBRARY_PATH"
  CONFIG["TRY_LINK"] = ""
  CONFIG["STRIP"] = "strip -A -n"
  CONFIG["EXTSTATIC"] = ""
  CONFIG["setup"] = "Setup"
  CONFIG["PREP"] = "miniruby$(EXEEXT)"
  CONFIG["EXTOUT"] = ".ext"
  CONFIG["ARCHFILE"] = ""
  CONFIG["RDOCTARGET"] = "install-doc"
  CONFIG["cppflags"] = ""
  CONFIG["cflags"] = "$(optflags) $(debugflags) $(warnflags)"
  CONFIG["optflags"] = "-O2"
  CONFIG["debugflags"] = "-g"
  CONFIG["warnflags"] = "-Wall -Wno-parentheses"
  CONFIG["LIBRUBY_LDSHARED"] = "cc -dynamiclib -undefined suppress -flat_namespace"
  CONFIG["LIBRUBY_DLDFLAGS"] = "-install_name $(libdir)/lib$(RUBY_SO_NAME).dylib -current_version $(MAJOR).$(MINOR).$(TEENY) -compatibility_version $(MAJOR).$(MINOR)"
  CONFIG["rubyw_install_name"] = ""
  CONFIG["RUBYW_INSTALL_NAME"] = ""
  CONFIG["LIBRUBY_A"] = "lib$(RUBY_SO_NAME)-static.a"
  CONFIG["LIBRUBY_SO"] = "lib$(RUBY_SO_NAME).$(MAJOR).$(MINOR).$(TEENY).dylib"
  CONFIG["LIBRUBY_ALIASES"] = "lib$(RUBY_SO_NAME).$(MAJOR).$(MINOR).dylib lib$(RUBY_SO_NAME).dylib"
  CONFIG["LIBRUBY"] = "$(LIBRUBY_SO)"
  CONFIG["LIBRUBYARG"] = "$(LIBRUBYARG_SHARED)"
  CONFIG["LIBRUBYARG_STATIC"] = "-l$(RUBY_SO_NAME)-static #{LDFLAGS}"
  CONFIG["LIBRUBYARG_SHARED"] = "-l$(RUBY_SO_NAME)"
  CONFIG["SOLIBS"] = ""
  CONFIG["DLDLIBS"] = ""
  CONFIG["ENABLE_SHARED"] = "yes"
  CONFIG["MAINLIBS"] = ""
  CONFIG["COMMON_LIBS"] = ""
  CONFIG["COMMON_MACROS"] = ""
  CONFIG["COMMON_HEADERS"] = ""
  CONFIG["EXPORT_PREFIX"] = ""
  CONFIG["THREAD_MODEL"] = "pthread"
  CONFIG["MAKEFILES"] = "Makefile"
  CONFIG["arch"] = "#{NEW_RUBY_PLATFORM}"
  CONFIG["sitearch"] = "#{NEW_RUBY_PLATFORM}"
  CONFIG["sitedir"] = "$(libdir)/ruby/site_ruby"
  CONFIG["vendordir"] = "$(prefix)/lib/ruby/vendor_ruby"
  CONFIG["configure_args"] = ""
  CONFIG["rubyhdrdir"] = "$(includedir)/ruby-$(MAJOR).$(MINOR).$(TEENY)"
  CONFIG["sitehdrdir"] = "$(rubyhdrdir)/site_ruby"
  CONFIG["vendorhdrdir"] = "$(rubyhdrdir)/vendor_ruby"
  CONFIG["NROFF"] = "/usr/bin/nroff"
  CONFIG["MANTYPE"] = "doc"
  CONFIG["ruby_version"] = "$(MAJOR).$(MINOR).$(TEENY)"
  CONFIG["rubylibdir"] = "$(libdir)/ruby/$(ruby_version)"
  CONFIG["archdir"] = "$(rubylibdir)/$(arch)"
  CONFIG["sitelibdir"] = "$(sitedir)/$(ruby_version)"
  CONFIG["sitearchdir"] = "$(sitelibdir)/$(sitearch)"
  CONFIG["vendorlibdir"] = "$(vendordir)/$(ruby_version)"
  CONFIG["vendorarchdir"] = "$(vendorlibdir)/$(sitearch)"
  CONFIG["topdir"] = File.dirname(__FILE__)
  MAKEFILE_CONFIG = {}
  CONFIG.each{|k,v| MAKEFILE_CONFIG[k] = v.dup}
  def RbConfig::expand(val, config = CONFIG)
    val.gsub!(/\\$\\$|\\$\\(([^()]+)\\)|\\$\\{([^{}]+)\\}/) do
      var = $&
      if !(v = $1 || $2)
        '$'
      elsif key = config[v = v[/\\A[^:]+(?=(?::(.*?)=(.*))?\\z)/]]
        pat, sub = $1, $2
        config[v] = false
        RbConfig::expand(key, config)
        config[v] = key
        key = key.gsub(/\#{Regexp.quote(pat)}(?=\\s|\\z)/n) {sub} if pat
        key
      else
        var
      end
    end
    val
  end
  CONFIG.each_value do |val|
    RbConfig::expand(val)
  end
end
Config = RbConfig # compatibility for ruby-1.8.4 and older.
CROSS_COMPILING = nil
RUBY_FRAMEWORK = true
RUBY_FRAMEWORK_VERSION = RbConfig::CONFIG['ruby_version']
EOS
  if File.read('rbconfig.rb') != rbconfig
    File.open('rbconfig.rb', 'w') { |io| io.print rbconfig }
  end
end

task :macruby_dylib => [:rbconfig, :miniruby] do
  exec_line("./miniruby -I. -I./lib -rrbconfig tool/compile_prelude.rb prelude.rb gem_prelude.rb prelude.c.new")
  if !File.exist?('prelude.c') or File.read('prelude.c') != File.read('prelude.c.new')
    FileUtils.mv('prelude.c.new', 'prelude.c')
  else
    FileUtils.rm('prelude.c.new')
  end
  dylib = "lib#{RUBY_SO_NAME}.#{NEW_RUBY_VERSION}.dylib"
  $builder.link_dylib(dylib, $builder.objs - ['main', 'gc-stub', 'miniprelude'])
  major, minor, teeny = NEW_RUBY_VERSION.scan(/\d+/)
  ["lib#{RUBY_SO_NAME}.#{major}.#{minor}.dylib", "lib#{RUBY_SO_NAME}.dylib"].each do |dylib_alias|
    if !File.exist?(dylib_alias) or File.readlink(dylib_alias) != dylib  
      FileUtils.rm_f(dylib_alias)
      FileUtils.ln_s(dylib, dylib_alias)
    end
  end
end

task :macruby_static => [:macruby_dylib] do
  $builder.link_archive("lib#{RUBY_SO_NAME}-static.a", $builder.objs - ['main', 'gc-stub', 'miniprelude'])
end

task :macruby => [:macruby_dylib] do
  $builder.link_executable(RUBY_INSTALL_NAME, ['main', 'gc-stub'], "-L. -l#{RUBY_SO_NAME}")
end

DESTDIR = (ENV['DESTDIR'] or "")
EXTOUT = (ENV['EXTOUT'] or ".ext")
INSTALLED_LIST = '.installed.list'
SCRIPT_ARGS = "--make=\"/usr/bin/make\" --dest-dir=\"#{DESTDIR}\" --extout=\"#{EXTOUT}\" --mflags=\"\" --make-flags=\"\""
EXTMK_ARGS = "#{SCRIPT_ARGS} --extension --extstatic"
INSTRUBY_ARGS = "#{SCRIPT_ARGS} --data-mode=0644 --prog-mode=0755 --installed-list #{INSTALLED_LIST} --mantype=\"doc\""

task :extensions => [:miniruby, :macruby_static] do
  exec_line("./miniruby -I./lib -I.ext/common -I./- -r./ext/purelib.rb ext/extmk.rb #{EXTMK_ARGS}")
end

task :install do
  exec_line("./miniruby instruby.rb #{INSTRUBY_ARGS}")  
end

task :clean_local do
  $builder.clean
  FileUtils.rm_f(INSTALLED_LIST)
end

task :clean_ext do
  if File.exist?('./miniruby') 
    exec_line("./miniruby -I./lib -I.ext/common -I./- -r./ext/purelib.rb ext/extmk.rb #{EXTMK_ARGS} clean")
  end
end

task :clean => [:clean_local, :clean_ext]

task :all => [:macruby, :extensions] do
end