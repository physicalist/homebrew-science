require "formula"

class Genesis < Formula
  # description "GENESIS is the GEneral NEural SImulator Suite"
  homepage "http://genesis-sim.org/GENESIS"
  url "https://github.com/borismarin/genesis2.4gamma/archive/v2.4-RC.tar.gz"
  sha1 "0f30d729f6c4b47cdac18222ec28d9912da6ca43"
  version "2.4rc"

  head "https://github.com/physicalist/genesis2.4gamma.git" #, :using => :git

  depends_on :x11 => :recommended

  # Fix:
  # - GENESIS binary isn't copied to #{bin}
  # - `convert` tool conflicts with ImageMagick's convert -> rename!
  patch :DATA

  def install
    ENV.deparallelize  # if your formula fails when building in parallel

    # fix Makefile.in
    inreplace "src/Makefile.in", /make -f /, "make -C src -f "
    inreplace "src/Makefile.in", />> liblist/, ">> src/liblist"
    inreplace "src/Makefile.in", />> nxliblist/, ">> src/nxliblist"
    inreplace "src/Makefile.in", />> minliblist/, ">> src/minliblist"

    # Remove unrecognized options if warned by configure
    system "src/configure", "--disable-debug",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules",
                          "--prefix=#{prefix}"

    if build.with? :x11
      system "make"
      system "make", "install"
    else
      # build special version without GUI
      system "make", "nxgenesis"
      system "make", "nxinstall"
    end
  end

  test do
    (testpath/".simrc").install "#{prefix}/startup/.simrc"

    (testpath/"test.g").write <<-EOS.undent
      setrand -sprng
      randseed 0
      echo {rand 0 1} {rand 0 1} {rand 0 1} {rand 0 1} {rand 0 1}
      quit
    EOS

    system "#{bin}/genesis", "#{testpath}/test.g"

    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test genesis2.4gamma`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
  end
end
__END__
diff --git a/src/Makefile.BASE b/src/Makefile.BASE
index b918d57..a9e629f 100644
--- a/src/Makefile.BASE
+++ b/src/Makefile.BASE
@@ -114,15 +114,15 @@ copydirs:
 
 install: copydirs
 	@(for i in $(FULLDIR); do echo cd $$i; cd $$i; make MACHINE=$(MACHINE) XINCLUDE="$(XINCLUDE)" SPRNG_LIB=$(SPRNG_LIB) DISKIOSUBDIR="$(DISKIOSUBDIR)" INSTALLDIR="$(INSTALLDIR)" INSTALLBIN="$(INSTALLBIN)" RANLIB="$(RANLIB)" install; cd ..;done)
-	@cp genesis$(EXE_EXT) "$(INSTALLDIR)"
+	@cp genesis$(EXE_EXT) "$(INSTALLDIR)"/bin
 	@echo "Done with full install"
 
 nxinstall: copydirs
 	@(for i in $(NXDIR); do echo cd $$i; cd $$i; make MACHINE=$(MACHINE) SPRNG_LIB=$(SPRNG_LIB) DISKIOSUBDIR="$(DISKIOSUBDIR)" INSTALLDIR=$(INSTALLDIR) INSTALLBIN=$(INSTALLBIN) RANLIB="$(RANLIB)" install; cd ..;done)
-	@cp nxgenesis$(EXE_EXT) "$(INSTALLDIR)"
+	@cp nxgenesis$(EXE_EXT) "$(INSTALLDIR)"/bin
 	@echo "Done with non-X install"
 
 mininstall: copydirs
 	@(for i in $(MINDIR); do echo cd $$i; cd $$i; make MACHINE=$(MACHINE) SPRNG_LIB=$(SPRNG_LIB) INSTALLDIR="$(INSTALLDIR)" INSTALLBIN="$(INSTALLBIN)" RANLIB="$(RANLIB)" install; cd ..;done)
-	@cp mingenesis$(EXE_EXT) "$(INSTALLDIR)"
+	@cp mingenesis$(EXE_EXT) "$(INSTALLDIR)"/bin
 	@echo "Done with minimal install"
diff --git a/src/convert/Makefile b/src/convert/Makefile
index a5b4e28..a59e9e5 100644
--- a/src/convert/Makefile
+++ b/src/convert/Makefile
@@ -125,14 +125,14 @@ realclean:
 	-rm -f *.o y.tab.h y.tab.c lex.yy.c convert
 
 install:
-	-cp convert$(EXE_EXT) $(INSTALLBIN)
+	-cp convert$(EXE_EXT) $(INSTALLBIN)/genconvert$(EXE_EXT)
 	-if test ! -d $(X1COMPAT_DIR); then mkdir $(X1COMPAT_DIR); fi
 	-cp X1compat/*.g $(X1COMPAT_DIR)
 	-chmod +w $(X1COMPAT_DIR)/*.g
 	-if test ! -d $(INSTALLDIR)/man; then mkdir $(INSTALLDIR)/man $(INSTALLDIR)/man/man1; fi
 	-if test ! -d $(INSTALLDIR)/man/man1; then mkdir $(INSTALLDIR)/man/man1; fi
-	-cp convert.man $(INSTALLDIR)/man/man1/convert.1
-	-cp convert.txt $(INSTALLDIR)/Doc
+	-cp convert.man $(INSTALLDIR)/man/man1/genconvert.1
+	-cp convert.txt $(INSTALLDIR)/Doc/genconvert.txt
 
 freeze:
 	rcsclean
