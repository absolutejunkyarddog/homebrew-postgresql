require "formula"
require_relative "../custom_download_strategy.rb"

class PostgresqlAT17 < Formula
  desc "Object-relational database system"
  homepage "https://www.postgresql.org/"
  version = "17beta2"
  url "https://ftp.postgresql.org/pub/source/v#{version}/postgresql-#{version}.tar.bz2"
  version version
  sha256 "157af3af2cbc40364990835f518aea0711703e1c48f204b54dfd49b46cd8716c"
  license "PostgreSQL"

  head "https://git.postgresql.org/git/postgresql.git", branch: "master"

  keg_only :versioned_formula

  option "with-cassert", "Enable assertion checks (for debugging)"
  deprecated_option "enable-cassert" => "with-cassert"

  # https://www.postgresql.org/support/versioning/
  #deprecate! date: "2029-11-NN", because: :unsupported

  depends_on "docbook-xsl" => :build
  depends_on "pkg-config" => :build

  depends_on "gettext"
  depends_on "icu4c"
  depends_on "krb5"
  depends_on "lz4"
  depends_on "openldap"
  depends_on "openssl"
  depends_on "python@3"
  depends_on "readline"
  depends_on "tcl-tk"
  depends_on "zstd"
  depends_on "llvm" => :optional

  on_macos do    
    if Hardware::CPU.arm?
      url "https://github.com/absolutejunkyarddog/homebrew-private/releases/download/v#{version}/postgresql-#{version}.tar.gz", :using => GitHubPrivateRepositoryReleaseDownloadStrategy
      sha256 "72a16bed745861a09c98e4e16481eb5662277db363371453edaf40aff0bb6a38"
    end
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --enable-dtrace
      --enable-nls
      --with-bonjour
      --with-gssapi
      --with-icu
      --with-ldap
      --with-libxml
      --with-libxslt
      --with-lz4
      --with-openssl
      --with-uuid=e2fs
      --with-pam
      --with-perl
      --with-python
      --with-tcl
      --with-zstd
      PYTHON=python3
      XML2_CONFIG=:
    ]

    # Add include and library directories of dependencies, so that
    # they can be used for compiling extensions.  Superenv does this
    # when compiling this package, but won't record it for pg_config.
    deps = %w[gettext icu4c openldap openssl@1.1 readline tcl-tk]
    with_includes = deps.map { |f| Formula[f].opt_include }.join(":")
    with_libraries = deps.map { |f| Formula[f].opt_lib }.join(":")
    args << "--with-includes=#{with_includes}"
    args << "--with-libraries=#{with_libraries}"

    args << "--enable-cassert" if build.with? "cassert"
    args << "--with-llvm" if build.with? "llvm"

    extra_version = ""
    extra_version += "+git" if build.head?
    extra_version += " (Homebrew absolutejunkyarddog/postgresql)"
    args << "--with-extra-version=#{extra_version}"

    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "./configure", *args
    system "make", "install-world"

    bin.install "./extras/pg_start"
    bin.install "./extras/pg_beta"
  end

  def post_install
    (var/"log").mkpath
    postgresql_datadir.mkpath

    odeprecated old_postgres_data_dir, new_postgres_data_dir if old_postgres_data_dir.exist?

    # Don't initialize database, it clashes when testing other PostgreSQL versions.
    return if ENV["HOMEBREW_GITHUB_ACTIONS"]

    system "#{bin}/initdb", "--locale=C", "-E", "UTF-8", postgresql_datadir unless pg_version_exists?
  end

  def postgresql_datadir
    if old_postgres_data_dir.exist?
      old_postgres_data_dir
    else
      new_postgres_data_dir
    end
  end

  def postgresql_log_path
    var/"log/#{name}.log"
  end

  def pg_version_exists?
    (postgresql_datadir/"PG_VERSION").exist?
  end

  def new_postgres_data_dir
    var/name
  end

  def old_postgres_data_dir
    var/"postgres"
  end

  # Figure out what version of PostgreSQL the old data dir is
  # using
  def old_postgresql_datadir_version
    pg_version = old_postgres_data_dir/"PG_VERSION"
    pg_version.exist? && pg_version.read.chomp
  end

  def caveats
    caveats = ""

    # Extract the version from the formula name
    pg_formula_version = version.major.to_s
    # ... and check it against the old data dir postgres version number
    # to see if we need to print a warning re: data dir
    if old_postgresql_datadir_version == pg_formula_version
      caveats += <<~EOS
        Previous versions of postgresql shared the same data directory.

        You can migrate to a versioned data directory by running:
          mv -v "#{old_postgres_data_dir}" "#{new_postgres_data_dir}"

        (Make sure PostgreSQL is stopped before executing this command)

      EOS
    end

    caveats += <<~EOS
      This formula has created a default database cluster with:
        initdb --locale=C -E UTF-8 #{postgresql_datadir}
      For more details, read:
        https://www.postgresql.org/docs/#{version.major}/app-initdb.html
    EOS

    caveats
  end

  service do
    run [opt_bin/"pg_start", "-D", f.postgresql_datadir]
    keep_alive true
    environment_variables LC_ALL: "en_US.UTF-8"
  end

  test do
    system bin/"initdb", testpath/"test" unless ENV["HOMEBREW_GITHUB_ACTIONS"]
    assert_equal "#{HOMEBREW_PREFIX}/share/#{name}", shell_output("#{bin}/pg_config --sharedir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/lib/#{name}", shell_output("#{bin}/pg_config --libdir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/lib/#{name}", shell_output("#{bin}/pg_config --pkglibdir").chomp
    assert_equal "#{HOMEBREW_PREFIX}/include/#{name}", shell_output("#{bin}/pg_config --includedir").chomp
  end
end