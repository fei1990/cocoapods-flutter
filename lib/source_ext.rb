# require "cocoapods"
module Pod
  class Source
    class Manager
      def private_source1
        url = "git@code.sohuno.com:MPTC-iOS/SHSpecs.git"
        source = source_with_url(url)
        return source if source
      end

      def private_source2
        url = "git@code.sohuno.com:mtpc_sh_ios/ios_sohu_spec.git"
        source = source_with_url(url)
        return source if source
      end
    end
  end
end
