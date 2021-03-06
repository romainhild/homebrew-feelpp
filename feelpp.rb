require 'formula'

# We remove the use of submodules as it makes the checkout step
# fails if we don't have access to them but keep the ones in contrib
class GitNoSubmoduleDownloadStrategy < GitDownloadStrategy
  def initialize name, resource
    super
  end
  def update_submodules
    safe_system 'git', 'submodule', '--quiet', 'deinit', '-f', '--all'
    safe_system 'git', 'submodule', '--quiet', 'update', '--init', 'contrib'
  end
end

class Feelpp < Formula
  homepage 'http://www.feelpp.org'
  url 'https://github.com/feelpp/feelpp/releases/download/v0.101.1/feelpp-0.101.1.tar.gz'
  head 'https://github.com/feelpp/feelpp.git', :using => GitNoSubmoduleDownloadStrategy, :branch => 'develop'
  version '0.101.1'
  sha256 '70418fb0ce9f5069190fcc1677615663dbca71cea39e2b858356476a9e8627cf'


  depends_on 'autoconf'
  depends_on 'automake'
  depends_on 'libtool'
  depends_on 'cmake' => :build
  depends_on 'cln'
  depends_on 'eigen'
  depends_on 'gmsh' => :recommended #feel++ can download and install it
  depends_on 'scalapack'
  depends_on 'petsc'
  depends_on 'slepc' => :recommended
  depends_on 'boost' => ['with-mpi', 'c++11']
  depends_on 'ann' => :recommended
  depends_on 'glpk' => :recommended
  depends_on 'doxygen' => :optional

  def install
    # had to keep application for mesh_partitioner
    args=std_cmake_args+ ['-DFEELPP_ENABLE_TESTS=OFF', '-Wno-dev']


    Dir.mkdir 'opt'
    cd 'opt' do
      system "cmake", "..", *args
      system "make", "install-feelpp-lib", "-j#{ENV.make_jobs}"
    end
  end

  # create a CMakeLists.txt and a test.cpp initializing the environment
  # and try to compile it
  test do
    (testpath/"CMakeLists.txt").write <<-EOS.undent
      if ( ${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_CURRENT_SOURCE_DIR} )
        find_package(Feel++
                PATHS $ENV{FEELPP_DIR}/share/feel/cmake/modules
                      /usr/share/feel/cmake/modules
                      /usr/local/share/feel/cmake/modules
                      /opt/share/feel/cmake/modules
                      )
        if(NOT FEELPP_FOUND)
          message(FATAL_ERROR "Feel++ was not found on your system. Make sure to install it and specify the FEELPP_DIR to reference the installation directory.")
        endif()
      endif()
      feelpp_add_application(test_homebrew SRCS test.cpp )
    EOS
    (testpath/"test.cpp").write <<-EOS.undent
      #include <feel/feelcore/environment.hpp>
      using namespace Feel;
      int main(int argc, char** argv)
      {
        Environment env( _argc=argc, _argv=argv);
        return 0;
      }
    EOS
    system "cmake", "."
    system 'make', 'feelpp_test_homebrew'
  end
end
