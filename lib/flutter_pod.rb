module Pod
  class Podfile
    module DSL
      def flutter_pod(name, *requirements)
        if requirements.empty?
          pod name, *requirements
        else
          requirements.each do |param|
            if param.is_a? Hash
              if param[:path]
                # 本地源码集成
                path = param[:path]
                flutter_application_path = File.expand_path(name, path)
                flutter_script = File.join(flutter_application_path, ".ios", "Flutter", "podhelper.rb")
                load flutter_script
                # install_all_flutter_pods(flutter_application_path)
                require File.expand_path(File.join("packages", "flutter_tools", "bin", "podhelper"), flutter_root)

                flutter_application_path ||= File.join("..", "..")
                install_flutter_engine_pod(flutter_application_path)
                install_flutter_plugin_pods(flutter_application_path)
                install_flutter_application_pod(flutter_application_path)
              else
                pod name, *requirements
              end
            else
              pod name, *requirements
            end
          end
        end
      end
    end
  end
end
