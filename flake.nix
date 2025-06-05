{
  description = "OpenCV flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
    };
    cmakePackage = (
      pkgs.cmake.overrideAttrs
      (oldAttr: {
        postPatch =
          oldAttr.postPatch
          or ""
          + ''
            substituteInPlace Modules/FindJNI.cmake \
            --replace "/usr/lib64/jvm/jre" "/usr/lib64/jvm/jre\n${pkgs.corretto21}"
          '';

        # patches = [
        #   (pkgs.writeText "add-custom-jvm.patch" ''
        #     --- a/Modules/FindJNI.cmake
        #     +++ b/Modules/FindJNI.cmake
        #     @@ -312,7 +312,8 @@
        #        # SuSE specific paths for default JVM
        #        /usr/lib64/jvm/java
        #        /usr/lib64/jvm/jre
        #        /usr/lib/corretto
        #        /usr/lib/openjdk
        #        /usr/lib/corretto
        #     -  )
        #     +  )
        #     +set(_JNI_JAVA_AWT_LIBRARY_TRIES)
        #   '')
        # ];
      })
    );
  in {
    devShells.${system}.default =
      (pkgs.buildFHSEnv {
        name = "opencv-fhs";
        targetPkgs = pkgs: (with pkgs;
          [
            ant
            corretto21
            gcc
            jre_minimal
            libgcc
            openblas
            vtk
          ]
          ++ [cmakePackage]);
        profile = ''
          export JAVA_HOME=${pkgs.corretto21}
          export PATH=$JAVA_HOME/bin:$PATH

          echo  "cmake \\" > a.sh
          echo  "-DBUILD_JAVA=ON \\" >> a.sh
          echo  "-DBUILD_SHARED_LIBS=OFF \\" >> a.sh
          echo  "-DBUILD_opencv_core=ON \\" >> a.sh
          echo  "-DBUILD_opencv_imgcodecs=ON \\" >> a.sh
          echo  "-DBUILD_opencv_imgproc=ON \\" >> a.sh
          echo  "-DBUILD_opencv_java=ON \\" >> a.sh
          echo  "-DBUILD_opencv_java_bindings_gen=ON \\" >> a.sh
          echo  "-DJAVA_AWT_INCLUDE_PATH=${pkgs.corretto21}/include \\" >> a.sh
          echo  "-DJAVA_AWT_LIBRARY=${pkgs.corretto21}/lib/libjawt.so \\" >> a.sh
          echo  "-DJAVA_INCLUDE_PATH2=${pkgs.corretto21}/include/linux \\" >> a.sh
          echo  "-DJAVA_INCLUDE_PATH=${pkgs.corretto21}/include \\" >> a.sh
          echo  "-DJAVA_JVM_LIBRARY=${pkgs.corretto21}/lib/server/libjvm.so \\" >> a.sh
          echo  "-DJava_JARSIGNER_EXECUTABLE=${pkgs.corretto21}/bin/jarsigner \\" >> a.sh
          echo  "-DJava_JAR_EXECUTABLE=${pkgs.corretto21}/bin/jar \\" >> a.sh
          echo  "-DJava_JAVAC_EXECUTABLE=${pkgs.corretto21}/bin/javac \\" >> a.sh
          echo  "-DJava_JAVADOC_EXECUTABLE=${pkgs.corretto21}/bin/javadoc \\" >> a.sh
          echo  "-DJava_JAVA_EXECUTABLE=${pkgs.corretto21}/bin/java \\" >> a.sh
          echo  "-D_JNI_JAVA_DIRECTORIES_BASE=${pkgs.corretto21}/bin/java \\" >> a.sh
        '';
      })
      .env;

    packages.${system} = {
      cmake = cmakePackage;

      default = (
        pkgs.opencv4.overrideAttrs
        (oldAttr: {
          buildInputs =
            oldAttr.buildInputs
            ++ (with pkgs; [
              ant
              corretto21
              gcc
              jre_minimal
              libgcc
            ]);
          cmakeFlags =
            oldAttr.cmakeFlags
            ++ [
              "-DBUILD_JAVA=ON"
              "-DBUILD_SHARED_LIBS=OFF"
              "-DBUILD_opencv_core=ON"
              "-DBUILD_opencv_imgcodecs=ON"
              "-DBUILD_opencv_imgproc=ON"
              "-DBUILD_opencv_java=ON"
              "-DBUILD_opencv_java_bindings_gen=ON"
              "-DJAVA_AWT_INCLUDE_PATH=${pkgs.corretto21}/include"
              "-DJAVA_AWT_LIBRARY=${pkgs.corretto21}/lib/libjawt.so"
              "-DJAVA_INCLUDE_PATH2=${pkgs.corretto21}/include/linux"
              "-DJAVA_INCLUDE_PATH=${pkgs.corretto21}/include"
              "-DJAVA_JVM_LIBRARY=${pkgs.corretto21}/lib/server/libjvm.so"
              "-DJava_JARSIGNER_EXECUTABLE=${pkgs.corretto21}/bin/jarsigner"
              "-DJava_JAR_EXECUTABLE=${pkgs.corretto21}/bin/jar"
              "-DJava_JAVAC_EXECUTABLE=${pkgs.corretto21}/bin/javac"
              "-DJava_JAVADOC_EXECUTABLE=${pkgs.corretto21}/bin/javadoc"
              "-DJava_JAVA_EXECUTABLE=${pkgs.corretto21}/bin/java"
              "-D_JNI_JAVA_DIRECTORIES_BASE=${pkgs.corretto21}/bin/java"
            ];
        })
      );
    };
  };
}